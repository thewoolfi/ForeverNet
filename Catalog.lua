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
