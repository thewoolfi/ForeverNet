local _, F = ...
F.Catalog = {}
local C = F.Catalog
local lowerRU = {}
local upper, lower = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ', 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
for i = 1, #upper, 2 do lowerRU[upper:sub(i,i+1)] = lower:sub(i,i+1) end
local latin={['À']='à',['Á']='á',['Â']='â',['Ã']='ã',['Ä']='ä',['Å']='å',['Æ']='æ',['Ç']='ç',
    ['È']='è',['É']='é',['Ê']='ê',['Ë']='ë',['Ì']='ì',['Í']='í',['Î']='î',['Ï']='ï',['Ð']='ð',
    ['Ñ']='ñ',['Ò']='ò',['Ó']='ó',['Ô']='ô',['Õ']='õ',['Ö']='ö',['Ø']='ø',['Ù']='ù',['Ú']='ú',
    ['Û']='û',['Ü']='ü',['Ý']='ý',['Þ']='þ',['Œ']='œ',['Ÿ']='ÿ',['ẞ']='ss',['ß']='ss'}
for from,to in pairs(latin) do lowerRU[from]=to end
function C.Fold(text)
    return ((text or ''):gsub('[A-Z]',function(c) return string.char(c:byte()+32) end):gsub('[\192-\255][\128-\191]*', function(c) return lowerRU[c] or c end))
end
function C.Safe(text) return (tostring(text or ''):gsub('|', '||')) end
function C.ItemName(id, fallback)
    local numeric = id and tonumber(id:match('^item:(%d+)$'))
    local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local name = numeric and getInfo and getInfo(numeric)
    if name then return name end
    if fallback then return fallback end
    for _, owner in ipairs(F.Keys(F.db.profiles)) do
        for _, recipeID in ipairs(F.Keys(F.db.profiles[owner].recipes)) do
            local r = F.db.profiles[owner].recipes[recipeID]
            if r.output == id then return r.name end
        end
    end
    return id or ''
end
function C.Icon(id)
    local numeric = id and tonumber(id:match('^item:(%d+)$'))
    return (numeric and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(numeric)) or
        (numeric and GetItemIcon and GetItemIcon(numeric)) or 'Interface\\Icons\\INV_Misc_Gear_01'
end
-- Crafting-material test. An item counts as a material when any known recipe,
-- our own or a peer's, lists it among its reagents. The answer describes the
-- recipes we know about, not the whole game, so the badge can only appear for
-- items the scanner has actually seen.
--
-- Results are cached per item. The cache key is recomputed on every call from the
-- number of stored profiles and F.recipeRevision, which is bumped wherever recipe
-- data changes. Catalog.lua is loaded before Core.lua creates F.db, so a cache
-- built at load time would otherwise stay empty forever; the self-check covers
-- that case as well as any missed invalidation call.
C.materialCache,C.materialCacheKey={},''
function C.InvalidateMaterials()
    C.materialCache={}
    F.recipeRevision=(F.recipeRevision or 0)+1
end
function C.MaterialCacheKey()
    local profiles=F.db and F.db.profiles
    if not profiles then return 'none' end
    return (F.recipeRevision or 0)..'/'..tostring(#F.Keys(profiles))
end
-- Crafting materials come from the client's own item data, not from what the player
-- has scanned. A brand-new install with no professions scanned must still mark every
-- trade good and reagent in the bags, so the rule below never depends on our
-- catalogue. Recipe data is only a last-resort extra signal.
C.TRADE_GOOD_CLASS=7
C.REAGENT_CLASS=5
-- Well-known materials, so common goods are marked even before the client has cached
-- their data. Kept short on purpose: the item class covers the rest.
C.KNOWN_MATERIALS={
    [2589]=true,[2590]=true,[2591]=true,[2592]=true,[4306]=true,[4338]=true,[14047]=true,[14256]=true,
    [774]=true,[818]=true,[1206]=true,[1210]=true,[1705]=true,[3864]=true,[5498]=true,[5500]=true,
    [2320]=true,[2321]=true,[4291]=true,[6260]=true,[14341]=true,[8343]=true,
    [2770]=true,[2771]=true,[2772]=true,[2775]=true,[2776]=true,[3858]=true,[3860]=true,[7911]=true,
    [2835]=true,[2836]=true,[2838]=true,[2840]=true,[2841]=true,[2842]=true,[3575]=true,[3576]=true,
    [12359]=true,[12360]=true,[12655]=true,[23445]=true,[23446]=true,[23447]=true,
    [4359]=true,[4360]=true,[4361]=true,[2840]=true,[2842]=true,[3577]=true,[6037]=true,
    [2318]=true,[2319]=true,[4231]=true,[4232]=true,[4233]=true,[4234]=true,[4235]=true,[4236]=true,
    [4237]=true,[4238]=true,[4239]=true,[4240]=true,[4241]=true,[4242]=true,[4243]=true,[4244]=true,
    [4245]=true,[4246]=true,[4247]=true,[4248]=true,[4249]=true,[4250]=true,[4251]=true,[4252]=true,
    [4253]=true,[4254]=true,[4255]=true,[4256]=true,[4257]=true,[4258]=true,[4259]=true,[4260]=true,
    [4261]=true,[4262]=true,[4263]=true,[4264]=true,[4265]=true,[4266]=true,[4267]=true,[4268]=true,
    [4269]=true,[4270]=true,[4271]=true,[4272]=true,[4273]=true,[4274]=true,[4275]=true,[4276]=true,
    [4277]=true,[4278]=true,[4279]=true,[4280]=true,[4281]=true,[4282]=true,[4283]=true,[4284]=true,
    [4285]=true,[4286]=true,[4287]=true,[4288]=true,[4289]=true,[4290]=true,[4292]=true,[4293]=true,
    [4294]=true,[4295]=true,[4296]=true,[4297]=true,[4298]=true,[4299]=true,[4300]=true,[4301]=true,
    [4302]=true,[4303]=true,[4304]=true,[4305]=true,[4307]=true,[4308]=true,[4309]=true,[4310]=true,
    [4311]=true,[4312]=true,[4313]=true,[4314]=true,[4315]=true,[4316]=true,[4317]=true,[4318]=true,
    [4319]=true,[4320]=true,[4321]=true,[4322]=true,[4323]=true,[4324]=true,[4325]=true,[4326]=true,
    [4327]=true,[4328]=true,[4329]=true,[4330]=true,[4331]=true,[4332]=true,[4333]=true,[4334]=true,
    [4335]=true,[4336]=true,[4337]=true,[4339]=true,[4340]=true,[4341]=true,[4342]=true,[4343]=true,
    [4344]=true,[4345]=true,[4346]=true,[4347]=true,[4348]=true,[4349]=true,[4350]=true,[4351]=true,
    [4352]=true,[4353]=true,[4354]=true,[4355]=true,[4356]=true,[4357]=true,[4358]=true,[4362]=true,
    [4363]=true,[4364]=true,[4365]=true,[4366]=true,[4367]=true,[4368]=true,[4369]=true,[4370]=true,
    [4371]=true,[4372]=true,[4373]=true,[4374]=true,[4375]=true,[4376]=true,[4377]=true,[4378]=true,
    [4379]=true,[4380]=true,[4381]=true,[4382]=true,[4383]=true,[4384]=true,[4385]=true,[4386]=true,
    [4387]=true,[4388]=true,[4389]=true,[4390]=true,[4391]=true,[4392]=true,[4393]=true,[4394]=true,
    [4395]=true,[4396]=true,[4397]=true,[4398]=true,[4399]=true,[4400]=true,[4401]=true,[4402]=true,
    [4403]=true,[4404]=true,[4405]=true,[4406]=true,[4407]=true,[4408]=true,[4409]=true,[4410]=true,
    [4470]=true,[4471]=true,[4472]=true,[4473]=true,[4474]=true,[4475]=true,[4476]=true,[4477]=true,
    [4478]=true,[4479]=true,[4480]=true,[4481]=true,[4482]=true,[4483]=true,[4484]=true,[4485]=true,
    [4486]=true,[4487]=true,[4488]=true,[4489]=true,[4490]=true,[4491]=true,[4492]=true,[4493]=true,
    [4494]=true,[4495]=true,[4496]=true,[4497]=true,[4498]=true,[4499]=true,[4500]=true,
    [6219]=true,[5956]=true,[2880]=true,[2901]=true,[3466]=true,[3859]=true,[3860]=true,
    [7067]=true,[7068]=true,[7069]=true,[7070]=true,[7071]=true,[7072]=true,[7073]=true,[7074]=true,
    [7075]=true,[7076]=true,[7077]=true,[7078]=true,[7079]=true,[7080]=true,[7081]=true,[7082]=true,
    [7909]=true,[7910]=true,[7971]=true,[7972]=true,[7973]=true,[7974]=true,
    [11370]=true,[11371]=true,[11382]=true,[11754]=true,[12361]=true,[12363]=true,[12364]=true,
    [12662]=true,[12799]=true,[12800]=true,[12808]=true,[12809]=true,[12810]=true,[12811]=true,
    [13463]=true,[13464]=true,[13465]=true,[13466]=true,[13467]=true,[13468]=true,
    [14227]=true,[15407]=true,[15408]=true,[15409]=true,[15410]=true,[15411]=true,[15412]=true,
    [15413]=true,[15414]=true,[15415]=true,[15416]=true,[15417]=true,
    [17010]=true,[17011]=true,[17012]=true,[17194]=true,[17195]=true,[17196]=true,[17197]=true,
    [17198]=true,[17202]=true,[17203]=true,[17204]=true,
    [18562]=true,[18567]=true,[18588]=true,[18590]=true,[18591]=true,
    [21752]=true,[21884]=true,[21885]=true,[21886]=true,[21887]=true,[22445]=true,[22446]=true,
    [22447]=true,[22448]=true,[22449]=true,[22450]=true,[22451]=true,[22452]=true,[22456]=true,
    [22457]=true,[22458]=true,[22459]=true,[22460]=true,[22461]=true,[22462]=true,[22463]=true,
    [23571]=true,[23572]=true,[23573]=true,[23574]=true,[23575]=true,[23576]=true,
    [23781]=true,[23782]=true,[23783]=true,[23784]=true,[23785]=true,[23786]=true,[23787]=true,
}
-- Positional capture cannot be used here: these client calls return nil in the middle
-- of the list, and a nil ends the list for positional assignment, so the class id
-- would be read from the wrong slot. select() with an explicit result is exact, and it
-- also distinguishes "no data yet" (false) from "not a number" (nil).
function C.ItemClassByInstant(id)
    local instant=C_Item and C_Item.GetItemInfoInstant
    if not instant then return nil end
    -- Called directly, never through pcall: this build of Lua truncates a pcall result
    -- to a single value, which silently produced nil for the class fields. The call is
    -- a plain field read on a numeric id, so it does not raise.
    local classID=select(6,instant(id))
    local subclassID=select(7,instant(id))
    if type(classID)=='number' then return classID,subclassID end
    return nil
end
function C.ItemClassByInfo(id)
    local get=C_Item and C_Item.GetItemInfo or GetItemInfo
    if not get then return nil end
    -- Reading through GetItemInfo also fills the client cache, so a later sweep
    -- succeeds even when this one does not.
    -- Same reasoning as above: read the positions straight from the call.
    local classID=select(12,get(id))
    local subclassID=select(13,get(id))
    if type(classID)=='number' then return classID,subclassID end
    return nil
end
function C.ItemClasses(id)
    local numeric=type(id)=='string' and tonumber(id:match('^item:(%d+)$'))
    if not numeric then return nil end
    local classID,subclassID=C.ItemClassByInstant(numeric)
    if classID then return classID,subclassID end
    return C.ItemClassByInfo(numeric)
end
-- True only for the item families a profession consumes as a reagent. The class is
-- necessary but not sufficient on its own: it also covers items nobody crafts with,
-- so the caller must have separate evidence before trusting this.
function C.IsReagentFamily(id)
    local classID,subclassID=C.ItemClasses(id)
    if classID==C.REAGENT_CLASS or classID==C.TRADE_GOOD_CLASS then return true end
    if classID~=nil and subclassID==C.TRADE_GOOD_CLASS then return true end
    return false
end
function C.ItemUsedForProfessions(id)
    return C.IsReagentFamily(id)
end
function C.KnownRecipeOutput(id)
    local profiles=F.db and F.db.profiles
    if not profiles then return false end
    for _,owner in ipairs(F.Keys(profiles)) do
        local recipes=profiles[owner].recipes
        if recipes then
            for _,recipeID in ipairs(F.Keys(recipes)) do
                local recipe=recipes[recipeID]
                if recipe.output==id then return true end
            end
        end
    end
    return false
end
function C.IsCraftMaterial(id)
    if type(id)~='string' or id:match('^item:%d+$')==nil then return false end
    local key=C.MaterialCacheKey()
    if key~=C.materialCacheKey then C.materialCache={}; C.materialCacheKey=key end
    local cached=C.materialCache[id]
    if cached~=nil then return cached end
    local numeric=tonumber(id:match('^item:(%d+)$'))
    local found=false
    -- 1. Any item belonging to trade goods or reagents family (covers all professions).
    if C.IsReagentFamily(id) then found=true end
    -- 2. bundled list of well-known materials, which also covers a player who has
    --    scanned nothing at all and whose client hasn't loaded item info yet.
    if not found and C.KNOWN_MATERIALS[numeric] then found=true end
    -- 3. a known recipe consumes it: covers non-trade goods that are reagents for specific crafts.
    if not found then
        local profiles=F.db and F.db.profiles
        if profiles then
            for _,owner in ipairs(F.Keys(profiles)) do
                local recipes=profiles[owner].recipes
                if recipes then
                    for _,recipeID in ipairs(F.Keys(recipes)) do
                        local recipe=recipes[recipeID]
                        if recipe.reagents and recipe.reagents[id] then found=true; break end
                    end
                end
                if found then break end
            end
        end
    end
    C.materialCache[id]=found
    return found
end
function C.Recipes(profiles, query, choices, options)
    local entries, groups, filter = {}, {}, C.Fold(query)
    for _, owner in ipairs(F.Keys(profiles)) do
        for _, recipeID in ipairs(F.Keys(profiles[owner].recipes)) do
            local r = profiles[owner].recipes[recipeID]
            local allowed=not options or ((not options.profession or r.profession==options.profession)
                and (not options.kind or (options.kind=='blueprint')==not not r.blueprint)
                and (not options.scope or (options.scope=='mine')==(owner==F.me)))
            if allowed then
                local name = C.ItemName(r.output, r.name)
                local searchable = C.Fold(name .. ' ' .. r.name .. ' ' .. owner .. ' ' .. r.output .. ' ' .. C.ProfessionName(r.profession))
                local group=groups[r.output]
                if not group then group={providers={},matches=false}; groups[r.output]=group end
                group.providers[#group.providers+1]={key=owner..'/'..recipeID,owner=owner,recipeID=recipeID,recipe=r}
                group.matches=group.matches or filter=='' or searchable:find(filter,1,true)~=nil
            end
        end
    end
    for item,group in pairs(groups) do
        if group.matches then
            table.sort(group.providers,function(a,b)
                if (a.owner==F.me)~=(b.owner==F.me) then return a.owner==F.me end
                local staleA,staleB=F.ProfileStale(profiles[a.owner]),F.ProfileStale(profiles[b.owner])
                if staleA~=staleB then return not staleA end
                return a.key<b.key
            end)
            local selected=group.providers[1]
            local owners={}
            for _,provider in ipairs(group.providers) do
                owners[provider.owner]=true
                if choices and choices[item]==provider.key then selected=provider end
            end
            local count=#F.Keys(owners)
            entries[#entries+1]={key='item/'..item,kind='recipe',owner=selected.owner,
                recipeID=selected.recipeID,recipe=selected.recipe,item=item,
                title=C.ItemName(item,selected.recipe.name),providers=group.providers,
                subtitle=count>1 and string.format(F.L('CRAFTER_COUNT'),count) or
                    (selected.owner==F.me and F.L('YOU') or selected.owner)}
        end
    end
    table.sort(entries, function(a,b)
        local favoriteA,favoriteB=F.IsFavorite('recipes',a.item),F.IsFavorite('recipes',b.item)
        if favoriteA~=favoriteB then return favoriteA end
        if (a.owner == F.me) ~= (b.owner == F.me) then return a.owner == F.me end
        local an,bn=C.Fold(a.title),C.Fold(b.title)
        if an ~= bn then return an < bn end
        return a.key < b.key
    end)
    return entries
end

local professionIDs={alchemy=171,blacksmithing=164,engineering=202,leatherworking=165,tailoring=197,
    enchanting=333,herbalism=182,mining=186,skinning=393,cooking=185,fishing=356,firstaid=129}
local professionIcons={[171]='Trade_Alchemy',[164]='Trade_BlackSmithing',[202]='Trade_Engineering',
    [165]='Trade_LeatherWorking',[197]='Trade_Tailoring',[333]='Trade_Engraving',[182]='Trade_Herbalism',
    [186]='Trade_Mining',[393]='INV_Misc_Pelt_Wolf_01',[185]='INV_Misc_Food_15',[356]='Trade_Fishing',
    [129]='Spell_Holy_SealOfSacrifice'}
function C.ProfessionName(id)
    local numeric=tonumber(id:match('^skill:(%d+)$')) or professionIDs[id]
    if numeric and C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillDisplayName then
        local ok,name=pcall(C_TradeSkillUI.GetTradeSkillDisplayName,numeric)
        if ok and name and name~='' then return name end
    end
    local hex=id:match('^legacy:[^:]+:([%da-f]+)$')
    if hex and #hex%2==0 then return (hex:gsub('..',function(pair) return string.char(tonumber(pair,16)) end)) end
    return id
end
function C.ProfessionIcon(id)
    local numeric=tonumber(id:match('^skill:(%d+)$')) or professionIDs[id]
    return 'Interface\\Icons\\'..(professionIcons[numeric] or 'INV_Scroll_03')
end
function C.ProfileProfessions(profile)
    local groups,entries={},{}
    local function group(id)
        if not groups[id] then
            groups[id]={id=id,title=C.ProfessionName(id),rank=profile.professions[id],recipes={}}
            entries[#entries+1]=groups[id]
        end
        return groups[id]
    end
    for id in pairs(profile.professions) do group(id) end
    for id,r in pairs(profile.recipes) do
        local g=group(r.profession)
        g.recipes[#g.recipes+1]={recipeID=id,recipe=r,title=C.ItemName(r.output,r.name),item=r.output}
    end
    for _,g in ipairs(entries) do
        table.sort(g.recipes,function(a,b)
            local an,bn=C.Fold(a.title),C.Fold(b.title)
            if an~=bn then return an<bn end
            return a.recipeID<b.recipeID
        end)
    end
    table.sort(entries,function(a,b)
        local an,bn=C.Fold(a.title),C.Fold(b.title)
        if an~=bn then return an<bn end
        return a.id<b.id
    end)
    return entries
end
function C.Crafters(profiles,item,query)
    local entries={}
    if not F.ID(item) then return entries end
    local filter=C.Fold(query)
    for _,owner in ipairs(F.Keys(profiles)) do
        if not F.IsSelf(owner) then
            local profile=profiles[owner]
            local matches,searchable,professions={},{owner},{}
            for _,recipeID in ipairs(F.Keys(profile.recipes)) do
                local recipe=profile.recipes[recipeID]
                if recipe.output==item then
                    matches[#matches+1]={recipeID=recipeID,recipe=recipe}
                    if filter~='' then
                        searchable[#searchable+1]=recipe.name
                        professions[recipe.profession]=true
                    end
                end
            end
            for _,profession in ipairs(F.Keys(professions)) do searchable[#searchable+1]=C.ProfessionName(profession) end
            if #matches>0 and (filter=='' or C.Fold(table.concat(searchable,' ')):find(filter,1,true)) then
                entries[#entries+1]={key=owner,kind='crafter',owner=owner,title=owner,profile=profile,recipes=matches,
                    subtitle=string.format(F.L('RECIPE_COUNT'),#matches)..(F.ProfileStale(profile) and '\n'..F.L('PROFILE_CACHED') or '')}
            end
        end
    end
    table.sort(entries,function(a,b)
        local favoriteA,favoriteB=F.IsFavorite('profiles',a.owner),F.IsFavorite('profiles',b.owner)
        if favoriteA~=favoriteB then return favoriteA end
        local staleA,staleB=F.ProfileStale(a.profile),F.ProfileStale(b.profile)
        if staleA~=staleB then return not staleA end
        local an,bn=C.Fold(a.owner),C.Fold(b.owner)
        if an~=bn then return an<bn end
        return a.owner<b.owner
    end)
    return entries
end
function C.GroupRecipes(entries)
    local groups,result={},{}
    for _,entry in ipairs(entries) do
        local id=entry.recipe.profession
        if not groups[id] then
            groups[id]={id=id,title=C.ProfessionName(id),recipes={}}
            result[#result+1]=groups[id]
        end
        groups[id].recipes[#groups[id].recipes+1]=entry
    end
    table.sort(result,function(a,b)
        local an,bn=C.Fold(a.title),C.Fold(b.title)
        if an~=bn then return an<bn end
        return a.id<b.id
    end)
    return result
end
