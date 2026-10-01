local F = ForeverNet
assert(GetTradeSkillLine == nil and GetNumTradeSkills == nil)
local ids = {101, 102, 103, 104, 105, 106, 107}
local infos = {
    [101] = {name='Test bags', learned=true},
    [102] = {name='Unlearned', learned=false},
    [103] = {name='Currency cost', learned=true},
    [104] = {name='Reagent alternatives', learned=true},
    [105] = {name='Gathering', learned=true, isGatheringRecipe=true},
    [106] = {name='Variable cost', learned=true},
    [107] = {name='Missing output', learned=true},
}
local function slot(item, qty)
    return {required=true, quantityRequired=qty, reagents={{itemID=item}}, variableQuantities={}}
end
local schematics = {
    [101] = {outputItemID=201, quantityMin=2, reagentSlotSchematics={slot(301,3),slot(301,2),
        {required=false, quantityRequired=1, reagents={{itemID=999}}}}},
    [103] = {outputItemID=203, quantityMin=1, reagentSlotSchematics={
        {required=true, quantityRequired=1, reagents={{currencyID=999}}}}},
    [104] = {outputItemID=204, quantityMin=1, reagentSlotSchematics={
        {required=true, quantityRequired=1, reagents={{itemID=1},{itemID=2}}}}},
    [106] = {outputItemID=206, quantityMin=1, reagentSlotSchematics={
        {required=true, quantityRequired=1, reagents={{itemID=1}}, variableQuantities={{quantity=2}}}}},
    [107] = {quantityMin=1, reagentSlotSchematics={}},
}
C_TradeSkillUI = {
    GetBaseProfessionInfo=function() return {professionID=165,skillLevel=72} end,
    GetFilteredRecipeIDs=function() return ids end,
    GetRecipeInfo=function(id) return infos[id] end,
    GetRecipeSchematic=function(id, recraft)
        assert(recraft==false and infos[id].learned and not infos[id].isGatheringRecipe)
        return schematics[id]
    end,
    SetShowUnlearned=function() error('Scanner must not change filters') end,
}
local ok, message = F.Adapter.Scan()
assert(ok and message:find('4',1,true))
assert(F.localProfile.professions['skill:165']==72)
local r=F.localProfile.recipes['spell:101']
assert(r.output=='item:201' and r.quantity==2 and r.reagents['item:301']==5 and not r.reagents['item:999'])
assert(#F.Keys(F.localProfile.recipes)==1)
r.blueprint, r.stations.workshop = true, true
assert(F.Adapter.Scan())
assert(F.localProfile.recipes['spell:101'].blueprint and F.localProfile.recipes['spell:101'].stations.workshop)
local snapshot = F.Codec.Encode(F.localProfile)
ids={}; assert(not F.Adapter.Scan()); assert(F.Codec.Encode(F.localProfile)==snapshot)
ids={101,108}; assert(not F.Adapter.Scan()); assert(F.Codec.Encode(F.localProfile)==snapshot)
ids={101}; schematics[101].reagentSlotSchematics[1].reagents={}
assert(not F.Adapter.Scan()); assert(F.Codec.Encode(F.localProfile)==snapshot)
schematics[101].reagentSlotSchematics[1] = slot(301,3)
for _, flag in ipairs({'IsTradeSkillLinked','IsTradeSkillGuild','IsTradeSkillGuildMember','IsNPCCrafting'}) do
    C_TradeSkillUI[flag] = function() return true end
    assert(not F.Adapter.Scan()); assert(F.Codec.Encode(F.localProfile)==snapshot)
    C_TradeSkillUI[flag] = nil
end
-- A filtered scan merges new results and preserves older learned recipes.
ids={109}; infos[109]={name='Filtered new item',learned=true}
schematics[109]={outputItemID=209,quantityMin=1,reagentSlotSchematics={slot(309,1)}}
assert(F.Adapter.Scan())
assert(F.localProfile.recipes['spell:101'] and F.localProfile.recipes['spell:109'])
C_TradeSkillUI.GetBaseProfessionInfo=function() return nil end
assert(not F.Adapter.Scan())
