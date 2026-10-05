local F,T,Q=ForeverNet,ForeverNet.Tracker,ForeverNet.Queue
local bags={}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Material '..id end}
F.localProfile.recipes={a={name='Boots',output='item:1',quantity=1,profession='leatherworking',blueprint=false,reagents={['item:10']=12},stations={}},
    b={name='Gloves',output='item:2',quantity=1,profession='leatherworking',blueprint=false,reagents={['item:10']=8},stations={}}}
F.db.banks={[F.me]={items={['item:10']=4},seen=clock}}
bags[10]=5
Q.Add('item:1',1,F.me,'a'); Q.Add('item:2',1,F.me,'b')
local s=T.Snapshot()
assert(s.bank['item:10']==4 and s.missing['item:10']==11 and s.kind=='bank')
assert(s.plan.supplied['item:10']==9) -- Shared once across both goals.
F.Command('track'); assert(T.frame:IsShown() and Q.data.tracker and T.frame.clamped)
assert(T.snapshot.bank['item:10']==4)
F.UI.Navigate('queue'); F.UI.frame:Hide()
assert(T.frame:IsShown()) -- Independent of main window.
-- A bank withdrawal moves stock; it does not create stock or reduce the external deficit.
bags[10]=9; F.db.banks[F.me].items['item:10']=0
F.UI.DataChanged(); T.Tick(.5)
assert(not next(T.snapshot.bank) and T.snapshot.missing['item:10']==11 and T.snapshot.kind=='get')
bags[10]=20; F.UI.DataChanged(); T.Tick(.5)
assert(not next(T.snapshot.missing) and T.snapshot.kind=='craft' and T.snapshot.step.item=='item:1')
-- Actual crafting replaces inputs with output, rebuilding the remaining plan.
bags[10]=8; bags[1]=1; F.UI.DataChanged(); T.Tick(.5)
assert(T.snapshot.step.item=='item:2' and not next(T.snapshot.missing))
bags[10]=0; bags[2]=1; F.UI.DataChanged(); T.Tick(.5)
assert(T.snapshot.kind=='owned' and not T.snapshot.step and #Q.data.goals==2)
-- Bank preference must exclude all saved bank quantities when disabled.
bags[1]=0; bags[2]=0; F.db.banks[F.me].items['item:10']=20
F.db.settings.useBank=false
s=T.Snapshot(); assert(not next(s.bank) and s.missing['item:10']==20)
F.db.settings.useBank=true
T.Toggle(false); Q.Init(); assert(not Q.data.tracker)
T.Toggle(true); Q.Init(); assert(Q.data.tracker)
local saved=F.Copy(Q.data)
F.me='Other-Realm'; Q.Init(); assert(not Q.data.tracker and #Q.data.goals==0)
F.me='TrackerTest-Realm'; Q.Init(); assert(Q.data.tracker and #Q.data.goals==#saved.goals)
Q.data.goals={}; T.Render(); assert(T.snapshot.kind=='empty')
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; T.Render()
    assert(T.title:GetText()==F.L('TRACK_TITLE') and F.L('TRACK_TITLE')~='TRACK_TITLE')
    assert(F.L('TRACK_SEARCH_HINT')~='TRACK_SEARCH_HINT')
    assert(T.queue.point[3]>=T.help:GetStringHeight()+16) -- Wrapped help never covers controls.
end
F.db.settings.locale='enUS'
T.close.scripts.OnClick(); assert(not T.frame:IsShown() and not Q.data.tracker)
