local addonName, F = ...
_G.ForeverNet = F
F.name, F.version = addonName, '0.3.3'
F.MAX_RECIPES, F.PEER_TTL = 1000, 1800
function F.Now() return time() end
local function compact(name) return (name:gsub('%s','')) end
local function identityKey(name) return F.Catalog.Fold(compact(name)) end
local function localRealm()
    local realm=GetNormalizedRealmName and GetNormalizedRealmName()
    return realm and realm~='' and realm or GetRealmName()
end
local function surnameAPI()
    return UnitNameUnmodified and ((NameUtil and NameUtil.GetUnmodifiedUnitFullName) or
        (Constants and Constants.CharacterNameSeparatorConsts))
end
function F.UnitIdentity(unit)
    if surnameAPI() then
        local first,surname=UnitNameUnmodified(unit)
        if not first or first=='' then return end
        return compact(surname and surname~='' and first..'-'..surname or first)
    end
    local name,realm=UnitFullName(unit)
    if not name or name=='' then return end
    return compact(name..'-'..(realm and realm~='' and realm or localRealm()))
end
local function rememberAlias(alias,identity)
    if alias and alias~='' then F.identityAliases[identityKey(alias)]=identity end
end
local function nameAliases(name,identity,realms,bare)
    local forms={name,compact(name),(name:gsub('[%s%-]','')),(name:gsub('%s','-'))}
    for _,form in ipairs(forms) do
        if bare then rememberAlias(form,identity); rememberAlias(form..'-',identity) end
        for _,realm in ipairs(realms) do rememberAlias(form..'-'..realm,identity) end
    end
end
function F.RefreshIdentityAliases()
    F.identityAliases={}
    F.realmAliases={GetRealmName(),localRealm()}
    local function unitAliases(unit)
        local canonical=F.UnitIdentity(unit); if not canonical then return end
        rememberAlias(canonical,canonical)
        if surnameAPI() then
            local first,surname=UnitNameUnmodified(unit)
            local full=surname and surname~='' and first..'-'..surname or first
            nameAliases(full,canonical,F.realmAliases,true)
            local oldName,oldRealm=UnitFullName(unit)
            if oldName then rememberAlias(oldName..'-'..(oldRealm or GetRealmName()),canonical) end
        else
            local name,realm=UnitFullName(unit)
            local realms={realm and realm~='' and realm or localRealm()}
            local bare=identityKey(realms[1])==identityKey(localRealm())
            if bare then realms=F.realmAliases end
            nameAliases(name,canonical,realms,bare)
        end
    end
    unitAliases('player')
    local home=(Enum and Enum.PartyCategory and Enum.PartyCategory.Home) or LE_PARTY_CATEGORY_HOME or 1
    local raid=IsInRaid and IsInRaid(home)
    local count=GetNumGroupMembers and GetNumGroupMembers(home) or 0
    for i=1,count do unitAliases((raid and 'raid' or 'party')..i) end
end
function F.Identity(name,learn)
    if not name then return F.UnitIdentity('player') end
    local known=F.identityAliases and F.identityAliases[identityKey(name)]
    if known then return known end
    name=compact(name)
    if surnameAPI() then
        -- Forever uses the hyphen between first name and surname, rather than
        -- treating every hyphen as the start of a realm suffix.
        for _,realm in ipairs(F.realmAliases or {}) do
            local ending='-'..compact(realm)
            if identityKey(name:sub(-#ending))==identityKey(ending) then name=name:sub(1,-#ending-1); break end
        end
        local first,surname=name:match('^([^-]+)%-(.+)$')
        if first and surname and learn~=false then nameAliases(name,name,F.realmAliases or {},true) end
        return name
    end
    if not name:find('-',1,true) then name=name..'-'..compact(localRealm()) end
    return name
end
function F.ResolveSender(sender,claimed)
    if not F.Text(claimed) then return end
    local actual,candidate=F.Identity(sender,false),F.Identity(claimed,false)
    if actual==candidate then return actual end
    -- Only Forever's authenticated compact chat name may teach a surname
    -- boundary. Reject unrelated claims before adding any new aliases.
    if surnameAPI() and identityKey(actual:gsub('-',''))==identityKey(candidate:gsub('-','')) then
        local canonical=candidate:find('-',1,true) and candidate or actual
        nameAliases(canonical,canonical,F.realmAliases or {},true)
        return canonical
    end
end
function F.IsSelf(name) return type(name)=='string' and F.Identity(name)==F.me end
function F.Copy(t)
    if type(t) ~= 'table' then return t end
    local out = {}; for k, v in pairs(t) do out[k] = F.Copy(v) end; return out
end
function F.Keys(t)
    local keys = {}; for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys); return keys
end
function F.Print(s)
    DEFAULT_CHAT_FRAME:AddMessage('|cff54d8c7ForeverNet:|r ' .. tostring(s):gsub('|', '||'))
end
function F.Init()
    ForeverNetDB = ForeverNetDB or {schema = 1, profiles = {}, requests = {}, settings = {sharing = false}}
    if ForeverNetDB.schema ~= 1 then F.Print(F.L('Неизвестная версия базы; загрузка остановлена.')); return false end
    F.db = ForeverNetDB
    F.db.profiles, F.db.requests = F.db.profiles or {}, F.db.requests or {}
    F.db.settings = F.db.settings or {sharing = false}
    F.me = F.Identity()
    F.RefreshIdentityAliases()
    F.db.profiles[F.me] = F.db.profiles[F.me] or F.NewProfile()
    F.localProfile = F.db.profiles[F.me]
    F.CleanSelfAliases()
    F.localProfile.seen = F.Now()
    return true
end
function F.CleanSelfAliases()
    for _,owner in ipairs(F.Keys(F.db.profiles)) do
        if owner~=F.me and F.IsSelf(owner) then
            local old=F.db.profiles[owner]
            if F.ValidProfile(old) then
                for _,field in ipairs({'professions','recipes','camps'}) do
                    for key,value in pairs(old[field]) do
                        if F.localProfile[field][key]==nil then F.localProfile[field][key]=F.Copy(value) end
                    end
                end
                F.localProfile.rev=math.max(F.localProfile.rev,old.rev)
            end
            F.db.profiles[owner]=nil
        end
    end
    for _,owner in ipairs(F.Keys(F.db.banks or {})) do
        if owner~=F.me and F.IsSelf(owner) then
            local saved=F.db.banks[owner]
            if not F.db.banks[F.me] or (saved.seen or 0)>(F.db.banks[F.me].seen or 0) then F.db.banks[F.me]=saved end
            F.db.banks[owner]=nil
        end
    end
    for _,r in pairs(F.db.requests) do
        if F.IsSelf(r.owner) then r.owner=F.me end
        if r.assignee~='' and F.IsSelf(r.assignee) then r.assignee=F.me end
    end
end
function F.Touch()
    F.localProfile.rev = F.localProfile.rev + 1
    F.localProfile.seen = F.Now()
    if F.Net then F.Net.ProfileChanged() end
end
