local _, F = ...
F.UI = {page='recipes', rows={}, filter='', entries={}, recipeChoices={}}
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
local function amount(qty) return tostring(qty or 0) end
function U.Quantity() return tonumber(U.qty and U.qty:GetText()) end
function U.Ensure()
    if U.frame then return end
    local frame=CreateFrame('Frame','ForeverNetWindow',UIParent,'PortraitFrameTemplate')
    frame:SetSize(780,570); frame:SetPoint('CENTER'); frame:SetFrameStrata('DIALOG')
    frame:SetTitle('ForeverNet'); frame:SetPortraitToAsset(F.icon)
    F.Theme.Title(frame)
    U.paper,U.paperBase=F.Theme.Background(frame)
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
    U.search:SetFontObject('GameFontHighlightSmall')
    F.Theme.Font(U.search,12)
    U.search:SetSize(124,22); U.search:SetPoint('TOPLEFT',16,-29); U.search:SetAutoFocus(false)
    U.filterButton=button(left,'',150,-29,82,function() U.OpenFilters() end)
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
    U.detailTitle=label(right,'GameFontNormalLarge',66,-14,397,'')
    U.detailTitle:SetHeight(22)
    U.summary=label(right,'GameFontHighlightSmall',66,-39,397,'')
    U.summary:SetHeight(20)
    U.details=F.Theme.ScrollFrame(right)
    U.details:SetPoint('TOPLEFT',16,-64); U.details:SetPoint('BOTTOMRIGHT',-28,46)
    U.body=CreateFrame('Frame',nil,U.details); U.body:SetSize(440,240)
    U.bodyText=U.body:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetWidth(440)
    U.bodyText:SetSpacing(4); U.bodyText:SetJustifyH('LEFT'); U.bodyText:SetJustifyV('TOP'); U.bodyText:SetWordWrap(true)
    F.Theme.Text(U.bodyText,false,14)
    U.details:SetScrollChild(U.body)
    U.accept=button(right,'',12,-319,150,function() U.RequestAction('accept') end)
    U.done=button(right,'',169,-319,150,function() U.RequestAction('done') end)
    U.cancel=button(right,'',326,-319,150,function() U.RequestAction('cancel') end)
    U.crafter=button(right,'',12,-319,220,function() U.CycleCrafter() end)
    U.itemLabel=label(frame,'GameFontNormalSmall',24,-461,235,'')
    local chosen=CreateFrame('Frame',nil,frame,'BackdropTemplate')
    chosen:SetPoint('TOPLEFT',14,-479); chosen:SetSize(248,48); skin(chosen,true)
    U.itemIcon=chosen:CreateTexture(nil,'ARTWORK'); U.itemIcon:SetSize(28,28); U.itemIcon:SetPoint('LEFT',8,0)
    U.item=label(chosen,'GameFontHighlightSmall',43,-8,193,'')
    U.item:SetHeight(36)
    U.qtyLabel=label(frame,'GameFontNormalSmall',280,-461,68,'')
    U.qty=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
    U.qty:SetFontObject('GameFontHighlightSmall')
    F.Theme.Font(U.qty,12)
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
    local icons={'INV_Scroll_03','INV_Misc_GroupLooking','INV_Misc_Note_01','INV_Misc_EngGizmos_01','Trade_Engineering'}
    local pages={'recipes','network','requests','chain','settings'}
    U.navigation={}
    local previousTab
    for i,page in ipairs(pages) do
        local nav=CreateFrame('Frame',nil,frame,'LargeSideTabButtonTemplate')
        nav:EnableMouse(true)
        if previousTab then nav:SetPoint('TOPLEFT',previousTab,'BOTTOMLEFT',0,-3)
        else nav:SetPoint('TOPLEFT',frame,'TOPRIGHT',-3,-93) end
        nav.Icon:SetTexture('Interface\\Icons\\'..icons[i]); nav:SetFillToInterior(true,40); nav:SetChecked(false)
        nav:SetCustomOnMouseUpHandler(function(_,mouse,inside)
            if mouse=='LeftButton' and inside then
                if page=='settings' then F.Settings.Open() else U.Navigate(page) end
            end
        end)
        U.navigation[page]=nav
        nav:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,self.tooltipText) end)
        nav:SetScript('OnLeave',F.Theme.HideTooltip)
        previousTab=nav
    end
    U.frame=frame; frame:Hide(); UISpecialFrames[#UISpecialFrames+1]='ForeverNetWindow'
    frame:SetScript('OnHide',function() F.Theme.HideTooltip(); if U.filterMenu then U.filterMenu:Hide() end end)
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
    U.plan:SetText(F.L(U.page=='chain' and U.planData and 'CHAIN_REFRESH' or 'Собрать цепочку'))
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
    for _,header in ipairs(U.profileHeaders or {}) do header:Hide() end
    for _,card in ipairs(U.profileCards or {}) do card:Hide() end
    for _,row in ipairs(U.sourceRows or {}) do row:Hide() end
    U.bodyText:Show(); for _,card in ipairs(U.cards or {}) do card:Hide() end
    U.hero:SetTexture(U.selectedEntry and U.selectedEntry.item and C.Icon(U.selectedEntry.item) or 'Interface\\Icons\\INV_Misc_EngGizmos_01')
    U.accept:Hide(); U.done:Hide(); U.cancel:Hide(); U.crafter:Hide()
    U.detailTitle:SetText(C.Safe(title or F.L('PAGE_'..U.page)))
    U.summary:SetText(C.Safe(subtitle or ''))
    if tone=='good' or tone=='missing' then F.Theme.Color(U.summary,tone)
    else F.Theme.Text(U.summary) end
    U.bodyText:ClearAllPoints(); U.bodyText:SetPoint('TOPLEFT'); U.bodyText:SetHeight(0); U.bodyText:SetText(C.Safe(text))
    U.body:SetHeight(math.max(240,U.bodyText:GetStringHeight()+24))
    U.details:SetVerticalScroll(0); U.frame:Show()
end
function U.RefreshRows()
    for _, row in ipairs(U.rows) do row:Hide() end
    for _,header in ipairs(U.recipeHeaders or {}) do header:Hide() end
    local profiles,entries=F.Profiles(),{}
    local function add(entry)
        local text=C.Fold(entry.title..' '..(entry.subtitle or ''))
        if U.filter=='' or text:find(C.Fold(U.filter),1,true) then entries[#entries+1]=entry end
    end
    if U.page=='recipes' then entries=C.Recipes(profiles,U.filter,U.recipeChoices,U.recipeFilters)
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
    local starPage=U.page=='recipes' or U.page=='network'
    U.rowMeasure:SetWidth(starPage and 136 or 158)
    U.rowMeasure:SetWordWrap(true); U.rowMeasure:Hide()
    local function append(entry)
        U.rowMeasure:SetHeight(0); U.rowMeasure:SetText(C.Safe(entry.title..'\n'..(entry.subtitle or '')))
        local height=math.max(46,U.rowMeasure:GetStringHeight()+14)
        rows[#rows+1]=entry; positions[#positions+1]=y; heights[#heights+1]=height; y=y+height+4
    end
    if U.page=='recipes' then
        U.recipeHeaders,U.catalogCollapsed=U.recipeHeaders or {},U.catalogCollapsed or {}
        local pinned,regular={},{}
        for _,entry in ipairs(entries) do
            local destination=F.IsFavorite('recipes',entry.item) and pinned or regular
            destination[#destination+1]=entry
        end
        U.recipeGroups=C.GroupRecipes(regular)
        if #pinned>0 then table.insert(U.recipeGroups,1,{id='favorite-recipes',title=F.L('FAVORITES'),recipes=pinned}) end
        for i,group in ipairs(U.recipeGroups) do
            local header=U.recipeHeaders[i]
            if not header then
                header=CreateFrame('Button',nil,U.list,'BackdropTemplate'); header:SetWidth(208); F.Theme.Section(header)
                header.label=label(header,'GameFontNormalSmall',8,-5,173,''); header.label:SetWordWrap(true)
                header.label:SetTextColor(1,.82,.22)
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
                local kind=b.entry.kind=='player' and 'profiles' or 'recipes'
                local ok,why=F.ToggleFavorite(kind,kind=='profiles' and b.entry.owner or b.entry.item)
                if not ok then F.Print(why) end
                U.Status()
            end)
            tooltip(b.favorite,'FAVORITE_HINT')
            b:SetScript('OnEnter',function(self) self:SetBackdropBorderColor(.95,.75,.22,1) end)
            b:SetScript('OnLeave',function(self) self:SetBackdropBorderColor(self.selected and .95 or .52,self.selected and .75 or .38,.18,1) end)
            U.rows[i]=b
        end
        b.entry,b.selected=entry,U.selectionKey==entry.key
        b.label:SetWidth(starPage and 136 or 158); b.favorite:SetShown(starPage)
        if starPage then
            local kind=U.page=='network' and 'profiles' or 'recipes'
            b.favorite.icon:SetAtlas(F.IsFavorite(kind,kind=='profiles' and entry.owner or entry.item)
                and 'auctionhouse-icon-favorite' or 'auctionhouse-icon-favorite-off')
        end
        b:ClearAllPoints(); b:SetPoint('TOPLEFT',0,-positions[i]); b:SetHeight(heights[i])
        b.label:SetText(C.Safe(entry.title..'\n'..(entry.subtitle or '')))
        b.icon:SetTexture(entry.item and C.Icon(entry.item) or 'Interface\\Icons\\INV_Misc_GroupLooking')
        b:SetBackdropBorderColor(b.selected and .95 or .52,b.selected and .75 or .38,.18,1)
        b:SetScript('OnClick',function(self) U.Select(self.entry) end); b:Show()
    end
    U.list:SetHeight(math.max(280,y)); U.empty:SetShown(#entries==0)
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
    if U.view=='help' then U.RenderHelp(); return end
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
            U.Show(text,F.L('PAGE_network')); return
        end
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
        local lines={string.format(F.L('RECIPE_OVERVIEW'),qty,inBags,r.quantity,batches)}
        if next(r.reagents)==nil then lines[#lines+1]=F.L('NO_REAGENTS') end
        for _,station in ipairs(F.Keys(r.stations)) do lines[#lines+1]='\n'..F.L('CAMP')..station end
        if r.blueprint then lines[#lines+1]='\nBlueprint' end
        lines[#lines+1]='\n'..F.L('RECIPE_NEXT')
        U.Show(table.concat(lines,'\n'),e.title,F.L('CRAFTER')..who(e.owner))
        U.crafter:SetText(F.L('CHANGE_CRAFTER')); U.crafter:SetShown(#e.providers>1)
        local cards={}
        for _,item in ipairs(F.Keys(r.reagents)) do
            local needed=r.reagents[item]*batches; local have=F.Adapter.StockCount(item)
            cards[#cards+1]={item=item,title=C.ItemName(item),text=string.format(F.L('MATERIAL_CARD'),F.Adapter.ItemCount(item),F.Bank.Count(item),needed),good=have>=needed}
        end
        local y=U.ShowCards(cards)
        local providers,counts={},{}
        for _,provider in ipairs(e.providers) do
            counts[provider.owner]=(counts[provider.owner] or 0)+1
        end
        local owners=F.Keys(counts)
        table.sort(owners,function(a,b) if (a==F.me)~=(b==F.me) then return a==F.me end; return a<b end)
        for _,owner in ipairs(owners) do
            local variants=counts[owner]>1 and ' ('..string.format(F.L('RECIPE_COUNT'),counts[owner])..')' or ''
            providers[#providers+1]=who(owner)..': '..e.title..variants
        end
        U.ShowBlocks({{title=F.L('AVAILABLE_CRAFTERS'),text=table.concat(providers,'\n')},
            {title=F.L('RECIPE_DETAILS'),text=table.concat(lines,'\n')}},y)
    elseif e.kind=='player' then
        local p=F.db.profiles[e.owner]; if not p then return end
        U.RenderPlayer(e,p)
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
    U.Show('',entry.title,string.format(F.L(stale and 'PROFILE_CACHED_AGE' or 'DATA_AGE'),
        math.max(0,math.floor((F.Now()-(profile.seen or 0))/60))),stale and 'missing' or nil)
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
            header.title=label(header,'GameFontNormal',36,-6,204,''); header.title:SetWordWrap(true); header.title:SetTextColor(1,.82,.22)
            header.detail=label(header,'GameFontHighlightSmall',247,-6,153,''); header.detail:SetWordWrap(true); header.detail:SetTextColor(.91,.81,.60)
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
            U.details:SetVerticalScroll(math.min(position,math.max(0,U.body:GetHeight()-240)))
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
                                F.Theme.ShowTooltip(self,C.Safe(self.entry.title),F.L('PROFILE_RECIPE_HINT'))
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
local function defaultSource(material)
    for _,source in ipairs(material and material.alternatives or {}) do
        if source.ready and (not material.chosen or (source.owner==material.chosen.owner and source.recipeID==material.chosen.recipeID)) then return source end
    end
    for _,source in ipairs(material and material.alternatives or {}) do if source.ready then return source end end
end
function U.AddRecipeOptions(rows,item,material)
    if U.expandedSource~=item then return end
    if U.recipeOptionsRendered[item] then return end
    U.recipeOptionsRendered[item]=true
    rows[#rows+1]={section=true,title=F.L('CHAIN_RECIPES'),text=F.L('CHAIN_RECIPES_HELP')}
    local profiles=U.planData.demo and F.Adapter.Demo() or F.Profiles()
    local needed=math.max(0,material.quantity-material.stock)
    for _,source in ipairs(F.Planner.Sources(profiles,item,nil,F.me)) do
        local r=source.recipe
        local batches=math.ceil(needed/r.quantity)
        local text=string.format(F.L('CHAIN_FROM'),ingredientList(r.reagents,batches))..'\n'..F.L('CRAFTER')..who(source.owner)
        if batches*r.quantity>needed then text=text..'\n'..string.format(F.L('CHAIN_SURPLUS'),batches*r.quantity-needed) end
        if F.ProfileStale(profiles[source.owner]) then text=text..'\n'..F.L('PROFILE_CACHED') end
        if not source.ready then text=text..'\n'..F.L('MISSING_REASON_camp') end
        local owner,recipeID=source.owner,source.recipeID
        local current=material.chosen and material.chosen.owner==owner and material.chosen.recipeID==recipeID
        rows[#rows+1]={item=item,title=r.name..' x'..(batches*r.quantity),text=text,
            actions={{text=F.L(current and 'SOURCE_SELECTED' or 'CHAIN_USE_RECIPE'),enabled=source.ready and not current,
                run=function() U.ChooseSource(item,{owner=owner,recipeID=recipeID}) end}}}
    end
end
function U.RenderPlan()
    local p=U.planData
    U.recipeOptionsRendered={}
    U.Show('',C.ItemName(p.target)..' x'..p.quantity,F.L(p.demo and 'DEMO_ONLY' or 'CHAIN_PLAN_ONLY'),p.complete and 'good' or 'missing')
    U.hero:SetTexture(C.Icon(p.target))
    local rows={{section=true,title=F.L('CHAIN_GET'),text=F.L(next(p.missing) and 'CHAIN_GET_HELP' or 'NOTHING_MISSING')}}
    for _,item in ipairs(F.Keys(p.missing)) do
        local id,m=item,p.materials and p.materials[item]
        local source=defaultSource(m)
        local text=string.format(F.L('CHAIN_GET_COUNT'),p.missing[item])
        if m and m.stock>0 then text=text..'\n'..string.format(F.L('CHAIN_HAVE'),m.stock) end
        local reason=p.missingReasons[item]
        if reason=='camp' or reason=='source' or reason=='cycle' or reason=='limit' then text=text..'\n'..F.L('MISSING_REASON_'..reason) end
        local actions={}
        if source and id~=p.target then
            local needed=math.max(0,m.quantity-m.stock)
            local batches=math.ceil(needed/source.recipe.quantity)
            text=text..'\n\n'..F.L('CHAIN_OR_MAKE')..'\n'..string.format(F.L('CHAIN_FROM'),ingredientList(source.recipe.reagents,batches))..'\n'..F.L('CRAFTER')..who(source.owner)
            local owner,recipeID=source.owner,source.recipeID
            actions[#actions+1]={text=string.format(F.L('CHAIN_MAKE_BUTTON'),needed),run=function() U.ChooseSource(id,{owner=owner,recipeID=recipeID}) end}
        end
        if m and id~=p.target and (#m.alternatives>1 or (#m.alternatives>0 and not source)) then
            actions[#actions+1]={text=F.L(U.expandedSource==id and 'CHAIN_HIDE_RECIPES' or #m.alternatives==1 and 'CHAIN_RECIPES' or 'CHAIN_OTHER_RECIPES'),run=function() U.OpenSources(id) end}
        end
        rows[#rows+1]={key='get/'..id,item=id,title=C.ItemName(id)..' x'..p.missing[id],text=text,tone='missing',actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    rows[#rows+1]={section=true,title=F.L('CHAIN_MAKE'),text=F.L(next(p.missing) and 'CHAIN_MAKE_WAIT' or 'CHAIN_MAKE_HELP')}
    for i,step in ipairs(p.steps) do
        local id,m=step.item,p.materials and p.materials[step.item]
        local text=F.L('CRAFTER')..who(step.owner)..'\n'..string.format(F.L('CHAIN_FROM'),ingredientList(step.reagents))
        for _,station in ipairs(F.Keys(step.stations)) do text=text..'\n'..F.L('CAMP')..station..': '..who(step.stations[station]) end
        local actions={}
        if m and id~=p.target then
            local needed=math.max(0,m.quantity-m.stock)
            if m.stock>0 then text=text..'\n'..string.format(F.L('CHAIN_HAVE'),m.stock) end
            actions[#actions+1]={text=string.format(F.L('CHAIN_GET_BUTTON'),needed),run=function() U.ChooseSource(id,'external') end}
            if #m.alternatives>1 then
                actions[#actions+1]={text=F.L(U.expandedSource==id and 'CHAIN_HIDE_RECIPES' or 'CHAIN_OTHER_RECIPES'),run=function() U.OpenSources(id) end}
            end
        end
        rows[#rows+1]={key='make/'..i,item=id,title=i..'. '..string.format(F.L('CHAIN_MAKE_ITEM'),C.ItemName(id,step.name),step.quantity),text=text,actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    if #p.steps==0 and p.complete then rows[#rows+1]={title=F.L('ALREADY_OWNED'),text=''} end
    if #p.warnings>0 then rows[#rows+1]={title=F.L('PLAN_NEEDS'),text=F.L('PLAN_CYCLE_WARNING'),tone='missing'} end
    if next(p.supplied) then
        rows[#rows+1]={section=true,title=F.L('CHAIN_STOCK'),text='',actions={{text=F.L(U.showPlanStock and 'CHAIN_HIDE_STOCK' or 'CHAIN_SHOW_STOCK'),run=function()
            local position=U.details:GetVerticalScroll(); U.showPlanStock=not U.showPlanStock; U.RenderPlan(); U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
        end}}}
        if U.showPlanStock then
            for _,item in ipairs(F.Keys(p.supplied)) do
                local bags=p.bagSupplied and p.bagSupplied[item] or p.supplied[item]
                rows[#rows+1]={item=item,title=C.ItemName(item)..' x'..p.supplied[item],text=string.format(F.L('STOCK_CARD'),bags,p.supplied[item]-bags),tone='good'}
            end
        end
    end
    local y=U.ShowSourceRows(rows,0)
    local notes={}
    if not p.demo and F.db.settings.useBank~=false then notes[#notes+1]={title=F.L('BANK_SECTION'),text=F.Bank.Status()..'\n'..F.L('BANK_REMINDER')} end
    notes[#notes+1]={title=F.L('NEXT_SECTION'),text=F.L('MANUAL_CRAFT')}
    U.ShowBlocks(notes,y)
end
function U.SetRecipeFilter(key,value)
    U.recipeFilters=U.recipeFilters or {}
    if key then U.recipeFilters[key]=value else U.recipeFilters={} end
    U.selectionKey,U.target,U.view=nil,nil,nil
    U.filterMenu:Hide(); U.listScroll:SetVerticalScroll(0); U.Status()
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
        if not b then b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); U.filterControls[index]=b end
        b:SetParent(parent); b:ClearAllPoints(); b:SetPoint('TOPLEFT',x,y); b:SetSize(width,24); b:SetText(title)
        b:SetEnabled(key==false or (U.recipeFilters or {})[key]~=value)
        b:SetScript('OnClick',function() U.SetRecipeFilter(key or nil,value) end); b:Show()
    end
    local professions,groups={},{}
    for _,profile in pairs(F.Profiles()) do
        for _,recipe in pairs(profile.recipes) do professions[recipe.profession]=true end
    end
    for id in pairs(professions) do groups[#groups+1]={id=id,title=C.ProfessionName(id)} end
    table.sort(groups,function(a,b) return C.Fold(a.title)<C.Fold(b.title) end)
    table.insert(groups,1,{title=F.L('FILTER_ALL')})
    for i,group in ipairs(groups) do
        choice(U.filterProfessionList,C.Safe(group.title),'profession',group.id,((i-1)%2)*202,-math.floor((i-1)/2)*26,192)
    end
    U.filterProfessionList:SetHeight(math.max(132,math.ceil(#groups/2)*26))
    U.filterProfessionScroll:SetVerticalScroll(0)
    local types={{'FILTER_ALL'},{'FILTER_REGULAR','regular'},{'FILTER_BLUEPRINT','blueprint'}}
    local scopes={{'FILTER_ALL'},{'FILTER_MINE','mine'},{'FILTER_NETWORK','network'}}
    for i,option in ipairs(types) do choice(U.filterMenu,F.L(option[1]),'kind',option[2],12+(i-1)*140,-200,132) end
    for i,option in ipairs(scopes) do choice(U.filterMenu,F.L(option[1]),'scope',option[2],12+(i-1)*140,-252,132) end
    choice(U.filterMenu,F.L('FILTER_RESET'),false,nil,12,-294,412)
    U.filterMenu:Show()
end
function U.Status()
    F.Theme.RefreshFonts(); U.Ensure(); F.Prune()
    U.heading:SetText(F.L(U.page=='recipes' and 'WHAT_TO_MAKE' or 'PAGE_'..U.page))
    U.sharing:SetText(string.format(F.L('NETWORK_SUMMARY'),#C.Recipes(F.db.profiles,''),math.max(0,#F.Keys(F.db.profiles)-1),F.L(F.db.settings.sharing and 'включён' or 'выключен')))
    U.scan:SetText(F.L('Сканировать')); U.share:SetText(F.L(F.db.settings.sharing and 'SHARE_ON' or 'SHARE_OFF')); U.sync:SetText(F.L('Обновить'))
    U.searchLabel:SetText(F.L('SEARCH_LABEL')); U.itemLabel:SetText(F.L('CHOSEN_ITEM')); U.qtyLabel:SetText(F.L('QUANTITY_FIELD'))
    U.filterButton:SetShown(U.page=='recipes'); U.search:SetWidth(U.page=='recipes' and 124 or 210)
    U.filterButton:SetText(F.L('FILTER_BUTTON')..(next(U.recipeFilters or {}) and ' *' or ''))
    if U.page~='recipes' and U.filterMenu then U.filterMenu:Hide() end
    U.plan:SetText(F.L('Собрать цепочку')); U.request:SetText(F.L('ASK_HELP')); U.demo:SetText(F.L('DEMO_BUTTON')); U.help:SetText(F.L('HELP_BUTTON'))
    U.accept:SetText(F.L('ACCEPT')); U.done:SetText(F.L('DONE')); U.cancel:SetText(F.L('CANCEL'))
    for page,nav in pairs(U.navigation) do nav:SetChecked(page==U.page); nav.tooltipText=F.L('PAGE_'..page) end
    U.RefreshRows(); U.UpdateActions(); U.RenderSelection()
    U.frame:Show()
end
function U.BuildSelected()
    local target,qty=U.target,U.Quantity()
    if U.page=='chain' and U.planData and target and target.item~=U.planData.target then
        local p=U.planData
        U.SetTarget(p.target,p.quantity,p.owner,p.recipeID,p.demo)
        target,qty=U.target,U.Quantity()
    end
    if not target or not F.Integer(qty,1,10000) then return end
    local profiles=target.demo and F.Adapter.Demo() or F.Profiles()
    local inventory=target.demo and {['demo:ore']=3,['demo:cloth']=4} or F.Adapter.Inventory(profiles)
    if not target.demo then inventory[target.item]=F.Adapter.StockCount(target.item) end
    local previous=U.planData
    local same=previous and previous.target==target.item and previous.owner==target.owner and previous.recipeID==target.recipeID and previous.demo==target.demo
    if not same then U.expandedSource,U.showPlanStock=nil,nil end
    local sources=same and previous.sources or {}
    local p=F.Planner.Build(profiles,target.item,qty,inventory,nil,{owner=target.owner,recipeID=target.recipeID,localOwner=F.me,sources=sources})
    p.demo,p.owner,p.recipeID=target.demo,target.owner,target.recipeID; U.Plan(p)
end
function U.OpenSources(item)
    local p=U.planData
    if not p then return end
    local position=U.details:GetVerticalScroll()
    U.expandedSource=U.expandedSource~=item and item or nil
    U.view,U.selectionKey=nil,nil
    U.SetTarget(p.target,p.quantity,p.owner,p.recipeID,p.demo)
    U.Status()
    U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
end
function U.ChooseSource(item,choice)
    local p=U.planData
    if not p or item==p.target then return end
    p.sources=p.sources or {}; p.sources[item]=choice
    U.view,U.selectionKey,U.expandedSource=nil,nil,nil
    U.SetTarget(p.target,p.quantity,p.owner,p.recipeID,p.demo)
    U.BuildSelected()
end
function U.ShowSourceRows(entries,offset)
    U.sourceRows=U.sourceRows or {}; U.chainRows=entries
    U.bodyText:Hide()
    local y=offset or 0
    for i,entry in ipairs(entries) do
        local row=U.sourceRows[i]
        if not row then
            row=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); row:SetWidth(434); skin(row,true)
            row.icon=row:CreateTexture(nil,'ARTWORK'); row.icon:SetSize(36,36); row.icon:SetPoint('TOPLEFT',10,-10)
            row.title=label(row,'GameFontNormal',10,-10,414,''); row.title:SetWordWrap(true)
            row.detail=label(row,'GameFontHighlight',10,-35,414,''); row.detail:SetWordWrap(true); row.detail:SetSpacing(3)
            row.buttons={}
            for j=1,2 do row.buttons[j]=button(row,'',10,0,200,function(self) if self.action then self.action() end end) end
            row.action=row.buttons[1]
            U.sourceRows[i]=row
        end
        row:ClearAllPoints(); row:SetPoint('TOPLEFT',0,-y)
        row.entry=entry
        local x=entry.item and 56 or 10
        row.icon:SetShown(entry.item~=nil); if entry.item then row.icon:SetTexture(C.Icon(entry.item)) end
        row.title:ClearAllPoints(); row.title:SetPoint('TOPLEFT',x,-10); row.title:SetWidth(424-x)
        row.title:SetHeight(0); row.title:SetText(C.Safe(entry.title))
        local top=math.max(entry.item and 54 or 0,18+row.title:GetStringHeight())
        row.detail:ClearAllPoints(); row.detail:SetPoint('TOPLEFT',10,-top); row.detail:SetHeight(0); row.detail:SetText(C.Safe(entry.text or ''))
        row.detail:SetShown(entry.text and entry.text~='')
        if row.detail:IsShown() then top=top+row.detail:GetStringHeight()+10 end
        F.Theme.Color(row.detail,entry.tone or 'text')
        local color=F.Theme.colors[entry.tone or 'muted']; row:SetBackdropBorderColor(color[1],color[2],color[3],1)
        for j,control in ipairs(row.buttons) do
            local action=entry.actions and entry.actions[j]
            control:SetShown(action~=nil)
            if action then
                control:ClearAllPoints(); control:SetPoint('TOPLEFT',10+(j-1)*210,-top)
                control:SetWidth(#entry.actions==1 and 300 or 200)
                control:SetText(action.text); control:SetEnabled(action.enabled~=false); control.action=action.run
            else control.action=nil end
        end
        local height=top+(entry.actions and #entry.actions>0 and 34 or 10)
        row:SetHeight(height); row:Show(); y=y+height+12
    end
    U.body:SetHeight(math.max(240,y+8)); return y
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
            card.title=label(card,'GameFontNormal',56,-8,368,''); card.title:SetWordWrap(true)
            card.detail=label(card,'GameFontHighlightSmall',56,-30,368,''); card.detail:SetWordWrap(true)
            U.cards[i]=card
        end
        card:ClearAllPoints(); card:SetPoint('TOPLEFT',0,-y); card.icon:SetTexture(C.Icon(entry.item))
        card.title:SetHeight(0); card.detail:SetHeight(0)
        card.title:SetText(C.Safe(entry.title)); card.detail:SetText(C.Safe(entry.text))
        local titleHeight=card.title:GetStringHeight()
        card.detail:ClearAllPoints(); card.detail:SetPoint('TOPLEFT',56,-(12+titleHeight))
        local height=math.max(56,titleHeight+card.detail:GetStringHeight()+20)
        card:SetHeight(height)
        local color=F.Theme.colors[entry.good and 'good' or 'missing']
        card:SetBackdropBorderColor(color[1],color[2],color[3],1)
        F.Theme.Color(card.detail,entry.good and 'good' or 'missing'); card:Show(); y=y+height+12
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
