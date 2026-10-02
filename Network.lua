local _, F = ...
F.Net = {prefix='ForeverNet1', queue={}, buffers={}, rates={}, serial=0, elapsed=0, hello={}, followupProfiles={}, stats={sent=0,received=0}}
local N=F.Net
function N.AutoEnabled() return F.db.settings.autoSync~=false end
function N.Interval()
    local seconds=F.db.settings.syncInterval
    return (seconds==60 or seconds==120 or seconds==300) and seconds or 120
end
function N.ProfileChanged()
    if F.db.settings.sharing and N.AutoEnabled() then N.pendingPublish=.5 end
end
local function homeCategory()
    return (Enum and Enum.PartyCategory and Enum.PartyCategory.Home) or LE_PARTY_CATEGORY_HOME or 1
end
function N.Channel()
    -- Never call IsInGroup(nil): a removed legacy constant would test the current
    -- ordinary party and incorrectly reject it as an instance group.
    local home=homeCategory()
    if IsInRaid and IsInRaid(home) then return 'RAID' end
    if IsInGroup and IsInGroup(home) then return 'PARTY' end
    if IsInGuild and IsInGuild() then return 'GUILD' end
end
function N.ChannelAvailable(channel)
    local home=homeCategory()
    if channel=='GUILD' then return IsInGuild and IsInGuild() end
    if channel=='RAID' then return IsInRaid and IsInRaid(home) end
    if channel=='PARTY' then return IsInGroup and IsInGroup(home) and not (IsInRaid and IsInRaid(home)) end
    return false
end
function N.Error(reason)
    N.lastError=reason; F.UI.DataChanged(); F.Print(reason)
end
function N.Send(kind,value,channel)
    if not F.db.settings.sharing then return false,F.L('Обмен выключен: /fn share on') end
    if not N.available then return false,F.L('API обмена недоступен.') end
    channel=channel or N.Channel()
    if not channel then return false,F.L('Для обмена нужна гильдия или обычная группа.') end
    local ok,payload=pcall(F.Codec.Encode,{kind=kind,data=value})
    if not ok then return false,F.L('Сообщение превышает ограничения.') end
    local total=math.ceil(#payload/200)
    if #N.queue+total>1000 then return false,F.L('Очередь заполнена; повторите позже.') end
    N.serial=N.serial+1
    local token=F.Now()..'.'..N.serial
    local urgent=kind=='REQUEST' or kind=='OFFER' or kind=='HELLO'
    local position=1
    if urgent then
        while N.queue[position] and N.queue[position].urgent do position=position+1 end
    end
    for i=1,total do
        local msg={channel=channel,urgent=urgent,kind=kind,profileRev=kind=='PROFILE' and value.rev or nil,
            text='1|'..token..'|'..i..'|'..total..'|'..payload:sub((i-1)*200+1,i*200)}
        if urgent then table.insert(N.queue,position,msg); position=position+1 else N.queue[#N.queue+1]=msg end
    end
    return true
end
function N.Publish(channel)
    channel=channel or N.Channel()
    -- Complete a profile already in flight; do not queue identical snapshots
    -- for every HELLO in a group. Send a newer revision once this one finishes.
    for _,msg in ipairs(N.queue) do
        if msg.kind=='PROFILE' and msg.channel==channel then
            if msg.profileRev~=F.localProfile.rev then N.followupProfiles[channel]=true end
            return true
        end
    end
    local ok,why=N.Send('PROFILE',F.localProfile,channel)
    if ok then N.pendingPublish=nil; if channel then N.followupProfiles[channel]=nil end end
    return ok,why
end
function N.Snapshot(channel)
    -- A late arrival needs requests as well as profession capabilities.
    F.Prune()
    for _,id in ipairs(F.Keys(F.db.requests)) do
        local r=F.db.requests[id]
        if r.owner==F.me and r.expires>F.Now() and r.channel==channel then
            local ok,why=N.Send('REQUEST',r,channel); if not ok then return false,why end
        end
    end
    return N.Publish(channel)
end
function N.Sync(channel)
    N.autoElapsed=0
    channel=channel or N.Channel()
    local ok,why=N.Send('HELLO',{},channel); if not ok then return false,why end
    return N.Snapshot(channel)
end
function N.ScheduleSync()
    if F.db.settings.sharing and N.AutoEnabled() then N.pendingSync=.5 end
end
function N.Start()
    local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    local ok,result=false,nil
    if register then ok,result=pcall(register,N.prefix) end
    local codes=Enum and Enum.RegisterAddonMessagePrefixResult
    N.available=ok and (result==true or type(result)=='number' and
        (result==(codes and codes.Success or 0) or result==(codes and codes.DuplicatePrefix or 1)))
end
local function sendAccepted(result)
    -- Modern APIs return an enum (Success=0), older APIs true or nil.
    return result==nil or result==true or result==((Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success) or 0)
end
function N.Tick(elapsed)
    local channel=N.Channel()
    local automatic=N.AutoEnabled()
    if N.sharingState~=F.db.settings.sharing or N.activeChannel~=channel or N.autoState~=automatic then
        N.sharingState,N.activeChannel,N.autoState=F.db.settings.sharing,channel,automatic
        N.autoElapsed=0
        if F.db.settings.sharing and channel then N.ScheduleSync() end
    end
    if not F.db.settings.sharing then
        N.queue,N.buffers,N.followupProfiles,N.pendingSync,N.pendingPublish,N.autoElapsed={},{},{},nil,nil,0; return
    end
    if not automatic then N.pendingSync,N.pendingPublish,N.autoElapsed=nil,nil,0
    elseif channel and N.available then
        N.autoElapsed=(N.autoElapsed or 0)+elapsed
        if N.autoElapsed>=N.Interval() and not N.pendingSync then N.pendingSync=0 end
    end
    if N.pendingSync then
        N.pendingSync=N.pendingSync-elapsed
        if N.pendingSync<=0 and #N.queue==0 then
            N.pendingSync=nil
            if channel and N.available then
                local ok,why=N.Sync(channel); if not ok then N.Error(why) end
            end
        end
    end
    if N.pendingPublish then
        N.pendingPublish=N.pendingPublish-elapsed
        if N.pendingPublish<=0 and #N.queue==0 then
            N.pendingPublish=nil
            if automatic and channel and N.available then
                local ok,why=N.Publish(channel); if not ok then N.Error(why) end
            end
        end
    end
    if #N.queue==0 then
        for _,originalChannel in ipairs(F.Keys(N.followupProfiles)) do
            N.followupProfiles[originalChannel]=nil
            if N.ChannelAvailable(originalChannel) and N.available then
                local ok,why=N.Publish(originalChannel); if not ok then N.Error(why) end
                break
            end
        end
    end
    N.elapsed=N.elapsed+elapsed
    if N.elapsed<.25 then return end
    N.elapsed=0
    local now=F.Now()
    for key,b in pairs(N.buffers) do if now-b.created>150 then N.buffers[key]=nil end end
    for sender,rate in pairs(N.rates) do if now-rate.start>150 then N.rates[sender]=nil end end
    for sender,at in pairs(N.hello) do if now-at>150 then N.hello[sender]=nil end end
    local msg=N.queue[1]
    if not msg then return end
    if not N.ChannelAvailable(msg.channel) then
        -- Stale channels after a party/guild change must not silently eat messages.
        local remaining={}; for _,queued in ipairs(N.queue) do if queued.channel~=msg.channel then remaining[#remaining+1]=queued end end
        N.queue=remaining; N.Error(F.L('NET_CHANNEL_LOST')); return
    end
    local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not send or not N.available then return end
    local ok,result=pcall(send,N.prefix,msg.text,msg.channel)
    if ok and sendAccepted(result) then
        table.remove(N.queue,1); N.stats.sent=N.stats.sent+1; N.lastError=nil
    else
        local codes=Enum and Enum.SendAddonMessageResult
        local throttle=ok and (result==(codes and codes.AddonMessageThrottle or 3) or result==(codes and codes.ChannelThrottle or 8))
        if throttle then
            msg.retries=(msg.retries or 0)+1
            if msg.retries<=20 then N.elapsed=-.75; return end
        end
        N.queue={}; N.Error(F.L('NET_SEND_FAILED')..' ('..tostring(ok and result or 'API')..')')
    end
end

function N.Receive(prefix, text, channel, sender)
    if prefix ~= N.prefix or not F.db.settings.sharing or type(text) ~= 'string' or #text > 250 then return end
    if channel ~= 'GUILD' and channel ~= 'PARTY' and channel ~= 'RAID' then return end
    if type(sender)~='string' or sender=='' then return end
    N.stats.received=N.stats.received+1
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
            C_Timer.After(math.random() * 3, function()
                if F.db.settings.sharing and N.ChannelAvailable(channel) then
                    local ok,why=N.Snapshot(channel); if not ok then N.Error(why) end
                end
            end)
        end
    elseif message.kind == 'REQUEST' or message.kind == 'OFFER' then
        F.Requests.Receive(message.kind, message.data, sender, channel)
    end
end
