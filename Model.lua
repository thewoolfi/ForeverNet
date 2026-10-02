local _, F = ...
function F.NewProfile() return {rev = 0, seen = F.Now(), professions = {}, recipes = {}, camps = {}} end
function F.Integer(n, low, high)
    return type(n) == 'number' and n == math.floor(n) and n >= low and n <= high
end
function F.ID(s) return type(s) == 'string' and #s > 0 and #s <= 100 and s:match('^[%w_:%.%-]+$') ~= nil end
function F.Text(s) return type(s) == 'string' and #s <= 160 and not s:find('[%c|]') end
function F.ValidProfile(p)
    if type(p) ~= 'table' or not F.Integer(p.rev, 0, 2147483647) then return false end
    if type(p.professions) ~= 'table' or type(p.recipes) ~= 'table' or type(p.camps) ~= 'table' then return false end
    local n = 0
    for id, rank in pairs(p.professions) do
        n = n + 1; if n > 20 or not F.ID(id) or not F.Integer(rank, 0, 1000) then return false end
    end
    n = 0
    for id, r in pairs(p.recipes) do
        n = n + 1
        if n > F.MAX_RECIPES or not F.ID(id) or type(r) ~= 'table' or not F.Text(r.name) or
            not F.ID(r.output) or not F.Integer(r.quantity, 1, 1000) or not F.ID(r.profession) or
            type(r.blueprint) ~= 'boolean' or type(r.reagents) ~= 'table' or type(r.stations) ~= 'table' then return false end
        local count = 0
        for item, qty in pairs(r.reagents) do
            count = count + 1; if count > 30 or not F.ID(item) or not F.Integer(qty, 1, 10000) then return false end
        end
        count = 0
        for station, required in pairs(r.stations) do
            count = count + 1; if count > 10 or not F.ID(station) or required ~= true then return false end
        end
    end
    n = 0
    for id, ready in pairs(p.camps) do
        n = n + 1; if n > 50 or not F.ID(id) or not F.Integer(ready, 0, 2147483647) then return false end
    end
    return true
end
function F.Prune()
    F.CleanSelfAliases()
    -- Normalize known roster aliases before building the shared catalog.
    for _,owner in ipairs(F.Keys(F.db.profiles)) do
        local canonical=F.Identity(owner)
        if owner~=canonical and canonical~=F.me then
            local old,current=F.db.profiles[owner],F.db.profiles[canonical]
            if not current or old.rev>current.rev or (old.rev==current.rev and (old.seen or 0)>(current.seen or 0)) then
                F.db.profiles[canonical]=old
            end
            F.db.profiles[owner]=nil
        end
    end
    local now = F.Now()
    for owner, p in pairs(F.db.profiles) do
        if owner ~= F.me and now - (p.seen or 0) > F.PEER_TTL then F.db.profiles[owner] = nil end
    end
    for id, r in pairs(F.db.requests) do
        if r.expires <= now then F.db.requests[id] = nil
        else
            if type(r.owner)=='string' then r.owner=F.Identity(r.owner) end
            if type(r.assignee)=='string' and r.assignee~='' then r.assignee=F.Identity(r.assignee) end
        end
    end
end
function F.Profiles()
    F.Prune(); return F.db.profiles
end
-- Directed graph: player -> profession/recipe/camp; recipe -> output/reagent/station.
function F.SkillGraph(profiles)
    local graph = {nodes = {}, edges = {}}
    local function edge(a, b, kind)
        graph.nodes[a], graph.nodes[b] = true, true
        graph.edges[#graph.edges + 1] = {from = a, to = b, kind = kind}
    end
    for _, owner in ipairs(F.Keys(profiles)) do
        local p = profiles[owner]
        for _, id in ipairs(F.Keys(p.professions)) do edge('player:' .. owner, 'profession:' .. id, 'practices') end
        for _, id in ipairs(F.Keys(p.camps)) do edge('player:' .. owner, 'camp:' .. id, 'provides') end
        for _, id in ipairs(F.Keys(p.recipes)) do
            local r, node = p.recipes[id], 'recipe:' .. owner .. ':' .. id
            edge('player:' .. owner, node, r.blueprint and 'blueprint' or 'knows')
            edge(node, 'item:' .. r.output, 'produces')
            for _, item in ipairs(F.Keys(r.reagents)) do edge(node, 'item:' .. item, 'requires') end
            for _, station in ipairs(F.Keys(r.stations)) do edge(node, 'camp:' .. station, 'needs') end
        end
    end
    return graph
end
