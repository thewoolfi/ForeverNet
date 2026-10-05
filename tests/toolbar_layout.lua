local F,P,U=ForeverNet,ForeverNet.ProfessionActions,ForeverNet.UI
local sent=0
C_ChatInfo.SendAddonMessage=function() sent=sent+1 end
C_TradeSkillUI={
    GetBaseProfessionInfo=function() return {professionID=171,skillLevel=7,maxSkillLevel=75} end,
    GetProfessionInfoByRecipeID=function() return {professionID=171} end,
    GetRecipeInfo=function() return {recipeID=101,name='Potion',learned=true} end,
    GetRecipeSchematic=function() return {recipeID=101,outputItemID=1,quantityMin=1,quantityMax=1,reagentSlotSchematics={}} end}
ProfessionsFrame=CreateFrame('Frame')
local page=CreateFrame('Frame',nil,ProfessionsFrame); ProfessionsFrame.CraftingPage=page
page.SchematicForm={GetRecipeInfo=function() return {recipeID=101,name='Potion',learned=true} end}
page:SetSize(640,600)
function hooksecurefunc() end
assert(P.Attach())
local profile=F.Codec.Encode(F.localProfile)
toolbarMetrics={}
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; F.Theme.RefreshFonts()
    for _,width in ipairs({350,620,640,800,1000}) do
        page:SetWidth(width); P.Refresh()
        assert(P.panel:GetWidth()==width-8)
        local metadataBottom=-P.output.point[3]+P.output:GetStringHeight()
        local previousRight=nil
        for _,b in ipairs({P.add,P.materials,P.find}) do
            assert(b.point[2]+b:GetWidth()<=P.panel:GetWidth()-12+.01)
            assert(-b.point[3]+b:GetHeight()<=P.panel:GetHeight()-8)
            assert(b:GetHeight()>=b.measure:GetStringHeight()+8)
            if width>=620 then
                assert(b.point[2]>P.qty.point[2]+P.qty:GetWidth())
                assert(-b.point[3]<metadataBottom) -- Use the blank area beside quantity, never below it.
                if previousRight then assert(b.point[2]>=previousRight+7.99) end
                previousRight=b.point[2]+b:GetWidth()
            end
        end
        if width==640 then toolbarMetrics[locale]=P.panel:GetHeight() end
        assert(not P.title:IsShown() and not P.status:IsShown())
        assert(P.panel:GetHeight()<100 or width==350)
    end
    U.Show('')
    U.ShowSourceRows({{section=true,title='Tools',actions={{text='Save',run=function() end},{text='Open',run=function() end}}}})
    local row=U.sourceRows[1]
    assert(row.buttons[1].point[2]>=row.title.point[2]+row.title:GetWidth()+12)
    assert(row.buttons[1].point[3]==row.buttons[2].point[3] and row:GetHeight()==44)
    U.ShowSourceRows({{item='item:1',title='Goal',text='Stock: 0 / 1',actions={{text='Remove',run=function() end},{text='Up',run=function() end}},
        extraAction={text='Maintain stock',run=function() end}}})
    row=U.sourceRows[1]
    assert(row.buttons[1].point[3]==row.extraButton.point[3])
    assert(row.extraButton.point[2]>=row.buttons[2].point[2]+row.buttons[2]:GetWidth()+7.99)
    -- Long translations safely revert to an extra row without stale positions.
    U.ShowSourceRows({{item='item:1',title='Goal',text='Stock',actions={{text='Remove',run=function() end},{text='Up',run=function() end}},
        extraAction={text=string.rep('Long translated mode ',8),run=function() end}}})
    row=U.sourceRows[1]
    assert(-row.extraButton.point[3]>=-row.buttons[1].point[3]+row.buttons[1]:GetHeight())
end
assert(sent==0 and F.Codec.Encode(F.localProfile)==profile and #F.Queue.data.goals==0)
for _,pageName in ipairs({'home','network','recipes','queue','crafters'}) do
    if pageName=='crafters' then U.FindCrafters('item:1',3) else U.Navigate(pageName) end
    local browse=pageName=='home' or pageName=='network'
    assert(U.right:GetHeight()==(browse and 433 or 357) and U.left:GetHeight()==U.right:GetHeight())
    assert(U.qty:IsShown()==not browse and U.chosen:IsShown()==not browse and U.plan:IsShown()==not browse)
end
P.qty:SetText('0'); P.Refresh()
assert(P.status:IsShown() and -P.status.point[3]>=-P.find.point[3]+P.find:GetHeight())
assert(P.panel:GetHeight()>=-P.status.point[3]+P.status:GetStringHeight()+8)
