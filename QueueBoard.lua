local _,F=...
local U,Q,C,T=F.UI,F.Queue,F.Catalog,F.Theme
local function label(parent,width,size)
    local text=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    T.Text(text,false,size or 12); text:SetWidth(width); text:SetJustifyH('LEFT'); text:SetWordWrap(true)
    return text
end
local function button(parent,caption,width,run)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); T.Button(b)
    b:SetText(caption); T.FitButton(b,width); b:SetScript('OnClick',run); return b
end
local function hint(widget,title,detail)
    widget:SetScript('OnEnter',function() T.ShowTooltip(widget,title,detail) end)
    widget:SetScript('OnLeave',T.HideTooltip)
end
function U.HideQueueBoard()
    local b=U.queueBoard
    if not b then return end
    b.bar:Hide(); b.next:Hide(); b.empty:Hide()
    for _,row in ipairs(b.steps) do row:Hide() end
    local editing=U.page=='queue' and U.view~='help' and U.view~='commands' and U.selectedEntry and U.selectedEntry.kind=='goal' and Q.data.goals[U.selectedEntry.index]
    if not editing then
        b.goalBar:Hide()
        U.qty:SetParent(U.frame); U.qty:ClearAllPoints(); U.qty:SetPoint('TOPLEFT',285,-487); U.qty:SetWidth(55)
        U.qtyLabel:SetParent(U.frame); U.qtyLabel:ClearAllPoints(); U.qtyLabel:SetPoint('TOPLEFT',280,-461); U.qtyLabel:SetWidth(68)
        U.queueQtyParent=U.frame
    end
    if U.page~='queue' then b.menu:Hide() end
end
function U.EnsureQueueBoard()
    if U.queueBoard then return U.queueBoard end
    local b={steps={},menuRows={}}
    b.bar=CreateFrame('Frame',nil,U.body); b.bar:SetSize(434,34)
    b.materials=button(b.bar,'',142,function() U.queueSourceItem=nil; b.view='materials'; U.Status() end); b.materials:SetPoint('TOPLEFT',0,0)
    b.crafts=button(b.bar,'',118,function() U.queueSourceItem=nil; b.view='crafts'; U.Status() end); b.crafts:SetPoint('TOPLEFT',150,0)
    b.cost=CreateFrame('Frame',nil,b.bar); b.cost:SetSize(156,32); b.cost:SetPoint('TOPLEFT',278,0); b.cost:EnableMouse(true)
    b.costIcon=b.cost:CreateTexture(nil,'ARTWORK'); b.costIcon:SetTexture('Interface\\Icons\\INV_Misc_Coin_01'); b.costIcon:SetSize(18,18); b.costIcon:SetPoint('TOPLEFT',0,-4)
    b.costValue=label(b.cost,130,14); b.costValue:SetPoint('TOPLEFT',24,-4)
    b.goalBar=CreateFrame('Frame',nil,U.body); b.goalBar:SetWidth(434)
    b.up=button(b.goalBar,'',28,function()
        local e=U.selectedEntry
        if e and Q.MoveUp(e.index) then U.selectionKey=tostring(e.index-1); U.Status() end
    end); b.up:SetPoint('TOPLEFT',182,-8)
    b.up.icon=b.up:CreateTexture(nil,'ARTWORK'); b.up.icon:SetSize(16,16); b.up.icon:SetPoint('CENTER'); b.up.icon:SetTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up')
    b.remove=button(b.goalBar,'x',28,function() local e=U.selectedEntry; if e then Q.Remove(e.index); U.selectionKey=nil; U.Status() end end); b.remove:SetPoint('TOPLEFT',218,-8)
    b.stock=button(b.goalBar,'',174,function()
        local e=U.selectedEntry; local goal=e and Q.data.goals[e.index]
        if not goal then return end
        local ok,why=Q.Mode(e.index,goal.mode~='stock' and 'stock' or nil)
        if ok then U.Status() else F.Print(why) end
    end); b.stock:SetPoint('TOPLEFT',260,-8)
    b.next=CreateFrame('Frame',nil,U.body); b.next:SetWidth(434)
    b.next.caption=label(b.next,380); b.next.caption:SetPoint('TOPLEFT',0,0); T.Color(b.next.caption,'muted')
    b.next.icon=b.next:CreateTexture(nil,'ARTWORK'); b.next.icon:SetSize(32,32); b.next.icon:SetPoint('TOPLEFT',0,-24)
    b.next.title=label(b.next,390,14); b.next.title:SetPoint('TOPLEFT',44,-24)
    b.next.detail=label(b.next,390); b.next.detail:SetPoint('TOPLEFT',44,-46); T.Color(b.next.detail,'muted')
    b.empty=CreateFrame('Frame',nil,U.body); b.empty:SetWidth(434)
    b.empty.text=label(b.empty,400,14); b.empty.text:SetPoint('TOPLEFT',8,-8)
    b.empty.action=button(b.empty,'',190,function() U.Navigate('recipes') end)
    b.menu=CreateFrame('Frame',nil,U.frame,'BackdropTemplate'); T.Skin(b.menu); b.menu:SetWidth(272); b.menu:SetFrameLevel(U.frame:GetFrameLevel()+40); b.menu:SetClampedToScreen(true); b.menu:Hide()
    b.menu:SetPoint('TOPLEFT',U.filterButton,'BOTTOMLEFT',-130,-6)
    b.menuScroll=T.ScrollFrame(b.menu); b.menuScroll:SetPoint('TOPLEFT',8,-8); b.menuScroll:SetPoint('BOTTOMRIGHT',-28,8)
    b.menuBody=CreateFrame('Frame',nil,b.menuScroll); b.menuBody:SetSize(236,240); b.menuScroll:SetScrollChild(b.menuBody)
    U.queueBoard=b; return b
end
function U.QueueMenu(refresh)
    local b=U.EnsureQueueBoard()
    if b.menu:IsShown() and not refresh then b.menu:Hide(); return end
    local actions={
        {text=F.L('SETS_SAVE'),enabled=#Q.data.goals>0,run=function() U.QueueSetDialog('save') end},
        {text=F.L('SETS_CLEAN'),enabled=#Q.data.goals>0,run=function() Q.RemoveOwned(); U.selectionKey=nil; U.Status() end},
        {text=F.L('SETS_UNDO'),enabled=Q.undo~=nil,run=function() Q.Undo(); U.selectionKey=nil; U.queueSourceItem=nil; U.Status() end},
    }
    for _,name in ipairs(F.Keys(Q.data.sets)) do
        local setName=name
        actions[#actions+1]={text=name,run=function() U.QueueSetDialog('load',setName) end,delete=function() Q.DeleteSet(setName); b.menu:Hide(); U.QueueMenu() end}
    end
    for _,row in ipairs(b.menuRows) do row:Hide() end
    local y=8
    for i,action in ipairs(actions) do
        local row=b.menuRows[i]
        if not row then
            row=CreateFrame('Frame',nil,b.menuBody); row:SetWidth(236)
            row.open=button(row,'',200,function(self) local run=self.run; b.menu:Hide(); if run then run() end end)
            row.open:SetPoint('TOPLEFT'); row.delete=button(row,'x',28,function(self) if self.run then self.run() end end); row.delete:SetPoint('TOPRIGHT')
            b.menuRows[i]=row
        end
        row:ClearAllPoints(); row:SetPoint('TOPLEFT',8,-y)
        row.open:SetText(C.Safe(action.text)); row.open:SetEnabled(action.enabled~=false); row.open.run=action.run
        row.delete:SetShown(action.delete~=nil); row.delete.run=action.delete
        hint(row.delete,F.L('SETS_DELETE'),action.text)
        local height=T.FitButton(row.open,action.delete and 200 or 236)
        row:SetHeight(height); row:Show(); y=y+height+6
    end
    b.menuBody:SetHeight(y+2); b.menu:SetHeight(math.min(330,y+18)); b.menu:Show()
end
function U.LayoutQueueControls()
    if U.page~='queue' or not U.queueBoard then return end
    local b=U.queueBoard
    local e=U.selectedEntry; local goal=e and e.kind=='goal' and Q.data.goals[e.index]
    local show=goal and b.goalBar:IsShown()
    U.qty:SetShown(not not show); U.qtyLabel:SetShown(not not show)
    if show then
        if U.queueQtyParent~=b.goalBar then
            U.qty:SetParent(b.goalBar); U.qtyLabel:SetParent(b.goalBar); U.queueQtyParent=b.goalBar
        end
        U.qty:ClearAllPoints(); U.qty:SetPoint('TOPLEFT',106,-8); U.qty:SetWidth(56)
        U.qtyLabel:ClearAllPoints(); U.qtyLabel:SetPoint('TOPLEFT',8,-10); U.qtyLabel:SetWidth(90)
        T.Color(U.qty,F.Integer(U.Quantity(),1,10000) and 'text' or 'missing')
    end
end
function U.RenderQueue()
    local plan=Q.Build(); U.queuePlan=plan
    local materials=F.Copy(plan.materials)
    for item,count in pairs(plan.missing) do if not materials[item] then materials[item]={quantity=count,stock=0,alternatives={}} end end
    local e=U.selectedEntry; local goal=e and e.kind=='goal' and Q.data.goals[e.index]
    U.Show('',goal and C.ItemName(goal.item)..' x'..goal.quantity or F.L('PAGE_queue'),string.format(F.L('VIS_QUEUE_MINI'),#plan.goals,#F.Keys(plan.missing)))
    U.hero:SetTexture(goal and C.Icon(goal.item) or 'Interface\\Icons\\INV_Misc_Note_05')
    U.crafter:SetText(F.L('TRACK_SHOW')); U.crafter:Show(); U.enqueue:Hide()
    local b=U.EnsureQueueBoard(); U.chainRows={}
    b.bar:SetPoint('TOPLEFT',0,0); b.bar:Show()
    b.materials:SetText(F.L('QB_MATERIALS')..' '..#F.Keys(materials)); b.crafts:SetText(F.L('QB_CRAFTS')..' '..#plan.steps)
    local active=(b.view=='crafts' and not U.queueSourceItem) and b.crafts or b.materials
    for _,control in ipairs({b.materials,b.crafts}) do control.flatEdge:SetColorTexture(control==active and .78 or .22,control==active and .60 or .20,control==active and .30 or .17,1) end
    b.costValue:SetText(U.ShortBudget(plan.missing)); hint(b.cost,F.L('VIS_COST'),U.BudgetText(plan.missing))
    local barHeight=math.max(T.FitButton(b.materials,142),T.FitButton(b.crafts,118),b.costValue:GetStringHeight()+8); b.bar:SetHeight(barHeight)
    b.cost:SetHeight(barHeight)
    local y=barHeight+14
    if goal then
        local state=plan.goalStates[e.index]
        b.goalBar:ClearAllPoints(); b.goalBar:SetPoint('TOPLEFT',0,-y); b.goalBar:Show()
        U.LayoutQueueControls()
        b.up:SetEnabled(e.index>1); hint(b.up,F.L('QUEUE_UP')); hint(b.remove,F.L('QUEUE_REMOVE'))
        b.up.icon:SetAlpha(e.index>1 and 1 or .3)
        b.stock:SetText(F.L('QB_STOCK')); hint(b.stock,F.L(goal.mode=='stock' and 'RESTOCK_ONCE' or 'RESTOCK_ENABLE'),F.L('RESTOCK_HELP'))
        b.stock.flatEdge:SetColorTexture(goal.mode=='stock' and .45 or .25,goal.mode=='stock' and .9 or .22,goal.mode=='stock' and .48 or .18,1)
        local height=math.max(T.FitButton(b.stock,174),U.qtyLabel:GetStringHeight()+6,24)+16
        b.goalBar:SetHeight(height); y=y+height+12
        U.summary:SetText(F.L('VIS_OWNED')..' '..state.stock..' / '..goal.quantity)
    end
    if b.menu:IsShown() then U.QueueMenu(true) end
    if #plan.goals==0 then
        b.empty:ClearAllPoints(); b.empty:SetPoint('TOPLEFT',0,-y); b.empty.text:SetText(F.L('EMPTY_queue'))
        b.empty.action:SetText(F.L('PAGE_recipes')); b.empty.action:ClearAllPoints(); b.empty.action:SetPoint('TOPLEFT',8,-(b.empty.text:GetStringHeight()+24))
        local h=b.empty.text:GetStringHeight()+T.FitButton(b.empty.action,190)+40
        b.empty:SetHeight(h); b.empty:Show(); U.body:SetHeight(math.max(240,y+h)); return
    end
    if U.queueSourceItem then
        local item=U.queueSourceItem
        local rows={}
        U.AddCostOptions(rows,item,U.SourceComparison(item,true),function(choice)
            local ok,why=Q.SetSource(item,choice); if not ok then F.Print(why); return end
            U.queueSourceItem=nil; U.Status()
        end)
        U.ShowSourceRows(rows,y); return
    end
    if b.view=='crafts' then
        local nextCraft=U.NextCraft(plan)
        for i,step in ipairs(plan.steps) do
            local row=b.steps[i]
            if not row then
                row=CreateFrame('Frame',nil,U.body); row:SetWidth(434); row:EnableMouse(true)
                row.icon=row:CreateTexture(nil,'ARTWORK'); row.icon:SetSize(32,32); row.icon:SetPoint('TOPLEFT',0,-8)
                row.title=label(row,310,14); row.title:SetPoint('TOPLEFT',44,-8)
                row.owner=label(row,310); row.count=label(row,66,16); row.count:SetPoint('TOPRIGHT',0,-8); row.count:SetJustifyH('RIGHT')
                b.steps[i]=row
            end
            row:ClearAllPoints(); row:SetPoint('TOPLEFT',0,-y); row.icon:SetTexture(C.Icon(step.item)); row.title:SetText(C.ItemName(step.item,step.name))
            row.owner:ClearAllPoints(); row.owner:SetPoint('TOPLEFT',44,-(row.title:GetStringHeight()+12))
            row.owner:SetText(step.owner==F.me and F.L('YOU') or step.owner); T.Color(row.owner,i==nextCraft and 'good' or 'muted')
            row.count:SetText('x'..step.quantity); hint(row,row.title:GetText(),F.L('MANUAL_CRAFT'))
            local top=math.max(44,row.title:GetStringHeight()+row.owner:GetStringHeight()+18,row.count:GetStringHeight()+16)
            local height=U.DrawIngredients(row,step.reagents,top)+12
            row:SetHeight(height); row:Show(); y=y+height+10
        end
        if #plan.steps==0 then U.ShowBlocks({{text=F.L(plan.complete and 'ALREADY_OWNED' or 'NOTHING_MISSING')}},y) else U.body:SetHeight(math.max(240,y+8)) end
        return
    end
    local nextCraft=U.NextCraft(plan)
    local nextStep=plan.steps[nextCraft or 1]
    if nextStep then
        b.next:ClearAllPoints(); b.next:SetPoint('TOPLEFT',0,-y); b.next.caption:SetText(F.L('QB_NEXT'))
        b.next.icon:SetTexture(C.Icon(nextStep.item)); b.next.title:SetText(C.ItemName(nextStep.item,nextStep.name)..' x'..nextStep.quantity)
        b.next.detail:ClearAllPoints(); b.next.detail:SetPoint('TOPLEFT',44,-(28+b.next.title:GetStringHeight()))
        b.next.detail:SetText(F.L(nextCraft and 'VIS_READY' or 'VIS_GET')); T.Color(b.next.detail,nextCraft and 'good' or 'muted')
        local height=math.max(62,b.next.title:GetStringHeight()+b.next.detail:GetStringHeight()+38)
        b.next:SetHeight(height); b.next:Show(); y=y+height+18
    elseif plan.complete then
        b.next:ClearAllPoints(); b.next:SetPoint('TOPLEFT',0,-y); b.next.caption:SetText(F.L('VIS_READY'))
        b.next.icon:SetTexture('Interface\\Buttons\\UI-CheckBox-Check'); b.next.title:SetText(F.L('ALREADY_OWNED')); b.next.detail:SetText('')
        b.next:SetHeight(64); b.next:Show(); y=y+82
    end
    local tiles={}
    for _,item in ipairs(F.Keys(materials)) do
        local id=item; local m=materials[item]; local missing=plan.missing[item] or 0
        local tone=missing>0 and 'missing' or m.stock>=m.quantity and 'good' or 'muted'
        tiles[#tiles+1]={item=item,title=C.ItemName(item),text=m.stock..' / '..m.quantity,current=m.stock,maximum=m.quantity,tone=tone,
            hint=string.format(F.L('MATERIAL_CARD'),F.Adapter.ItemCount(item),F.Bank.Count(item),m.quantity)..'\n'..
                (missing>0 and F.L('MISSING_REASON_'..plan.missingReasons[item])..'\n'..U.PriceText(item,missing) or m.stock<m.quantity and F.L('VIS_MAKE') or F.L('VIS_READY')),
            run=function()
                if #m.alternatives>0 then U.queueSourceItem=id; U.Status()
                elseif F.Auction.open then local ok,why=F.Auction.Search(id); if not ok then F.Print(why) end
                else U.FindCrafters(id,math.min(10000,math.max(1,missing))) end
            end}
    end
    U.ShowVisualTiles(tiles,y)
    if #plan.warnings>0 then U.ShowBlocks({{text=F.L('PLAN_CYCLE_WARNING')}},U.body:GetHeight()) end
end
