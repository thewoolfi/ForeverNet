local F,U=ForeverNet,ForeverNet.UI
assert(#chatMessages==1 and chatMessages[1]:find(F.version,1,true))
assert(not chatMessages[1]:find('/fn',1,true) and not F.Adapter.Demo)
F.db.settings.locale='ruRU'
local function recipe(item)
    return {name=item,output=item,quantity=1,profession='skill:165',blueprint=false,reagents={},stations={}}
end
F.localProfile.professions['skill:165']=50; F.localProfile.recipes.one=recipe('item:1')
F.db.professionScans={[F.me]={['skill:165']={seen=clock,maximum=75}}}
U.Navigate('home')
assert(U.rows[1].entry.maximum==75 and U.rows[1].fill:IsShown() and U.rows[1]:GetHeight()>=66)
assert(U.visualTiles[1].entry.title==F.L('PAGE_queue'))
U.rows[1].scripts.OnClick(U.rows[1]); assert(U.recipeFilters.profession=='skill:165')
assert(F.ToggleFavorite('recipes','item:1'))
for i=2,6 do assert(F.ToggleFavorite('market','item:'..i)) end
assert(not F.ToggleFavorite('market','item:7') and not F.ToggleFavorite('market',false))
local _,limit=F.ToggleFavorite('market','item:7'); assert(limit==F.L('MARKET_FAVORITE_LIMIT'))
U.Navigate('market')
assert(U.recipeGroups[1].id=='favorite-market' and #U.recipeGroups[1].recipes==5)
assert(U.recipeGroups[2].id=='market-items')
assert(F.IsFavorite('market',U.rows[1].entry.item) and U.rows[1].favorite:IsShown())
assert(not U.rows[1].fill:IsShown())
local selected=U.rows[1].entry.item
U.rows[1].scripts.OnClick(U.rows[1]); assert(U.selectedEntry.item==selected)
U.rows[1].favorite.scripts.OnClick(); assert(not F.IsFavorite('market',selected) and F.IsFavorite('recipes','item:1'))
assert(F.ToggleFavorite('market',selected))
U.search:SetText('item:5'); assert(#U.entries==1 and U.recipeGroups[1].id=='favorite-market')
U.search:SetText(''); U.recipeHeaders[1].scripts.OnClick(); assert(U.catalogCollapsed['favorite-market'])
U.recipeHeaders[1].scripts.OnClick(); assert(not U.catalogCollapsed['favorite-market'])
U.commands.scripts.OnClick(); assert(U.view=='commands' and U.bodyText:GetText()==F.Catalog.Safe(F.L('HELP')))
assert(not U.qty:IsShown() and not U.plan:IsShown() and not U.queueBoard)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Status()
    assert(U.commands:GetText()==F.L('COMMANDS_BUTTON') and not F.L('HELP'):lower():find('demo',1,true))
    assert(F.L('HELP'):find('netstatus',1,true) and F.L('HELP'):find('track',1,true))
end
U.Help(); assert(U.view=='help')
local before=F.Codec.Encode(F.localProfile)
F.Command('demo'); assert(U.view=='commands' and F.Codec.Encode(F.localProfile)==before)
F.db.settings.locale='ruRU'; U.Navigate('recipes'); U.Select(U.entries[1]); U.BuildSelected()
U.Commands(); local plan=U.planData; U.DataChanged(); U.Tick(1)
assert(U.view=='commands' and U.planData==plan)
