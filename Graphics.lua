local _,F=...
local U,C,T=F.UI,F.Catalog,F.Theme
local function who(owner) return owner==F.me and F.L('YOU') or owner end
local function text(parent,size,gold)
    local region=parent:CreateFontString(nil,'OVERLAY',gold and 'GameFontNormal' or 'GameFontHighlightSmall')
    T.Text(region,gold,size); region:SetJustifyH('LEFT'); region:SetWordWrap(true)
    return region
end
local function tip(widget,title,detail)
    widget:SetScript('OnEnter',function() T.ShowTooltip(widget,title,detail) end)
    widget:SetScript('OnLeave',T.HideTooltip)
end
function U.HideGraphics()
    for _,group in ipairs({U.visualStats or {},U.visualTiles or {}}) do
        for _,widget in ipairs(group) do widget:Hide() end
    end
end
function U.ShortPrice(item,quantity)
    if not F.Market.Number(quantity,0,10000) then return '?' end
    local q=F.Market.Quote(item,math.max(1,quantity))
    if quantity==0 then return F.Market.Money(0) end
    if q.status~='known' then return '?' end
    return F.Market.Money(q.cost)..((q.stale or q.partial or q.approximate or q.remaining>0) and ' *' or '')
end
function U.ShortBudget(missing)
    local b=F.Market.Budget(missing)
    if b.unknown>0 and b.cost==0 then return '?' end
    return F.Market.Money(b.cost)..((b.uncovered>0 or b.stale>0 or b.partial>0 or b.approximate) and ' *' or '')
end
function U.ShowVisualStats(entries,offset)
    U.visualStats=U.visualStats or {}
    local y=offset or 0
    local width=(434-(#entries-1)*8)/math.max(1,#entries)
    local height=58
    for i,entry in ipairs(entries) do
        local card=U.visualStats[i]
        if not card then
            card=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); T.Skin(card,true); card:EnableMouse(true)
            card.icon=card:CreateTexture(nil,'ARTWORK'); card.icon:SetSize(20,20); card.icon:SetPoint('TOPLEFT',8,-9)
            card.value=text(card,16,true); card.value:SetPoint('TOPLEFT',34,-8)
            card.caption=text(card,12); card.caption:SetPoint('TOPLEFT',8,-32)
            U.visualStats[i]=card
        end
        card:ClearAllPoints(); card:SetPoint('TOPLEFT',(i-1)*(width+8),-y); card:SetWidth(width)
        card.value:SetWidth(width-42); card.value:SetHeight(0); card.value:SetText(entry.value)
        card.icon:SetTexture(entry.icon); card.caption:SetWidth(width-16); card.caption:SetHeight(0); card.caption:SetText(entry.title)
        local valueHeight=card.value:GetStringHeight()
        card.caption:ClearAllPoints(); card.caption:SetPoint('TOPLEFT',8,-(valueHeight+14))
        height=math.max(height,valueHeight+card.caption:GetStringHeight()+22)
        T.Color(card.value,entry.tone or 'heading'); tip(card,entry.title,entry.hint); card:Show()
    end
    for i=#entries+1,#U.visualStats do U.visualStats[i]:Hide() end
    for i=1,#entries do U.visualStats[i]:SetHeight(height) end
    U.bodyText:Hide(); U.body:SetHeight(math.max(240,y+height+16))
    return y+height+10
end
function U.ShowVisualTiles(entries,offset)
    U.visualTiles=U.visualTiles or {}
    for _,tile in ipairs(U.visualTiles) do tile:Hide() end
    local y=offset or 0
    for start=1,#entries,2 do
        local height,pair=64,{}
        for i=start,math.min(start+1,#entries) do
            local entry=entries[i]
            local tile=U.visualTiles[i]
            if not tile then
                tile=CreateFrame('Button',nil,U.body,'BackdropTemplate'); T.Skin(tile,true); tile:SetWidth(212)
                tile.icon=tile:CreateTexture(nil,'ARTWORK'); tile.icon:SetSize(36,36); tile.icon:SetPoint('TOPLEFT',8,-8)
                tile.title=text(tile,12,true); tile.title:SetPoint('TOPLEFT',52,-8); tile.title:SetWidth(152)
                tile.detail=text(tile,12); tile.detail:SetWidth(152)
                tile.track=tile:CreateTexture(nil,'BACKGROUND'); tile.track:SetColorTexture(.22,.19,.14,1)
                tile.track:SetHeight(4); tile.track:SetPoint('BOTTOMLEFT',8,8); tile.track:SetWidth(196)
                tile.fill=tile:CreateTexture(nil,'ARTWORK'); tile.fill:SetHeight(4); tile.fill:SetPoint('BOTTOMLEFT',8,8)
                tile:SetScript('OnClick',function(self) if self.entry.run then T.HideTooltip(); self.entry.run() end end)
                U.visualTiles[i]=tile
            end
            tile.entry=entry; tile:ClearAllPoints(); tile:SetPoint('TOPLEFT',(i-start)*222,-y)
            tile.icon:SetTexture(entry.icon or C.Icon(entry.item)); tile.title:SetHeight(0); tile.title:SetText(C.Safe(entry.title))
            tile.detail:ClearAllPoints(); tile.detail:SetPoint('TOPLEFT',52,-(12+tile.title:GetStringHeight()))
            tile.detail:SetHeight(0); tile.detail:SetText(C.Safe(entry.text or ''))
            height=math.max(height,tile.title:GetStringHeight()+tile.detail:GetStringHeight()+32)
            local tone=entry.tone or 'muted'; local color=T.colors[tone] or T.colors.muted
            tile:SetBackdropBorderColor(.22,.20,.17,1); T.Color(tile.detail,tone)
            local progress=entry.maximum and entry.maximum>0
            tile.track:SetShown(not not progress); tile.fill:SetShown(not not progress and (entry.current or 0)>0)
            if progress then
                tile.fill:SetWidth(math.max(1,196*math.min(1,(entry.current or 0)/entry.maximum)))
                tile.fill:SetColorTexture(color[1],color[2],color[3],1)
            end
            tip(tile,entry.title,entry.hint); tile:Show(); pair[#pair+1]=tile
        end
        for _,tile in ipairs(pair) do tile:SetHeight(height) end
        y=y+height+8
    end
    U.bodyText:Hide(); U.body:SetHeight(math.max(240,y+8)); return y
end
-- Each reagent retains its own name/count tooltip. No links to secure bag buttons.
function U.DrawIngredients(row,reagents,top)
    row.ingredients=row.ingredients or {}
    for _,widget in ipairs(row.ingredients) do widget:Hide() end
    local keys=F.Keys(reagents or {})
    local y,height=top,0
    for i,item in ipairs(keys) do
        if i>1 and (i-1)%7==0 then y=y+height+4; height=0 end
        local widget=row.ingredients[i]
        if not widget then
            widget=CreateFrame('Frame',nil,row); widget:SetSize(54,46); widget:EnableMouse(true)
            widget.icon=widget:CreateTexture(nil,'ARTWORK'); widget.icon:SetSize(26,26); widget.icon:SetPoint('TOPLEFT',14,0)
            widget.count=text(widget,12); widget.count:SetPoint('TOPLEFT',0,-28); widget.count:SetWidth(54); widget.count:SetJustifyH('CENTER')
            row.ingredients[i]=widget
        end
        widget:ClearAllPoints(); widget:SetPoint('TOPLEFT',10+((i-1)%7)*59,-y)
        widget.icon:SetTexture(C.Icon(item)); widget.count:SetText(tostring(reagents[item]))
        widget:SetHeight(28+widget.count:GetStringHeight()+4); height=math.max(height,widget:GetHeight())
        tip(widget,C.ItemName(item),'x'..reagents[item]); widget:Show()
    end
    return #keys>0 and y+height+4 or top
end
function U.ToggleVisual(key)
    U.visualExpanded=U.visualExpanded or {}
    U.visualExpanded[key]=not U.visualExpanded[key]
    local position=U.details:GetVerticalScroll() or 0
    U.RenderSelection(); U.LayoutDetails()
    U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
end
function U.NextCraft(plan)
    for i,step in ipairs(plan.steps) do
        if step.owner==F.me then
            local ready=true
            for item,quantity in pairs(step.reagents) do if F.Adapter.ItemCount(item)<quantity then ready=false; break end end
            if ready then return i end
        end
    end
end
function U.RenderRecipe(entry)
    local r,qty=entry.recipe,U.Quantity()
    if not F.Integer(qty,1,10000) then U.Show(F.L('QUANTITY_ERROR'),entry.title); return end
    local owned=F.Adapter.StockCount(entry.item)
    local batches=math.ceil(math.max(0,qty-owned)/r.quantity)
    U.Show('',entry.title,who(entry.owner))
    U.hero:SetTexture(C.Icon(entry.item))
    U.crafter:SetText(F.L('CHANGE_CRAFTER')); U.crafter:SetShown(#entry.providers>1)
    U.crafter:SetScript('OnEnter',function(self)
        local names,seen={},{}
        for _,p in ipairs(U.selectedEntry.providers) do if not seen[p.owner] then seen[p.owner]=true; names[#names+1]=who(p.owner) end end
        T.ShowTooltip(self,F.L('AVAILABLE_CRAFTERS'),table.concat(names,' / '))
    end)
    U.crafter:SetScript('OnLeave',T.HideTooltip)
    U.enqueue:SetText(F.L('QUEUE_ADD')); U.enqueue:Show()
    local y=U.ShowVisualStats({
        {title=F.L('VIS_TARGET'),value=tostring(qty),icon=C.Icon(entry.item)},
        {title=F.L('VIS_OWNED'),value=tostring(owned),icon='Interface\\Icons\\INV_Misc_Bag_08',tone=owned>=qty and 'good' or 'muted'},
        {title=F.L('VIS_CRAFTS'),value=tostring(batches),icon='Interface\\Icons\\Trade_Engineering',hint=string.format(F.L('RECIPE_OVERVIEW'),qty,owned,r.quantity,batches)},
    })
    local tiles={}
    for _,item in ipairs(F.Keys(r.reagents)) do
        local needed=r.reagents[item]*batches; local have=F.Adapter.StockCount(item)
        local shortage=math.max(0,needed-have)
        tiles[#tiles+1]={item=item,title=C.ItemName(item),current=math.min(have,needed),maximum=needed,
            text=have..' / '..needed..(shortage>0 and '  '..U.ShortPrice(item,shortage) or ''),tone=have>=needed and 'good' or 'missing',
            hint=string.format(F.L('MATERIAL_CARD'),F.Adapter.ItemCount(item),F.Bank.Count(item),needed)..
                (shortage>0 and '\n'..U.PriceText(item,shortage) or ''),
            run=function() U.FindCrafters(item,math.max(1,shortage)) end}
    end
    y=U.ShowVisualTiles(tiles,y)
    local notes={}
    if #tiles==0 then notes[#notes+1]={title=F.L('NO_REAGENTS')} end
    for _,station in ipairs(F.Keys(r.stations)) do notes[#notes+1]={title=F.L('CAMP')..station,tone='missing'} end
    if r.blueprint then notes[#notes+1]={title=F.L('FILTER_BLUEPRINT'),tone='blueprint'} end
    if #notes>0 then U.ShowSourceRows(notes,y) end
end
function U.RenderHome()
    local plan=F.Queue.Build()
    U.Show('',F.me,(UnitClass and UnitClass('player') or '?')..'  '..(UnitLevel and UnitLevel('player') or 0))
    if SetPortraitTexture then SetPortraitTexture(U.hero,'player') end
    local tiles={}
    local peers=math.max(0,#F.Keys(F.Profiles())-1)
    local channel=F.Net.Channel()
    local ready=0
    for _,state in ipairs(plan.goalStates) do if state.ready then ready=ready+1 end end
    tiles[#tiles+1]={title=F.L('PAGE_queue'),icon='Interface\\Icons\\INV_Misc_Note_05',
        text=string.format(F.L('VIS_QUEUE_MINI'),#plan.goals,#F.Keys(plan.missing)),hint=string.format(F.L('QUEUE_SUMMARY'),#plan.goals,ready,#F.Keys(plan.missing)),
        run=function() U.Navigate('queue') end}
    tiles[#tiles+1]={title=F.L('PAGE_network'),icon='Interface\\Icons\\INV_Misc_GroupLooking',
        text=tostring(peers),tone=channel and F.db.settings.sharing and 'good' or 'muted',
        hint=F.L('NETWORK_CHANNEL')..(channel and F.L('CHANNEL_'..channel) or F.L('NETWORK_NO_CHANNEL'))..(F.Net.lastError and '\n'..F.Net.lastError or ''),
        run=function() U.Navigate('network') end}
    local y=U.ShowVisualTiles(tiles)
    local notes={{title=F.L('BANK_SECTION'),text=F.Bank.Status()}}
    if next(F.localProfile.professions)==nil then
        table.insert(notes,1,{title=F.L('START_SCAN'),actions={{text=F.L('Сканировать'),run=function() F.Command('scan') end}}})
    end
    U.ShowSourceRows(notes,y)
end

function U.RenderPlan()
    local p=U.planData
    U.recipeOptionsRendered={}
    U.Show('',C.ItemName(p.target)..' x'..p.quantity,F.L(p.complete and (#p.steps>0 and 'VIS_READY' or 'VIS_OWNED') or 'VIS_GET'),p.complete and 'good' or 'missing')
    U.hero:SetTexture(C.Icon(p.target))
    local y=U.ShowVisualStats({
        {title=F.L('VIS_GET'),value=tostring(#F.Keys(p.missing)),icon='Interface\\Icons\\INV_Misc_Bag_08',tone=next(p.missing) and 'missing' or 'good'},
        {title=F.L('VIS_CRAFTS'),value=tostring(#p.steps),icon='Interface\\Icons\\Trade_Engineering'},
        {title=F.L('VIS_COST'),value=U.ShortBudget(p.missing),icon='Interface\\Icons\\INV_Misc_Coin_01',hint=U.BudgetText(p.missing)},
    })
    local rows={}
    if next(p.missing) then rows[#rows+1]={section=true,title=F.L('VIS_GET')} end
    for _,item in ipairs(F.Keys(p.missing)) do
        local id,m=item,p.materials and p.materials[item]
        local reason=p.missingReasons[item]
        local hint=F.L('MISSING_REASON_'..reason)..('\n'..U.PriceText(item,p.missing[item]))
        local actions={}
        local source
        if m then
            for _,candidate in ipairs(m.alternatives) do if candidate.ready then source=candidate; break end end
        end
        if source and id~=p.target then
            local owner,recipeID=source.owner,source.recipeID
            local batches=math.ceil(math.max(0,m.quantity-m.stock)/source.recipe.quantity)
            local inputs={}
            for reagent,count in pairs(source.recipe.reagents) do inputs[#inputs+1]=C.ItemName(reagent)..' x'..(count*batches) end
            hint=hint..'\n'..F.L('CHAIN_OR_MAKE')..'\n'..table.concat(inputs,', ')
            actions[#actions+1]={text=string.format(F.L('CHAIN_MAKE_BUTTON'),math.max(0,m.quantity-m.stock)),run=function() U.ChooseSource(id,{owner=owner,recipeID=recipeID}) end}
        end
        if m and id~=p.target and #m.alternatives>0 then
            actions[#actions+1]={text=F.L('VIS_SOURCES'),run=function() U.OpenSources(id) end}
        end
        rows[#rows+1]={key='get/'..id,visual=true,item=id,title=C.ItemName(id)..' x'..p.missing[id],tone='missing',
            text=U.ShortPrice(id,p.missing[id])..
                ((reason=='camp' or reason=='source' or reason=='cycle' or reason=='limit') and '\n'..F.L('MISSING_REASON_'..reason) or ''),hint=hint,actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    if #p.steps>0 then rows[#rows+1]={section=true,title=F.L('VIS_MAKE')} end
    local nextCraft=U.NextCraft(p)
    for i,step in ipairs(p.steps) do
        local id,m=step.item,p.materials and p.materials[step.item]
        local actions={}
        if m and id~=p.target then
            actions[#actions+1]={text=string.format(F.L('CHAIN_GET_BUTTON'),math.max(0,m.quantity-m.stock)),run=function() U.ChooseSource(id,'external') end}
            if #m.alternatives>1 then actions[#actions+1]={text=F.L('VIS_SOURCES'),run=function() U.OpenSources(id) end} end
        end
        local hint=F.L('MANUAL_CRAFT')
        for _,station in ipairs(F.Keys(step.stations)) do hint=hint..'\n'..F.L('CAMP')..station..': '..who(step.stations[station]) end
        rows[#rows+1]={key='make/'..i,visual=true,item=id,title=i..'. '..C.ItemName(id,step.name)..' x'..step.quantity,
            text=who(step.owner)..(i==nextCraft and '  /  '..F.L('VIS_READY') or ''),tone=i==nextCraft and 'good' or nil,reagents=step.reagents,hint=hint,actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    if #p.steps==0 and p.complete then rows[#rows+1]={title=F.L('ALREADY_OWNED'),tone='good'} end
    if #p.warnings>0 then rows[#rows+1]={title=F.L('PLAN_NEEDS'),text=F.L('PLAN_CYCLE_WARNING'),tone='missing'} end
    rows[#rows+1]={section=true,title=F.L('VIS_DETAILS'),actions={{text=U.planDetails and '-' or '+',run=function() U.planDetails=not U.planDetails; U.RenderSelection(); U.LayoutDetails() end}}}
    if U.planDetails then
        for _,item in ipairs(F.Keys(p.supplied)) do
            local bags=p.bagSupplied and p.bagSupplied[item] or p.supplied[item]
            rows[#rows+1]={item=item,title=C.ItemName(item)..' x'..p.supplied[item],text=string.format(F.L('STOCK_CARD'),bags,p.supplied[item]-bags),tone='good'}
        end
        if F.db.settings.useBank~=false then rows[#rows+1]={title=F.L('BANK_SECTION'),text=F.Bank.Status()..'\n'..F.L('BANK_REMINDER')} end
        rows[#rows+1]={text=F.L('MANUAL_CRAFT')}
    end
    U.ShowSourceRows(rows,y)
end
