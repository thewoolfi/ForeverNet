local F,U=ForeverNet,ForeverNet.UI
local function recipe(id) return {name='Item '..id,output='item:'..id,profession='skill:171',quantity=1,blueprint=false,reagents={},stations={}} end
F.localProfile.recipes={}
for i=1,6 do
    local owner='Crafter'..i..'-Realm'; local peer=F.NewProfile(); peer.rev=10; peer.recipes.r=recipe(100+i)
    F.db.profiles[owner]=peer; F.localProfile.recipes['r'..i]=recipe(200+i)
    if i<=5 then
        assert(F.ToggleFavorite('profiles',owner)); assert(F.ToggleFavorite('recipes','item:'..(200+i)))
    end
end
assert(not F.ToggleFavorite('profiles','Crafter6-Realm'))
assert(not F.ToggleFavorite('recipes','item:206'))
U.Navigate('network'); assert(F.IsFavorite('profiles',U.entries[1].owner))
assert(U.rows[1].favorite.icon.atlas=='auctionhouse-icon-favorite')
local first=U.rows[1].entry.owner
U.rows[1].favorite.scripts.OnClick(); assert(not F.IsFavorite('profiles',first))
assert(F.ToggleFavorite('profiles',first))
U.Navigate('recipes'); assert(U.recipeGroups[1].id=='favorite-recipes' and #U.recipeGroups[1].recipes==5)
local item=U.rows[1].entry.item
U.rows[1].favorite.scripts.OnClick(); assert(not F.IsFavorite('recipes',item))
assert(F.ToggleFavorite('recipes',item))
F.db.banks={[F.me]={seen=clock,items={['item:999']=17}}}
local original=ForeverNetDB
clock=clock+86400; assert(F.Init()); F.Prune()
assert(F.db==original and #F.Keys(F.db.favorites.profiles)==5 and #F.Keys(F.db.favorites.recipes)==5)
assert(not F.db.profiles['Crafter6-Realm'] and F.db.profiles[first])
assert(F.localProfile.recipes.r6 and F.Bank.Count('item:999')==17)
U.Navigate('network'); U.Select(U.entries[1]); assert(U.summary:GetText():find(F.L('PROFILE_CACHED_AGE'):match('^(.-)%%d'),1,true))
assert(F.ToggleFavorite('profiles',first)); F.Prune(); assert(not F.db.profiles[first])
F.db.settings.sharing=true
local refreshed=F.NewProfile(); refreshed.rev=1; refreshed.recipes.r=recipe(102)
local payload=F.Codec.Encode({kind='PROFILE',data=refreshed}); local total=math.ceil(#payload/200)
for i=1,total do F.Net.Receive(F.Net.prefix,'1|22.1|'..i..'|'..total..'|'..payload:sub((i-1)*200+1,i*200),'GUILD','Crafter2-Realm') end
assert(F.db.profiles['Crafter2-Realm'].rev==1 and not F.ProfileStale(F.db.profiles['Crafter2-Realm']))
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('recipes')
    assert(U.recipeGroups[1].title==F.L('FAVORITES'))
end
