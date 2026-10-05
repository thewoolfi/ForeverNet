local _, F = ...
F.Adapter = {}
local function itemID(link)
    local id = link and link:match('item:(%d+)'); return id and 'item:' .. id
end
local function commit(profession, rank, recipes, count, skipped, maximum)
    if count == 0 then return false, F.L('SCAN_EMPTY') end
    local candidate = F.Copy(F.localProfile)
    candidate.professions[profession] = rank
    -- A filtered/partially supported list never deletes recipes already known.
    for id, recipe in pairs(recipes) do candidate.recipes[id] = recipe end
    if not F.ValidProfile(candidate) then return false, F.L('Сканирование превышает лимиты профиля.') end
    F.localProfile.professions, F.localProfile.recipes = candidate.professions, candidate.recipes
    F.Touch()
    F.db.professionScans=F.db.professionScans or {}
    F.db.professionScans[F.me]=F.db.professionScans[F.me] or {}
    F.db.professionScans[F.me][profession]={seen=F.Now(),maximum=F.Integer(maximum,1,1000) and maximum or nil}
    local message = F.L('Считано рецептов: ') .. count
    if skipped and skipped > 0 then message = message .. string.format(F.L('SCAN_SKIPPED'), skipped) end
    return true, message
end
local function recipe(id, name, output, quantity, profession, reagents)
    local old = F.localProfile.recipes[id]
    return {name = name, output = output, quantity = quantity, profession = profession,
        reagents = reagents, blueprint = old and old.blueprint or false, stations = old and old.stations or {}}
end

-- Forever 1.60.1 (70124): Blizzard's own Professions list enumerates
-- GetFilteredRecipeIDs, then GetRecipeInfo and GetRecipeSchematic.
-- Read current filters; do not change the player's profession UI settings.
local function scanModern(api, selected, preview)
    local professionInfo = api.GetBaseProfessionInfo()
    if not professionInfo or not F.Integer(professionInfo.professionID, 1, 2147483647) or
        not F.Integer(professionInfo.skillLevel, 1, 1000) then
        return false, F.L('Откройте окно профессии.')
    end
    local profession = 'skill:' .. professionInfo.professionID
    if preview and api.GetProfessionInfoByRecipeID then
        local belongs=api.GetProfessionInfoByRecipeID(selected[1])
        local baseID=belongs and (belongs.parentProfessionID or belongs.professionID)
        if not F.Integer(baseID,1,2147483647) or baseID~=professionInfo.professionID then return false,F.L('SCAN_LOADING') end
    end
    local ids = selected or api.GetFilteredRecipeIDs()
    if type(ids) ~= 'table' then return false, F.L('SCAN_LOADING') end
    local recipes, count, skipped = {}, 0, 0
    for _, spellID in ipairs(ids) do
        local info = api.GetRecipeInfo(spellID)
        if not info then return false, F.L('SCAN_LOADING') end
        if info.learned and not info.isRecraft and not info.isDummyRecipe and not info.isGatheringRecipe and not info.isSalvageRecipe then
            local schematic = api.GetRecipeSchematic(spellID, false)
            if not schematic then return false, F.L('SCAN_LOADING') end
            local outputID = schematic.outputItemID
            local valid = F.Integer(outputID, 1, 2147483647) and F.Integer(schematic.quantityMin, 1, 1000)
            if preview and schematic.quantityMax and schematic.quantityMax~=schematic.quantityMin then valid=false end
            if type(schematic.reagentSlotSchematics) ~= 'table' then return false, F.L('SCAN_LOADING') end
            local reagents = {}
            for _, slot in ipairs(schematic.reagentSlotSchematics) do
                if type(slot.required) ~= 'boolean' then return false, F.L('SCAN_LOADING') end
                if slot.required then
                    -- No arbitrary choice between alternative/quality reagents,
                    -- and no treating unsupported currency costs as free crafts.
                    local options = slot.reagents
                    local reagent = type(options) == 'table' and options[1]
                    if not reagent then return false, F.L('SCAN_LOADING') end
                    if #options ~= 1 or not F.Integer(reagent.itemID, 1, 2147483647) or reagent.currencyID or
                        not F.Integer(slot.quantityRequired, 1, 10000) or
                        (slot.variableQuantities and next(slot.variableQuantities)) then
                        valid = false
                    else
                        local item = 'item:' .. reagent.itemID
                        reagents[item] = (reagents[item] or 0) + slot.quantityRequired
                    end
                end
            end
            if valid and F.Text(info.name) then
                local id = 'spell:' .. spellID
                if not recipes[id] then count = count + 1 end
                recipes[id] = recipe(id, info.name, 'item:' .. outputID, schematic.quantityMin, profession, reagents)
            else skipped = skipped + 1 end
        end
    end
    if preview then
        local result=recipes['spell:'..selected[1]]
        if not result then return false,F.L('PRO_UNSUPPORTED') end
        return true,result,professionInfo
    end
    return commit(profession, professionInfo.skillLevel, recipes, count, skipped,professionInfo.maxSkillLevel)
end

-- Inspect only the selected recipe. Reading must not change profile revisions,
-- native filters or the queue; commit only after an explicit action.
local function ownCraftingMode(api)
    if IsTradeSkillLinked and IsTradeSkillLinked() then return false,F.L('OWN_PROFESSION_ONLY') end
    for _,flag in ipairs({'IsTradeSkillLinked','IsTradeSkillGuild','IsTradeSkillGuildMember','IsNPCCrafting'}) do
        if api[flag] and api[flag]() then return false,F.L('OWN_PROFESSION_ONLY') end
    end
    if Professions and Professions.InLocalCraftingMode and not Professions.InLocalCraftingMode() then
        return false,F.L('OWN_PROFESSION_ONLY')
    end
    return true
end
-- Resolve only the base output, including unlearned recipes. This does not
-- publish a recipe or claim that its reagents/optional variants are supported.
function F.Adapter.RecipeOutput(spellID)
    if not F.Integer(spellID,1,2147483647) then return nil,F.L('PRO_CHOOSE') end
    local api=C_TradeSkillUI
    if not api or not api.GetBaseProfessionInfo or not api.GetRecipeInfo or not api.GetRecipeSchematic then return nil,F.L('SCAN_UNSUPPORTED') end
    local ok,result,why=pcall(function()
        local own,message=ownCraftingMode(api)
        if not own then return nil,message end
        local profession=api.GetBaseProfessionInfo()
        if not profession or not F.Integer(profession.professionID,1,2147483647) then return nil,F.L('SCAN_LOADING') end
        if api.GetProfessionInfoByRecipeID then
            local belongs=api.GetProfessionInfoByRecipeID(spellID)
            if not belongs or (belongs.parentProfessionID or belongs.professionID)~=profession.professionID then return nil,F.L('SCAN_LOADING') end
        end
        local info=api.GetRecipeInfo(spellID)
        if not info or info.recipeID~=spellID then return nil,F.L('SCAN_LOADING') end
        if info.isDummyRecipe or info.isRecraft or info.isGatheringRecipe or info.isSalvageRecipe then return nil,F.L('FINDER_NO_OUTPUT') end
        local schematic=api.GetRecipeSchematic(spellID,false)
        if not schematic then return nil,F.L('SCAN_LOADING') end
        if schematic.recipeID~=nil and schematic.recipeID~=spellID then return nil,F.L('SCAN_LOADING') end
        if schematic.isRecraft then return nil,F.L('FINDER_NO_OUTPUT') end
        if not F.Integer(schematic.outputItemID,1,2147483647) then return nil,F.L('FINDER_NO_OUTPUT') end
        return {output='item:'..schematic.outputItemID,name=F.Text(info.name) and info.name or nil}
    end)
    if not ok then return nil,F.L('SCAN_LOADING') end
    return result,why
end
function F.Adapter.ReadRecipe(spellID)
    if not F.Integer(spellID,1,2147483647) then return nil,F.L('PRO_CHOOSE') end
    local api=C_TradeSkillUI
    if not api or not api.GetBaseProfessionInfo or not api.GetRecipeInfo or not api.GetRecipeSchematic then
        return nil,F.L('SCAN_UNSUPPORTED')
    end
    local ok,success,result,info=pcall(function()
        local own,why=ownCraftingMode(api)
        if not own then return false,why end
        return scanModern(api,{spellID},true)
    end)
    if not ok then return nil,F.L('SCAN_LOADING') end
    if not success then return nil,result end
    return result,nil,info
end
function F.Adapter.CaptureRecipe(spellID)
    local result,why,info=F.Adapter.ReadRecipe(spellID)
    if not result then return nil,why end
    local id='spell:'..spellID
    local ok,message=commit(result.profession,info.skillLevel,{[id]=result},1,nil,info.maxSkillLevel)
    if not ok then return nil,message end
    F.UI.DataChanged()
    return result,nil,id
end
local function scanLegacy()
    local name, rank, maximum = GetTradeSkillLine()
    if not name or name == 'UNKNOWN' then return false, F.L('Откройте окно профессии.') end
    local profession = 'legacy:' .. tostring(GetLocale()) .. ':' .. (name:gsub('.', function(c) return string.format('%02x', string.byte(c)) end))
    -- Localized profession label is metadata, never used for recipe matching.
    local recipes, count = {}, 0
    for i = 1, GetNumTradeSkills() do
        local label, kind = GetTradeSkillInfo(i)
        if kind ~= 'header' then
            local output = itemID(GetTradeSkillItemLink(i))
            local recipeLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i)
            local spell = recipeLink and recipeLink:match('enchant:(%d+)')
            if output and label then
                local reagents, valid = {}, true
                for j = 1, GetTradeSkillNumReagents(i) do
                    local _, _, qty = GetTradeSkillReagentInfo(i, j)
                    local reagent = itemID(GetTradeSkillReagentItemLink(i, j))
                    if not reagent or not qty then valid = false; break end
                    reagents[reagent] = (reagents[reagent] or 0) + qty
                end
                if not valid then return false, F.L('Данные предметов ещё загружаются. Повторите сканирование.') end
                local minimum = GetTradeSkillNumMade(i)
                local id = spell and 'spell:' .. spell or output
                recipes[id] = recipe(id, label, output, minimum or 1, profession, reagents)
                count = count + 1
            end
        end
    end
    return commit(profession, rank or 0, recipes, count,nil,maximum)
end
function F.Adapter.Scan()
    local api = C_TradeSkillUI
    if IsTradeSkillLinked and IsTradeSkillLinked() then return false, F.L('OWN_PROFESSION_ONLY') end
    if api then
        for _, name in ipairs({'IsTradeSkillLinked', 'IsTradeSkillGuild', 'IsTradeSkillGuildMember', 'IsNPCCrafting'}) do
            if api[name] and api[name]() then return false, F.L('OWN_PROFESSION_ONLY') end
        end
        if api.GetBaseProfessionInfo and api.GetFilteredRecipeIDs and api.GetRecipeInfo and api.GetRecipeSchematic then
            return scanModern(api)
        end
    end
    if GetNumTradeSkills and GetTradeSkillLine and GetTradeSkillInfo and GetTradeSkillItemLink and
        GetTradeSkillNumReagents and GetTradeSkillReagentInfo and GetTradeSkillReagentItemLink and GetTradeSkillNumMade then
        return scanLegacy()
    end
    return false, F.L('SCAN_UNSUPPORTED')
end
function F.Adapter.ItemCount(item)
    local id = item and tonumber(item:match('^item:(%d+)$'))
    if not id then return 0 end
    return (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(id, false)) or (GetItemCount and GetItemCount(id, false)) or 0
end
function F.Adapter.StockCount(item)
    return F.Adapter.ItemCount(item)+(F.db.settings.useBank~=false and F.Bank.Count(item) or 0)
end
function F.Adapter.Inventory(profiles,bagCounts)
    local result = {}
    local function read(item)
        if result[item]~=nil then return end
        local count=F.Adapter.ItemCount(item)
        if bagCounts then bagCounts[item]=count end
        result[item]=count+(F.db.settings.useBank~=false and F.Bank.Count(item) or 0)
    end
    for _, p in pairs(profiles) do
        for _, r in pairs(p.recipes) do
            read(r.output)
            for item in pairs(r.reagents) do read(item) end
        end
    end
    return result
end
function F.Adapter.Demo()
    local a, b = F.NewProfile(), F.NewProfile()
    a.professions.engineering, b.professions.tailoring = 300, 300
    a.recipes['demo:engine'] = {name = F.L('DEMO: двигатель'), output = 'demo:engine', quantity = 1, profession = 'engineering',
        blueprint = true, reagents = {['demo:ore'] = 3}, stations = {}}
    b.recipes['demo:bag'] = {name = F.L('DEMO: сумка'), output = 'demo:bag', quantity = 1, profession = 'tailoring',
        blueprint = true, reagents = {['demo:engine'] = 1, ['demo:cloth'] = 4}, stations = {['demo:workshop'] = true}}
    a.camps['demo:workshop'] = F.Now()
    return {['DemoEngineer-Realm'] = a, ['DemoTailor-Realm'] = b}
end
