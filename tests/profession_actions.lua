local F,P=ForeverNet,ForeverNet.ProfessionActions
local selected,linked=nil,false
local infos={[101]={recipeID=101,name='Leather bundles',learned=true},[102]={recipeID=102,name='Leather gloves',learned=true},
    [103]={recipeID=103,name='Unlearned',learned=false},[104]={recipeID=104,name='Currency',learned=true},
    [105]={recipeID=105,name='Variable output',learned=true}}
local function slot(item,quantity) return {required=true,quantityRequired=quantity,reagents={{itemID=item}}} end
local schematics={
    [101]={outputItemID=201,quantityMin=2,quantityMax=2,reagentSlotSchematics={slot(301,3),slot(301,2),
        {required=false,reagents={{itemID=999}},quantityRequired=1}}},
    [102]={outputItemID=202,quantityMin=1,reagentSlotSchematics={slot(301,1)}},
    [104]={outputItemID=204,quantityMin=1,reagentSlotSchematics={{required=true,quantityRequired=1,reagents={{currencyID=4}}}}},
    [105]={outputItemID=205,quantityMin=1,quantityMax=3,reagentSlotSchematics={}},
}
C_TradeSkillUI={GetBaseProfessionInfo=function() return {professionID=165,skillLevel=72,maxSkillLevel=150} end,
    GetProfessionInfoByRecipeID=function() return {professionID=165} end,
    GetRecipeInfo=function(id) return infos[id] end,GetRecipeSchematic=function(id,recraft) assert(recraft==false); return schematics[id] end,
    IsTradeSkillLinked=function() return linked end,
    GetFilteredRecipeIDs=function() error('Selected actions must not enumerate or change native filters') end,
    SetRecipeItemNameFilter=function() error('Native filters must remain untouched') end,
    CraftRecipe=function() error('Only the player performs crafting') end}
C_Item={GetItemCount=function(id) return id==301 and 4 or 0 end}
F.db.banks={[F.me]={items={['item:301']=1},seen=clock}}
F.localProfile.professions['skill:171']=10
F.localProfile.recipes.other={name='Unrelated',output='item:700',quantity=1,profession='skill:171',blueprint=false,reagents={},stations={}}
ProfessionsFrame=CreateFrame('Frame')
local page=CreateFrame('Frame',nil,ProfessionsFrame); ProfessionsFrame.CraftingPage=page; page:SetSize(680,600)
page.SchematicForm={GetRecipeInfo=function() return infos[selected] end}
page.CreateMultipleInputBox={GetValue=function() return 77 end,SetValue=function() error('Do not alter native craft count') end}
local selections=0
function page:SelectRecipe(info) selected=info and info.recipeID; selections=selections+1 end
local hooks=0
function hooksecurefunc(object,name,callback)
    hooks=hooks+1
    local prior=object[name]
    object[name]=function(...) local result=prior(...); callback(...); return result end
end
assert(P.Attach() and P.Attach() and hooks==1)
assert(P.panel.parent==page and P.panel.point[3]=='BOTTOMLEFT' and not P.add:IsEnabled())
local original=F.Codec.Encode(F.localProfile)
page:SelectRecipe(infos[101]); P.Tick(.25)
assert(selections==1 and P.add:IsEnabled() and P.materials:IsEnabled())
assert(F.Codec.Encode(F.localProfile)==original and #F.Queue.data.goals==0) -- Selection is read-only.
assert(P.output:GetText():find('2',1,true))
P.qty:SetText('5'); P.Tick(.25); P.add.scripts.OnClick()
local goal=F.Queue.data.goals[1]
assert(goal.item=='item:201' and goal.quantity==5 and goal.owner==F.me and goal.recipeID=='spell:101')
assert(F.localProfile.recipes.other and F.localProfile.recipes['spell:101'].reagents['item:301']==5)
assert(not F.localProfile.recipes['spell:101'].reagents['item:999'])
local plan=F.Queue.Build()
assert(plan.steps[1].batches==3 and plan.steps[1].quantity==6 and plan.missing['item:301']==10)
assert(page.CreateMultipleInputBox:GetValue()==77)
P.materials.scripts.OnClick()
assert(#F.Queue.data.goals==1 and F.UI.page=='chain' and F.UI.planData.recipeID=='spell:101')
assert(F.UI.planData.missing['item:301']==10 and F.UI.planData.bagSupplied['item:301']==4)
-- Always read current schematic at click time, even before the debounced update.
page:SelectRecipe(infos[102]); P.add.scripts.OnClick()
assert(F.Queue.data.goals[2].item=='item:202' and F.Queue.data.goals[2].quantity==1)
assert(F.Queue.data.goals[2].recipeID=='spell:102' and P.qty:GetText()=='1')
page:SelectRecipe(infos[101]); P.Refresh()
P.qty:SetText('0'); original=F.Codec.Encode(F.localProfile)
assert(not P.Action('queue') and #F.Queue.data.goals==2 and F.Codec.Encode(F.localProfile)==original)
P.qty:SetText('3')
for _,id in ipairs({103,104,105}) do
    page:SelectRecipe(infos[id]); P.Tick(.25)
    assert(not P.add:IsEnabled() and not P.materials:IsEnabled() and not P.Action('queue'))
end
assert(#F.Queue.data.goals==2 and F.Codec.Encode(F.localProfile)==original)
page:SelectRecipe(infos[101]); linked=true; P.Refresh()
assert(not P.add:IsEnabled() and not P.Action('materials') and F.Codec.Encode(F.localProfile)==original)
linked=false
local belongs=C_TradeSkillUI.GetProfessionInfoByRecipeID
C_TradeSkillUI.GetProfessionInfoByRecipeID=function() return {professionID=171} end
assert(not F.Adapter.CaptureRecipe(101) and F.Codec.Encode(F.localProfile)==original) -- Stale schematic after a profession switch.
C_TradeSkillUI.GetProfessionInfoByRecipeID=function() return {professionID=999,parentProfessionID=165} end
assert(F.Adapter.ReadRecipe(101)) -- A child skill line belongs to its base profession.
C_TradeSkillUI.GetProfessionInfoByRecipeID=belongs
Professions={InLocalCraftingMode=function() return false end}
assert(not F.Adapter.ReadRecipe(101)); Professions=nil
local saved=schematics[101]; schematics[101]=nil
assert(not F.Adapter.CaptureRecipe(101) and F.Codec.Encode(F.localProfile)==original)
schematics[101]=saved
local getter=C_TradeSkillUI.GetRecipeSchematic
C_TradeSkillUI.GetRecipeSchematic=function() error('Still loading') end
assert(not F.Adapter.CaptureRecipe(101)); C_TradeSkillUI.GetRecipeSchematic=getter
-- Single-recipe capture preserves manual Blueprint/station metadata and other recipes.
F.localProfile.recipes['spell:101'].blueprint=true; F.localProfile.recipes['spell:101'].stations.workshop=true
assert(F.Adapter.CaptureRecipe(101))
assert(F.localProfile.recipes['spell:101'].blueprint and F.localProfile.recipes['spell:101'].stations.workshop)
for i=3,F.Queue.MAX_GOALS do F.Queue.Add('item:201',1,F.me,'spell:101') end
P.Refresh(); original=F.Codec.Encode(F.localProfile)
assert(not P.add:IsEnabled() and P.materials:IsEnabled() and P.status:GetText()==F.L('QUEUE_FULL'))
assert(not P.Action('queue') and F.Codec.Encode(F.localProfile)==original)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; page:SetWidth(350); P.Refresh()
    assert(P.add:GetText()==F.L('QUEUE_ADD') and P.materials:GetText()==F.L('PRO_MATERIALS'))
    assert(F.L('PRO_HELP')~='PRO_HELP')
    local helpTop=-P.help.point[3]
    assert(not P.help:IsShown() and P.panel:GetHeight()>=helpTop+8)
    local narrowHeight=P.panel:GetHeight()
    assert(-P.find.point[3]>=-P.add.point[3]+P.add:GetHeight())
    page:SetWidth(640); P.Refresh()
    assert(P.add.point[3]==P.materials.point[3] and P.add.point[3]==P.find.point[3])
    assert(P.panel:GetHeight()<narrowHeight and P.title:GetText()=='ForeverNet')
    assert(P.add.point[2]>P.qty.point[2]+P.qty:GetWidth())
    assert(-P.add.point[3]<-P.output.point[3]+P.output:GetStringHeight()) -- Actions occupy the right of the metadata band.
    assert(P.panel:GetWidth()==page:GetWidth()-8 and not P.title:IsShown())
    for _,b in ipairs({P.add,P.materials,P.find}) do assert(b:GetHeight()>=b.measure:GetStringHeight()+8) end
end
P.qty:SetText('7'); P.Refresh()
F.Command('language ruRU'); P.Tick(.25)
assert(P.materials:GetText()==F.L('PRO_MATERIALS') and P.quantityLabel:GetText()==F.L('PRO_QUANTITY') and P.qty:GetText()=='7')
F.db.settings.locale='enUS'
page:Hide(); page.scripts.OnHide(page); P.Tick(1)
assert(not P.panel:IsShown() and not P.Action('queue'))
page:Show(); page.scripts.OnShow(page); P.Tick(.25); assert(P.panel:IsShown())
-- Repeated load events must not create another panel or duplicate hooks.
local panel=P.panel
P.frame.scripts.OnEvent(P.frame,'ADDON_LOADED','Blizzard_Professions')
assert(P.panel==panel and hooks==1)
