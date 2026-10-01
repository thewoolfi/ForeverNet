local _, F = ...
F.Net = {prefix = 'ForeverNet1', queue = {}, buffers = {}, rates = {}, serial = 0, elapsed = 0, hello = {}}
local N = F.Net
function N.Channel()
    if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return nil end
    if IsInRaid and IsInRaid() then return 'RAID' end
    if IsInGroup and IsInGroup() then return 'PARTY' end
    if IsInGuild and IsInGuild() then return 'GUILD' end
end
function N.Send(kind, value, channel)
    if not F.db.settings.sharing then return false, F.L('Обмен выключен: /fn share on') end
    if not N.available then return false, F.L('API обмена недоступен.') end
    channel = channel or N.Channel()
    if not channel then return false, F.L('Для обмена нужна гильдия или обычная группа.') end
    local ok, payload = pcall(F.Codec.Encode, {kind = kind, data = value})
    if not ok then return false, F.L('Сообщение превышает ограничения.') end
    local total = math.ceil(#payload / 200)
    if #N.queue + total > 1000 then return false, F.L('Очередь заполнена; повторите позже.') end
    N.serial = N.serial + 1
    local token = F.Now() .. '.' .. N.serial
    for i = 1, total do
        N.queue[#N.queue + 1] = {channel = channel, text = '1|' .. token .. '|' .. i .. '|' .. total .. '|' .. payload:sub((i - 1) * 200 + 1, i * 200)}
    end
    return true
end
function N.Publish(channel) return N.Send('PROFILE', F.localProfile, channel) end
function N.Start()
    local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    N.available = register and register(N.prefix)
end
function N.Tick(elapsed)
    N.elapsed = N.elapsed + elapsed
    if N.elapsed < .25 then return end
    N.elapsed = 0
    local now = F.Now()
    for key, buffer in pairs(N.buffers) do if now - buffer.created > 150 then N.buffers[key] = nil end end
    for sender, rate in pairs(N.rates) do if now - rate.start > 150 then N.rates[sender] = nil end end
    for sender, at in pairs(N.hello) do if now - at > 150 then N.hello[sender] = nil end end
    if not F.db.settings.sharing then N.queue = {}; return end
    local msg = table.remove(N.queue, 1)
    local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if msg and send and N.available then
        local ok = pcall(send, N.prefix, msg.text, msg.channel)
        if not ok then F.Print(F.L('Не удалось отправить сообщение. Повторите /fn sync.')); N.queue = {} end
    end
end
function N.Receive(prefix, text, channel, sender)
    if prefix ~= N.prefix or not F.db.settings.sharing or type(text) ~= 'string' or #text > 250 then return end
    if channel ~= 'GUILD' and channel ~= 'PARTY' and channel ~= 'RAID' then return end
    sender = F.Identity(sender); if sender == F.me then return end
    local now = F.Now()
    local rate = N.rates[sender]
    if not rate then
        if #F.Keys(N.rates) >= 100 then return end
        rate = {start = now, count = 0}; N.rates[sender] = rate
    end
    if now - rate.start >= 30 then rate.start, rate.count = now, 0 end
    rate.count = rate.count + 1; if rate.count > 300 then return end
    local token, index, total, chunk = text:match('^1|([%d%.]+)|(%d+)|(%d+)|(.*)$')
    index, total = tonumber(index), tonumber(total)
    if not token or #token > 30 or not F.Integer(total, 1, 480) or not F.Integer(index, 1, total) or #chunk > 200 then return end
    local key = sender .. ':' .. channel .. ':' .. token
    local buffer = N.buffers[key]
    if not buffer then
        if #F.Keys(N.buffers) >= 16 then return end
        buffer = {total = total, chunks = {}, count = 0, created = now}; N.buffers[key] = buffer
    end
    if buffer.total ~= total then N.buffers[key] = nil; return end
    if not buffer.chunks[index] then buffer.chunks[index] = chunk; buffer.count = buffer.count + 1 end
    if buffer.count ~= total then return end
    N.buffers[key] = nil
    local message = F.Codec.Decode(table.concat(buffer.chunks))
    if type(message) ~= 'table' then return end
    if message.kind == 'PROFILE' and F.ValidProfile(message.data) then
        local previous = F.db.profiles[sender]
        F.Prune()
        if not previous and #F.Keys(F.db.profiles) >= 100 then return end
        if previous and previous.rev > message.data.rev then return end
        message.data.seen = now; F.db.profiles[sender] = message.data; F.UI.DataChanged()
    elseif message.kind == 'HELLO' then
        if not N.hello[sender] or now - N.hello[sender] >= 30 then
            N.hello[sender] = now
            C_Timer.After(math.random() * 3, function() N.Publish(channel) end)
        end
    elseif message.kind == 'REQUEST' or message.kind == 'OFFER' then
        F.Requests.Receive(message.kind, message.data, sender, channel)
    end
end
