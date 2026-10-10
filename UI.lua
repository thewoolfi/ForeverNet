local _, F = ...
F.UI = {page='home', rows={}, filter='', entries={}, recipeChoices={}}
local U, C = F.UI, F.Catalog
local function skin(frame, dark)
    F.Theme.Skin(frame,dark)
end
local function label(parent,font,x,y,width,text)
    local l=parent:CreateFontString(nil,'OVERLAY',font)
    l:SetPoint('TOPLEFT',x,y); l:SetWidth(width); l:SetJustifyH('LEFT'); l:SetText(C.Safe(text))
    F.Theme.Text(l,font:find('Normal',1,true),font:find('Small',1,true) and 12 or 14); return l
end
local function tooltip(widget,text)
    widget:SetScript('OnEnter',function(self)
        F.Theme.ShowTooltip(self,F.L(text))
    end)
    widget:SetScript('OnLeave',F.Theme.HideTooltip)
end
local function button(parent,text,x,y,width,action)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetSize(width,24); b:SetPoint('TOPLEFT',x,y); b:SetText(text); F.Theme.Button(b); b:SetScript('OnClick',action); return b
end
local function who(owner) return owner == F.me and F.L('YOU') or owner end
local function profileAge(profile)
    if not F.Integer(profile.seen,0,2147483647) then return F.L('FINDER_AGE_UNKNOWN') end
    return string.format(F.L(F.ProfileStale(profile) and 'PROFILE_CACHED_AGE' or 'DATA_AGE'),math.max(0,math.floor((F.Now()-profile.seen)/60)))
end
local function amount(qty) return tostring(qty or 0) end
function U.Quantity() return tonumber(U.qty and U.qty:GetText()) end
function U.Ensure()
    if U.frame then return end
    local frame=CreateFrame('Frame','ForeverNetWindow',UIParent,'PortraitFrameTemplate')
    frame:SetSize(780,570); frame:SetPoint('CENTER'); frame:SetFrameStrata('DIALOG'); frame:SetClampedToScreen(true)
    frame:SetTitle('ForeverNet'); frame:SetPortraitToAsset(F.icon)
    F.Theme.Title(frame)
    U.paper,U.paperBase=F.Theme.Background(frame)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
    U.heading=label(frame,'GameFontNormal',24,-48,360,'')
    U.sharing=label(frame,'GameFontHighlightSmall',24,-73,730,'')
    U.scan=button(frame,'',405,-48,108,function() F.Command('scan') end)
    U.share=button(frame,'',519,-48,108,function() F.Command('share '..(F.db.settings.sharing and 'off' or 'on')) end)
    U.sync=button(frame,'',633,-48,122,function() F.Command('sync') end)
    tooltip(U.scan,'SCAN_HINT'); tooltip(U.share,'SHARE_HINT'); tooltip(U.sync,'SYNC_HINT')
    local left=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    U.left=left
    left:SetPoint('TOPLEFT',14,-93); left:SetSize(248,357); skin(left,true)
    U.searchLabel=label(left,'GameFontNormalSmall',14,-10,222,'')
    U.search=CreateFrame('EditBox',nil,left,'InputBoxTemplate')
    U.search:SetFontObject('GameFontHighlightSmall')
    F.Theme.Font(U.search,12)
    U.search:SetSize(124,22); U.search:SetPoint('TOPLEFT',16,-29); U.search:SetAutoFocus(false)
    U.filterButton=button(left,'',150,-29,82,function() if U.page=='queue' then U.QueueMenu() else U.OpenFilters() end end)
    U.filterButton:SetHeight(22)
    U.search:SetScript('OnTextChanged',function(self)
        U.filter=self:GetText(); if not U.resettingSearch then U.Status() end
    end)
    U.search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    U.listScroll=F.Theme.ScrollFrame(left)
    U.listScroll:SetPoint('TOPLEFT',8,-65); U.listScroll:SetPoint('BOTTOMRIGHT',-28,12)
    U.list=CreateFrame('Frame',nil,U.listScroll); U.list:SetSize(208,280); U.listScroll:SetScrollChild(U.list)
    U.empty=label(U.list,'GameFontHighlightSmall',8,-14,188,'')
    local right=CreateFrame('Frame',nil,frame,'BackdropTemplate'); U.right=right
    right:SetPoint('TOPLEFT',270,-93); right:SetSize(496,357); skin(right)
    U.hero=right:CreateTexture(nil,'ARTWORK'); U.hero:SetSize(40,40); U.hero:SetPoint('TOPLEFT',14,-12)
    U.heroHover=CreateFrame('Frame',nil,right); U.heroHover:SetAllPoints(U.hero)
    F.Theme.BindItemTooltip(U.heroHover,function() return U.detailItem end,function() return U.detailItem and C.ItemName(U.detailItem) or '' end)
    U.detailTitle=label(right,'GameFontNormalLarge',66,-14,397,'')
    U.detailTitle:SetHeight(22)
    U.summary=label(right,'GameFontHighlightSmall',66,-39,397,'')
    U.summary:SetHeight(20)
    U.details=F.Theme.ScrollFrame(right)
    U.details:SetPoint('TOPLEFT',16,-64); U.details:SetPoint('BOTTOMRIGHT',-28,46)
    U.body=CreateFrame('Frame',nil,U.details); U.body:SetSize(440,240)
    U.bodyText=U.body:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetWidth(440)
    U.bodyText:SetSpacing(2); U.bodyText:SetJustifyH('LEFT'); U.bodyText:SetJustifyV('TOP'); U.bodyText:SetWordWrap(true)
    F.Theme.Text(U.bodyText,false,14)
    U.details:SetScrollChild(U.body)
    U.accept=button(right,'',12,-319,150,function() U.RequestAction('accept') end)
    U.done=button(right,'',169,-319,150,function() U.RequestAction('done') end)
    U.cancel=button(right,'',326,-319,150,function() U.RequestAction('cancel') end)
    U.crafter=button(right,'',12,-319,220,function()
        if U.page=='queue' then F.Tracker.Toggle()
        elseif U.page=='crafters' then U.Navigate('network') else U.CycleCrafter() end
    end)
    U.enqueue=button(right,'',248,-319,220,function() if U.page=='network' then U.Navigate('requests') else U.Enqueue() end end)
    U.itemLabel=label(frame,'GameFontNormalSmall',24,-461,235,'')
    local chosen=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    U.chosen=chosen
    chosen:SetPoint('TOPLEFT',14,-479); chosen:SetSize(248,48); skin(chosen,true)
    U.itemIcon=chosen:CreateTexture(nil,'ARTWORK'); U.itemIcon:SetSize(28,28); U.itemIcon:SetPoint('LEFT',8,0)
    F.Theme.BindItemTooltip(chosen,function() return U.target and U.target.item end,function() return U.target and C.ItemName(U.target.item) or '' end)
    U.item=label(chosen,'GameFontHighlightSmall',43,-8,193,'')
    U.item:SetHeight(36)
    U.qtyLabel=label(frame,'GameFontNormalSmall',280,-461,68,'')
    U.qty=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
    U.qty:SetFontObject('GameFontHighlightSmall')
    F.Theme.Font(U.qty,12)
    U.qty:SetSize(55,24); U.qty:SetPoint('TOPLEFT',285,-487); U.qty:SetNumeric(true); U.qty:SetAutoFocus(false); U.qty:SetText('1')
    U.qty:SetScript('OnTextChanged',function()
        if U.frame and not U.settingTarget then
            if U.page=='queue' and U.selectedEntry and U.selectedEntry.kind=='goal' and F.Integer(U.Quantity(),1,10000) then
                local goal=F.Queue.data.goals[U.selectedEntry.index]
                if goal and goal.quantity~=U.Quantity() then F.Queue.Quantity(U.selectedEntry.index,U.Quantity()) end
            end
            local position=U.details:GetVerticalScroll() or 0
            if U.page=='chain' and U.planData and U.target and U.target.item==U.planData.target and F.Integer(U.Quantity(),1,10000) then
                U.planData.quantity=U.Quantity(); F.Automation.RefreshPlan()
            end
            U.UpdateActions(); U.RenderSelection(); U.LayoutDetails()
            U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
        end
    end)
    U.qty:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    U.plan=button(frame,'',355,-487,185,function() U.BuildSelected() end)
    tooltip(U.plan,'RECIPE_NEXT')
    U.request=button(frame,'',550,-487,200,function() U.RequestSelected() end)
    U.footer=label(frame,'GameFontHighlightSmall',24,-535,450,'')
    U.commands=button(frame,'',490,-535,112,function() U.Commands() end)
    U.help=button(frame,'',614,-535,136,function() U.Help() end)
    local icons={'INV_Misc_Head_Human_01','INV_Scroll_03','INV_Misc_Note_05','INV_Misc_Coin_01','INV_Misc_GroupLooking','INV_Misc_Note_01','INV_Misc_EngGizmos_01','Trade_Engineering'}
    local pages={'home','recipes','queue','market','network','requests','chain','settings'}
    U.navigation={}
    local previousTab
    for i,page in ipairs(pages) do
        local nav=CreateFrame('Frame',nil,frame,'LargeSideTabButtonTemplate')
        nav:EnableMouse(true)
        if previousTab then nav:SetPoint('TOPLEFT',previousTab,'BOTTOMLEFT',0,-3)
        else nav:SetPoint('TOPLEFT',frame,'TOPRIGHT',-3,-93) end
        nav.Icon:SetTexture('Interface\\Icons\\'..icons[i]); nav:SetFillToInterior(true,40); nav:SetChecked(false)
        F.Theme.SideTab(nav)
        nav:SetCustomOnMouseUpHandler(function(_,mouse,inside)
            if mouse=='LeftButton' and inside then
                if page=='settings' then
                    if U.setDialog then U.setDialog:Hide() end
                    F.Settings.Open()
                else U.Navigate(page) end
            end
        end)
        U.navigation[page]=nav
        nav:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,self.tooltipText) end)
        nav:SetScript('OnLeave',F.Theme.HideTooltip)
        previousTab=nav
    end
    U.frame=frame; frame:Hide(); UISpecialFrames[#UISpecialFrames+1]='ForeverNetWindow'
    frame:SetScript('OnHide',function()
        F.Theme.HideTooltip()
        if U.filterMenu then U.filterMenu:Hide() end
        if U.setDialog then U.setDialog:Hide() end
        if U.queueBoard then U.queueBoard.menu:Hide() end
    end)
end
function U.Toggle()
    if U.frame and U.frame:IsShown() then U.frame:Hide() else U.Status() end
end
function U.Navigate(page)
    U.Ensure(); U.page,U.selectionKey,U.view=page,nil,nil
    if U.setDialog then U.setDialog:Hide() end
    U.resettingSearch=true; U.search:SetText(''); U.filter=''; U.resettingSearch=false
    U.listScroll:SetVerticalScroll(0)
    if page=='chain' and U.planData then U.SetTarget(U.planData.target,U.planData.quantity,U.planData.owner,U.planData.recipeID) end
    U.Status()
end
function U.FindCrafters(item,quantity)
    if not F.ID(item) or not F.Integer(quantity,1,10000) then return false,F.L('QUANTITY_ERROR') end
    U.Ensure(); U.finder={item=item}
    U.SetTarget(item,quantity); U.Navigate('crafters')
    return true
end
function U.SetTarget(item,quantity,owner,recipeID)
    U.Ensure(); U.target={item=item,owner=owner,recipeID=recipeID}
    F.Theme.HideTooltipFor(U.chosen)
    U.settingTarget=true; U.qty:SetText(amount(quantity or 1)); U.settingTarget=false
    U.UpdateActions()
end
function U.UpdateActions()
    if not U.frame then return end
    local target,qty=U.target,U.Quantity()
    local goal=U.page=='queue' and U.selectedEntry and U.selectedEntry.kind=='goal' and F.Queue.data.goals[U.selectedEntry.index]
    U.qtyLabel:SetText(F.L(goal and goal.mode=='stock' and 'RESTOCK_TARGET' or 'QUANTITY_FIELD'))
    local valid=target and F.ID(target.item) and F.Integer(qty,1,10000)
    U.item:SetText(C.Safe(target and C.ItemName(target.item) or F.L('CHOOSE_RECIPE')))
    U.itemIcon:SetTexture(target and C.Icon(target.item) or 'Interface\\Icons\\INV_Misc_QuestionMark')
    U.plan:SetEnabled(not not valid and U.page~='crafters')
    U.plan:SetText(F.L(U.page=='chain' and U.planData and 'CHAIN_REFRESH' or 'Собрать цепочку'))
    local canRequest=valid and U.page~='requests' and U.page~='crafters' and F.db.settings.sharing and F.Net.available and F.Net.Channel()
    U.request:SetEnabled(not not canRequest)
    local hint
    if not target then hint='CHOOSE_RECIPE'
    elseif not F.Integer(qty,1,10000) then hint='QUANTITY_ERROR'
    elseif not F.db.settings.sharing then hint='ENABLE_TO_REQUEST'
    elseif not F.Net.Channel() then hint='JOIN_TO_REQUEST'
    else hint='FOOTER_FLOW' end
    U.footer:SetText(F.L(hint))
end
function U.Show(text,title,subtitle,tone)
    if U.HideGraphics then U.HideGraphics() end
    if U.HideQueueBoard then U.HideQueueBoard() end
    if U.crafter then U.crafter:SetScript('OnEnter',nil); U.crafter:SetScript('OnLeave',F.Theme.HideTooltip) end
    if U.marketPlot then U.marketPlot:Hide() end
    U.Ensure(); U.blockCount=0; for _,block in ipairs(U.blocks or {}) do block.title:Hide(); block.text:Hide() end
    for _,header in ipairs(U.profileHeaders or {}) do header:Hide() end
    for _,card in ipairs(U.profileCards or {}) do card:Hide() end
    for _,row in ipairs(U.sourceRows or {}) do row:Hide() end
    U.bodyText:Show(); for _,card in ipairs(U.cards or {}) do card:Hide() end
    F.Theme.HideTooltipFor(U.heroHover)
    local entry=U.view~='help' and U.view~='commands' and U.selectedEntry
    U.detailItem=entry and entry.item
    U.hero:SetTexture(U.detailItem and C.Icon(U.detailItem) or 'Interface\\Icons\\INV_Misc_EngGizmos_01')
    U.accept:Hide(); U.done:Hide(); U.cancel:Hide(); U.crafter:Hide(); U.enqueue:Hide()
    U.detailTitle:SetText(C.Safe(title or F.L('PAGE_'..U.page)))
    U.summary:SetText(C.Safe(subtitle or ''))
    if tone=='good' or tone=='missing' then F.Theme.Color(U.summary,tone)
    else F.Theme.Text(U.summary) end
    U.bodyText:ClearAllPoints(); U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetHeight(0); U.bodyText:SetText(C.Safe(text))
    U.body:SetHeight(math.max(240,U.bodyText:GetStringHeight()+24))
    U.LayoutDetails(); U.details:SetVerticalScroll(0); U.frame:Show()
end
function U.LayoutMain(browsing)
    local T=F.Theme
    U.heading:SetHeight(0); U.heading:ClearAllPoints()
    U.heading:SetPoint('TOPLEFT',T.IsClassic() and 78 or 24,-48); U.heading:SetWidth(T.IsClassic() and 310 or 360)
    local headerHeight=U.heading:GetStringHeight()
    for _,b in ipairs({U.scan,U.share,U.sync}) do headerHeight=math.max(headerHeight,T.FitButton(b,b:GetWidth())) end
    local top=math.max(93,48+headerHeight+12)
    U.paneTop=top
    local footerHeight=0
    for _,b in ipairs({U.plan,U.request}) do
        footerHeight=math.max(footerHeight,T.FitButton(b,b:GetWidth()))
        b:ClearAllPoints(); b:SetPoint('BOTTOMLEFT',b==U.plan and 355 or 550,59)
    end
    for _,b in ipairs({U.commands,U.help}) do
        T.FitButton(b,b:GetWidth()); b:ClearAllPoints(); b:SetPoint('BOTTOMLEFT',b==U.commands and 490 or 614,11)
    end
    local footerExtra=browsing and 0 or math.max(0,footerHeight-40)
    U.left:ClearAllPoints(); U.left:SetPoint('TOPLEFT',14,-top)
    U.right:ClearAllPoints(); U.right:SetPoint('TOPLEFT',270,-top)
    local paneHeight=(browsing and 433 or 357)-(top-93)-footerExtra
    U.left:SetHeight(paneHeight); U.right:SetHeight(paneHeight)
    local listTop=math.max(65,29+(U.filterButton:IsShown() and U.filterButton:GetHeight() or U.search:GetHeight())+10)
    U.listScroll:ClearAllPoints(); U.listScroll:SetPoint('TOPLEFT',8,-listTop); U.listScroll:SetPoint('BOTTOMRIGHT',-28,12)
end
function U.LayoutDetails()
    if not U.frame then return end
    local browsing=U.page=='home' or U.page=='network' or U.page=='market' or U.page=='queue' or U.view=='help' or U.view=='commands'
    for _,region in ipairs({U.itemLabel,U.chosen,U.qtyLabel,U.qty,U.plan,U.request}) do
        if not (U.page=='queue' and U.view~='help' and U.view~='commands' and (region==U.qty or region==U.qtyLabel)) then region:SetShown(not browsing) end
    end
    -- Overview/profile browsing does not need the crafting footer controls.
    -- Reclaim that area for both content panes rather than leaving disabled buttons.
    U.LayoutMain(browsing)
    U.detailTitle:SetWordWrap(true); U.detailTitle:SetHeight(0)
    U.summary:SetWordWrap(true); U.summary:SetHeight(0)
    U.hero:SetSize(32,32)
    U.detailTitle:ClearAllPoints(); U.detailTitle:SetPoint('TOPLEFT',54,-12); U.detailTitle:SetWidth(409)
    U.summary:SetWidth(409)
    local titleHeight=U.detailTitle:GetStringHeight()
    local titleWidth=U.detailTitle:GetUnboundedStringWidth()
    local inline=U.summary:GetText()~='' and titleWidth+16+U.summary:GetUnboundedStringWidth()<=409
    U.summary:ClearAllPoints()
    local top
    if inline then
        U.detailTitle:SetWidth(titleWidth+1); U.summary:SetWidth(409-titleWidth-16)
        U.summary:SetPoint('TOPLEFT',54+titleWidth+16,-14)
        top=math.max(52,20+math.max(titleHeight,U.summary:GetStringHeight()))
    else
        U.summary:SetPoint('TOPLEFT',54,-(16+titleHeight))
        top=math.max(52,16+titleHeight+(U.summary:GetText()~='' and U.summary:GetStringHeight()+6 or 0))
    end
    local height=0
    for _,control in ipairs({U.accept,U.done,U.cancel,U.crafter,U.enqueue}) do
        if control:IsShown() then
            height=math.max(height,F.Theme.FitButton(control,control:GetWidth()))
            local x=(control==U.accept or control==U.crafter) and 12 or control==U.done and 169 or control==U.cancel and 326 or 248
            -- All action rows follow the bottom edge, regardless of header wrapping.
            control:ClearAllPoints(); control:SetPoint('BOTTOMLEFT',x,12)
        end
    end
    U.details:ClearAllPoints(); U.details:SetPoint('TOPLEFT',16,-top)
    U.details:SetPoint('BOTTOMRIGHT',-28,height>0 and height+20 or 12)
    if U.LayoutQueueControls then U.LayoutQueueControls() end
end
function U.RefreshRows()
    for _, row in ipairs(U.rows) do row:Hide() end
    for _,header in ipairs(U.recipeHeaders or {}) do header:Hide() end
    local profiles,entries=F.Profiles(),{}
    local function add(entry)
        local text=C.Fold(entry.title..' '..(entry.subtitle or ''))
        if U.filter=='' or text:find(C.Fold(U.filter),1,true) then entries[#entries+1]=entry end
    end
    if U.page=='home' then
        local scans=F.db.professionScans and F.db.professionScans[F.me] or {}
        for _,group in ipairs(C.ProfileProfessions(F.localProfile)) do
            local scan=scans[group.id]
            local maximum=scan and F.Integer(scan.maximum,1,1000) and scan.maximum
            local rank=tostring(group.rank or '?')..(maximum and '/'..maximum or '')
            add({key=group.id,kind='profession',profession=group.id,title=group.title,icon=C.ProfessionIcon(group.id),
                rank=group.rank,maximum=maximum,
                subtitle=rank..'  /  '..#group.recipes..' '..F.L('RECIPES_COUNT')})
        end
    elseif U.page=='queue' then
        for i,goal in ipairs(F.Queue.data.goals) do
            add({key=tostring(i),kind='goal',index=i,item=goal.item,title=C.ItemName(goal.item)..' x'..goal.quantity,
                subtitle=who(goal.owner or F.me)..(goal.mode=='stock' and ' / '..F.L('RESTOCK_MODE') or '')})
        end
    elseif U.page=='market' then
        local items={}
        for item in pairs(F.Market.data.snapshots) do items[item]=true end
        for item in pairs(F.Queue.Build().missing) do items[item]=true end
        for item in pairs(F.db.favorites.recipes) do items[item]=true end
        for item in pairs(F.db.favorites.market) do items[item]=true end
        for _,item in ipairs(F.Keys(items)) do add({key=item,kind='market',item=item,title=C.ItemName(item),subtitle=F.Market.data.snapshots[item] and F.L('MARKET_HISTORY') or F.L('MARKET_UNKNOWN')}) end
    elseif U.page=='recipes' then entries=C.Recipes(profiles,U.filter,U.recipeChoices,U.recipeFilters)
    elseif U.page=='crafters' then entries=C.Crafters(profiles,U.finder and U.finder.item,U.filter)
    elseif U.page=='network' then
        for _, owner in ipairs(F.Keys(profiles)) do
            local p=profiles[owner]
            if owner~=F.me then add({key=owner,kind='player',owner=owner,title=who(owner),
                subtitle=string.format(F.L('RECIPE_COUNT'),#F.Keys(p.recipes))..(F.ProfileStale(p) and '\n'..F.L('PROFILE_CACHED') or '')}) end
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
    if U.page=='network' then table.sort(entries,function(a,b)
        local favoriteA,favoriteB=F.IsFavorite('profiles',a.owner),F.IsFavorite('profiles',b.owner)
        if favoriteA~=favoriteB then return favoriteA end
        return C.Fold(a.title)<C.Fold(b.title)
    end) end
    for i,entry in ipairs(entries) do
        if U.selectionKey==entry.key then
            U.selectedEntry=entry
            if entry.kind=='recipe' then U.SetTarget(entry.item,U.Quantity() or 1,entry.owner,entry.recipeID) end
        end
    end
    local rows,positions,heights,y={}, {},{},0
    U.rowMeasure=U.rowMeasure or label(U.list,'GameFontHighlightSmall',0,0,158,'')
    local starPage=U.page=='recipes' or U.page=='network' or U.page=='crafters' or U.page=='market'
    U.rowMeasure:SetWidth(starPage and 136 or 158)
    U.rowMeasure:SetWordWrap(true); U.rowMeasure:Hide()
    local function append(entry)
        U.rowMeasure:SetHeight(0); U.rowMeasure:SetText(C.Safe(entry.title..'\n'..(entry.subtitle or '')))
        local height=math.max(entry.kind=='profession' and 66 or 50,U.rowMeasure:GetStringHeight()+(entry.kind=='profession' and 30 or 18))
        rows[#rows+1]=entry; positions[#positions+1]=y; heights[#heights+1]=height; y=y+height+4
    end
    if U.page=='recipes' or U.page=='market' then
        U.recipeHeaders,U.catalogCollapsed=U.recipeHeaders or {},U.catalogCollapsed or {}
        local pinned,regular={},{}
        for _,entry in ipairs(entries) do
            local destination=F.IsFavorite(U.page=='market' and 'market' or 'recipes',entry.item) and pinned or regular
            destination[#destination+1]=entry
        end
        U.recipeGroups=U.page=='market' and (#regular>0 and {{id='market-items',title=F.L('PAGE_market'),recipes=regular}} or {}) or C.GroupRecipes(regular)
        if #pinned>0 then table.insert(U.recipeGroups,1,{id=U.page=='market' and 'favorite-market' or 'favorite-recipes',title=F.L('FAVORITES'),recipes=pinned}) end
        for i,group in ipairs(U.recipeGroups) do
            local header=U.recipeHeaders[i]
            if not header then
                header=CreateFrame('Button',nil,U.list,'BackdropTemplate'); header:SetWidth(208); F.Theme.Section(header)
                header.label=label(header,'GameFontNormalSmall',8,-5,173,''); header.label:SetWordWrap(true)
                F.Theme.Color(header.label,'heading')
                header.toggle=label(header,'GameFontNormal',189,-5,15,''); header.toggle:SetTextColor(1,.82,.22)
                U.recipeHeaders[i]=header
            end
            local professionID=group.id
            local closed=U.catalogCollapsed[professionID] and U.filter==''
            header:ClearAllPoints(); header:SetPoint('TOPLEFT',0,-y)
            header.label:SetHeight(0)
            header.label:SetText(C.Safe(group.title..' ('..#group.recipes..')'))
            header.toggle:SetText(closed and '+' or '-')
            local height=math.max(24,header.label:GetStringHeight()+10)
            header:SetHeight(height); header:Show(); y=y+height+4
            header:SetScript('OnClick',function()
                U.catalogCollapsed[professionID]=not U.catalogCollapsed[professionID]
                local position=U.listScroll:GetVerticalScroll() or 0
                U.Status(); U.listScroll:SetVerticalScroll(math.min(position,math.max(0,U.list:GetHeight()-280)))
            end)
            if not closed then
                for _,entry in ipairs(group.recipes) do
                    append(entry)
                end
            end
            y=y+8
        end
    else
        U.recipeGroups=nil
        for _,entry in ipairs(entries) do append(entry) end
    end
    for i,entry in ipairs(rows) do
        local b=U.rows[i]
        if not b then
            b=CreateFrame('Button',nil,U.list,'BackdropTemplate'); b:SetSize(208,46); skin(b,true)
            b.icon=b:CreateTexture(nil,'ARTWORK'); b.icon:SetSize(26,26); b.icon:SetPoint('LEFT',7,0)
            b.label=label(b,'GameFontHighlightSmall',40,-7,158,'')
            b.label:SetWordWrap(true); b.label:SetHeight(0)
            b.favorite=CreateFrame('Button',nil,b); b.favorite:SetSize(20,20); b.favorite:SetPoint('TOPRIGHT',-6,-6)
            b.favorite.icon=b.favorite:CreateTexture(nil,'ARTWORK'); b.favorite.icon:SetSize(20,18); b.favorite.icon:SetPoint('CENTER')
            b.favorite:SetScript('OnClick',function()
                local kind=(b.entry.kind=='player' or b.entry.kind=='crafter') and 'profiles' or b.entry.kind=='market' and 'market' or 'recipes'
                local ok,why=F.ToggleFavorite(kind,kind=='profiles' and b.entry.owner or b.entry.item)
                if not ok then F.Print(why) end
                U.Status()
            end)
            tooltip(b.favorite,'FAVORITE_HINT')
            b.progress=b:CreateTexture(nil,'BACKGROUND'); b.progress:SetColorTexture(.22,.20,.16,1)
            b.progress:SetPoint('BOTTOMLEFT',40,8); b.progress:SetSize(158,3)
            b.fill=b:CreateTexture(nil,'ARTWORK'); b.fill:SetColorTexture(.72,.55,.27,1)
            b.fill:SetPoint('BOTTOMLEFT',40,8); b.fill:SetHeight(3)
            b:SetScript('OnEnter',function(self)
                self:SetBackdropBorderColor(.95,.75,.22,1)
                if self.entry.item then F.Theme.ShowItemTooltip(self,self.entry.item,self.entry.title,self.entry.subtitle)
                elseif self.entry.kind=='profession' then
                    local scans=F.db.professionScans and F.db.professionScans[F.me] or {}
                    local scan=scans[self.entry.profession]
                    F.Theme.ShowTooltip(self,self.entry.title,scan and F.Integer(scan.seen,0,2147483647) and string.format(F.L('SCAN_AGE'),math.max(0,math.floor((F.Now()-scan.seen)/60))) or F.L('SCAN_UNKNOWN'))
                end
            end)
            b:SetScript('OnLeave',function(self) F.Theme.HideTooltip(); self:SetBackdropBorderColor(self.selected and .95 or .52,self.selected and .75 or .38,.18,1) end)
            U.rows[i]=b
        end
        F.Theme.HideTooltipFor(b)
        b.entry,b.selected=entry,U.selectionKey==entry.key
        b.label:SetWidth(starPage and 136 or 158); b.favorite:SetShown(starPage)
        if starPage then
            local kind=(U.page=='network' or U.page=='crafters') and 'profiles' or U.page=='market' and 'market' or 'recipes'
            b.favorite.icon:SetAtlas(F.IsFavorite(kind,kind=='profiles' and entry.owner or entry.item)
                and 'auctionhouse-icon-favorite' or 'auctionhouse-icon-favorite-off')
        end
        b:ClearAllPoints(); b:SetPoint('TOPLEFT',0,-positions[i]); b:SetHeight(heights[i])
        b.label:SetText(C.Safe(entry.title..'\n'..(entry.subtitle or '')))
        local progress=entry.kind=='profession' and entry.maximum and entry.maximum>0 and type(entry.rank)=='number'
        b.progress:SetShown(not not progress); b.fill:SetShown(not not progress)
        if progress then b.fill:SetWidth(math.max(1,158*math.min(1,entry.rank/entry.maximum))) end
        if U.page=='queue' then
            b:SetBackdropBorderColor(.25,.225,.185,1)
            b:SetBackdropColor(b.selected and .18 or .085,b.selected and .16 or .078,b.selected and .12 or .066,1)
        end
        b.icon:SetTexture(entry.icon or entry.item and C.Icon(entry.item) or 'Interface\\Icons\\INV_Misc_GroupLooking')
        b:SetBackdropBorderColor(b.selected and .95 or .52,b.selected and .75 or .38,.18,1)
        b:SetScript('OnClick',function(self) U.Select(self.entry) end); b:Show()
    end
    U.list:SetHeight(math.max(280,y)); U.empty:SetShown(#entries==0)
    U.empty:SetText(F.L(U.filter~='' and 'SEARCH_EMPTY' or 'EMPTY_'..U.page))
end
function U.Select(entry)
    U.selectionKey,U.view=entry.key,nil
    if entry.kind=='profession' then U.Navigate('recipes'); U.SetRecipeFilter('profession',entry.profession); return
    elseif entry.kind=='goal' then
        local goal=F.Queue.data.goals[entry.index]
        U.SetTarget(goal.item,goal.quantity,goal.owner,goal.recipeID)
    elseif entry.kind=='market' then U.SetTarget(entry.item,F.Queue.Build().missing[entry.item] or 1)
    elseif entry.kind=='recipe' then U.SetTarget(entry.item,U.Quantity() or 1,entry.owner,entry.recipeID)
    elseif entry.kind=='request' then U.SetTarget(entry.item,entry.request.quantity)
    elseif entry.kind=='missing' then U.SetTarget(entry.item,entry.quantity,nil,nil)
    elseif entry.kind=='step' then U.SetTarget(entry.item,entry.step.quantity,entry.step.owner,entry.step.recipeID) end
    U.Status()
end
function U.CycleCrafter()
    local e=U.selectedEntry
    if not e or e.kind~='recipe' or #e.providers<2 then return end
    local index=1
    for i,p in ipairs(e.providers) do if p.owner==e.owner and p.recipeID==e.recipeID then index=i; break end end
    local provider=e.providers[index%#e.providers+1]
    U.recipeChoices[e.item]=provider.key
    U.SetTarget(e.item,U.Quantity() or 1,provider.owner,provider.recipeID)
    U.Status()
end
function U.RenderSelection()
    local e=U.selectedEntry
    if U.view=='commands' then U.Show(F.L('HELP'),F.L('COMMANDS_BUTTON')); return end
    if U.view=='help' then U.RenderHelp(); return end
    if U.page=='home' then U.RenderHome(); return end
    if U.page=='queue' then U.RenderQueue(); return end
    if U.page=='market' then U.RenderMarket(); return end
    if U.page=='crafters' then U.RenderFinder(); return end
    if U.page=='chain' and U.planData and e and (e.kind=='missing' or e.kind=='step') then
        U.RenderPlan(); return
    end
    if not e then
        if U.page=='chain' and U.planData then U.RenderPlan(); return end
        if U.page=='network' then
            local text=F.L(#U.entries>0 and 'NETWORK_PICK' or 'EMPTY_network')
            local channel=F.Net.Channel()
            text=text..'\n\n'..F.L('NETWORK_CHANNEL')..(channel and F.L('CHANNEL_'..channel) or F.L('NETWORK_NO_CHANNEL'))
            if F.Net.lastError then text=text..'\n\n'..F.Net.lastError end
            U.Show(text,F.L('PAGE_network')); U.enqueue:SetText(F.L('PAGE_requests')); U.enqueue:Show(); return
        end
        if U.page~='recipes' then U.Show(F.L('EMPTY_'..U.page),F.L('PAGE_'..U.page)); return end
        local hasRecipes=#C.Recipes(F.Profiles(),'')>0
        U.Show(F.L(hasRecipes and 'CHOOSE_RECIPE' or 'START_SCAN'),F.L('PAGE_recipes'))
        return
    end
    if e.kind=='recipe' then
        U.RenderRecipe(e)
    elseif e.kind=='player' then
        local p=F.db.profiles[e.owner]; if not p then return end
        U.RenderPlayer(e,p)
        U.enqueue:SetText(F.L('PAGE_requests')); U.enqueue:Show()
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
    end
end

function U.OpenProfileRecipe(owner,recipeID,item)
    local p=F.Profiles()[owner]
    if not p or not p.recipes[recipeID] or p.recipes[recipeID].output~=item then U.DataChanged(); return end
    U.recipeChoices[item]=owner..'/'..recipeID
    U.recipeFilters={}
    U.Navigate('recipes'); U.selectionKey='item/'..item; U.Status()
end
function U.RenderPlayer(entry,profile)
    local stale=F.ProfileStale(profile)
    U.Show('',entry.title,profileAge(profile),stale and 'missing' or nil)
    U.hero:SetTexture('Interface\\Icons\\INV_Misc_GroupLooking')
    U.bodyText:Hide()
    U.profileHeaders,U.profileCards=U.profileHeaders or {},U.profileCards or {}
    U.profileCollapsed=U.profileCollapsed or {}
    local collapsed=U.profileCollapsed[entry.owner] or {}
    U.profileCollapsed[entry.owner]=collapsed
    local groups=C.ProfileProfessions(profile)
    local y,cardIndex=0,0
    for i,g in ipairs(groups) do
        local header=U.profileHeaders[i]
        if not header then
            header=CreateFrame('Button',nil,U.body,'BackdropTemplate'); header:SetWidth(434); F.Theme.Section(header)
            header.icon=header:CreateTexture(nil,'ARTWORK'); header.icon:SetSize(22,22); header.icon:SetPoint('TOPLEFT',7,-6)
            header.title=label(header,'GameFontNormal',36,-6,204,''); header.title:SetWordWrap(true); F.Theme.Color(header.title,'text')
            header.detail=label(header,'GameFontHighlightSmall',247,-6,153,''); header.detail:SetWordWrap(true); F.Theme.Color(header.detail,'muted')
            header.toggle=label(header,'GameFontNormalLarge',407,-7,20,''); header.toggle:SetTextColor(1,.82,.22)
            U.profileHeaders[i]=header
        end
        header:ClearAllPoints(); header:SetPoint('TOPLEFT',0,-y)
        header.icon:SetTexture(C.ProfessionIcon(g.id)); header.title:SetHeight(0); header.title:SetText(C.Safe(g.title))
        local titleHeight=header.title:GetStringHeight()
        header.detail:SetHeight(0)
        local rank=g.rank and string.format(F.L('SKILL_RANK'),g.rank)..'  /  ' or ''
        header.detail:SetText(C.Safe(rank..string.format(F.L('RECIPE_COUNT'),#g.recipes)))
        header.toggle:SetText(collapsed[g.id] and '+' or '-')
        local headerHeight=math.max(34,math.max(titleHeight,header.detail:GetStringHeight())+12)
        header:SetHeight(headerHeight); header:Show()
        local professionID=g.id
        header:SetScript('OnClick',function()
            collapsed[professionID]=not collapsed[professionID]
            local position=U.details:GetVerticalScroll() or 0
            U.RenderSelection()
            U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
        end)
        y=y+headerHeight+8
        if not collapsed[g.id] then
            for start=1,#g.recipes,2 do
                local row,rowHeight={},0
                for col=0,1 do
                    local r=g.recipes[start+col]
                    if r then
                        cardIndex=cardIndex+1
                        local card=U.profileCards[cardIndex]
                        if not card then
                            card=CreateFrame('Button',nil,U.body,'BackdropTemplate'); card:SetWidth(212); skin(card,true)
                            card.icon=card:CreateTexture(nil,'ARTWORK'); card.icon:SetSize(32,32); card.icon:SetPoint('TOPLEFT',8,-9)
                            card.title=label(card,'GameFontNormalSmall',48,-8,156,''); card.title:SetWordWrap(true)
                            card.detail=label(card,'GameFontHighlightSmall',48,0,156,''); card.detail:SetWordWrap(true)
                            card:SetScript('OnEnter',function(self)
                                self:SetBackdropBorderColor(.95,.75,.22,1)
                                F.Theme.ShowItemTooltip(self,self.entry.item,C.Safe(self.entry.title),F.L('PROFILE_RECIPE_HINT'))
                            end)
                            card:SetScript('OnLeave',function(self)
                                self:SetBackdropBorderColor(self.blueprint and .68 or .52,self.blueprint and .4 or .38,self.blueprint and .9 or .18,1)
                                F.Theme.HideTooltip()
                            end)
                            card:SetScript('OnClick',function(self)
                                F.Theme.HideTooltip()
                                U.OpenProfileRecipe(self.owner,self.entry.recipeID,self.entry.item)
                            end)
                            U.profileCards[cardIndex]=card
                        end
                        card.entry,card.owner,card.blueprint=r,entry.owner,r.recipe.blueprint
                        card:ClearAllPoints(); card:SetPoint('TOPLEFT',col*222,-y)
                        card.icon:SetTexture(C.Icon(r.item)); card.title:SetHeight(0); card.title:SetText(C.Safe(r.title))
                        local titleHeight=card.title:GetStringHeight()
                        card.detail:ClearAllPoints(); card.detail:SetPoint('TOPLEFT',48,-(titleHeight+12)); card.detail:SetHeight(0)
                        card.detail:SetText(C.Safe(r.recipe.blueprint and 'Blueprint  /  x'..r.recipe.quantity or F.L('RECIPE')..'  /  x'..r.recipe.quantity))
                        F.Theme.Color(card.detail,r.recipe.blueprint and 'blueprint' or 'muted')
                        card:SetBackdropBorderColor(card.blueprint and .68 or .52,card.blueprint and .4 or .38,card.blueprint and .9 or .18,1)
                        rowHeight=math.max(rowHeight,58,titleHeight+card.detail:GetStringHeight()+22)
                        row[#row+1]=card
                    end
                end
                for _,card in ipairs(row) do card:SetHeight(rowHeight); card:Show() end
                y=y+rowHeight+8
            end
        end
        y=y+10
    end
    local camps={}
    for _,id in ipairs(F.Keys(profile.camps)) do
        camps[#camps+1]=F.L('CAMP')..id..' ('..math.max(0,profile.camps[id]-F.Now())..F.L('SECONDS')..')'
    end
    if #camps>0 then U.ShowBlocks({{title=F.L('CAPABILITIES'),text=table.concat(camps,'\n')}},y)
    elseif #groups==0 then U.ShowBlocks({{title=F.L('PROFESSIONS'),text=F.L('PROFILE_EMPTY')}},y)
    else U.body:SetHeight(math.max(240,y+8)) end
end
local function ingredientList(reagents,multiplier)
    local lines={}
    for _,item in ipairs(F.Keys(reagents or {})) do
        lines[#lines+1]=C.ItemName(item)..' x'..reagents[item]*(multiplier or 1)
    end
    return #lines>0 and table.concat(lines,'\n') or F.L('NO_REAGENTS')
end
local function finderProfession(profile,profession)
    local rank=profile.professions[profession]
    return C.ProfessionName(profession)..' / '..(rank and string.format(F.L('SKILL_RANK'),rank) or F.L('FINDER_SKILL_UNKNOWN'))
end
function U.PreviewCrafter(owner,recipeID,openRecipe)
    if U.page~='crafters' or not U.finder then return false end
    local profiles=F.Profiles()
    local profile=profiles[owner]
    local recipe=profile and profile.recipes[recipeID]
    if F.IsSelf(owner) or not recipe or recipe.output~=U.finder.item then
        F.Print(F.L('FINDER_CHANGED')); U.DataChanged(); return false
    end
    local quantity=U.Quantity()
    if not F.Integer(quantity,1,10000) then F.Print(F.L('QUANTITY_ERROR')); return false end
    if openRecipe then U.OpenProfileRecipe(owner,recipeID,recipe.output); return true end
    local inventory=F.Adapter.Inventory(profiles)
    inventory[recipe.output]=F.Adapter.StockCount(recipe.output)
    local plan=F.Planner.Build(profiles,recipe.output,quantity,inventory,nil,{owner=owner,recipeID=recipeID,localOwner=F.me})
    plan.owner,plan.recipeID=owner,recipeID
    U.Plan(plan); return true
end
function U.OpenFinderProfile(owner)
    if F.IsSelf(owner) or not F.Profiles()[owner] then F.Print(F.L('FINDER_CHANGED')); U.DataChanged(); return false end
    U.Navigate('network'); U.selectionKey=owner; U.Status(); return true
end
function U.RenderFinder()
    local context=U.finder
    if not context then U.Show(F.L('EMPTY_crafters'),F.L('PAGE_crafters')); return end
    U.Show('',C.ItemName(context.item),string.format(F.L('FINDER_COUNT'),#U.entries))
    U.detailItem=context.item; U.hero:SetTexture(C.Icon(context.item)); U.crafter:SetText(F.L('FINDER_NETWORK')); U.crafter:Show()
    local channel=F.Net.Channel()
    local rows={{section=true,title=F.L('PAGE_crafters'),hint=F.L('FINDER_HELP')..'\n'..F.L('NETWORK_CHANNEL')..
        (channel and F.L('CHANNEL_'..channel) or F.L('NETWORK_NO_CHANNEL'))}}
    local selected=U.selectedEntry
    if selected and selected.kind=='crafter' then
        local owner=selected.owner
        rows[#rows+1]={section=true,title=owner,text=profileAge(selected.profile),tone=F.ProfileStale(selected.profile) and 'missing' or nil,
            actions={{text=F.L('FINDER_PROFILE'),run=function() U.OpenFinderProfile(owner) end}}}
        local filtered={professions=selected.profile.professions,recipes={}}
        for i,match in ipairs(selected.recipes) do
            if i>20 then break end
            filtered.recipes[match.recipeID]=match.recipe
        end
        local valid=F.Integer(U.Quantity(),1,10000)
        if not valid then rows[#rows+1]={title=F.L('QUANTITY_ERROR'),tone='missing'} end
        for _,group in ipairs(C.ProfileProfessions(filtered)) do
            if #group.recipes>0 then
                rows[#rows+1]={section=true,title=finderProfession(selected.profile,group.id)}
                for _,match in ipairs(group.recipes) do
                    local recipeID=match.recipeID
                    local recipe=match.recipe
                    rows[#rows+1]={item=context.item,title=recipe.name,text=string.format(F.L('PRO_OUTPUT'),recipe.quantity)..'\n'..
                        string.format(F.L('CHAIN_FROM'),ingredientList(recipe.reagents))..(recipe.blueprint and '\n'..F.L('FILTER_BLUEPRINT') or ''),
                        actions={{text=F.L('FINDER_PLAN'),enabled=valid,run=function() U.PreviewCrafter(owner,recipeID,false) end},
                            {text=F.L('FINDER_RECIPE'),enabled=valid,run=function() U.PreviewCrafter(owner,recipeID,true) end}}}
                end
            end
        end
        if #selected.recipes>20 then rows[#rows+1]={title=F.L('FINDER_PROFILE'),text=string.format(F.L('FINDER_VARIANT_LIMIT'),20)} end
    else
        rows[#rows+1]={title=F.L('FINDER_PICK'),text=#U.entries==0 and F.L(U.filter~='' and 'SEARCH_EMPTY' or 'EMPTY_crafters') or ''}
        for i,entry in ipairs(U.entries) do
            if i>20 then break end
            local owner=entry.owner
            local professions={}
            for _,match in ipairs(entry.recipes) do professions[match.recipe.profession]=true end
            local text={profileAge(entry.profile)}
            for _,profession in ipairs(F.Keys(professions)) do text[#text+1]=finderProfession(entry.profile,profession) end
            rows[#rows+1]={title=owner,text=table.concat(text,'\n'),tone=F.ProfileStale(entry.profile) and 'missing' or nil,
                actions={{text=F.L('FINDER_RECIPES'),run=function() U.selectionKey=owner; U.Status() end},
                    {text=F.L('FINDER_PROFILE'),run=function() U.OpenFinderProfile(owner) end}}}
        end
        if #U.entries>20 then rows[#rows+1]={title=F.L('FINDER_PICK'),text=string.format(F.L('FINDER_PLAYER_LIMIT'),20)} end
    end
    U.ShowSourceRows(rows)
end
function U.SourceComparison(item,queue)
    local profiles=F.Profiles()
    local goals=queue and F.Queue.data.goals or U.planData.goals
    local inventory=F.Adapter.Inventory(profiles)
    for _,goal in ipairs(goals) do inventory[goal.item]=F.Adapter.StockCount(goal.item) end
    local sources=queue and F.Queue.data.sources or U.planData.sources
    return F.SourceCosts.Compare(profiles,goals,inventory,item,{localOwner=F.me,sources=sources})
end
function U.SourceCostText(row)
    local b=row.budget
    local lines={}
    if F.Market.Number(b.cost,0,9007199254740991) then
        lines[#lines+1]=string.format(F.L('SOURCE_SPENDING'),F.Market.Money(b.cost))
    else lines[#lines+1]=F.L('MARKET_UNKNOWN') end
    if b.uncovered>0 then lines[#lines+1]=string.format(F.L('SOURCE_UNCOVERED'),b.uncovered) end
    if b.stale>0 or b.partial>0 or b.approximate then lines[#lines+1]=F.L('MARKET_WARNING') end
    if b.limited then lines[#lines+1]=F.L('SOURCE_LIMIT') end
    if row.fees then lines[#lines+1]=F.L('SOURCE_FEES') end
    if row.staleProvider then lines[#lines+1]=F.L('PROFILE_CACHED') end
    if row.blocked then lines[#lines+1]=F.L('SOURCE_BLOCKED') end
    if row.lowest then lines[#lines+1]=F.L('SOURCE_LOWEST') end
    if row.delta and row.delta~=0 then
        lines[#lines+1]=string.format(F.L(row.delta<0 and 'SOURCE_LESS' or 'SOURCE_MORE'),F.Market.Money(math.abs(row.delta)))
    end
    return table.concat(lines,'\n')
end
function U.AddCostOptions(rows,item,comparison,apply)
    rows[#rows+1]={section=true,title=F.L('SOURCE_COMPARE'),text=F.L('SOURCE_COST_HELP')}
    for _,option in ipairs(comparison.rows) do
        local title=F.L(option.kind=='auto' and 'SOURCE_AUTO' or 'SOURCE_READY')
        local text=U.SourceCostText(option)
        if option.kind=='external' then text=string.format(F.L('CHAIN_GET_COUNT'),option.get)..'\n'..text end
        if option.source then
            title=option.source.recipe.name..(option.made>0 and ' x'..option.made or '')
            text=F.L('CRAFTER')..who(option.source.owner)..'\n'..text
            if option.made>0 then
                text=string.format(F.L('SOURCE_BATCHES'),option.batches,option.made)..'\n'..
                    string.format(F.L('CHAIN_FROM'),ingredientList(option.reagents))..'\n'..text
                -- This is remaining planned output, not items already in bags.
                if option.surplus>0 then text=text..'\n'..string.format(F.L('CHAIN_SURPLUS'),option.surplus) end
            end
            if not option.source.ready then text=text..'\n'..F.L('MISSING_REASON_camp') end
        end
        local choice=F.Copy(option.choice)
        rows[#rows+1]={item=item,title=title,text=text,tone=option.lowest and 'good' or nil,
            actions={{text=F.L(option.selected and 'SOURCE_SELECTED' or 'CHAIN_USE_RECIPE'),
                enabled=option.available and not option.selected,run=function() apply(choice) end}}}
    end
    if comparison.truncated then rows[#rows+1]={title=F.L('SOURCE_COMPARE'),text=F.L('SOURCE_LIMIT')} end
end
function U.AddRecipeOptions(rows,item,material)
    if U.expandedSource~=item then return end
    if U.recipeOptionsRendered[item] then return end
    U.recipeOptionsRendered[item]=true
    U.AddCostOptions(rows,item,U.SourceComparison(item,false),function(choice) U.ChooseSource(item,choice) end)
end
function U.SetRecipeFilter(key,value)
    U.recipeFilters=U.recipeFilters or {}
    if key then U.recipeFilters[key]=value else U.recipeFilters={} end
    U.selectionKey,U.target,U.view=nil,nil,nil
    if U.filterMenu then U.filterMenu:Hide() end
    if U.listScroll then U.listScroll:SetVerticalScroll(0) end
    U.Status()
end
function U.OpenFilters()
    if U.filterMenu and U.filterMenu:IsShown() then U.filterMenu:Hide(); return end
    if not U.filterMenu then
        local menu=CreateFrame('Frame',nil,U.frame,'BackdropTemplate')
        menu:SetSize(440,332); menu:SetPoint('TOPLEFT',28,-151)
        menu:SetFrameLevel(U.frame:GetFrameLevel()+40); menu:EnableMouse(true); skin(menu)
        U.filterMenu=menu; U.filterControls={}; U.filterLabels={}
        for i,y in ipairs({-12,-180,-232}) do
            U.filterLabels[i]=label(menu,'GameFontNormal',12,y,408,'')
        end
        U.filterProfessionScroll=F.Theme.ScrollFrame(menu)
        U.filterProfessionScroll:SetPoint('TOPLEFT',12,-36); U.filterProfessionScroll:SetSize(394,132)
        U.filterProfessionList=CreateFrame('Frame',nil,U.filterProfessionScroll)
        U.filterProfessionList:SetSize(394,132); U.filterProfessionScroll:SetScrollChild(U.filterProfessionList)
    end
    for _,control in ipairs(U.filterControls) do control:Hide() end
    U.filterLabels[1]:SetText(F.L('FILTER_PROFESSION'))
    U.filterLabels[2]:SetText(F.L('FILTER_TYPE')); U.filterLabels[3]:SetText(F.L('FILTER_CRAFTERS'))
    local index=0
    local function choice(parent,title,key,value,x,y,width)
        index=index+1
        local b=U.filterControls[index]
        if not b then b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); F.Theme.Button(b); U.filterControls[index]=b end
        b:SetParent(parent); b:ClearAllPoints(); b:SetPoint('TOPLEFT',x,y); b:SetSize(width,24); b:SetText(title)
        b:SetEnabled(key==false or (U.recipeFilters or {})[key]~=value)
        b:SetScript('OnClick',function() U.SetRecipeFilter(key or nil,value) end); b:Show()
        return F.Theme.FitButton(b,width)
    end
    local professions,groups={},{}
    for _,profile in pairs(F.Profiles()) do
        for _,recipe in pairs(profile.recipes) do professions[recipe.profession]=true end
    end
    for id in pairs(professions) do groups[#groups+1]={id=id,title=C.ProfessionName(id)} end
    table.sort(groups,function(a,b) return C.Fold(a.title)<C.Fold(b.title) end)
    table.insert(groups,1,{title=F.L('FILTER_ALL')})
    local listY=0
    for i=1,#groups,2 do
        local rowHeight=0
        for j=i,math.min(i+1,#groups) do
            local group=groups[j]
            rowHeight=math.max(rowHeight,choice(U.filterProfessionList,C.Safe(group.title),'profession',group.id,(j-i)*202,-listY,192))
        end
        listY=listY+rowHeight+4
    end
    U.filterProfessionList:SetHeight(math.max(132,listY))
    U.filterProfessionScroll:SetVerticalScroll(0)
    local types={{'FILTER_ALL'},{'FILTER_REGULAR','regular'},{'FILTER_BLUEPRINT','blueprint'}}
    local scopes={{'FILTER_ALL'},{'FILTER_MINE','mine'},{'FILTER_NETWORK','network'}}
    local y=12
    local function heading(i)
        local l=U.filterLabels[i]; l:SetWordWrap(true); l:SetHeight(0)
        l:ClearAllPoints(); l:SetPoint('TOPLEFT',12,-y); y=y+l:GetStringHeight()+6
    end
    heading(1)
    U.filterProfessionScroll:ClearAllPoints(); U.filterProfessionScroll:SetPoint('TOPLEFT',12,-y); y=y+132+10
    for i,options in ipairs({types,scopes}) do
        heading(i+1)
        local height=0
        for j,option in ipairs(options) do
            height=math.max(height,choice(U.filterMenu,F.L(option[1]),i==1 and 'kind' or 'scope',option[2],12+(j-1)*140,-y,132))
        end
        y=y+height+10
    end
    y=y+choice(U.filterMenu,F.L('FILTER_RESET'),false,nil,12,-y,412)+12
    U.filterMenu:SetHeight(y)
    U.filterMenu:Show()
end
function U.Status()
    F.Theme.RefreshFonts(); U.Ensure(); F.Prune()
    U.heading:SetText(F.L('PAGE_'..U.page))
    U.sharing:SetText('')
    U.share:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,F.L('SHARE_HINT'),string.format(F.L('NETWORK_SUMMARY'),#C.Recipes(F.db.profiles,''),math.max(0,#F.Keys(F.db.profiles)-1),F.L(F.db.settings.sharing and 'включён' or 'выключен'))..(F.Net.lastError and '\n'..F.Net.lastError or '')) end)
    U.scan:SetText(F.L('Сканировать')); U.share:SetText(F.L(F.db.settings.sharing and 'SHARE_ON' or 'SHARE_OFF')); U.sync:SetText(F.L('Обновить'))
    U.searchLabel:SetText(F.L('SEARCH_LABEL')); U.itemLabel:SetText(F.L('CHOSEN_ITEM')); U.qtyLabel:SetText(F.L('QUANTITY_FIELD'))
    U.filterButton:SetShown(U.page=='recipes' or U.page=='queue'); U.search:SetWidth((U.page=='recipes' or U.page=='queue') and 124 or 210)
    U.filterButton:SetText(U.page=='queue' and F.L('SETS_TITLE') or F.L('FILTER_BUTTON')..(next(U.recipeFilters or {}) and ' *' or ''))
    if U.page~='recipes' and U.filterMenu then U.filterMenu:Hide() end
    U.plan:SetText(F.L('Собрать цепочку')); U.request:SetText(F.L('ASK_HELP')); U.commands:SetText(F.L('COMMANDS_BUTTON')); U.help:SetText(F.L('HELP_BUTTON'))
    U.accept:SetText(F.L('ACCEPT')); U.done:SetText(F.L('DONE')); U.cancel:SetText(F.L('CANCEL'))
    U.LayoutMain(U.page=='home' or U.page=='network' or U.page=='market' or U.page=='queue' or U.view=='help' or U.view=='commands')
    local previous
    for _,page in ipairs({'home','recipes','queue','market','network','requests','chain','settings'}) do
        local nav=U.navigation[page]
        nav:SetShown(page~='chain' or U.page==page)
        if nav:IsShown() then
            nav:ClearAllPoints()
            if previous then nav:SetPoint('TOPLEFT',previous,'BOTTOMLEFT',0,-3) else nav:SetPoint('TOPLEFT',U.frame,'TOPRIGHT',-3,-U.paneTop) end
            previous=nav
        end
        nav:SetChecked(page==U.page or page=='network' and U.page=='crafters'); nav.tooltipText=F.L('PAGE_'..page)
    end
    U.RefreshRows(); U.UpdateActions(); U.RenderSelection()
    U.LayoutDetails()
    if U.page=='home' or U.page=='queue' or U.page=='market' then
        U.plan:SetEnabled(false); U.request:SetEnabled(false)
        U.footer:SetText('')
    end
    if U.page=='crafters' then U.footer:SetText(F.L('FINDER_PICK')) end
    U.frame:Show()
end
function U.Enqueue()
    local target=U.target
    if not target then return end
    if U.page=='queue' and U.selectedEntry and U.selectedEntry.kind=='goal' then
        if not F.Queue.Quantity(U.selectedEntry.index,U.Quantity()) then F.Print(F.L('QUANTITY_ERROR')); return end
    else
        local ok,why=F.Queue.Add(target.item,U.Quantity(),target.owner,target.recipeID)
        if not ok then F.Print(why); return end
    end
    U.Navigate('queue')
end
function U.QueueSetDialog(mode,name)
    U.Ensure()
    local Q=F.Queue
    local set=mode=='load' and Q.data.sets[name] or Q.data
    if not set then return end
    local d=U.setDialog
    if not d then
        d=CreateFrame('Frame','ForeverNetQueueSetDialog',U.frame,'PortraitFrameTemplate')
        U.setDialog=d
        d:SetSize(440,440); d:SetPoint('CENTER'); d:SetFrameStrata('FULLSCREEN_DIALOG'); d:EnableMouse(true); d:SetClampedToScreen(true)
        d:SetPortraitToAsset(F.icon); F.Theme.Background(d); F.Theme.Title(d)
        d.help=label(d,'GameFontHighlightSmall',24,-56,380,''); d.help:SetWordWrap(true)
        d.name=CreateFrame('EditBox',nil,d,'InputBoxTemplate')
        d.name:SetSize(375,24); d.name:SetAutoFocus(false); d.name:SetFontObject('GameFontHighlight')
        F.Theme.Font(d.name,14)
        d.name:SetScript('OnEscapePressed',function() d:Hide() end)
        d.scroll=F.Theme.ScrollFrame(d)
        d.scroll:SetPoint('BOTTOMRIGHT',-48,76)
        d.body=CreateFrame('Frame',nil,d.scroll); d.body:SetSize(360,200); d.scroll:SetScrollChild(d.body)
        d.preview=label(d.body,'GameFontHighlight',0,0,360,''); d.preview:SetWordWrap(true); d.preview:SetSpacing(4)
        d.error=label(d,'GameFontHighlightSmall',24,-370,392,''); d.error:SetWordWrap(true); F.Theme.Color(d.error,'missing')
        d.first=button(d,'',24,-402,192,function() U.ApplyQueueSet(false) end)
        d.second=button(d,'',224,-402,192,function()
            if d.mode=='save' then d:Hide() else U.ApplyQueueSet(true) end
        end)
        d.name:SetScript('OnEnterPressed',function() if d.mode=='save' then U.ApplyQueueSet(false) end end)
        d:SetScript('OnHide',function() d.name:ClearFocus() end)
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetQueueSetDialog'
    end
    d:SetFrameLevel(U.frame:GetFrameLevel()+50)
    d.mode,d.setName=mode,name
    d:SetTitle(F.L('SETS_TITLE'))
    d.error:SetText(''); d.error:SetHeight(0)
    d.help:SetHeight(0)
    d.help:SetText(F.L(mode=='save' and 'SETS_SAVE_HELP' or 'SETS_LOAD_HELP'))
    local top=64+d.help:GetStringHeight()
    d.name:SetShown(mode=='save')
    if mode=='save' then
        d.name:ClearAllPoints(); d.name:SetPoint('TOPLEFT',28,-top); d.name:SetText(name or '')
        top=top+36
    end
    d.scroll:ClearAllPoints(); d.scroll:SetPoint('TOPLEFT',24,-top); d.scroll:SetPoint('BOTTOMRIGHT',-48,76)
    local lines={mode=='load' and name or F.L('PAGE_queue')}
    for i,goal in ipairs(set.goals) do
        lines[#lines+1]=i..'. '..C.ItemName(goal.item)..' x'..goal.quantity..' / '..who(goal.owner or F.me)..
            (goal.mode=='stock' and ' / '..F.L('RESTOCK_MODE') or '')
    end
    d.preview:SetHeight(0); d.preview:SetText(C.Safe(table.concat(lines,'\n')))
    d.body:SetHeight(math.max(1,d.preview:GetStringHeight()+12)); d.scroll:SetVerticalScroll(0)
    d.first:SetText(F.L(mode=='save' and 'SETS_SAVE' or 'SETS_REPLACE'))
    d.second:SetText(F.L(mode=='save' and 'CANCEL' or 'SETS_APPEND'))
    local actionHeight=math.max(F.Theme.FitButton(d.first,192),F.Theme.FitButton(d.second,192))
    for _,b in ipairs({d.first,d.second}) do b:ClearAllPoints(); b:SetPoint('BOTTOMLEFT',b==d.first and 24 or 224,14) end
    d.error:ClearAllPoints(); d.error:SetPoint('BOTTOMLEFT',24,actionHeight+22)
    d.scroll:ClearAllPoints(); d.scroll:SetPoint('TOPLEFT',24,-top); d.scroll:SetPoint('BOTTOMRIGHT',-48,actionHeight+54)
    d:Show()
end
function U.ApplyQueueSet(append)
    local d=U.setDialog
    if not d or not d:IsShown() then return end
    local ok,why
    if d.mode=='save' then ok,why=F.Queue.SaveSet(d.name:GetText())
    else ok,why=F.Queue.LoadSet(d.setName,append) end
    if not ok then
        d.error:SetText(why); d.error:SetHeight(0)
        local height=d.error:GetStringHeight()
        local bottom=math.max(d.first:GetHeight(),d.second:GetHeight())+22
        d.error:SetHeight(height); d.error:ClearAllPoints(); d.error:SetPoint('BOTTOMLEFT',24,bottom)
        d.scroll:SetPoint('BOTTOMRIGHT',-48,height+bottom+12)
        return
    end
    if d.mode=='load' and why>0 then F.Print(string.format(F.L('SETS_CONFLICTS'),why)) end
    d:Hide(); U.selectionKey=nil; U.queueSourceItem=nil; U.Status()
end
function U.PriceText(item,quantity)
    if not F.Market.Number(quantity,0,10000) then return F.L('MARKET_UNKNOWN') end
    local quote=F.Market.Quote(item,math.max(1,quantity))
    if quote.status~='known' then return F.L(quote.status=='empty' and 'MARKET_EMPTY' or 'MARKET_UNKNOWN') end
    local text=string.format(F.L('MARKET_PRICE'),F.Market.Money(quote.minimum),quantity,F.Market.Money(quantity>0 and quote.cost or 0),
        quantity>0 and quote.remaining or 0,math.max(0,math.floor((F.Now()-quote.seen)/60)))
    if quantity>0 and quote.surplus>0 then text=text..'\n'..string.format(F.L('MARKET_SURPLUS'),quote.bought,quote.surplus) end
    if quote.stale or quote.partial or quote.approximate then text=text..'\n'..F.L('MARKET_WARNING') end
    return text
end
function U.BudgetText(missing)
    local budget=F.Market.Budget(missing)
    local text=string.format(F.L('MARKET_BUDGET'),F.Market.Money(budget.cost),budget.uncovered)
    if budget.stale>0 or budget.partial>0 or budget.approximate then text=text..'\n'..F.L('MARKET_WARNING') end
    return text
end
function U.RenderMarket()
    local entry=U.selectedEntry
    if not entry then U.Show(F.L('MARKET_SCAN_HELP')..'\n\n'..U.BudgetText(F.Queue.Build().missing),F.L('PAGE_market')); return end
    local quantity=U.Quantity()
    if not F.Integer(quantity,1,10000) then U.Show(F.L('QUANTITY_ERROR'),entry.title); return end
    U.Show('',entry.title,F.L('PAGE_market'))
    U.detailItem=entry.item; U.hero:SetTexture(C.Icon(entry.item))
    local days=U.historyDays or 30
    local rows={{key='market/'..entry.item,item=entry.item,title=entry.title,text=U.ShortPrice(entry.item,quantity),hint=U.PriceText(entry.item,quantity),
        actions={{text=F.L('MARKET_SCAN'),enabled=F.Auction.open==true,run=function()
            if F.Auction.panel and AuctionHouseFrame then AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.ForeverNet) end
            local ok,why=F.Auction.Scan({entry.item}); if why then F.Print(why) end
        end},{text=F.L('TRACK_SEARCH'),run=function() local ok,why=F.Auction.Search(entry.item); if not ok then F.Print(why) end end}}},
        {section=true,title=F.L('MARKET_HISTORY')..' ('..days..'d)',hint=F.L('MARKET_HISTORY_HELP'),
            actions={{text='30d / 90d',run=function() U.historyDays=days==30 and 90 or 30; U.RenderMarket() end}}}}
    local points=F.Market.History(entry.item,days)
    if #points==0 then rows[#rows+1]={title=F.L('MARKET_HISTORY'),text=F.L('MARKET_HISTORY_EMPTY')}; U.ShowSourceRows(rows); return end
    local y=U.ShowSourceRows(rows)
    local chart=U.marketPlot
    if not chart then
        chart=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); chart:SetSize(434,180); skin(chart,true)
        chart.dots,chart.lines={},{}
        chart.high=label(chart,'GameFontHighlightSmall',8,-6,150,'')
        chart.low=label(chart,'GameFontHighlightSmall',8,-145,150,'')
        chart.firstDate=label(chart,'GameFontHighlightSmall',60,-164,175,'')
        chart.lastDate=label(chart,'GameFontHighlightSmall',250,-164,175,'')
        U.marketPlot=chart
    end
    chart:ClearAllPoints(); chart:SetPoint('TOPLEFT',0,-y); chart:Show()
    for _,dot in ipairs(chart.dots) do dot:Hide() end
    for _,line in pairs(chart.lines) do line:Hide() end
    local minimum,maximum=points[1].price,points[1].price
    for _,point in ipairs(points) do minimum=math.min(minimum,point.price); maximum=math.max(maximum,point.price) end
    chart.high:SetText(F.Market.Money(maximum)); chart.low:SetText(F.Market.Money(minimum))
    chart.firstDate:SetText(date and date('%Y-%m-%d',F.Now()-days*86400) or tostring(F.Now()-days*86400))
    chart.lastDate:SetText(date and date('%Y-%m-%d',F.Now()) or tostring(F.Now()))
    local previous
    for i,point in ipairs(points) do
        local x=60+math.max(0,math.min(1,(point.seen-(F.Now()-days*86400))/(days*86400)))*358
        local value=maximum==minimum and .5 or (point.price-minimum)/(maximum-minimum)
        local yy=-145+value*116
        local dot=chart.dots[i]
        if not dot then
            dot=CreateFrame('Frame',nil,chart); dot:SetSize(5,5); dot:EnableMouse(true)
            dot.fill=dot:CreateTexture(nil,'ARTWORK'); dot.fill:SetAllPoints(); dot.fill:SetColorTexture(1,.82,.22,1)
            chart.dots[i]=dot
        end
        dot:ClearAllPoints(); dot:SetPoint('CENTER',chart,'TOPLEFT',x,yy); dot:Show()
        local when=date and date('%Y-%m-%d',point.seen) or tostring(point.seen)
        dot:SetScript('OnEnter',function() F.Theme.ShowTooltip(dot,when,F.Market.Money(point.price)) end)
        dot:SetScript('OnLeave',F.Theme.HideTooltip)
        if previous and math.floor(point.seen/86400)-math.floor(previous.point.seen/86400)==1 and chart.CreateLine then
            local line=chart.lines[i]
            if not line then line=chart:CreateLine(nil,'ARTWORK'); chart.lines[i]=line end
            line:SetColorTexture(1,.82,.22,1); line:SetThickness(2)
            line:SetStartPoint('TOPLEFT',chart,previous.x,previous.y); line:SetEndPoint('TOPLEFT',chart,x,yy); line:Show()
        end
        previous={point=point,x=x,y=yy}
    end
    U.body:SetHeight(math.max(240,y+194))
end
function U.BuildSelected()
    local target,qty=U.target,U.Quantity()
    if U.page=='chain' and U.planData and target and target.item~=U.planData.target then
        local p=U.planData
        U.SetTarget(p.target,p.quantity,p.owner,p.recipeID)
        target,qty=U.target,U.Quantity()
    end
    if not target or not F.Integer(qty,1,10000) then return end
    local profiles=F.Profiles()
    local inventory=F.Adapter.Inventory(profiles)
    inventory[target.item]=F.Adapter.StockCount(target.item)
    local previous=U.planData
    local same=previous and previous.target==target.item and previous.owner==target.owner and previous.recipeID==target.recipeID
    if not same then U.expandedSource,U.showPlanStock=nil,nil end
    local sources=same and (previous.manualSources or previous.sources) or {}
    local p=F.Automation.Build(profiles,{{item=target.item,quantity=qty,owner=target.owner,recipeID=target.recipeID}},inventory,{localOwner=F.me,sources=sources})
    p.target,p.quantity=target.item,qty
    p.owner,p.recipeID=target.owner,target.recipeID; U.Plan(p)
end
function U.OpenSources(item)
    local p=U.planData
    if not p then return end
    local position=U.details:GetVerticalScroll()
    U.expandedSource=U.expandedSource~=item and item or nil
    U.view,U.selectionKey=nil,nil
    U.SetTarget(p.target,p.quantity,p.owner,p.recipeID)
    U.Status()
    U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
end
function U.ChooseSource(item,choice)
    local p=U.planData
    if not p or item==p.target then return end
    p.manualSources=p.manualSources or F.Copy(p.sources or {}); p.manualSources[item]=choice
    p.sources=p.sources or {}; p.sources[item]=choice
    U.view,U.selectionKey,U.expandedSource=nil,nil,nil
    U.SetTarget(p.target,p.quantity,p.owner,p.recipeID)
    U.BuildSelected()
end
function U.ShowSourceRows(entries,offset)
    U.sourceRows=U.sourceRows or {}; U.chainRows=entries
    for _,row in ipairs(U.sourceRows) do row:Hide() end
    U.bodyText:Hide()
    local y=offset or 0
    for i,entry in ipairs(entries) do
        local row=U.sourceRows[i]
        if not row then
            row=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); row:SetWidth(434); skin(row,true)
            row.icon=row:CreateTexture(nil,'ARTWORK'); row.icon:SetSize(36,36); row.icon:SetPoint('TOPLEFT',10,-10)
            row.title=label(row,'GameFontNormal',10,-10,414,''); row.title:SetWordWrap(true)
            row.detail=label(row,'GameFontHighlightSmall',10,-35,414,''); row.detail:SetWordWrap(true); row.detail:SetSpacing(1)
            row.divider=row:CreateTexture(nil,'BACKGROUND'); row.divider:SetColorTexture(.5,.35,.14,.3)
            row.divider:SetHeight(1); row.divider:SetPoint('BOTTOMLEFT',8,0); row.divider:SetPoint('BOTTOMRIGHT',-8,0)
            row.track=row:CreateTexture(nil,'BACKGROUND'); row.track:SetColorTexture(.22,.19,.14,1); row.track:SetSize(414,4); row.track:SetPoint('BOTTOMLEFT',10,5)
            row.fill=row:CreateTexture(nil,'ARTWORK'); row.fill:SetHeight(4); row.fill:SetPoint('BOTTOMLEFT',10,5)
            row:EnableMouse(true)
            row:SetScript('OnEnter',function(self)
                if self.entry.item then F.Theme.ShowItemTooltip(self,self.entry.item,self.entry.title,self.entry.hint)
                elseif self.entry.hint then F.Theme.ShowTooltip(self,self.entry.title,self.entry.hint) end
            end)
            row:SetScript('OnLeave',F.Theme.HideTooltip)
            row.buttons={}
            for j=1,2 do
                row.buttons[j]=button(row,'',10,0,200,function(self) if self.action then self.action() end end)
                row.buttons[j]:SetScript('OnEnter',function(self) if self.hint then F.Theme.ShowTooltip(self,self:GetText(),self.hint) end end)
                row.buttons[j]:SetScript('OnLeave',F.Theme.HideTooltip)
            end
            row.action=row.buttons[1]
            row.extraButton=button(row,'',10,0,410,function(self) if self.action then self.action() end end)
            row.extraButton:SetScript('OnEnter',function(self) if self.hint then F.Theme.ShowTooltip(self,self:GetText(),self.hint) end end)
            row.extraButton:SetScript('OnLeave',F.Theme.HideTooltip)
            row.more=button(row,'+',402,-8,24,function(self) U.ToggleVisual(self.key) end)
            row.more:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,F.L('VIS_DETAILS'),self.hint) end)
            row.more:SetScript('OnLeave',F.Theme.HideTooltip)
            U.sourceRows[i]=row
        end
        row:ClearAllPoints(); row:SetPoint('TOPLEFT',0,-y)
        row.entry=entry
        local progress=entry.maximum and entry.maximum>0
        row.track:SetShown(not not progress); row.fill:SetShown(not not progress and (entry.current or 0)>0)
        if progress then
            row.fill:SetWidth(math.max(1,414*math.min(1,(entry.current or 0)/entry.maximum)))
            row.fill:SetColorTexture(.45,.9,.48,1)
        end
        local original=entry
        if entry.visual then
            local key=entry.key or ('visual/'..i)
            local expanded=U.visualExpanded and U.visualExpanded[key]
            row.more:SetShown(entry.hint~=nil or entry.actions~=nil or entry.extraAction~=nil)
        row.more.key,row.more.hint=key,entry.hint
            row.more:SetText(expanded and '-' or '+')
            if not expanded then
                entry={}
                for k,v in pairs(original) do entry[k]=v end
                entry.actions,entry.extraAction=nil,nil
            end
        else row.more:Hide(); row.more.key,row.more.hint=nil,nil end
        local passive=not entry.section and (not entry.actions or #entry.actions==0) and not entry.extraAction
        if entry.section then F.Theme.Section(row) elseif passive then row:SetBackdrop(nil) else skin(row,true) end
        row.divider:SetShown(passive)
        local x=entry.item and (passive and 42 or 56) or 10
        row.icon:SetSize(passive and 26 or 36,passive and 26 or 36)
        row.icon:ClearAllPoints(); row.icon:SetPoint('TOPLEFT',passive and 8 or 10,passive and -8 or -10)
        row.icon:SetShown(entry.item~=nil); if entry.item then row.icon:SetTexture(C.Icon(entry.item)) end
        row.title:ClearAllPoints(); row.title:SetPoint('TOPLEFT',x,-10); row.title:SetWidth(424-x-(row.more:IsShown() and 30 or 0))
        row.title:SetHeight(0); row.title:SetText(C.Safe(entry.title or '')); row.title:SetShown(entry.title and entry.title~='')
        local inline=false
        local widths,total={},0
        if not entry.item and (not entry.text or entry.text=='') and not entry.extraAction and entry.actions and #entry.actions>0 then
            for j,action in ipairs(entry.actions) do
                if row.buttons[j] then
                    row.buttons[j]:SetText(action.text)
                    widths[j]=math.max(72,F.Theme.ButtonWidth(row.buttons[j])); total=total+widths[j]+(j>1 and 8 or 0)
                end
            end
            inline=414-total-12>=row.title:GetUnboundedStringWidth()
            if inline then row.title:SetWidth(414-total-12) end
        end
        local top=row.title:IsShown() and 14+row.title:GetStringHeight() or 8
        row.detail:ClearAllPoints(); row.detail:SetPoint('TOPLEFT',x,-top); row.detail:SetWidth(424-x)
        row.detail:SetHeight(0); row.detail:SetText(C.Safe(entry.text or '')); row.detail:SetSpacing(1)
        row.detail:SetShown(entry.text and entry.text~='')
        if row.detail:IsShown() then top=top+row.detail:GetStringHeight()+6 end
        if original.visual and original.reagents then top=U.DrawIngredients(row,original.reagents,top+2)
        else for _,ingredient in ipairs(row.ingredients or {}) do ingredient:Hide() end end
        local inlineData=false
        if not original.visual and passive and row.title:IsShown() and row.detail:IsShown() and not row.detail:GetText():find('\n',1,true) then
            local titleWidth=row.title:GetUnboundedStringWidth()
            inlineData=titleWidth+12+row.detail:GetUnboundedStringWidth()<=424-x
            if inlineData then
                row.title:SetWidth(titleWidth+1)
                row.detail:ClearAllPoints(); row.detail:SetPoint('TOPLEFT',x+titleWidth+12,-10)
                row.detail:SetWidth(424-x-titleWidth-12)
                top=10+math.max(row.title:GetStringHeight(),row.detail:GetStringHeight())
            end
        end
        top=math.max(entry.item and (passive and 36 or 52) or 0,top)
        F.Theme.Color(row.detail,entry.tone or 'text')
        local color=F.Theme.colors[entry.tone or 'muted']; row:SetBackdropBorderColor(color[1],color[2],color[3],1)
        local sharedExtra,compactWidths=false,{}
        if entry.extraAction and entry.actions and #entry.actions==2 then
            local totalWidth=16
            for j,action in ipairs(entry.actions) do
                row.buttons[j]:SetText(action.text)
                compactWidths[j]=math.max(72,F.Theme.ButtonWidth(row.buttons[j])); totalWidth=totalWidth+compactWidths[j]
            end
            row.extraButton:SetText(entry.extraAction.text)
            compactWidths[3]=math.max(72,F.Theme.ButtonWidth(row.extraButton)); totalWidth=totalWidth+compactWidths[3]
            sharedExtra=totalWidth<=414
            if sharedExtra then for j=1,3 do compactWidths[j]=compactWidths[j]+(414-totalWidth)/3 end end
        end
        local actionHeight,actionX=0,inline and 424-total or 10
        for j,control in ipairs(row.buttons) do
            local action=entry.actions and entry.actions[j]
            control:SetShown(action~=nil)
            if action then
                local bx=sharedExtra and (j==1 and 10 or 18+compactWidths[1]) or inline and actionX or 10+(j-1)*210
                control:ClearAllPoints(); control:SetPoint('TOPLEFT',bx,inline and -10 or -top)
                control:SetText(action.text); control:SetEnabled(action.enabled~=false); control.action=action.run; control.hint=action.hint
                actionHeight=math.max(actionHeight,F.Theme.FitButton(control,sharedExtra and compactWidths[j] or inline and widths[j] or #entry.actions==1 and 410 or 200))
                if inline then actionX=actionX+widths[j]+8 end
            else control.action,control.hint=nil,nil end
        end
        local height=top+(actionHeight>0 and actionHeight+6 or 0)
        if inline then
            row.title:ClearAllPoints(); row.title:SetPoint('TOPLEFT',10,-(10+math.max(0,(actionHeight-row.title:GetStringHeight())/2)))
            height=math.max(row.title:GetStringHeight(),actionHeight)+20
        end
        row.extraButton:SetShown(entry.extraAction~=nil)
        if entry.extraAction then
            row.extraButton:ClearAllPoints(); row.extraButton:SetPoint('TOPLEFT',sharedExtra and 26+compactWidths[1]+compactWidths[2] or 10,sharedExtra and -top or -height)
            row.extraButton:SetText(entry.extraAction.text); row.extraButton:SetEnabled(entry.extraAction.enabled~=false)
            row.extraButton.action,row.extraButton.hint=entry.extraAction.run,entry.extraAction.hint
            local extraHeight=F.Theme.FitButton(row.extraButton,sharedExtra and compactWidths[3] or 410)
            if sharedExtra then height=top+math.max(actionHeight,extraHeight)+6 else height=height+extraHeight+6 end
        else row.extraButton.action,row.extraButton.hint=nil,nil end
        if not entry.actions and not entry.extraAction or entry.actions and #entry.actions==0 and not entry.extraAction then height=height+(passive and 4 or 10) end
        if progress then height=height+10 end
        row:SetHeight(height); row:Show(); y=y+height+(passive and 3 or 6)
    end
    U.body:SetHeight(math.max(240,y+8)); return y
end
function U.RequestSelected()
    if not U.target or U.page=='requests' then return end
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
    for item,count in pairs(plan.supplied) do plan.bagSupplied[item]=math.min(F.Adapter.ItemCount(item),count) end
    U.planData=plan; U.Navigate('chain')
end
function U.Commands() U.Ensure(); U.view='commands'; U.Status() end
function U.Help() U.Ensure(); U.view='help'; U.Status() end
function U.DataChanged() U.dirty=true; if F.Tracker then F.Tracker.dirty=true end end
function U.Tick(elapsed)
    U.elapsed=(U.elapsed or 0)+elapsed
    if U.elapsed<.5 then return end
    U.elapsed=0
    if U.dirty or (U.frame and U.frame:IsShown() and U.page=='requests') then
        U.dirty=false
        if U.frame and U.frame:IsShown() then
            local position=U.details:GetVerticalScroll()
            if U.page=='chain' and U.view~='help' and U.view~='commands' then F.Automation.RefreshPlan() end
            U.Status(); U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
        end
    end
end

function U.ShowCards(entries,offset)
    U.cards=U.cards or {}
    for _,card in ipairs(U.cards) do card:Hide() end
    local y=offset or 0
    for start=1,#entries,2 do
        local pair,rowHeight={},0
        for i=start,math.min(start+1,#entries) do
            local entry=entries[i]
            local card=U.cards[i]
            if not card then
                card=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); card:SetSize(212,48); skin(card,true)
                card.icon=card:CreateTexture(nil,'ARTWORK'); card.icon:SetSize(26,26); card.icon:SetPoint('TOPLEFT',8,-8)
                card.title=label(card,'GameFontNormal',42,-8,162,''); card.title:SetWordWrap(true)
                card.detail=label(card,'GameFontHighlightSmall',42,-30,162,''); card.detail:SetWordWrap(true)
                U.cards[i]=card
            end
            F.Theme.BindItemTooltip(card,entry.item,entry.title,entry.text)
            card:ClearAllPoints(); card:SetPoint('TOPLEFT',(i-start)*222,-y); card.icon:SetTexture(C.Icon(entry.item))
            card.title:SetHeight(0); card.detail:SetHeight(0)
            card.title:SetText(C.Safe(entry.title)); card.detail:SetText(C.Safe(entry.text))
            local titleHeight=card.title:GetStringHeight()
            card.detail:ClearAllPoints(); card.detail:SetPoint('TOPLEFT',42,-(12+titleHeight))
            rowHeight=math.max(rowHeight,48,titleHeight+card.detail:GetStringHeight()+20)
            local color=F.Theme.colors[entry.good and 'good' or 'missing']
            card:SetBackdropBorderColor(color[1],color[2],color[3],1)
            F.Theme.Color(card.detail,entry.good and 'good' or 'missing'); pair[#pair+1]=card
        end
        for _,card in ipairs(pair) do card:SetHeight(rowHeight); card:Show() end
        y=y+rowHeight+6
    end
    U.bodyText:ClearAllPoints(); U.bodyText:SetPoint('TOPLEFT',0,-y)
    U.body:SetHeight(math.max(240,y+U.bodyText:GetStringHeight()+24))
    return y
end

-- Separate, measured text blocks avoid cramped paragraphs and hard-coded heights.
function U.ShowBlocks(entries,offset,append)
    U.bodyText:Hide(); U.blocks=U.blocks or {}
    if not append then for _,block in ipairs(U.blocks) do block.title:Hide(); block.text:Hide() end end
    local y=offset or 0
    local first=append and (U.blockCount or 0) or 0
    for i,entry in ipairs(entries) do
        local index=first+i
        local block=U.blocks[index]
        if not block then
            block={title=label(U.body,'GameFontNormal',4,0,426,''),text=label(U.body,'GameFontHighlight',4,0,426,'')}
            block.text:SetSpacing(1); block.text:SetWordWrap(true)
            U.blocks[index]=block
        end
        block.title:ClearAllPoints(); block.title:SetPoint('TOPLEFT',4,-y)
        block.title:SetHeight(0); block.title:SetText(C.Safe(entry.title or '')); block.title:SetShown(entry.title and entry.title~='')
        if block.title:IsShown() then y=y+block.title:GetStringHeight()+4 end
        block.text:ClearAllPoints(); block.text:SetPoint('TOPLEFT',4,-y)
        block.text:SetHeight(0); block.text:SetText(C.Safe(entry.text)); block.text:Show()
        y=y+block.text:GetStringHeight()+8
    end
    U.blockCount=first+#entries
    U.body:SetHeight(math.max(240,y+8))
    return y
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
