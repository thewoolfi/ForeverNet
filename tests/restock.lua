local F,Q,U,T=ForeverNet,ForeverNet.Queue,ForeverNet.UI,ForeverNet.Tracker
local bags={}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Item '..id end}
local function recipe(output,inputs,quantity)
    return {name=output,output=output,quantity=quantity or 1,profession='alchemy',blueprint=false,reagents=inputs,stations={}}
end
F.localProfile.recipes={a=recipe('item:1',{['item:10']=2}),b=recipe('item:2',{['item:1']=3}),c=recipe('item:11',{['item:10']=1},3)}
bags[1]=7
assert(Q.Add('item:1',20,F.me,'a','stock'))
local plan=Q.Build()
assert(plan.goalStates[1].stock==7 and plan.steps[1].batches==13 and plan.missing['item:10']==26)
assert(Q.data.goals[1].quantity==20 and Q.data.goals[1].mode=='stock')
F.db.banks={[F.me]={items={['item:1']=5},seen=clock-3600}}
plan=Q.Build()
assert(plan.goalStates[1].stock==12 and plan.goalStates[1].bankStock==5 and plan.steps[1].batches==8)
assert(plan.missing['item:10']==16 and plan.retainedBank['item:1']==5)
local snap=T.Snapshot()
assert(not snap.bank['item:1'] and snap.missing['item:10']==16)
-- Bank reagents for actual crafts are still withdrawal requirements.
F.db.banks[F.me].items['item:10']=16
snap=T.Snapshot(); assert(snap.bank['item:10']==16 and not snap.bank['item:1'])
F.db.settings.useBank=false
plan=Q.Build(); assert(plan.goalStates[1].stock==7 and plan.goalStates[1].bankStock==0 and plan.missing['item:10']==26)
assert(not next(plan.retainedBank) and not next(T.Snapshot().bank))
F.db.settings.useBank=true; F.db.banks={}
-- Fulfilled rules remain, then become actionable again on a real bag update.
bags[1]=20; bags[10]=100
assert(T.Snapshot().kind=='maintained' and #Q.Build().steps==0 and Q.RemoveOwned()==0)
T.Toggle(true)
bags[1]=17
frames[1].scripts.OnEvent(frames[1],'BAG_UPDATE_DELAYED'); T.Tick(.5)
assert(T.snapshot.kind=='craft' and T.snapshot.step.batches==3 and Q.data.goals[1].quantity==20)
bags[1]=20
frames[1].scripts.OnEvent(frames[1],'BAG_UPDATE_DELAYED'); T.Tick(.5)
assert(T.snapshot.kind=='maintained' and #Q.data.goals==1)
-- One target per item; a one-time goal for that item can coexist and uses separate stock.
assert(not Q.Add('item:1',10,F.me,'a','stock'))
assert(Q.Add('item:1',5,F.me,'a'))
assert(not Q.Mode(2,'stock') and Q.data.goals[2].mode==nil)
plan=Q.Build(); assert(plan.goalStates[1].stock==20 and plan.goalStates[2].stock==0 and plan.steps[1].batches==5)
assert(Q.RemoveOwned()==0) -- Mixed repeated item group is not fully covered.
bags[1]=25; assert(Q.RemoveOwned()==1 and #Q.data.goals==1 and Q.data.goals[1].mode=='stock')
assert(Q.Undo() and #Q.data.goals==2)
Q.Remove(2); assert(Q.Mode(1,nil) and Q.data.goals[1].mode==nil)
assert(Q.RemoveOwned()==1 and #Q.data.goals==0 and Q.Undo())
assert(Q.Mode(1,'stock') and not Q.undo)
-- Bank-retained final stock is distinct from bank reagents for another goal, in either order.
Q.data.goals={}; bags[1]=0; bags[10]=0
F.db.banks={[F.me]={items={['item:1']=8},seen=clock}}
Q.Add('item:1',5,F.me,'a','stock'); Q.Add('item:2',1,F.me,'b')
snap=T.Snapshot()
assert(snap.plan.retainedBank['item:1']==5 and snap.bank['item:1']==3 and snap.kind=='bank')
assert(snap.plan.supplied['item:1']==8 and snap.plan.bagSupplied['item:1']==0)
Q.MoveUp(2); snap=T.Snapshot(); assert(snap.bank['item:1']==3 and snap.plan.retainedBank['item:1']==5)
-- If bank can hold the entire target, avoid an unnecessary withdrawal for crafting with carried copies.
bags[1]=3; F.db.banks[F.me].items['item:1']=5
Q.MoveUp(2); snap=T.Snapshot()
assert(not next(snap.bank) and snap.kind=='craft' and snap.plan.goalStates[1].bankStock==5)
assert(snap.plan.bagSupplied['item:1']==3 and snap.plan.supplied['item:1']==8)
Q.MoveUp(2); snap=T.Snapshot(); assert(not next(snap.bank) and snap.kind=='craft')
-- Planned batches can supply future targets, but are not current stock or proof of fulfillment.
Q.data.goals={}; F.db.banks={}; bags[1]=0; bags[10]=1
Q.Add('item:11',1,F.me,'c'); Q.Add('item:11',2,F.me,'c','stock')
plan=Q.Build()
assert(#plan.steps==1 and plan.steps[1].quantity==3 and plan.goalStates[2].stock==0 and plan.goalStates[2].ready)
assert(T.Snapshot().kind=='craft' and Q.RemoveOwned()==0)
-- Root pins and source choices persist; missing providers do not silently switch.
Q.data.goals={}; Q.data.sources={}; bags[10]=0
Q.Add('item:1',20,F.me,'a','stock'); Q.SetSource('item:10','external')
assert(Q.SaveSet('Supplies'))
assert(Q.Mode(1,nil)); Q.Quantity(1,1)
assert(Q.LoadSet('Supplies',false) and Q.data.goals[1].mode=='stock' and Q.data.goals[1].quantity==20)
local count,choice=#Q.data.goals,Q.data.sources['item:10']
assert(not Q.LoadSet('Supplies',true) and #Q.data.goals==count and Q.data.sources['item:10']==choice)
assert(Q.Undo() and Q.data.goals[1].mode==nil and Q.data.goals[1].quantity==1)
Q.LoadSet('Supplies',false)
local calls={}
C_Item.GetItemCount=function(id) calls[id]=(calls[id] or 0)+1; return bags[id] or 0 end
Q.Build()
for _,count in pairs(calls) do assert(count==1) end -- One consistent bag survey for shared recipe items.
Q.data.goals[1].recipeID='vanished'; assert(Q.Build().missingReasons['item:1']=='unknown')
Q.data.goals[1].recipeID='a'
-- Saved data validation and character isolation.
Q.data.goals[2]={item='item:2',quantity=1,mode='invalid'}
Q.data.goals[3]={item='item:1',quantity=30,mode='stock'}
Q.data.sets.Bad={goals={{item='item:1',quantity=2,mode='stock'},{item='item:1',quantity=3,mode='stock'}}}
Q.Init(); assert(#Q.data.goals==1 and Q.data.goals[1].quantity==20 and Q.data.goals[1].mode=='stock' and not Q.data.sets.Bad)
local me=F.me; F.me='Other-Realm'; Q.Init(); assert(#Q.data.goals==0)
F.me=me; Q.Init(); assert(Q.data.goals[1].mode=='stock' and Q.data.sets.Supplies.goals[1].mode=='stock')
local rev=F.localProfile.rev
-- Actual goal buttons, source-card reuse, mode labels and previews on all supported languages.
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('queue')
    U.Select(U.entries[1]); assert(U.qtyLabel:GetText()==F.L('RESTOCK_TARGET'))
    if locale=='enUS' then
        U.qty:SetText('21'); U.enqueue.scripts.OnClick(U.enqueue)
        assert(Q.data.goals[1].quantity==21 and Q.data.goals[1].mode=='stock')
        Q.Quantity(1,20); U.Status(); U.Select(U.entries[1])
    end
    local row
    for _,candidate in ipairs(U.sourceRows) do
        if candidate:IsShown() and candidate.entry.extraAction then row=candidate; break end
    end
    assert(row and row.extraButton:IsShown() and row.extraButton:GetText()==F.L('RESTOCK_ONCE'))
    assert(row:GetHeight()>=-row.extraButton.point[3]+24)
    row.extraButton.scripts.OnClick(row.extraButton)
    assert(Q.data.goals[1].mode==nil and U.qtyLabel:GetText()==F.L('QUANTITY_FIELD'))
    for _,candidate in ipairs(U.sourceRows) do
        if candidate:IsShown() and candidate.entry.extraAction then row=candidate; break end
    end
    assert(row.extraButton:GetText()==F.L('RESTOCK_ENABLE'))
    row.extraButton.scripts.OnClick(row.extraButton); assert(Q.data.goals[1].mode=='stock')
    U.QueueSetDialog('load','Supplies'); assert(U.setDialog.preview:GetText():find(F.L('RESTOCK_MODE'),1,true))
    U.setDialog.second.scripts.OnClick(U.setDialog.second)
    assert(U.setDialog:IsShown() and U.setDialog.error:GetText()==F.L('RESTOCK_DUPLICATE'))
    assert(U.setDialog.error.point[1]=='BOTTOMLEFT' and U.setDialog.error.point[3]==68)
    assert(U.setDialog.error:GetHeight()+84<440) -- Wrapped errors shrink the preview, not overlap action buttons.
    U.setDialog.first.scripts.OnClick(U.setDialog.first)
    T.Toggle(true); T.Render()
    assert(T.rows[2].text:GetText():find(F.L('RESTOCK_MODE'),1,true))
    for _,key in ipairs({'RESTOCK_MODE','RESTOCK_ENABLE','RESTOCK_ONCE','RESTOCK_TARGET','RESTOCK_DUPLICATE','RESTOCK_HELP','RESTOCK_PROGRESS','RESTOCK_READY'}) do
        assert(F.L(key)~=key and type(F.Locales[locale][key])=='string')
    end
    U.Navigate('recipes')
    for _,candidate in ipairs(U.sourceRows) do
        if candidate:IsShown() and not candidate.entry.extraAction then assert(not candidate.extraButton:IsShown() and not candidate.extraButton.action) end
    end
end
F.db.settings.locale='enUS'
assert(F.localProfile.rev==rev)
Q.data.tracker=true
