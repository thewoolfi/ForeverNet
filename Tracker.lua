local _,F=...
F.Tracker={rows={},dirty=true}
local T=F.Tracker

function T.Snapshot()
    local plan=F.Queue.Build()
    local bank={}
    for item,count in pairs(plan.supplied) do
        local withdraw=count-(plan.bagSupplied[item] or 0)-(plan.retainedBank[item] or 0)
        if withdraw>0 then bank[item]=withdraw end
    end
    local kind=#plan.goals==0 and 'empty' or next(bank) and 'bank' or next(plan.missing) and 'get' or
        #plan.steps>0 and 'craft' or 'owned'
    if kind=='owned' then
        local allStock=true
        for _,goal in ipairs(plan.goals) do if goal.mode~='stock' then allStock=false end end
        if allStock then kind='maintained' end
    end
    return {plan=plan,bank=bank,missing=plan.missing,kind=kind,step=plan.steps[1]}
end
local function label(parent,width,size,gold)
    local text=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    text:SetWidth(width); text:SetJustifyH('LEFT'); text:SetWordWrap(true)
    F.Theme.Text(text,gold,size); return text
end
local function button(parent,width,action)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetSize(width,24); F.Theme.Button(b); b:SetScript('OnClick',action); return b
end
function T.Ensure()
    if T.frame then return end
    local frame=CreateFrame('Frame','ForeverNetMaterialTracker',UIParent,'BackdropTemplate')
    T.frame=frame; frame:SetSize(350,440); frame:SetPoint('CENTER',UIParent,'CENTER',330,0)
    frame:SetFrameStrata('HIGH'); F.Theme.Skin(frame,true)
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
    T.title=label(frame,280,14,true); T.title:SetPoint('TOPLEFT',12,-12)
    T.close=button(frame,24,function() T.Toggle(false) end); T.close:SetPoint('TOPRIGHT',-8,-8); T.close:SetText('×')
    T.summary=label(frame,322,12); T.summary:SetPoint('TOPLEFT',12,-42)
    T.scroll=F.Theme.ScrollFrame(frame); T.scroll:SetPoint('TOPLEFT',10,-112); T.scroll:SetPoint('BOTTOMRIGHT',-28,80)
    T.body=CreateFrame('Frame',nil,T.scroll); T.body:SetSize(310,240); T.scroll:SetScrollChild(T.body)
    T.scroll:SetVerticalScroll(0)
    T.queue=button(frame,158,function() F.UI.Navigate('queue') end); T.queue:SetPoint('BOTTOMLEFT',12,44)
    T.refresh=button(frame,158,function() T.Render() end); T.refresh:SetPoint('BOTTOMRIGHT',-12,44)
    T.help=label(frame,322,11); T.help:SetPoint('BOTTOMLEFT',12,8)
    frame:Hide()
end
function T.Toggle(show)
    T.Ensure()
    if show==nil then show=not T.frame:IsShown() end
    F.Queue.data.tracker=not not show
    T.frame:SetShown(show)
    if show then T.Render() end
end
function T.Start() if F.Queue.data.tracker then T.Toggle(true) end end
function T.Render()
    if not T.frame then return end
    T.dirty=false; T.age=0
    local snapshot=T.Snapshot(); T.snapshot=snapshot
    local plan=snapshot.plan
    T.title:SetText(F.L('TRACK_TITLE')); T.queue:SetText(F.L('PAGE_queue')); T.refresh:SetText(F.L('CHAIN_REFRESH'))
    T.help:SetText(F.L('TRACK_HELP'))
    local helpHeight=T.help:GetStringHeight()
    T.queue:ClearAllPoints(); T.queue:SetPoint('BOTTOMLEFT',12,helpHeight+16)
    T.refresh:ClearAllPoints(); T.refresh:SetPoint('BOTTOMRIGHT',-12,helpHeight+16)
    T.summary:SetText(F.Catalog.Safe(F.UI.BudgetText(plan.missing)))
    T.summary:SetHeight(0)
    T.scroll:ClearAllPoints(); T.scroll:SetPoint('TOPLEFT',10,-(50+T.summary:GetStringHeight()))
    T.scroll:SetPoint('BOTTOMRIGHT',-28,helpHeight+50)
    local entries={}
    local status=F.L(snapshot.kind=='empty' and 'EMPTY_queue' or snapshot.kind=='owned' and 'ALREADY_OWNED' or snapshot.kind=='maintained' and 'RESTOCK_READY' or
        snapshot.kind=='bank' and 'TRACK_BANK_NEXT' or snapshot.kind=='get' and 'CHAIN_GET_HELP' or 'CHAIN_PLAN_ONLY')
    entries[#entries+1]={title=F.L('NEXT_SECTION'),text=status}
    for i,goal in ipairs(plan.goals) do
        if goal.mode=='stock' then
            local state=plan.goalStates[i]
            entries[#entries+1]={item=goal.item,title=F.Catalog.ItemName(goal.item),text=F.L('RESTOCK_MODE')..'\n'..
                string.format(F.L('RESTOCK_PROGRESS'),state.stock-state.bankStock,state.bankStock,goal.quantity)..
                (state.bankStock>0 and '\n'..F.Bank.Status() or '')}
        end
    end
    if next(snapshot.bank) then
        entries[#entries+1]={title=F.L('BANK_SECTION'),text=F.Bank.Status()}
        for _,item in ipairs(F.Keys(snapshot.bank)) do
            entries[#entries+1]={item=item,title=F.Catalog.ItemName(item),text=string.format(F.L('TRACK_BANK_COUNT'),snapshot.bank[item])..'\n'..
                string.format(F.L('STOCK_CARD'),plan.bagSupplied[item] or 0,snapshot.bank[item])}
        end
    end
    if next(plan.missing) then
        entries[#entries+1]={title=F.L('CHAIN_GET'),text=''}
        for _,item in ipairs(F.Keys(plan.missing)) do
            local bags=plan.bagSupplied[item] or 0
            entries[#entries+1]={item=item,title=F.Catalog.ItemName(item),text=string.format(F.L('TRACK_GET_COUNT'),plan.missing[item])..'\n'..
                string.format(F.L('STOCK_CARD'),bags,(plan.supplied[item] or 0)-bags),search=true}
        end
    end
    if snapshot.step then
        local step=snapshot.step
        entries[#entries+1]={item=step.item,title=F.L('TRACK_NEXT_CRAFT'),text=string.format(F.L('CHAIN_MAKE_ITEM'),
            F.Catalog.ItemName(step.item,step.name),step.quantity)..'\n'..F.L('CRAFTER')..(step.owner==F.me and F.L('YOU') or step.owner)}
    end
    local y=0
    for i,entry in ipairs(entries) do
        local row=T.rows[i]
        if not row then
            row=CreateFrame('Frame',nil,T.body); row:SetWidth(308)
            row.title=label(row,302,12,true); row.text=label(row,302,12)
            row.icon=row:CreateTexture(nil,'ARTWORK'); row.icon:SetSize(22,22); row.icon:SetPoint('TOPLEFT',0,-4)
            row.search=button(row,100,function()
                local ok,why=F.Auction.Search(row.item); if not ok then F.Print(why) end
            end)
            row.search:SetScript('OnEnter',function(b) F.Theme.ShowTooltip(b,F.L('TRACK_SEARCH_HINT')) end)
            row.search:SetScript('OnLeave',F.Theme.HideTooltip)
            T.rows[i]=row
        end
        F.Theme.BindItemTooltip(row,entry.item,entry.title,entry.text)
        row.item=entry.item; row.search:SetText(F.L('TRACK_SEARCH'))
        row:ClearAllPoints(); row:SetPoint('TOPLEFT',0,-y)
        row.icon:SetShown(not not entry.item); if entry.item then row.icon:SetTexture(F.Catalog.Icon(entry.item)) end
        row.title:ClearAllPoints(); row.title:SetPoint('TOPLEFT',entry.item and 28 or 0,-4)
        row.title:SetWidth(entry.item and 274 or 302); row.title:SetText(F.Catalog.Safe(entry.title))
        local titleHeight=row.title:GetStringHeight()
        row.text:ClearAllPoints(); row.text:SetPoint('TOPLEFT',entry.item and 28 or 0,-(titleHeight+8))
        row.text:SetWidth(entry.search and 164 or entry.item and 274 or 302); row.text:SetText(F.Catalog.Safe(entry.text))
        row.search:ClearAllPoints(); row.search:SetPoint('TOPRIGHT',0,-(titleHeight+7)); row.search:SetShown(not not entry.search)
        local searchHeight=entry.search and F.Theme.FitButton(row.search,100) or 0
        local height=titleHeight+math.max(row.text:GetStringHeight(),searchHeight)+16
        row:SetHeight(height); row:Show(); y=y+height+6
    end
    for i=#entries+1,#T.rows do T.rows[i]:Hide() end
    T.body:SetHeight(math.max(240,y))
    local visible=T.scroll:GetHeight()>0 and T.scroll:GetHeight() or 240
    T.scroll:SetVerticalScroll(math.min(T.scroll:GetVerticalScroll(),math.max(0,y-visible)))
end
function T.Tick(elapsed)
    if not T.frame or not T.frame:IsShown() then return end
    T.elapsed=(T.elapsed or 0)+elapsed; T.age=(T.age or 0)+elapsed
    if T.elapsed<.5 then return end
    T.elapsed=0
    if T.dirty or T.age>=10 then T.Render() end
end
