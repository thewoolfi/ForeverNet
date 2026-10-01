local _, F = ...
F.UI = {page='recipes', rows={}, filter='', entries={}}
local U, C = F.UI, F.Catalog
local function skin(frame, dark)
    frame:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground', edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(dark and .065 or .11, dark and .045 or .075, dark and .025 or .04,.98)
    frame:SetBackdropBorderColor(.52,.38,.18,1)
end
local function label(parent,font,x,y,width,text)
    local l=parent:CreateFontString(nil,'OVERLAY',font)
    l:SetPoint('TOPLEFT',x,y); l:SetWidth(width); l:SetJustifyH('LEFT'); l:SetText(C.Safe(text)); return l
end
local function tooltip(widget,text)
    widget:SetScript('OnEnter',function(self)
        if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:SetText(F.L(text)); GameTooltip:Show() end
    end)
    widget:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
end
local function button(parent,text,x,y,width,action)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetSize(width,24); b:SetPoint('TOPLEFT',x,y); b:SetText(text); b:SetScript('OnClick',action); return b
end
local function who(owner) return owner == F.me and F.L('YOU') or owner end
local function amount(qty) return tostring(qty or 0) end
function U.Quantity() return tonumber(U.qty and U.qty:GetText()) end
function U.Ensure()
    if U.frame then return end
    local frame=CreateFrame('Frame','ForeverNetWindow',UIParent,'PortraitFrameTemplate')
    frame:SetSize(780,570); frame:SetPoint('CENTER'); frame:SetFrameStrata('DIALOG')
    frame:SetTitle('ForeverNet'); frame:SetPortraitToAsset('Interface\\Icons\\Trade_Engineering')
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
    U.heading=label(frame,'GameFontNormal',78,-48,310,'')
    U.sharing=label(frame,'GameFontHighlightSmall',24,-73,730,'')
    U.scan=button(frame,'',405,-48,108,function() F.Command('scan') end)
    U.share=button(frame,'',519,-48,108,function() F.Command('share '..(F.db.settings.sharing and 'off' or 'on')) end)
    U.sync=button(frame,'',633,-48,122,function() F.Command('sync') end)
    tooltip(U.scan,'SCAN_HINT'); tooltip(U.share,'SHARE_HINT'); tooltip(U.sync,'SYNC_HINT')
    local left=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    left:SetPoint('TOPLEFT',14,-93); left:SetSize(248,357); skin(left,true)
    U.searchLabel=label(left,'GameFontNormalSmall',14,-10,222,'')
    U.search=CreateFrame('EditBox',nil,left,'InputBoxTemplate')
    U.search:SetSize(210,24); U.search:SetPoint('TOPLEFT',16,-29); U.search:SetAutoFocus(false)
    U.search:SetScript('OnTextChanged',function(self)
        U.filter=self:GetText(); if not U.resettingSearch then U.Status() end
    end)
    U.search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    U.listScroll=CreateFrame('ScrollFrame',nil,left,'UIPanelScrollFrameTemplate')
    U.listScroll:SetPoint('TOPLEFT',8,-65); U.listScroll:SetPoint('BOTTOMRIGHT',-28,12)
    U.list=CreateFrame('Frame',nil,U.listScroll); U.list:SetSize(208,280); U.listScroll:SetScrollChild(U.list)
    U.empty=label(U.list,'GameFontHighlightSmall',8,-14,188,'')
    local right=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    right:SetPoint('TOPLEFT',270,-93); right:SetSize(496,357); skin(right)
    U.hero=right:CreateTexture(nil,'ARTWORK'); U.hero:SetSize(40,40); U.hero:SetPoint('TOPLEFT',14,-12)
    U.detailTitle=label(right,'GameFontNormalLarge',66,-14,397,'')
    U.detailTitle:SetHeight(22)
    U.summary=label(right,'GameFontHighlightSmall',66,-39,397,'')
    U.summary:SetHeight(20)
    U.details=CreateFrame('ScrollFrame',nil,right,'UIPanelScrollFrameTemplate')
    U.details:SetPoint('TOPLEFT',16,-64); U.details:SetPoint('BOTTOMRIGHT',-28,46)
    U.body=CreateFrame('Frame',nil,U.details); U.body:SetSize(440,240)
    U.bodyText=U.body:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetWidth(440)
    U.bodyText:SetSpacing(4); U.bodyText:SetJustifyH('LEFT'); U.bodyText:SetJustifyV('TOP'); U.bodyText:SetWordWrap(true)
    U.details:SetScrollChild(U.body)
    U.accept=button(right,'',12,-319,150,function() U.RequestAction('accept') end)
    U.done=button(right,'',169,-319,150,function() U.RequestAction('done') end)
    U.cancel=button(right,'',326,-319,150,function() U.RequestAction('cancel') end)
    U.itemLabel=label(frame,'GameFontNormalSmall',24,-461,235,'')
    local chosen=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    chosen:SetPoint('TOPLEFT',14,-479); chosen:SetSize(248,42); skin(chosen,true)
    U.itemIcon=chosen:CreateTexture(nil,'ARTWORK'); U.itemIcon:SetSize(28,28); U.itemIcon:SetPoint('LEFT',8,0)
    U.item=label(chosen,'GameFontHighlightSmall',43,-8,193,'')
    U.item:SetHeight(28)
    U.qtyLabel=label(frame,'GameFontNormalSmall',280,-461,68,'')
    U.qty=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
    U.qty:SetSize(55,24); U.qty:SetPoint('TOPLEFT',285,-487); U.qty:SetNumeric(true); U.qty:SetAutoFocus(false); U.qty:SetText('1')
    U.qty:SetScript('OnTextChanged',function()
        if U.frame and not U.settingTarget then U.UpdateActions(); U.RenderSelection() end
    end)
    U.qty:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    U.plan=button(frame,'',355,-487,185,function() U.BuildSelected() end)
    U.request=button(frame,'',550,-487,200,function() U.RequestSelected() end)
    U.footer=label(frame,'GameFontHighlightSmall',24,-535,450,'')
    U.demo=button(frame,'',490,-535,112,function() F.Command('demo') end)
    U.help=button(frame,'',614,-535,136,function() U.Help() end)
    local icons={'Trade_Engineering','INV_Misc_GroupLooking','INV_Misc_Note_01','INV_Misc_EngGizmos_01','Trade_Engineering'}
    local pages={'recipes','network','requests','chain','settings'}
    U.navigation={}
    for i,page in ipairs(pages) do
        local nav=CreateFrame('Button',nil,frame,'BackdropTemplate')
        nav:SetSize(44,44); nav:SetPoint('TOPLEFT',778,-93-(i-1)*48); skin(nav)
        local icon=nav:CreateTexture(nil,'ARTWORK')
        icon:SetPoint('TOPLEFT',7,-7); icon:SetPoint('BOTTOMRIGHT',-7,7); icon:SetTexture('Interface\\Icons\\'..icons[i])
        nav:SetScript('OnClick',function() if page=='settings' then F.Settings.Open() else U.Navigate(page) end end); tooltip(nav,'PAGE_'..page)
        U.navigation[page]=nav
    end
    U.frame=frame; frame:Hide(); UISpecialFrames[#UISpecialFrames+1]='ForeverNetWindow'
end
function U.Toggle()
    if U.frame and U.frame:IsShown() then U.frame:Hide() else U.Status() end
end
function U.Navigate(page)
    U.Ensure(); U.page,U.selectionKey,U.view=page,nil,nil
    U.resettingSearch=true; U.search:SetText(''); U.filter=''; U.resettingSearch=false
    U.listScroll:SetVerticalScroll(0)
    if page=='chain' and U.planData then U.SetTarget(U.planData.target,U.planData.quantity,U.planData.owner,U.planData.recipeID,U.planData.demo) end
    U.Status()
end
function U.SetTarget(item,quantity,owner,recipeID,demo)
    U.Ensure(); U.target={item=item,owner=owner,recipeID=recipeID,demo=demo}
    U.settingTarget=true; U.qty:SetText(amount(quantity or 1)); U.settingTarget=false
    U.UpdateActions()
end
function U.UpdateActions()
    if not U.frame then return end
    local target,qty=U.target,U.Quantity()
    local valid=target and F.ID(target.item) and F.Integer(qty,1,10000)
    U.item:SetText(C.Safe(target and C.ItemName(target.item) or F.L('CHOOSE_RECIPE')))
    U.itemIcon:SetTexture(target and C.Icon(target.item) or 'Interface\\Icons\\INV_Misc_QuestionMark')
    U.plan:SetEnabled(not not valid)
    local canRequest=valid and not target.demo and U.page~='requests' and F.db.settings.sharing and F.Net.available and F.Net.Channel()
    U.request:SetEnabled(not not canRequest)
    local hint
    if not target then hint='CHOOSE_RECIPE'
    elseif not F.Integer(qty,1,10000) then hint='QUANTITY_ERROR'
    elseif target.demo then hint='DEMO_ONLY'
    elseif not F.db.settings.sharing then hint='ENABLE_TO_REQUEST'
    elseif not F.Net.Channel() then hint='JOIN_TO_REQUEST'
    else hint='FOOTER_FLOW' end
    U.footer:SetText(F.L(hint))
end
function U.Show(text,title,subtitle,tone)
    U.Ensure(); for _,block in ipairs(U.blocks or {}) do block.title:Hide(); block.text:Hide() end
    U.bodyText:Show(); for _,card in ipairs(U.cards or {}) do card:Hide() end
    U.hero:SetTexture(U.selectedEntry and U.selectedEntry.item and C.Icon(U.selectedEntry.item) or 'Interface\\Icons\\INV_Misc_EngGizmos_01')
    U.accept:Hide(); U.done:Hide(); U.cancel:Hide()
    U.detailTitle:SetText(C.Safe(title or F.L('PAGE_'..U.page)))
    U.summary:SetText(C.Safe(subtitle or ''))
    if tone=='good' then U.summary:SetTextColor(.35,.9,.45)
    elseif tone=='missing' then U.summary:SetTextColor(1,.72,.25)
    else U.summary:SetTextColor(.8,.8,.8) end
    U.bodyText:ClearAllPoints(); U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetHeight(0); U.bodyText:SetText(C.Safe(text))
    U.body:SetHeight(math.max(240,U.bodyText:GetStringHeight()+24))
    U.details:SetVerticalScroll(0); U.frame:Show()
end
function U.RefreshRows()
    for _, row in ipairs(U.rows) do row:Hide() end
    local profiles,entries=F.Profiles(),{}
    local function add(entry)
        local text=C.Fold(entry.title..' '..(entry.subtitle or ''))
        if U.filter=='' or text:find(C.Fold(U.filter),1,true) then entries[#entries+1]=entry end
    end
    if U.page=='recipes' then entries=C.Recipes(profiles,U.filter)
    elseif U.page=='network' then
        for _, owner in ipairs(F.Keys(profiles)) do
            local p=profiles[owner]
            add({key=owner,kind='player',owner=owner,title=who(owner),subtitle=string.format(F.L('RECIPE_COUNT'),#F.Keys(p.recipes))})
        end
    elseif U.page=='requests' then
        for _, id in ipairs(F.Keys(F.db.requests)) do
            local r=F.db.requests[id]
            add({key=id,kind='request',request=r,item=r.item,title=C.ItemName(r.item)..' x'..r.quantity,
                subtitle=F.L('STATUS_'..r.status)..' / '..who(r.owner)})
        end
    elseif U.page=='chain' and U.planData then
        for _, item in ipairs(F.Keys(U.planData.missing)) do
            add({key='missing/'..item,kind='missing',item=item,quantity=U.planData.missing[item],title=C.ItemName(item),
                subtitle=string.format(F.L('MISSING_QUANTITY'),U.planData.missing[item])})
        end
        for i,step in ipairs(U.planData.steps) do
            add({key='step/'..i,kind='step',step=step,item=step.item,title=i..'. '..C.ItemName(step.item,step.name),subtitle=who(step.owner)})
        end
    end
    U.entries=entries; U.selectedEntry=nil
    for i,entry in ipairs(entries) do
        local b=U.rows[i]
        if not b then
            b=CreateFrame('Button',nil,U.list,'BackdropTemplate'); b:SetSize(208,46); skin(b,true)
            b.icon=b:CreateTexture(nil,'ARTWORK'); b.icon:SetSize(26,26); b.icon:SetPoint('LEFT',7,0)
            b.label=label(b,'GameFontHighlightSmall',40,-7,158,'')
            b.label:SetHeight(34)
            b:SetScript('OnEnter',function(self) self:SetBackdropBorderColor(.95,.75,.22,1) end)
            b:SetScript('OnLeave',function(self) self:SetBackdropBorderColor(self.selected and .95 or .52,self.selected and .75 or .38,.18,1) end)
            U.rows[i]=b
        end
        b.entry,b.selected=entry,U.selectionKey==entry.key
        if b.selected then U.selectedEntry=entry end
        b:SetPoint('TOPLEFT',0,-(i-1)*48); b.label:SetText(C.Safe(entry.title..'\n'..(entry.subtitle or '')))
        b.icon:SetTexture(entry.item and C.Icon(entry.item) or 'Interface\\Icons\\INV_Misc_GroupLooking')
        b:SetBackdropBorderColor(b.selected and .95 or .52,b.selected and .75 or .38,.18,1)
        b:SetScript('OnClick',function(self) U.Select(self.entry) end); b:Show()
    end
    U.list:SetHeight(math.max(280,#entries*48)); U.empty:SetShown(#entries==0)
    U.empty:SetText(F.L(U.filter~='' and 'SEARCH_EMPTY' or 'EMPTY_'..U.page))
end
function U.Select(entry)
    U.selectionKey,U.view=entry.key,nil
    if entry.kind=='recipe' then U.SetTarget(entry.item,U.Quantity() or 1,entry.owner,entry.recipeID)
    elseif entry.kind=='request' then U.SetTarget(entry.item,entry.request.quantity)
    elseif entry.kind=='missing' then U.SetTarget(entry.item,entry.quantity,nil,nil,U.planData.demo)
    elseif entry.kind=='step' then U.SetTarget(entry.item,entry.step.quantity,entry.step.owner,entry.step.recipeID,U.planData.demo) end
    U.Status()
end
function U.RenderSelection()
    local e=U.selectedEntry
    if U.view=='help' then U.RenderHelp(); return end
    if not e then
        if U.page=='chain' and U.planData then U.RenderPlan(); return end
        if U.page~='recipes' then U.Show(F.L('EMPTY_'..U.page),F.L('PAGE_'..U.page)); return end
        local hasRecipes=#C.Recipes(F.Profiles(),'')>0
        U.Show(F.L(hasRecipes and 'START_PICK' or 'START_SCAN'),F.L('WHAT_TO_MAKE'),F.L('START_SUBTITLE'))
        return
    end
    if e.kind=='recipe' then
        local r,qty=e.recipe,U.Quantity()
        if not F.Integer(qty,1,10000) then U.Show(F.L('QUANTITY_ERROR'),e.title); return end
        local inBags=F.Adapter.StockCount(e.item)
        local batches=math.ceil(math.max(0,qty-inBags)/r.quantity)
        local lines={string.format(F.L('RECIPE_OVERVIEW'),qty,inBags,r.quantity,batches),'',F.L('DIRECT_REAGENTS')}
        if next(r.reagents)==nil then lines[#lines+1]=F.L('NO_REAGENTS') end
        for _,station in ipairs(F.Keys(r.stations)) do lines[#lines+1]='\n'..F.L('CAMP')..station end
        if r.blueprint then lines[#lines+1]='\nBlueprint' end
        lines[#lines+1]='\n'..F.L('RECIPE_NEXT')
        U.Show(table.concat(lines,'\n'),e.title,F.L('CRAFTER')..who(e.owner))
        local cards={}
        for _,item in ipairs(F.Keys(r.reagents)) do
            local needed=r.reagents[item]*batches; local have=F.Adapter.StockCount(item)
            cards[#cards+1]={item=item,title=C.ItemName(item),text=string.format(F.L('MATERIAL_CARD'),F.Adapter.ItemCount(item),F.Bank.Count(item),needed),good=have>=needed}
        end
        U.ShowCards(cards)
    elseif e.kind=='player' then
        local p=F.db.profiles[e.owner]; if not p then return end
        local lines={F.L('PROFESSIONS')}
        for _,id in ipairs(F.Keys(p.professions)) do lines[#lines+1]=C.ProfessionName(id)..': '..p.professions[id] end
        lines[#lines+1]='\n'..F.L('CAPABILITIES')
        for _,id in ipairs(F.Keys(p.recipes)) do local r=p.recipes[id]; lines[#lines+1]=C.ItemName(r.output,r.name)..(r.blueprint and ' [Blueprint]' or '') end
        for _,id in ipairs(F.Keys(p.camps)) do lines[#lines+1]=F.L('CAMP')..id..' ('..math.max(0,p.camps[id]-F.Now())..F.L('SECONDS')..')' end
        U.Show(table.concat(lines,'\n'),e.title,string.format(F.L('DATA_AGE'),math.max(0,math.floor((F.Now()-p.seen)/60))))
    elseif e.kind=='request' then
        local r=e.request
        U.requestID=r.id
        U.Show(F.L('OWNER')..who(r.owner)..'\n'..F.L('CRAFTER')..(r.assignee~='' and who(r.assignee) or F.L('NOT_ASSIGNED'))..
            '\n\n'..string.format(F.L('REQUEST_EXPIRES'),math.max(0,math.ceil((r.expires-F.Now())/60)))..'\n\n'..F.L('REQUEST_HELP'),e.title,F.L('STATUS_'..r.status))
        local pending=F.Requests.IsOfferPending(r.id)
        U.accept:SetText(F.L(pending and 'OFFER_PENDING' or 'ACCEPT'))
        U.accept:SetShown(r.owner~=F.me and r.status=='open'); U.accept:SetEnabled(not pending and F.db.settings.sharing)
        U.done:SetShown(r.owner==F.me and r.status=='accepted'); U.done:SetEnabled(F.db.settings.sharing)
        U.cancel:SetShown(r.owner==F.me and (r.status=='open' or r.status=='accepted')); U.cancel:SetEnabled(F.db.settings.sharing)
    elseif e.kind=='missing' then
        local reason=U.planData.missingReasons[e.item] or 'unknown'
        U.Show(F.L('MISSING_REASON_'..reason)..'\n\n'..F.L('MISSING_HELP'),e.title,string.format(F.L('MISSING_QUANTITY'),e.quantity),'missing')
    elseif e.kind=='step' then
        local s=e.step
        local lines={string.format(F.L('STEP_OUTPUT'),s.batches,s.quantity)}
        for _,station in ipairs(F.Keys(s.stations)) do lines[#lines+1]=F.L('CAMP')..station..': '..who(s.stations[station]) end
        lines[#lines+1]='\n'..F.L('MANUAL_CRAFT')
        U.Show(table.concat(lines,'\n'),e.title,F.L('CRAFTER')..who(s.owner))
    end
end
function U.RenderPlan()
    local p=U.planData
    U.Show('',C.ItemName(p.target)..' x'..p.quantity,F.L(p.demo and 'DEMO_ONLY' or p.complete and 'PLAN_READY' or 'PLAN_NEEDS'),p.complete and 'good' or 'missing')
    local cards={}
    for _,item in ipairs(F.Keys(p.missing)) do cards[#cards+1]={item=item,title=C.ItemName(item),text=string.format(F.L('MISSING_QUANTITY'),p.missing[item]),good=false} end
    for _,item in ipairs(F.Keys(p.supplied)) do
        local bags=p.bagSupplied and p.bagSupplied[item] or p.supplied[item]
        cards[#cards+1]={item=item,title=C.ItemName(item),text=string.format(F.L('STOCK_CARD'),bags,p.supplied[item]-bags),good=true}
    end
    local y=U.ShowCards(cards)
    local blocks={}
    if next(p.missing)==nil then blocks[#blocks+1]={title=F.L('PLAN_MISSING'),text=F.L('NOTHING_MISSING')} end
    for i,step in ipairs(p.steps) do
        blocks[#blocks+1]={title=i..'. '..C.ItemName(step.item,step.name)..' x'..step.quantity,
            text=F.L('CRAFTER')..who(step.owner)..'\n'..string.format(F.L('CRAFTS'),step.batches)}
    end
    if #p.steps==0 and p.complete then blocks[#blocks+1]={title=F.L('PLAN_STEPS'),text=F.L('ALREADY_OWNED')} end
    if #p.warnings>0 then blocks[#blocks+1]={title=F.L('PLAN_NEEDS'),text=F.L('PLAN_CYCLE_WARNING')} end
    if not p.demo and F.db.settings.useBank~=false then blocks[#blocks+1]={title=F.L('BANK_SECTION'),text=F.Bank.Status()..'\n\n'..F.L('BANK_REMINDER')} end
    blocks[#blocks+1]={title=F.L('NEXT_SECTION'),text=F.L('MANUAL_CRAFT')}
    U.ShowBlocks(blocks,y)
end
function U.Status()
    U.Ensure(); F.Prune()
    U.heading:SetText(F.L(U.page=='recipes' and 'WHAT_TO_MAKE' or 'PAGE_'..U.page))
    U.sharing:SetText(string.format(F.L('NETWORK_SUMMARY'),#C.Recipes(F.db.profiles,''),#F.Keys(F.db.profiles),F.L(F.db.settings.sharing and 'включён' or 'выключен')))
    U.scan:SetText(F.L('Сканировать')); U.share:SetText(F.L(F.db.settings.sharing and 'SHARE_ON' or 'SHARE_OFF')); U.sync:SetText(F.L('Обновить'))
    U.searchLabel:SetText(F.L('SEARCH_LABEL')); U.itemLabel:SetText(F.L('CHOSEN_ITEM')); U.qtyLabel:SetText(F.L('QUANTITY_FIELD'))
    U.plan:SetText(F.L('Собрать цепочку')); U.request:SetText(F.L('ASK_HELP')); U.demo:SetText(F.L('DEMO_BUTTON')); U.help:SetText(F.L('HELP_BUTTON'))
    U.accept:SetText(F.L('ACCEPT')); U.done:SetText(F.L('DONE')); U.cancel:SetText(F.L('CANCEL'))
    for page,nav in pairs(U.navigation) do nav:SetBackdropBorderColor(page==U.page and .95 or .52,page==U.page and .72 or .38,.18,1) end
    U.RefreshRows(); U.UpdateActions(); U.RenderSelection(); U.frame:Show()
end
function U.BuildSelected()
    local target,qty=U.target,U.Quantity()
    if not target or not F.Integer(qty,1,10000) then return end
    local profiles=target.demo and F.Adapter.Demo() or F.Profiles()
    local inventory=target.demo and {['demo:ore']=3,['demo:cloth']=4} or F.Adapter.Inventory(profiles)
    if not target.demo then inventory[target.item]=F.Adapter.StockCount(target.item) end
    local p=F.Planner.Build(profiles,target.item,qty,inventory,nil,{owner=target.owner,recipeID=target.recipeID,localOwner=F.me})
    p.demo,p.owner,p.recipeID=target.demo,target.owner,target.recipeID; U.Plan(p)
end
function U.RequestSelected()
    if not U.target or U.target.demo or U.page=='requests' then return end
    local ok,id=F.Requests.Create(U.target.item,U.Quantity())
    if not ok then F.Print(id); return end
    U.Navigate('requests'); U.selectionKey=id; U.Status(); F.Print(F.L('REQUEST_PUBLISHED'))
end
function U.RequestAction(action)
    if not U.selectedEntry or U.selectedEntry.kind~='request' then return end
    local id=U.selectedEntry.key
    local ok,why
    if action=='accept' then ok,why=F.Requests.Accept(id) else ok,why=F.Requests.Close(id,action=='done' and 'done' or 'cancelled') end
    if not ok then F.Print(why) elseif action=='accept' then F.Print(F.L('OFFER_SENT')) end
    U.Status()
end
function U.RequestList() U.Navigate('requests') end
function U.Plan(plan)
    plan.bagSupplied={}
    for item,count in pairs(plan.supplied) do plan.bagSupplied[item]=plan.demo and count or math.min(F.Adapter.ItemCount(item),count) end
    U.planData=plan; U.Navigate('chain')
end
function U.Help() U.Ensure(); U.view='help'; U.Status() end
function U.DataChanged() U.dirty=true end
function U.Tick(elapsed)
    U.elapsed=(U.elapsed or 0)+elapsed
    if U.elapsed<.5 then return end
    U.elapsed=0
    if U.dirty or (U.frame and U.frame:IsShown() and U.page=='requests') then
        U.dirty=false
        if U.frame and U.frame:IsShown() then
            local position=U.details:GetVerticalScroll()
            U.Status(); U.details:SetVerticalScroll(math.min(position,math.max(0,U.body:GetHeight()-240)))
        end
    end
end

function U.ShowCards(entries)
    U.cards=U.cards or {}
    local y=0
    for i,entry in ipairs(entries) do
        local card=U.cards[i]
        if not card then
            card=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); card:SetSize(434,56); skin(card,true)
            card.icon=card:CreateTexture(nil,'ARTWORK'); card.icon:SetSize(38,38); card.icon:SetPoint('TOPLEFT',8,-8)
            card.title=label(card,'GameFontNormal',56,-8,368,''); card.title:SetHeight(18)
            card.detail=label(card,'GameFontHighlightSmall',56,-30,368,''); card.detail:SetHeight(18)
            U.cards[i]=card
        end
        card:SetPoint('TOPLEFT',0,-y); card.icon:SetTexture(C.Icon(entry.item))
        card.title:SetText(C.Safe(entry.title)); card.detail:SetText(C.Safe(entry.text))
        local r,g,b=entry.good and .3 or 1,entry.good and .8 or .55,entry.good and .45 or .2
        card:SetBackdropBorderColor(r,g,b,1); card.detail:SetTextColor(r,g,b); card:Show(); y=y+68
    end
    U.bodyText:ClearAllPoints(); U.bodyText:SetPoint('TOPLEFT',0,-y)
    U.body:SetHeight(math.max(240,y+U.bodyText:GetStringHeight()+24))
    return y
end

-- Separate, measured text blocks avoid cramped paragraphs and hard-coded heights.
function U.ShowBlocks(entries,offset)
    U.bodyText:Hide(); U.blocks=U.blocks or {}
    local y=offset or 0
    for i,entry in ipairs(entries) do
        local block=U.blocks[i]
        if not block then
            block={title=label(U.body,'GameFontNormal',4,0,426,''),text=label(U.body,'GameFontHighlight',4,0,426,'')}
            block.text:SetSpacing(4); block.text:SetWordWrap(true)
            U.blocks[i]=block
        end
        block.title:ClearAllPoints(); block.title:SetPoint('TOPLEFT',4,-y)
        block.title:SetHeight(0); block.title:SetText(C.Safe(entry.title)); block.title:Show()
        y=y+block.title:GetStringHeight()+8
        block.text:ClearAllPoints(); block.text:SetPoint('TOPLEFT',4,-y)
        block.text:SetHeight(0); block.text:SetText(C.Safe(entry.text)); block.text:Show()
        y=y+block.text:GetStringHeight()+22
    end
    U.body:SetHeight(math.max(240,y+8))
end
function U.RenderHelp()
    U.Show('',F.L('HELP_BUTTON'))
    U.hero:SetTexture('Interface\\Icons\\INV_Misc_Book_09')
    local blocks={}
    for i=1,4 do blocks[#blocks+1]={title=i..'. '..F.L('HELP_TITLE_'..i),text=F.L('HELP_TEXT_'..i)} end
    blocks[#blocks+1]={title=F.L('HELP_NETWORK'),text=F.L('HELP_NETWORK_TEXT')}
    blocks[#blocks+1]={title=F.L('HELP_CONTROLS'),text=F.L('MINIMAP_HINT')..'\n/fn settings - '..F.L('SETTINGS')}
    U.ShowBlocks(blocks)
end
