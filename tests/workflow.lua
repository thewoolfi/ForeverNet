local F,U=ForeverNet,ForeverNet.UI
F.db.settings.locale='ruRU'
F.db.settings.sharing=true
local function recipe(name,cost)
 return {name=name,output='item:100',quantity=1,profession='skill:165',blueprint=false,reagents={['item:200']=cost},stations={}}
end
F.localProfile.recipes.mine=recipe('Кожаная сумка',2)
local remote=F.NewProfile(); remote.recipes.theirs=recipe('Кожаная сумка',3)
F.db.profiles['Other-Realm']=remote
function GetItemCount(id) return id==200 and 1 or 0 end
U.Navigate('recipes'); U.search:SetText('КОЖАНАЯ')
assert(#U.entries==2 and U.entries[1].owner==F.me, tostring(#U.entries)..' / '..F.Catalog.Fold('КОЖАНАЯ')..' / '..F.Catalog.Fold('Кожаная сумка'))
U.Select(U.entries[2]); U.qty:SetText('2'); U.BuildSelected()
assert(U.planData.steps[1].owner=='Other-Realm')
assert(U.planData.missing['item:200']==5 and U.planData.supplied['item:200']==1)
U.qty:SetText('3'); U.BuildSelected()
assert(U.planData.steps[1].owner=='Other-Realm' and U.planData.missing['item:200']==8)
assert(U.entries[1].kind=='missing'); U.Select(U.entries[1]); U.RequestSelected()
local r=F.db.requests[U.selectionKey]
assert(r.item=='item:200' and r.quantity==8 and U.page=='requests')
F.Requests.Receive('OFFER',{id=r.id},'Helper-Realm','GUILD'); U.Tick(1)
assert(U.selectedEntry.request.status=='accepted' and U.done:IsShown())
U.frame:Hide(); F.UI.DataChanged(); U.Tick(1); assert(not U.frame:IsShown())
local count=#F.Keys(F.db.requests)
F.Command('demo'); assert(U.planData.demo and not U.request:IsEnabled())
U.RequestSelected(); assert(#F.Keys(F.db.requests)==count)
U.Navigate('recipes'); U.Select(U.entries[1]); U.qty:SetText('0'); assert(not U.plan:IsEnabled())
-- Every literal UI locale key must be translated in both bundled languages.
assert(F.L('MINIMAP_HINT')~='MINIMAP_HINT')
Minimap=CreateFrame('Frame'); Minimap:SetSize(140,140)
F.Minimap.Init(); local b=F.Minimap.button; assert(b and b.point[2]==Minimap)
U.frame:Hide(); b.scripts.OnClick(b,'LeftButton'); assert(U.frame:IsShown())
b.scripts.OnClick(b,'LeftButton'); assert(not U.frame:IsShown())
b.scripts.OnClick(b,'RightButton'); assert(U.view=='help' and U.frame:IsShown())
b.scripts.OnDragStart(b); b.scripts.OnUpdate(b)
assert(F.db.settings.minimapAngle==0)
b.scripts.OnDragStop(b); assert(b.scripts.OnUpdate==nil)
b.scripts.OnClick(b,'LeftButton'); assert(U.frame:IsShown())
clock=clock+1; b.scripts.OnClick(b,'LeftButton'); assert(not U.frame:IsShown())
local position=b.point[4]; F.Minimap.Position(); assert(b.point[4]==position)

