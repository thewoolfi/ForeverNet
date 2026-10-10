local _,F=...
F.ProfessionLinks={rows=setmetatable({}, {__mode='k'})}
local L=F.ProfessionLinks
local function other()
    local addon=_G.ForeverLink
    return addon and type(addon.Link)=='function' and addon
end
local function info(row,node)
    if row.GetElementData then node=row:GetElementData() end
    local data=node and (node.GetData and node:GetData() or node.data or node)
    local recipe=data and data.recipeInfo
    if recipe and Professions and Professions.GetHighestLearnedRecipe then
        recipe=Professions.GetHighestLearnedRecipe(recipe) or recipe
    end
    return recipe
end
local function validLink(link)
    return type(link)=='string' and link:find('|H[%w_]+:[^|]+|h') and link or nil
end
function L.Link(id)
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeLink or not F.Integer(id,1,2147483647) then return end
    local ok,link=pcall(C_TradeSkillUI.GetRecipeLink,id)
    return ok and validLink(link) or nil
end
function L.Insert(link)
    if not validLink(link) then return false end
    if ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow() then
        return ChatFrameUtil.InsertLink and ChatFrameUtil.InsertLink(link)~=false or false
    end
    if ChatEdit_InsertLink and ChatEdit_InsertLink(link) then return true end
    if ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat(link); return true end
    if ChatFrame_OpenChat then ChatFrame_OpenChat(link); return true end
    return false
end
local function makeButton(row)
    local button=CreateFrame('Button',nil,row)
    button:SetSize(20,20); button:RegisterForClicks('LeftButtonUp')
    button.Background=button:CreateTexture(nil,'BACKGROUND'); button.Background:SetAllPoints()
    button.Icon=button:CreateTexture(nil,'ARTWORK'); button.Icon:SetSize(16,16); button.Icon:SetPoint('CENTER')
    function button:RefreshAppearance(hover)
        local enabled=self:IsEnabled()
        self.Icon:SetAtlas(enabled and 'common-icon-chatlink' or 'common-icon-chatlink-disable')
        self.Background:SetAtlas(not enabled and 'common-button-tertiary-square-disabled' or
            hover and 'common-button-tertiary-square-hover' or 'common-button-tertiary-square-normal')
    end
    button:SetScript('OnEnter',function(self)
        self:RefreshAppearance(true)
        F.Theme.ShowTooltip(self,F.L('RECIPE_CHAT_LINK'),F.L(self:IsEnabled() and 'RECIPE_CHAT_LINK_HELP' or 'RECIPE_CHAT_LINK_UNAVAILABLE'))
    end)
    button:SetScript('OnLeave',function(self) self:RefreshAppearance(false); F.Theme.HideTooltipFor(self) end)
    button:SetScript('OnHide',function(self) F.Theme.HideTooltipFor(self) end)
    button:SetScript('OnClick',function()
        -- The native ScrollBox reuses rows; resolve the current recipe on click.
        local recipe=info(row,row.foreverNetLinkNode)
        local link=recipe and L.Link(recipe.recipeID)
        if not link or not L.Insert(link) then F.Print(F.L('RECIPE_CHAT_LINK_UNAVAILABLE')) end
    end)
    row.foreverNetRecipeLink=button
    return button
end
function L.UpdateRow(row,node,initialized)
    local button=row.foreverNetRecipeLink
    if other() then if button then button:Hide() end; return end
    if initialized and row.Label then L.rows[row]=row.Label:GetWidth() end
    row.foreverNetLinkNode=node
    local recipe=info(row,node)
    if not recipe or not row.Label then if button then button:Hide() end; return end
    L.rows[row]=L.rows[row] or row.Label:GetWidth()
    button=button or makeButton(row)
    button:SetEnabled(L.Link(recipe.recipeID)~=nil); button:RefreshAppearance(false)
    local locked=row.LockedIcon and row.LockedIcon:IsShown() and row.LockedIcon
    local countWidth=row.Count and row.Count:IsShown() and row.Count:GetStringWidth() or 0
    local skillWidth=row.SkillUps and row.SkillUps:GetWidth() or 0
    row.Label:SetWidth(math.max(1,math.min(L.rows[row],row:GetWidth()-skillWidth-countWidth-(locked and locked:GetWidth() or 0)-34)))
    button:ClearAllPoints()
    if locked then button:SetPoint('RIGHT',locked,'LEFT',-2,0)
    else button:SetPoint('RIGHT',row,'RIGHT',-2,0) end
    button:Show()
end
function L.ReleaseRows()
    local addon=other()
    local changed=false
    for row,width in pairs(L.rows) do
        changed=true
        if row.foreverNetRecipeLink then row.foreverNetRecipeLink:Hide() end
        if row.Label then
            row.Label:SetWidth(width)
            -- A late-loaded ForeverLink may have captured our reserved width.
            -- Restore its native baseline before its existing layout refresh.
            if row.foreverLinkRecipeLink then row.foreverLinkLinkLabelWidth=width end
        end
    end
    L.rows=setmetatable({}, {__mode='k'})
    if changed and addon and addon.Refresh then addon.Refresh() end
end
function L.Refresh()
    if other() then L.ReleaseRows(); return end
    if L.scrollBox then L.scrollBox:ForEachFrame(function(row,node) L.UpdateRow(row,node,false) end) end
end
function L.Attach()
    if other() then L.ReleaseRows(); return false end
    local page=ProfessionsFrame and ProfessionsFrame.CraftingPage
    local box=page and page.RecipeList and page.RecipeList.ScrollBox
    if not box or not ScrollUtil or not ScrollUtil.AddInitializedFrameCallback then return false end
    if L.scrollBox==box then return true end
    L.scrollBox=box
    ScrollUtil.AddInitializedFrameCallback(box,function(_,row,node) L.UpdateRow(row,node,true) end,L,false)
    box:ForEachFrame(function(row,node) L.UpdateRow(row,node,true) end)
    return true
end
function L.Start()
    if L.frame then return end
    L.frame=CreateFrame('Frame')
    for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','TRADE_SKILL_SHOW','TRADE_SKILL_LIST_UPDATE','TRADE_SKILL_DATA_SOURCE_CHANGED','GET_ITEM_INFO_RECEIVED'}) do L.frame:RegisterEvent(event) end
    L.frame:SetScript('OnEvent',function()
        C_Timer.After(0,function() if L.Attach() then L.Refresh() end end)
    end)
    L.Attach()
end
