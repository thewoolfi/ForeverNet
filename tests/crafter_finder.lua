local F,P,U,C=ForeverNet,ForeverNet.ProfessionActions,ForeverNet.UI,ForeverNet.Catalog
local infos={[101]={recipeID=101,name='Native potion',learned=true},[102]={recipeID=102,name='Unknown potion',learned=false},
    [103]={recipeID=103,name='Variable potion',learned=true},[104]={recipeID=104,name='No item',learned=false}}
local selected,linked=101,false
local schemas={[101]={outputItemID=1,quantityMin=1,reagentSlotSchematics={{required=true,quantityRequired=2,reagents={{itemID=10}}}}},
    [102]={outputItemID=2,quantityMin=1,reagentSlotSchematics={}},
    [103]={outputItemID=3,quantityMin=1,quantityMax=3,reagentSlotSchematics={}},[104]={quantityMin=1,reagentSlotSchematics={}}}
C_TradeSkillUI={GetBaseProfessionInfo=function() return {professionID=171,skillLevel=7,maxSkillLevel=75} end,
    GetProfessionInfoByRecipeID=function() return {professionID=171} end,
    GetRecipeInfo=function(id) return infos[id] end,GetRecipeSchematic=function(id,recraft) assert(recraft==false); return schemas[id] end,
    GetTradeSkillDisplayName=function(id) return id==171 and 'Alchemy' or id==197 and 'Tailoring' or 'Cooking' end,
    IsTradeSkillLinked=function() return linked end,
    GetFilteredRecipeIDs=function() error('Do not enumerate native filters') end,
    SetRecipeItemNameFilter=function() error('Do not alter native filters') end,
    CraftRecipe=function() error('Do not craft') end}
C_Item={GetItemCount=function(id) return id==10 and 1 or 0 end,GetItemInfo=function(id) return 'Item '..id end}
local sent=0
C_ChatInfo.SendAddonMessage=function() sent=sent+1; error('Lookup must not send messages') end
ProfessionsFrame=CreateFrame('Frame')
local page=CreateFrame('Frame',nil,ProfessionsFrame); ProfessionsFrame.CraftingPage=page; page:SetSize(680,600)
page.SchematicForm={GetRecipeInfo=function() return infos[selected] end}
function page:SelectRecipe(info) selected=info.recipeID end
function hooksecurefunc(object,key,callback)
    local prior=object[key]; object[key]=function(...) local result=prior(...); callback(...); return result end
end
local function recipe(item,profession,quantity,station)
    return {name='Different localized name',output='item:'..item,profession=profession,quantity=quantity or 1,
        blueprint=false,reagents={['item:10']=3},stations=station and {[station]=true} or {}}
end
local function peer(name,item,seen)
    local p=F.NewProfile(); p.seen=seen or clock
    p.professions['skill:171']=150; p.recipes.one=recipe(item,'skill:171',2)
    F.db.profiles[name]=p; return p
end
local alice=peer('Alice-Realm',1,clock-60)
alice.recipes.two=recipe(1,'skill:197',1,'workshop')
local bob=peer('Bob-Realm',1,clock-120)
local zed=peer('Zed-Realm',1,clock-F.PEER_TTL-1)
F.db.favorites.profiles['Zed-Realm']=true
peer('Dust-Realm',1,clock-F.PEER_TTL-1)
local eve=peer('Eve-Realm',2)
eve.recipes.one.name=infos[101].name -- Same localized name, different base item: must not match.
peer('Carol-Realm',3)
F.localProfile.professions['skill:171']=7
F.localProfile.recipes.own=recipe(1,'skill:171')
F.db.banks={[F.me]={items={['item:10']=2},seen=clock}}
F.Queue.Add('item:90',10)
local ownBefore=F.Codec.Encode(F.localProfile)
local bankBefore=F.Codec.Encode(F.db.banks)
assert(P.Attach() and P.find:IsEnabled())
P.qty:SetText('5'); P.find.scripts.OnClick(P.find)
assert(U.page=='crafters' and U.finder.item=='item:1' and U.Quantity()==5 and #U.entries==3)
assert(U.entries[1].owner=='Zed-Realm' and not F.db.profiles['Dust-Realm'])
assert(F.Codec.Encode(F.localProfile)==ownBefore and #F.Queue.data.goals==1 and F.Queue.data.goals[1].quantity==10)
assert(F.Codec.Encode(F.db.banks)==bankBefore and sent==0)
assert(not U.plan:IsEnabled() and not U.request:IsEnabled() and U.navigation.network.checked)
local function entry(owner)
    for _,e in ipairs(U.entries) do if e.owner==owner then return e end end
end
assert(entry('Alice-Realm') and #entry('Alice-Realm').recipes==2 and not entry(F.me) and not entry('Eve-Realm'))
U.search:SetText('aLcHeMy'); assert(#U.entries==3)
U.search:SetText('TAILORING'); assert(#U.entries==1 and U.entries[1].owner=='Alice-Realm')
U.search:SetText(''); U.rows[2].scripts.OnClick(U.rows[2])
assert(U.selectedEntry.owner=='Alice-Realm')
local planAction
for _,e in ipairs(U.chainRows) do
    if e.title==infos[101].name then error('Do not match by the native recipe name') end
    if e.actions and e.actions[1].text==F.L('FINDER_PLAN') then planAction=e.actions[1].run; break end
end
assert(planAction); planAction()
assert(U.page=='chain' and U.planData.owner=='Alice-Realm' and U.planData.recipeID=='one' and U.planData.quantity==5)
assert(U.planData.steps[#U.planData.steps].owner=='Alice-Realm' and U.planData.steps[#U.planData.steps].quantity==6)
assert(U.planData.missing['item:10']==6 and #F.Queue.data.goals==1)
U.FindCrafters('item:1',5)
assert(U.PreviewCrafter('Alice-Realm','two',false))
assert(U.planData.owner=='Alice-Realm' and U.planData.recipeID=='two' and U.planData.missingReasons['item:1']=='camp')
U.FindCrafters('item:1',5)
assert(U.PreviewCrafter('Alice-Realm','one',true) and U.page=='recipes')
assert(U.target.owner=='Alice-Realm' and U.target.recipeID=='one' and U.Quantity()==5)
-- Favorite toggles apply to profiles, not recipe favorites or the local player.
U.FindCrafters('item:1',5)
local bobRow
for _,row in ipairs(U.rows) do if row:IsShown() and row.entry.owner=='Bob-Realm' then bobRow=row end end
assert(bobRow and bobRow.favorite:IsShown()); bobRow.favorite.scripts.OnClick(bobRow.favorite)
assert(F.IsFavorite('profiles','Bob-Realm') and not F.IsFavorite('recipes','item:1'))
assert(U.entries[1].owner=='Bob-Realm') -- Fresh favorite before stale favorite.
-- Click-time revalidation: no replacement crafter, phantom item, or automatic queue mutation.
alice.recipes.one.output='item:999'
local previousPlan=U.planData
assert(not U.PreviewCrafter('Alice-Realm','one',false) and U.planData==previousPlan and U.page=='crafters')
alice.recipes.one.output='item:1'
local savedAlice=alice
F.db.profiles['Alice-Realm']=nil
assert(not U.PreviewCrafter('Alice-Realm','one',false) and not U.OpenFinderProfile('Alice-Realm'))
F.db.profiles['Alice-Realm']=savedAlice
assert(not U.PreviewCrafter(F.me,'own',false))
U.qty:SetText('0'); assert(not U.PreviewCrafter('Alice-Realm','one',false))
-- Unlearned and variable-output native lookups remain read-only; they do not pretend to scan unsupported recipes.
page:SelectRecipe(infos[102]); assert(P.Action('find'))
assert(U.finder.item=='item:2' and U.Quantity()==1 and #U.entries==1 and U.entries[1].owner=='Eve-Realm')
assert(not P.add:IsEnabled() and not P.materials:IsEnabled() and P.find:IsEnabled())
assert(P.status:GetText()==F.L('FINDER_LOOKUP_ONLY') and not F.localProfile.recipes['spell:102'])
page:SelectRecipe(infos[103]); P.Refresh(); assert(P.find:IsEnabled() and not P.add:IsEnabled() and P.Action('find'))
assert(U.finder.item=='item:3' and U.entries[1].owner=='Carol-Realm')
page:SelectRecipe(infos[104]); P.Refresh(); assert(not P.find:IsEnabled() and not P.Action('find'))
assert(not F.Adapter.RecipeOutput(0))
page:SelectRecipe(infos[101]); linked=true; P.Refresh(); assert(not P.find:IsEnabled() and not P.Action('find'))
linked=false
for _,flag in ipairs({'IsTradeSkillGuild','IsTradeSkillGuildMember','IsNPCCrafting'}) do
    C_TradeSkillUI[flag]=function() return true end
    assert(not F.Adapter.RecipeOutput(101)); C_TradeSkillUI[flag]=nil
end
Professions={InLocalCraftingMode=function() return false end}; assert(not F.Adapter.RecipeOutput(101)); Professions=nil
local belongs=C_TradeSkillUI.GetProfessionInfoByRecipeID
C_TradeSkillUI.GetProfessionInfoByRecipeID=function() return {professionID=197} end
assert(not F.Adapter.RecipeOutput(101)); C_TradeSkillUI.GetProfessionInfoByRecipeID=belongs
local getter=C_TradeSkillUI.GetRecipeSchematic
C_TradeSkillUI.GetRecipeSchematic=function() error('Loading') end
assert(not F.Adapter.RecipeOutput(101)); C_TradeSkillUI.GetRecipeSchematic=getter
schemas[101].recipeID=102; assert(not F.Adapter.RecipeOutput(101)); schemas[101].recipeID=nil
schemas[101].isRecraft=true; assert(not F.Adapter.RecipeOutput(101)); schemas[101].isRecraft=nil
infos[101].isRecraft=true; assert(not F.Adapter.RecipeOutput(101)); infos[101].isRecraft=nil
page:Hide(); assert(not P.Action('find')); page:Show()
assert(F.Codec.Encode(F.localProfile)==ownBefore and F.Codec.Encode(F.db.banks)==bankBefore and sent==0)
local goals=F.Copy(F.Queue.data.goals)
for i=2,F.Queue.MAX_GOALS do F.Queue.Add('item:90',1) end
P.Refresh(); assert(not P.add:IsEnabled() and P.find:IsEnabled() and P.Action('find'))
assert(#F.Queue.data.goals==F.Queue.MAX_GOALS)
F.Queue.data.goals=goals
for i=1,22 do peer('Extra'..i..'-Realm',1) end
U.FindCrafters('item:1',1)
assert(#U.entries==25 and U.chainRows[#U.chainRows].text==string.format(F.L('FINDER_PLAYER_LIMIT'),20))
U.Select(entry('Extra9-Realm')); assert(U.selectedEntry.owner=='Extra9-Realm')
for i=1,22 do F.db.profiles['Extra'..i..'-Realm']=nil end
-- Metadata, recipe bound, full profile, unknown age, empty results and all translated controls.
for i=1,25 do alice.recipes['variant'..i]=recipe(1,'skill:171') end
zed.seen=nil
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; page:SetWidth(350); P.Refresh()
    assert(P.find:GetText()==F.L('FINDER_BUTTON') and -P.find.point[3]+24<=-P.help.point[3])
    U.FindCrafters('item:1',5); U.Select(entry('Alice-Realm'))
    local cards,limited,unknownSkill=0,false,false
    for _,e in ipairs(U.chainRows) do
        if e.actions and e.actions[1].text==F.L('FINDER_PLAN') then cards=cards+1 end
        if e.text==string.format(F.L('FINDER_VARIANT_LIMIT'),20) then limited=true end
        if e.title:find(F.L('FINDER_SKILL_UNKNOWN'),1,true) then unknownSkill=true end
    end
    assert(cards==20 and limited)
    -- Missing rank is visible when the tailoring variant is inside the first page.
    assert(unknownSkill)
    U.Select(entry('Zed-Realm'))
    assert(U.chainRows[2].text==F.L('FINDER_AGE_UNKNOWN'))
    U.OpenFinderProfile('Zed-Realm'); assert(U.summary:GetText()==F.L('FINDER_AGE_UNKNOWN'))
    U.OpenFinderProfile('Alice-Realm'); assert(U.page=='network' and U.selectedEntry.owner=='Alice-Realm')
    local shown=0; for _,card in ipairs(U.profileCards) do if card:IsShown() then shown=shown+1 end end
    assert(shown==27)
    U.FindCrafters('item:9999',1)
    assert(#U.entries==0 and U.chainRows[2].text==F.L('EMPTY_crafters'))
    U.crafter.scripts.OnClick(U.crafter); assert(U.page=='network')
    for _,key in ipairs({'FINDER_BUTTON','PAGE_crafters','EMPTY_crafters','FINDER_NO_OUTPUT','FINDER_LOOKUP_ONLY','FINDER_HELP',
        'FINDER_COUNT','FINDER_PICK','FINDER_NETWORK','FINDER_PROFILE','FINDER_PLAN','FINDER_RECIPE','FINDER_RECIPES',
        'FINDER_AGE_UNKNOWN','FINDER_SKILL_UNKNOWN','FINDER_CHANGED','FINDER_VARIANT_LIMIT','FINDER_PLAYER_LIMIT'}) do
        assert(F.L(key)~=key and type(F.Locales[locale][key])=='string')
    end
end
F.db.settings.locale='enUS'
assert(F.Codec.Encode(F.localProfile)==ownBefore and F.Codec.Encode(F.db.banks)==bankBefore and sent==0 and #F.Queue.data.goals==1)
