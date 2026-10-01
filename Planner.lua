local _, F = ...
F.Planner = {}
-- A bounded, deterministic greedy plan, not a global cost optimizer.
function F.Planner.Build(profiles, item, quantity, inventory, now, options)
    assert(F.ID(item) and F.Integer(quantity, 1, 10000), 'invalid order')
    now = now or F.Now()
    options = options or {}
    local original = F.Copy(inventory or {})
    local result = {target=item, quantity=quantity, steps = {}, missing = {}, missingReasons = {}, supplied = {},
        warnings = {}, inventory = F.Copy(inventory or {})}
    local owners = F.Keys(profiles)
    table.sort(owners, function(a,b)
        if (a == options.localOwner) ~= (b == options.localOwner) then return a == options.localOwner end
        return a < b
    end)
    local function missing(id, qty, reason)
        result.missing[id] = (result.missing[id] or 0) + qty
        result.missingReasons[id] = reason
    end
    local active, visits = {}, 0
    local function need(id, qty, depth)
        visits = visits + 1
        local available = result.inventory[id] or 0
        local used = math.min(available, qty)
        local fromBags = math.min(original[id] or 0, used)
        if fromBags > 0 then
            result.supplied[id] = (result.supplied[id] or 0) + fromBags
            original[id] = original[id] - fromBags
        end
        result.inventory[id], qty = available - used, qty - used
        if qty == 0 then return end
        if active[id] or depth > 20 or visits > 2000 then
            missing(id, qty, active[id] and 'cycle' or 'limit')
            result.warnings[#result.warnings + 1] = F.L('Цикл/лимит: ') .. id; return
        end
        local chosen, blockedStation
        for _, owner in ipairs(owners) do
            for _, recipeID in ipairs(F.Keys(profiles[owner].recipes)) do
                local recipe = profiles[owner].recipes[recipeID]
                local selected = depth ~= 0 or not options.recipeID or (owner == options.owner and recipeID == options.recipeID)
                if recipe.output == id and selected then
                    local stations, ready = {}, true
                    for _, station in ipairs(F.Keys(recipe.stations)) do
                        local provider
                        for _, candidate in ipairs(F.Keys(profiles)) do
                            local at = profiles[candidate].camps[station]
                            if at and at <= now then provider = candidate; break end
                        end
                        if not provider then ready = false; blockedStation = true; break end
                        stations[station] = provider
                    end
                    if ready then chosen = {owner = owner, recipe = recipe, recipeID = recipeID, stations = stations}; break end
                end
            end
            if chosen then break end
        end
        if not chosen then missing(id, qty, blockedStation and 'camp' or 'unknown'); return end
        active[id] = true
        local batches = math.ceil(qty / chosen.recipe.quantity)
        for _, reagent in ipairs(F.Keys(chosen.recipe.reagents)) do need(reagent, chosen.recipe.reagents[reagent] * batches, depth + 1) end
        active[id] = nil
        result.steps[#result.steps + 1] = {owner = chosen.owner, recipeID = chosen.recipeID, name = chosen.recipe.name,
            item = id, batches = batches, quantity = batches * chosen.recipe.quantity, stations = chosen.stations}
        result.inventory[id] = (result.inventory[id] or 0) + batches * chosen.recipe.quantity - qty
    end
    need(item, quantity, 0)
    result.complete = next(result.missing) == nil and #result.warnings == 0
    return result
end
