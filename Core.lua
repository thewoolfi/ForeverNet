local addonName, F = ...
_G.ForeverNet = F
F.name, F.version = addonName, '0.3.3'
F.MAX_RECIPES, F.PEER_TTL = 1000, 1800
function F.Now() return time() end
function F.Identity(name)
    if not name then
        local n, r = UnitFullName('player')
        name = n .. '-' .. (r or GetRealmName())
    elseif not name:find('-', 1, true) then
        name = name .. '-' .. GetRealmName()
    end
    return (name:gsub('%s', ''))
end
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
    F.db.profiles[F.me] = F.db.profiles[F.me] or F.NewProfile()
    F.localProfile = F.db.profiles[F.me]
    F.localProfile.seen = F.Now()
    return true
end
function F.Touch()
    F.localProfile.rev = F.localProfile.rev + 1
    F.localProfile.seen = F.Now()
end
