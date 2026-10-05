local _,F=...
F.ProfessionActions={dirty=true}
local P=F.ProfessionActions

function P.RecipeID()
    local form=P.page and P.page.SchematicForm
    if not form or not form.GetRecipeInfo then return end
    local ok,info=pcall(form.GetRecipeInfo,form)
    if ok and type(info)=='table' and F.Integer(info.recipeID,1,2147483647) then return info.recipeID,info.name end
end
local function label(parent,width,gold)
    local text=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    text:SetWidth(width); text:SetWordWrap(true); text:SetJustifyH('LEFT'); F.Theme.Text(text,gold,12)
    return text
end
local function fail(why) F.Print(why or F.L('PRO_CHOOSE')); return false end
function P.Action(action)
    if not P.page or not P.page:IsVisible() then return fail(F.L('PRO_CHOOSE')) end
    -- Resolve the actual current schematic again; callbacks can lag a selection.
    P.Refresh()
    local id=P.RecipeID()
    local quantity=tonumber(P.qty:GetText())
    if not F.Integer(quantity,1,10000) then return fail(F.L('QUANTITY_ERROR')) end
    if action=='find' then
        local output,why=F.Adapter.RecipeOutput(id)
        if not output then return fail(why) end
        return F.UI.FindCrafters(output.output,quantity)
    end
    if action=='queue' and #F.Queue.data.goals>=F.Queue.MAX_GOALS then return fail(F.L('QUEUE_FULL')) end
    if action~='queue' and action~='materials' then return false end
    local recipe,why,recipeID=F.Adapter.CaptureRecipe(id)
    if not recipe then return fail(why) end
    if action=='queue' then
        local ok,message=F.Queue.Add(recipe.output,quantity,F.me,recipeID)
        if not ok then return fail(message) end
        F.Print(string.format(F.L('PRO_ADDED'),recipe.name,quantity))
        P.Refresh()
        return true
    end
    local profiles=F.Profiles()
    local inventory=F.Adapter.Inventory(profiles)
    inventory[recipe.output]=F.Adapter.StockCount(recipe.output)
    local plan=F.Planner.Build(profiles,recipe.output,quantity,inventory,nil,
        {owner=F.me,recipeID=recipeID,localOwner=F.me})
    plan.owner,plan.recipeID=F.me,recipeID
    F.UI.Plan(plan)
    return true
end
function P.Refresh()
    if not P.panel then return end
    P.dirty=false
    P.locale=F.Theme.Locale()
    local visible=P.page:IsVisible()
    P.panel:SetShown(visible)
    if not visible then return end
    local id,name=P.RecipeID()
    if P.selectedID~=id then
        P.selectedID=id; P.resetting=true; P.qty:SetText('1'); P.resetting=false
    end
    local recipe,why=F.Adapter.ReadRecipe(id)
    local lookup=F.Adapter.RecipeOutput(id)
    local quantity=tonumber(P.qty:GetText())
    local valid=recipe and F.Integer(quantity,1,10000)
    local width=math.max(340,P.page:GetWidth()-8)
    P.panel:SetWidth(width)
    P.title:SetWidth(width-24); P.title:SetText('ForeverNet'); P.title:Hide()
    P.quantityLabel:SetText(F.L('PRO_QUANTITY'))
    P.output:SetText(recipe and string.format(F.L('PRO_OUTPUT'),recipe.quantity) or '')
    P.help:SetWidth(width-24); P.help:SetText(''); P.help:Hide()
    P.status:SetWidth(width-24)
    P.status:SetText(F.Catalog.Safe(recipe and not valid and F.L('QUANTITY_ERROR') or not recipe and lookup and F.L('FINDER_LOOKUP_ONLY') or why or
        #F.Queue.data.goals>=F.Queue.MAX_GOALS and F.L('QUEUE_FULL') or ''))
    P.add:SetText(F.L('QUEUE_ADD')); P.materials:SetText(F.L('PRO_MATERIALS'))
    P.find:SetText(F.L('FINDER_BUTTON')); P.find:SetEnabled(not not lookup and F.Integer(quantity,1,10000))
    P.add:SetEnabled(not not valid and #F.Queue.data.goals<F.Queue.MAX_GOALS); P.materials:SetEnabled(not not valid)
    local labelWidth=math.min(width-100,math.max(110,math.ceil(P.quantityLabel:GetUnboundedStringWidth())))
    local infoWidth=math.max(205,labelWidth+76)
    local wide=width-infoWidth-48>=300
    if not wide then infoWidth=width-24 end
    P.quantityLabel:SetWidth(infoWidth-76)
    P.quantityLabel:ClearAllPoints(); P.quantityLabel:SetPoint('TOPLEFT',12,-14)
    P.qty:ClearAllPoints(); P.qty:SetPoint('TOPLEFT',12+labelWidth+10,-10)
    local outputTop=10+math.max(24,P.quantityLabel:GetStringHeight()+4)+4
    P.output:SetWidth(infoWidth); P.output:SetHeight(0)
    P.output:ClearAllPoints(); P.output:SetPoint('TOPLEFT',12,-outputTop)
    local infoBottom=outputTop+(P.output:GetText()~='' and P.output:GetStringHeight() or 0)
    local buttons=wide and {P.add,P.materials,P.find} or {P.add,P.materials}
    local startX=wide and infoWidth+24 or 12
    local buttonWidth=(width-startX-12-(#buttons-1)*8)/#buttons
    local natural,total={},0
    for i,b in ipairs(buttons) do natural[i]=math.max(80,F.Theme.ButtonWidth(b)); total=total+natural[i] end
    local available=width-startX-12-(#buttons-1)*8
    local widths={}
    local buttonHeight=0
    for i,b in ipairs(buttons) do
        widths[i]=total<=available and natural[i]+(available-total)/#buttons or buttonWidth
        buttonHeight=math.max(buttonHeight,F.Theme.FitButton(b,widths[i]))
    end
    local buttonTop=wide and 10+math.max(0,(infoBottom-10-buttonHeight)/2) or infoBottom+8
    local x=startX
    for i,b in ipairs(buttons) do
        b:ClearAllPoints(); b:SetPoint('TOPLEFT',x,-buttonTop); x=x+widths[i]+8
    end
    local y=math.max(infoBottom,buttonTop+buttonHeight)+6
    if not wide then
        P.find:ClearAllPoints(); P.find:SetPoint('TOPLEFT',12,-y)
        y=y+F.Theme.FitButton(P.find,width-24)+6
    end
    P.status:ClearAllPoints(); P.status:SetPoint('TOPLEFT',12,-y)
    P.status:SetShown(P.status:GetText()~='')
    if P.status:IsShown() then y=y+P.status:GetStringHeight()+6 end
    P.help:ClearAllPoints(); P.help:SetPoint('TOPLEFT',12,-y)
    P.panel:SetHeight(y+8)
end
function P.Attach()
    local page=ProfessionsFrame and ProfessionsFrame.CraftingPage
    if not page or not page.SchematicForm or not page.SchematicForm.GetRecipeInfo or not hooksecurefunc then return false end
    if P.page==page then return true end
    P.page=page
    if not P.panel then
        P.panel=CreateFrame('Frame',nil,page,'BackdropTemplate'); F.Theme.Skin(P.panel,true)
        P.panel:EnableMouse(true)
        P.panel:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,'ForeverNet',F.L('PRO_HELP')) end)
        P.panel:SetScript('OnLeave',F.Theme.HideTooltip)
        P.title=label(P.panel,616,true); P.title:SetPoint('TOPLEFT',12,-12)
        P.quantityLabel=label(P.panel,124,true); P.output=label(P.panel,424)
        P.help=label(P.panel,616); P.status=label(P.panel,616)
        P.qty=CreateFrame('EditBox',nil,P.panel,'InputBoxTemplate')
        P.qty:SetSize(54,24); P.qty:SetAutoFocus(false); P.qty:SetNumeric(true); F.Theme.Font(P.qty,12)
        P.qty:SetText('1')
        P.qty:SetScript('OnTextChanged',function() if not P.resetting then P.dirty=true end end)
        P.qty:SetScript('OnEscapePressed',function(b) b:ClearFocus() end)
        for _,entry in ipairs({{'add','queue'},{'materials','materials'},{'find','find'}}) do
            local action=entry[2]
            local b=CreateFrame('Button',nil,P.panel,'UIPanelButtonTemplate'); b:SetSize(302,24); F.Theme.Button(b)
            b:SetScript('OnClick',function() P.Action(action) end); P[entry[1]]=b
        end
    else P.panel:SetParent(page) end
    P.panel:ClearAllPoints(); P.panel:SetPoint('TOPLEFT',page,'BOTTOMLEFT',4,-4)
    page:HookScript('OnShow',function() P.dirty=true end)
    page:HookScript('OnHide',function() P.panel:Hide(); P.dirty=true end)
    page:HookScript('OnSizeChanged',function() P.dirty=true end)
    if page.SelectRecipe then hooksecurefunc(page,'SelectRecipe',function() P.dirty=true end) end
    P.Refresh()
    return true
end
function P.Start()
    if P.frame then return end
    P.frame=CreateFrame('Frame')
    for _,event in ipairs({'ADDON_LOADED','TRADE_SKILL_SHOW','TRADE_SKILL_LIST_UPDATE','TRADE_SKILL_DATA_SOURCE_CHANGED','GET_ITEM_INFO_RECEIVED'}) do
        P.frame:RegisterEvent(event)
    end
    P.frame:SetScript('OnEvent',function()
        P.dirty=true
        C_Timer.After(0,function() P.Attach() end)
    end)
    P.Attach()
end
function P.Tick(elapsed)
    if not P.panel or not P.page:IsVisible() then return end
    if P.locale~=F.Theme.Locale() then P.dirty=true end
    if not P.dirty then return end
    P.elapsed=(P.elapsed or 0)+elapsed
    if P.elapsed<.25 then return end
    P.elapsed=0; P.Refresh()
end
