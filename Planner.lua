local _, F = ...
F.Planner = {}
local function ownersByPreference(profiles, localOwner)
    local owners=F.Keys(profiles)
    table.sort(owners,function(a,b)
        if (a==localOwner)~=(b==localOwner) then return a==localOwner end
        local staleA,staleB=F.ProfileStale(profiles[a]),F.ProfileStale(profiles[b])
        if staleA~=staleB then return not staleA end
        return a<b
    end)
    return owners
end
local function sourcesIndex(profiles, now, localOwner)
    local index={}
    local owners=ownersByPreference(profiles,localOwner)
    for _,owner in ipairs(owners) do
        for _,recipeID in ipairs(F.Keys(profiles[owner].recipes)) do
            local recipe=profiles[owner].recipes[recipeID]
            local source={owner=owner,recipeID=recipeID,recipe=recipe,stations={},ready=true}
            for _,station in ipairs(F.Keys(recipe.stations)) do
                local provider
                for _,candidate in ipairs(owners) do
                    local at=profiles[candidate].camps[station]
                    if at and at<=now and (candidate==localOwner or not F.ProfileStale(profiles[candidate])) then
                        provider=candidate; break
                    end
                end
                if provider then source.stations[station]=provider else source.ready=false end
            end
            index[recipe.output]=index[recipe.output] or {}
            table.insert(index[recipe.output],source)
        end
    end
    return index
end
function F.Planner.Sources(profiles,item,now,localOwner)
    return sourcesIndex(profiles,now or F.Now(),localOwner)[item] or {}
end
function F.Planner.SourceIndex(profiles,now,localOwner)
    return sourcesIndex(profiles,now or F.Now(),localOwner)
end
-- A bounded, deterministic greedy plan, not a global cost optimizer.
function F.Planner.BuildQueue(profiles, goals, inventory, now, options)
    assert(type(goals)=='table' and #goals<=50, 'invalid queue')
    for _,goal in ipairs(goals) do assert(type(goal)=='table' and F.ID(goal.item) and F.Integer(goal.quantity,1,10000),'invalid order') end
    now = now or F.Now()
    options = options or {}
    local original = F.Copy(inventory or {})
    local carried=F.Copy(options.bags or {})
    local result = {goals=F.Copy(goals), goalStates={}, steps = {}, missing = {}, missingReasons = {}, supplied = {},
        warnings = {}, inventory = F.Copy(inventory or {}), materials={}, sources=F.Copy(options.sources or {}),bagSupplied={},retainedBank={}}
    local index=options.sourceIndex and options.sourceIndex() or sourcesIndex(profiles,now,options.localOwner)
    local function missing(id, qty, reason)
        result.missing[id] = (result.missing[id] or 0) + qty
        result.missingReasons[id] = reason
    end
    local active, visits, root, unavailable, rootStock, rootBankStock = {}, 0, {}, {}, 0, 0
    local function need(id, qty, depth)
        visits = visits + 1
        local material
        if depth>0 then
            material=result.materials[id] or {quantity=0,stock=0,shortage=0,alternatives=index[id] or {}}
            result.materials[id]=material
            material.quantity=material.quantity+qty
        end
        local available = result.inventory[id] or 0
        local used = math.min(available, qty)
        local blockedUsed=math.max(0,used-math.max(0,available-(unavailable[id] or 0)))
        unavailable[id]=math.max(0,(unavailable[id] or 0)-blockedUsed)
        local ready=blockedUsed==0
        local fromBags = math.min(original[id] or 0, used)
        local fromCarried=math.min(carried[id] or 0,fromBags)
        if options.bags and depth==0 and root.mode=='stock' then
            -- Maintained stock can stay in the bank. Reserve that part first so
            -- carried copies remain available to other goals without a withdrawal.
            local stored=math.max(0,(original[id] or 0)-(carried[id] or 0))
            fromCarried=fromBags-math.min(stored,fromBags)
        end
        carried[id]=math.max(0,(carried[id] or 0)-fromCarried)
        if fromCarried>0 then result.bagSupplied[id]=(result.bagSupplied[id] or 0)+fromCarried end
        if depth==0 then rootStock,rootBankStock=fromBags,options.bags and fromBags-fromCarried or 0 end
        if fromBags > 0 then
            result.supplied[id] = (result.supplied[id] or 0) + fromBags
            original[id] = original[id] - fromBags
        end
        result.inventory[id], qty = available - used, qty - used
        if material then material.stock=material.stock+fromBags; material.shortage=material.shortage+qty end
        if qty == 0 then return ready end
        local choice=depth>0 and (root.sources or result.sources)[id] or nil
        if choice=='external' then missing(id,qty,'external'); return false end
        if active[id] or depth > 20 or visits > 2000 then
            missing(id, qty, active[id] and 'cycle' or 'limit')
            result.warnings[#result.warnings + 1] = F.L('Цикл/лимит: ') .. id; return false
        end
        local chosen, blockedStation
        for _,source in ipairs(index[id] or {}) do
            local selected=depth~=0 or not root.recipeID or (source.owner==root.owner and source.recipeID==root.recipeID)
            if type(choice)=='table' then selected=source.owner==choice.owner and source.recipeID==choice.recipeID end
            if selected then
                if source.ready then chosen=source; break else blockedStation=true end
            end
        end
        if not chosen then missing(id, qty, blockedStation and 'camp' or type(choice)=='table' and 'source' or 'unknown'); return false end
        if material then material.chosen={owner=chosen.owner,recipeID=chosen.recipeID,name=chosen.recipe.name} end
        active[id] = true
        local batches = math.ceil(qty / chosen.recipe.quantity)
        for _, reagent in ipairs(F.Keys(chosen.recipe.reagents)) do
            if not need(reagent, chosen.recipe.reagents[reagent] * batches, depth + 1) then ready=false end
        end
        active[id] = nil
        local inputs={}
        for reagent,count in pairs(chosen.recipe.reagents) do inputs[reagent]=count*batches end
        result.steps[#result.steps + 1] = {owner = chosen.owner, recipeID = chosen.recipeID, name = chosen.recipe.name,
            item = id, batches = batches, quantity = batches * chosen.recipe.quantity, stations = chosen.stations, reagents=inputs}
        result.inventory[id] = (result.inventory[id] or 0) + batches * chosen.recipe.quantity - qty
        if not ready then unavailable[id]=(unavailable[id] or 0)+batches*chosen.recipe.quantity-qty end
        return ready
    end
    for i,goal in ipairs(goals) do
        root=goal
        local before=F.Copy(result.missing)
        local first=#result.steps+1
        local ready=need(goal.item,goal.quantity,0)
        local deficit={}
        for id,count in pairs(result.missing) do if count>(before[id] or 0) then deficit[id]=count-(before[id] or 0) end end
        result.goalStates[i]={ready=ready,stock=rootStock,bankStock=rootBankStock,missing=deficit,firstStep=first,lastStep=#result.steps}
        if goal.mode=='stock' and rootBankStock>0 then
            result.retainedBank[goal.item]=(result.retainedBank[goal.item] or 0)+rootBankStock
        end
    end
    result.complete = next(result.missing) == nil and #result.warnings == 0
    return result
end
function F.Planner.Build(profiles, item, quantity, inventory, now, options)
    options=options or {}
    local result=F.Planner.BuildQueue(profiles,{{item=item,quantity=quantity,owner=options.owner,recipeID=options.recipeID}},inventory,now,options)
    result.target,result.quantity=item,quantity
    return result
end
