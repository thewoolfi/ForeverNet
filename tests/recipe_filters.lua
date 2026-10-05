local F,U,C=ForeverNet,ForeverNet.UI,ForeverNet.Catalog
local function recipe(name,item,profession,blueprint)
    return {name=name,output=item,quantity=1,profession=profession,blueprint=blueprint,reagents={},stations={}}
end
F.localProfile.recipes={mine=recipe('Shared','item:101','skill:171',false),
    food=recipe('Food','item:102','skill:185',false)}
local peer=F.NewProfile()
peer.recipes={shared=recipe('Shared','item:101','skill:202',true),
    other=recipe('Other','item:103','skill:171',false)}
F.db.profiles['Peer-Realm']=peer
assert(#C.Recipes(F.Profiles(),'')==3)
local entries=C.Recipes(F.Profiles(),'Shared',nil,{kind='blueprint'})
assert(#entries==1 and entries[1].owner=='Peer-Realm' and #entries[1].providers==1)
entries=C.Recipes(F.Profiles(),'',{['item:101']='Peer-Realm/shared'},{scope='mine'})
assert(#entries==2)
for _,entry in ipairs(entries) do assert(entry.owner==F.me and #entry.providers==1) end
entries=C.Recipes(F.Profiles(),'',nil,{profession='skill:202'})
assert(#entries==1 and entries[1].recipeID=='shared') -- Filter precedes item deduplication.
assert(#C.Recipes(F.Profiles(),'',nil,{profession='skill:185',scope='network'})==0)
-- A profession card applies a filter before the lazy menu was ever opened.
assert(not U.frame and not U.filterMenu)
U.SetRecipeFilter('profession','skill:185')
assert(U.frame and not U.filterMenu and U.recipeFilters.profession=='skill:185')
U.Navigate('recipes'); assert(#U.entries==1 and U.entries[1].recipeID=='food')
U.Navigate('home')
local professionRow
for _,row in ipairs(U.rows) do
    if row:IsShown() and row.entry.kind=='profession' and row.entry.profession=='skill:171' then professionRow=row end
end
assert(professionRow and not professionRow.entry.subtitle:find('·',1,true))
professionRow.scripts.OnClick(professionRow)
assert(U.page=='recipes' and U.recipeFilters.profession=='skill:171' and not U.filterMenu)
assert(#U.entries==2)
U.SetRecipeFilter(); assert(#U.entries==3 and next(U.recipeFilters)==nil)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale
    assert(not F.L('HOME_INFO'):find('·',1,true) and not F.L('MARKET_BUDGET'):find('≈',1,true))
end
F.db.settings.locale='enUS'
U.Navigate('recipes'); U.Select(U.entries[1]); U.filterButton.scripts.OnClick()
assert(U.filterMenu:IsShown() and U.search:GetWidth()<150)
local function click(text)
    for _,b in ipairs(U.filterControls) do
        if b:IsShown() and b:GetText()==text then b.scripts.OnClick(); return end
    end
    error('Missing filter control: '..text)
end
click(F.L('FILTER_BLUEPRINT'))
assert(#U.entries==1 and U.entries[1].owner=='Peer-Realm' and not U.filterMenu:IsShown())
assert(U.target==nil and U.selectionKey==nil and U.filterButton:GetText():find('*',1,true))
U.OpenFilters(); click(F.L('FILTER_MINE')); assert(#U.entries==0)
U.OpenFilters(); click(F.L('FILTER_RESET')); assert(#U.entries==3 and next(U.recipeFilters)==nil)
U.recipeFilters={scope='mine'}; U.OpenProfileRecipe('Peer-Realm','shared','item:101')
assert(U.selectedEntry.owner=='Peer-Realm' and next(U.recipeFilters)==nil)
U.Navigate('chain')
assert(not U.filterButton:IsShown() and U.search:GetWidth()==210)
IsInGroup=function() return true end; IsInGuild=function() return false end
F.db.settings.locale='ruRU'; U.Navigate('network')
assert(U.bodyText:GetText():find('Канал обмена: Группа',1,true))
assert(not U.bodyText:GetText():find('PARTY',1,true))
assert(F.Net.Channel()=='PARTY') -- Localized presentation never changes the transport.
peer.recipes.more=recipe('New profession','item:104','skill:197',false)
U.Navigate('recipes'); U.OpenFilters()
click(F.L('FILTER_BLUEPRINT')); assert(#U.entries==1)
U.OpenFilters(); click(F.L('FILTER_RESET')); assert(#U.entries==4)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('recipes'); U.OpenFilters()
    assert(U.filterButton:GetText()==F.L('FILTER_BUTTON'))
    assert(U.filterLabels[1]:GetText()==F.L('FILTER_PROFESSION'))
    U.filterMenu:Hide()
end
-- Both panes use the native thin bar; wheel and thumb control the same range.
for _,frame in ipairs({U.listScroll,U.details,U.filterProfessionScroll}) do
    assert(frame.ScrollBar.template=='MinimalScrollBar' and frame.boundScrollBar==frame.ScrollBar)
    assert(frame.mouseWheelEnabled)
    frame:SetHeight(100); frame.child:SetHeight(500); frame:SetVerticalScroll(0)
    frame.scripts.OnMouseWheel(frame,-1); assert(frame:GetVerticalScroll()==30)
    frame.ScrollBar:SetScrollPercentage(.5); assert(frame:GetVerticalScroll()==200)
    frame.scripts.OnMouseWheel(frame,1); assert(frame:GetVerticalScroll()==170)
end
