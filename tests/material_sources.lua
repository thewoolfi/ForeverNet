local F,U=ForeverNet,ForeverNet.UI
local function recipe(name,output,reagents,quantity,stations)
    return {name=name,output=output,reagents=reagents,quantity=quantity or 1,
        profession='skill:165',blueprint=false,stations=stations or {}}
end
-- Actual conversion quantities from this client's scanned leatherworking recipes.
local own=F.NewProfile()
own.recipes.boots=recipe('Murloc Scale Boots','item:252426',{['item:2318']=12,['item:4231']=2,['item:5784']=4})
own.recipes.leather=recipe('Light Leather','item:2318',{['item:2934']=3})
own.recipes.hide=recipe('Cured Light Hide','item:4231',{['item:783']=1,['item:4289']=1})
local profiles={[F.me]=own}
local stock={['item:2318']=2,['item:2934']=30,['item:4231']=2,['item:5784']=4}
local opts={localOwner=F.me,owner=F.me,recipeID='boots'}
local auto=F.Planner.Build(profiles,'item:252426',1,stock,nil,opts)
assert(auto.complete and #auto.steps==2 and auto.steps[1].batches==10)
assert(auto.materials['item:2318'].quantity==12 and auto.materials['item:2318'].stock==2)
assert(auto.materials['item:2318'].shortage==10 and auto.supplied['item:2934']==30)
opts.sources={['item:2318']='external'}
local separate=F.Planner.Build(profiles,'item:252426',1,stock,nil,opts)
assert(not separate.complete and separate.missing['item:2318']==10)
assert(separate.missingReasons['item:2318']=='external' and #separate.steps==1)
assert(not separate.materials['item:2934'] and not separate.supplied['item:2934'])
assert(separate.inventory['item:2934']==30 and stock['item:2318']==2)
opts.sources['item:2318']='changed'
assert(separate.sources['item:2318']=='external') -- choice snapshot is independent
-- A second recipe yielding three units per craft; no silent recipe substitution.
local other=F.NewProfile()
other.recipes.alt=recipe('Alternative Leather','item:2318',{['item:900']=2},3)
profiles['Other-Realm']=other
opts.sources={['item:2318']={owner='Other-Realm',recipeID='alt'}}
stock['item:900']=8
local alternate=F.Planner.Build(profiles,'item:252426',1,stock,nil,opts)
assert(alternate.complete and alternate.steps[1].owner=='Other-Realm')
assert(alternate.steps[1].batches==4 and alternate.steps[1].quantity==12)
assert(alternate.inventory['item:2318']==2 and alternate.inventory['item:2934']==30)
other.recipes.alt=nil
local gone=F.Planner.Build(profiles,'item:252426',1,stock,nil,opts)
assert(gone.missing['item:2318']==10 and gone.missingReasons['item:2318']=='source')
other.recipes.alt=recipe('Alternative Leather','item:2318',{['item:900']=2},3,{workshop=true})
local blocked=F.Planner.Build(profiles,'item:252426',1,stock,nil,opts)
assert(blocked.missingReasons['item:2318']=='camp' and #blocked.steps==1)
local sources=F.Planner.Sources(profiles,'item:2318',nil,F.me)
assert(#sources==2 and sources[1].owner==F.me and not sources[2].ready)
other.camps.workshop=clock
assert(F.Planner.Build(profiles,'item:252426',1,stock,nil,opts).complete)
-- Shared dependencies retain batch surplus; external choices count exact deficits.
local shared=F.NewProfile()
shared.recipes.root=recipe('Root','root',{b=1,c=1})
shared.recipes.b=recipe('B','b',{ore=1},2)
shared.recipes.c=recipe('C','c',{b=1})
local sharedPlan=F.Planner.Build({X=shared},'root',1,{ore=1})
assert(sharedPlan.complete and #sharedPlan.steps==3 and sharedPlan.materials.b.quantity==2)
local external=F.Planner.Build({X=shared},'root',1,{b=1},nil,{sources={b='external'}})
assert(external.missing.b==1 and external.supplied.b==1 and not external.missing.ore)
shared.recipes.b=recipe('B','b',{root=1})
local cycle=F.Planner.Build({X=shared},'root',1,{})
assert(not cycle.complete and #cycle.warnings>0)
local stop=F.Planner.Build({X=shared},'root',1,{},nil,{sources={b='external'}})
assert(#stop.warnings==0 and stop.missing.b==2 and stop.missingReasons.b=='external')
-- The main UI tells the user what to obtain and what to craft, with direct switches.
F.db.profiles={[F.me]=own,['Other-Realm']=other}; F.localProfile=own
F.Adapter.ItemCount=function(item) return stock[item] or 0 end
F.Adapter.StockCount=function(item) return stock[item] or 0 end
local function rowFor(key)
    for _,row in ipairs(U.sourceRows or {}) do if row:IsShown() and row.entry.key==key then return row end end
end
local function recipeRow(owner)
    for _,row in ipairs(U.sourceRows) do
        if row:IsShown() and row.entry.item=='item:2318' and row.detail:GetText():find(F.L('CRAFTER')..owner,1,true)
            and row.buttons[1]:IsShown() and row.buttons[1]:GetText()==F.L('CHAIN_USE_RECIPE') then return row end
    end
end
local function click(row,index)
    assert(row); if not row.buttons[index or 1]:IsShown() and row.more:IsShown() then row.more.scripts.OnClick(row.more) end
    assert(row.buttons[index or 1]:IsShown())
    local b=row.buttons[index or 1]; assert(b.enabled~=false); b.scripts.OnClick(b)
end
U.Navigate('recipes'); U.SetTarget('item:252426',1,F.me,'boots'); U.BuildSelected()
assert(U.planData.target=='item:252426')
assert(U.chainRows[1].title==F.L('VIS_MAKE'))
local leather=rowFor('make/1')
assert(leather.ingredients[1].count:GetText()=='30')
assert(not leather.buttons[1]:IsShown()); leather.more.scripts.OnClick(leather.more)
assert(leather.buttons[1]:GetText()==string.format(F.L('CHAIN_GET_BUTTON'),10))
assert(rowFor('make/2').ingredients[1].count:GetText()=='12')
assert(U.planData.steps[1].reagents['item:2934']==30)
assert(U.plan:GetText()==F.L('CHAIN_REFRESH'))
-- One click replaces the leather craft with ten ready-made units to obtain.
click(leather)
assert(U.view==nil and U.planData.target=='item:252426' and U.target.item=='item:252426')
assert(U.planData.missing['item:2318']==10 and not U.planData.missing['item:2934'])
local get=rowFor('get/item:2318')
assert(get and get.entry.hint:find('item:2934 x30',1,true))
assert(get.entry.actions[1].text==string.format(F.L('CHAIN_MAKE_BUTTON'),10))
assert(#U.planData.steps==1 and rowFor('make/1').entry.item=='item:252426')
-- Crafting instead is another direct click; no separate screen or automatic mode.
click(get)
assert(U.planData.complete and #U.planData.steps==2)
assert(not rowFor('get/item:2318') and rowFor('make/1').entry.item=='item:2318')
assert(U.view==nil)
-- Other recipes unfold in the same chain and preview total, rather than per-craft, costs.
click(rowFor('make/1'),2)
assert(U.expandedSource=='item:2318' and U.view==nil)
local variant=recipeRow('Other-Realm')
assert(variant and variant.detail:GetText():find('item:900 x8',1,true))
assert(variant.detail:GetText():find(string.format(F.L('CHAIN_SURPLUS'),2),1,true))
click(variant)
assert(U.planData.sources['item:2318'].owner=='Other-Realm' and U.planData.complete)
assert(U.planData.target=='item:252426' and U.expandedSource==nil)
-- Unavailable station-dependent recipes remain visible and disabled.
other.camps.workshop=clock+3600
U.BuildSelected()
assert(U.planData.missingReasons['item:2318']=='camp')
U.OpenSources('item:2318')
local unavailable
for _,row in ipairs(U.sourceRows) do
    if row:IsShown() and row.entry.item=='item:2318' and row.detail:GetText():find(F.L('CRAFTER')..'Other-Realm',1,true) then unavailable=row end
end
assert(unavailable and unavailable.buttons[1].enabled==false)
other.camps.workshop=clock; U.expandedSource=nil; U.BuildSelected()
-- Selecting a missing component for a help request leaves the full chain visible.
click(rowFor('make/1'))
local entry
for _,e in ipairs(U.entries) do if e.kind=='missing' and e.item=='item:2318' then entry=e end end
assert(entry); U.Select(entry)
assert(U.target.item=='item:2318' and U.chainRows[1].title==F.L('VIS_GET'))
U.BuildSelected()
assert(U.target.item=='item:252426' and U.planData.target=='item:252426')
-- Adjusting the final target quantity retains the chosen path.
U.qty:SetText('2'); U.BuildSelected()
assert(U.planData.quantity==2 and U.planData.sources['item:2318']=='external')
assert(U.planData.missing['item:2318']==22)
assert(rowFor('get/item:2318').entry.hint:find('item:2934 x66',1,true))
U.ChooseSource('item:2318',nil)
assert(U.planData.quantity==2 and not U.planData.sources['item:2318'])
assert(U.planData.missing['item:2934']==36)
-- Stock is disclosed on demand; visiting other pages hides plan-specific widgets.
local stockRow
for _,row in ipairs(U.sourceRows) do if row:IsShown() and row.entry.title==F.L('VIS_DETAILS') then stockRow=row end end
assert(stockRow and not U.planDetails); click(stockRow); assert(U.planDetails)
U.Help(); for _,row in ipairs(U.sourceRows) do assert(not row:IsShown()) end
U.Navigate('recipes'); U.SetTarget('item:4231',1,F.me,'hide'); U.BuildSelected()
assert(next(U.planData.sources)==nil and not U.showPlanStock)
-- Translations, wrapped headings and controls fit without covering text.
for locale in pairs(F.Locales) do
    F.db.settings.locale=locale
    assert(F.L('CHAIN_GET')~='CHAIN_GET')
    assert(string.format(F.L('CHAIN_GET_BUTTON'),12):find('12'))
    U.Navigate('recipes'); U.SetTarget('item:252426',1,F.me,'boots'); U.BuildSelected(); U.OpenSources('item:2318')
    for _,row in ipairs(U.sourceRows) do
        if row:IsShown() then
            local titleBottom=10+row.title:GetStringHeight()
            local textBottom=row.detail:IsShown() and -row.detail.point[3]+row.detail:GetStringHeight() or titleBottom
            for _,b in ipairs(row.buttons) do if b:IsShown() then
                assert(-b.point[3]>=textBottom or b.point[2]>=row.title.point[2]+row.title:GetWidth()+12)
                assert(row:GetHeight()>=-b.point[3]+b:GetHeight())
            end end
        end
    end
end
