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
function C.Recipes(profiles, query, choices)
    local entries, groups, filter = {}, {}, C.Fold(query)
    for _, owner in ipairs(F.Keys(profiles)) do
        for _, recipeID in ipairs(F.Keys(profiles[owner].recipes)) do
            local r = profiles[owner].recipes[recipeID]
            local name = C.ItemName(r.output, r.name)
            local searchable = C.Fold(name .. ' ' .. r.name .. ' ' .. owner .. ' ' .. r.output)
            local group=groups[r.output]
            if not group then group={providers={},matches=false}; groups[r.output]=group end
            group.providers[#group.providers+1]={key=owner..'/'..recipeID,owner=owner,recipeID=recipeID,recipe=r}
            group.matches=group.matches or filter=='' or searchable:find(filter,1,true)~=nil
        end
    end
    for item,group in pairs(groups) do
        if group.matches then
            table.sort(group.providers,function(a,b)
                if (a.owner==F.me)~=(b.owner==F.me) then return a.owner==F.me end
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
        if (a.owner == F.me) ~= (b.owner == F.me) then return a.owner == F.me end
        local an,bn=C.Fold(a.title),C.Fold(b.title)
        if an ~= bn then return an < bn end
        return a.key < b.key
    end)
    return entries
end

function C.ProfessionName(id)
    local numeric=tonumber(id:match('^skill:(%d+)$'))
    if numeric and C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillDisplayName then
        local ok,name=pcall(C_TradeSkillUI.GetTradeSkillDisplayName,numeric)
        if ok and name and name~='' then return name end
    end
    local hex=id:match('^legacy:[^:]+:([%da-f]+)$')
    if hex and #hex%2==0 then return (hex:gsub('..',function(pair) return string.char(tonumber(pair,16)) end)) end
    return id
end
