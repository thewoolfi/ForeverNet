local F,U,C=ForeverNet,ForeverNet.UI,ForeverNet.Catalog
F.db.settings.locale='ruRU'
C_TradeSkillUI={GetTradeSkillDisplayName=function(id)
    return ({[171]='Алхимия',[185]='Кулинария',[186]='Горное дело'})[id]
end}
local function recipe(name,item,profession,blueprint)
    return {name=name,output=item,quantity=2,profession=profession,blueprint=not not blueprint,
        reagents={['item:999']=3},stations={}}
end
local peer=F.NewProfile()
peer.professions={['skill:171']=150,['skill:186']=75}
peer.recipes={
    potion=recipe('Длинное название зелья, которое должно переноситься на несколько строк','item:101','skill:171',true),
    elixir=recipe('Эликсир','item:102','skill:171'),
    food=recipe('Жареная кабанина','item:103','skill:185')}
peer.camps.workshop=clock+60
F.db.profiles['Crafter-Realm']=peer
F.localProfile.recipes.mine=recipe('Эликсир','item:102','skill:171')
local groups=C.ProfileProfessions(peer)
assert(#groups==3 and groups[1].id=='skill:171' and #groups[1].recipes==2)
assert(groups[2].id=='skill:186' and #groups[2].recipes==0)
assert(groups[3].id=='skill:185' and groups[3].rank==nil) -- Recipe-only profession is retained.
assert(C.ProfessionIcon('skill:171'):find('Trade_Alchemy',1,true))
assert(C.ProfessionIcon('unknown'):find('INV_Scroll_03',1,true))
U.Navigate('recipes')
assert(#U.recipeGroups==2 and U.recipeGroups[1].id=='skill:171' and #U.recipeGroups[1].recipes==2)
assert(#U.entries==3) -- Shared elixir remains one item, with two crafters.
local selected=U.recipeGroups[1].recipes[1]
U.Select(selected); local selectedKey=U.selectionKey
U.recipeHeaders[1].scripts.OnClick()
assert(U.catalogCollapsed['skill:171'] and U.recipeHeaders[1].toggle:GetText()=='+')
assert(U.selectionKey==selectedKey and U.selectedEntry.key==selectedKey and U.target.item==selected.item)
assert(U.rows[1].entry.recipe.profession=='skill:185' and not U.rows[2]:IsShown())
U.search:SetText('АЛХИМИЯ')
assert(#U.entries==2 and #U.recipeGroups==1 and U.recipeHeaders[1].toggle:GetText()=='-')
assert(U.rows[2]:IsShown()) -- Search expands matching collapsed professions.
U.search:SetText('no matching recipe')
assert(#U.entries==0 and not U.recipeHeaders[1]:IsShown() and U.empty:IsShown())
U.Navigate('network'); U.Select(U.entries[1])
assert(not U.recipeHeaders[1]:IsShown())
assert(#U.profileHeaders==3 and #U.profileCards==3)
assert(U.profileHeaders[1].title:GetText()=='Алхимия')
assert(U.profileHeaders[1].detail:GetText():find('150',1,true))
assert(U.profileCards[1].blueprint and U.profileCards[1]:GetHeight()>58)
assert(U.profileCards[1]:GetHeight()==U.profileCards[2]:GetHeight())
assert(U.profileCards[3].point[3]<U.profileCards[1].point[3]-U.profileCards[1]:GetHeight())
assert(U.blocks[1].text:GetText():find('workshop',1,true))
local height=U.body:GetHeight()
U.profileHeaders[1].scripts.OnClick()
assert(U.profileCollapsed['Crafter-Realm']['skill:171'] and U.profileHeaders[1].toggle:GetText()=='+')
assert(U.profileCards[1].entry.recipeID=='food' and not U.profileCards[2]:IsShown())
assert(U.body:GetHeight()<height)
U.profileHeaders[1].scripts.OnClick()
assert(not U.profileCollapsed['Crafter-Realm']['skill:171'] and U.profileCards[2]:IsShown())
local card=U.profileCards[2]
card.scripts.OnClick(card)
assert(U.page=='recipes' and U.selectedEntry.owner=='Crafter-Realm' and U.selectedEntry.recipeID=='elixir')
assert(U.target.owner=='Crafter-Realm' and U.target.item=='item:102')
assert(not U.profileHeaders[1]:IsShown() and not U.profileCards[1]:IsShown())
U.BuildSelected(); assert(U.planData.owner=='Crafter-Realm' and U.planData.missing['item:999']==3)
-- A removed/stale recipe cannot switch the user's current target.
local previous=U.target
peer.recipes.elixir=nil
U.OpenProfileRecipe('Crafter-Realm','elixir','item:102'); assert(U.target==previous)
-- Empty and expired profiles must not leave the previous player's cards behind.
local empty=F.NewProfile(); F.db.profiles['Empty-Realm']=empty
U.Navigate('network')
for _,entry in ipairs(U.entries) do if entry.owner=='Empty-Realm' then U.Select(entry); break end end
assert(U.blocks[1].text:GetText()==F.L('PROFILE_EMPTY') and not U.profileCards[1]:IsShown())
-- Build each new profile UI string in all supported languages.
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale
    U.RenderPlayer({owner='Crafter-Realm',title='Crafter-Realm'},peer)
    assert(U.profileHeaders[1].detail:GetText():find('150',1,true))
end
