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
function N.Diagnostics()
    local lines={F.L('NETWORK_CHANNEL')..(N.Channel() and F.L('CHANNEL_'..N.Channel()) or F.L('NETWORK_NO_CHANNEL'))}
    lines[#lines+1]='Paused = '..tostring(N.paused==true)..' / Retry wait = '..math.ceil(math.max(0,(N.sendInterval or .25)-N.elapsed))..'s'
    lines[#lines+1]='Throttled = '..tostring(N.throttled==true)..' / Send interval = '..(N.sendInterval or .25)..'s / Throttle results = '..(N.stats.throttles or 0)
    lines[#lines+1]='Lockdown results = '..(N.stats.lockdowns or 0)..' / Transfer restarts = '..(N.stats.restarts or 0)
    lines[#lines+1]='Last accepted message = '..(N.lastSuccessAt and math.max(0,F.Now()-N.lastSuccessAt)..'s ago' or 'none')
    for _,key in ipairs({'AreOutgoingAddonChatMessagesRestricted','InChatMessagingLockdown'}) do
        local fn=C_ChatInfo and C_ChatInfo[key]
        local ok,value=false,nil
        if fn then ok,value=pcall(fn) end
        lines[#lines+1]='C_ChatInfo.'..key..' = '..(ok and tostring(value) or 'unavailable')
    end
    lines[#lines+1]='InCombatLockdown = '..tostring(InCombatLockdown and InCombatLockdown() or false)
    lines[#lines+1]='SendAddonMessage result = '..tostring(N.lastSendResult or 'none')
    lines[#lines+1]='Queued fragments = '..#N.queue
    for _,line in ipairs(lines) do F.Print(line) end
end
local function pause()
    local now=F.Now()
    N.throttled=nil; N.throttleDelay=nil
    N.stats.lockdowns=(N.stats.lockdowns or 0)+1; N.lastLockdownAt=now
    if not N.paused then N.paused=true; N.lastError=F.L('NET_LOCKDOWN'); F.UI.DataChanged() end
    if not N.lockdownEpisode then
        N.lockdownEpisode=true
        if not N.lastLockdownNotice or now-N.lastLockdownNotice>=120 then
            N.lastLockdownNotice=now; F.Print(F.L('NET_LOCKDOWN'))
        end
    end
    N.lockdownDelay=math.min(30,(N.lockdownDelay or 1)*2)
    N.elapsed=(N.sendInterval or .25)-N.lockdownDelay
end
local function refreshTransfer(msg,now)
    local transfer=msg.transfer
    -- Brief interruptions keep their token and progress. Only an expired
    -- partial message needs a full restart before the next send attempt.
    if not transfer or not transfer.started or
        (now-(transfer.lastSent or transfer.started)<120 and now-transfer.started<840) then return msg end
    N.serial=N.serial+1
    local token,queue=now..'.'..N.serial,{}
    for i,part in ipairs(transfer.parts) do
        queue[#queue+1]={channel=msg.channel,urgent=msg.urgent,kind=msg.kind,profileRev=msg.profileRev,
            transfer=transfer,text='1|'..token..'|'..i..'|'..#transfer.parts..'|'..part}
    end
    for _,pending in ipairs(N.queue) do if pending.transfer~=transfer then queue[#queue+1]=pending end end
    transfer.started=nil; transfer.lastSent=nil
    N.queue=queue; N.stats.restarts=(N.stats.restarts or 0)+1
    return queue[1]
end
function N.Send(kind,value,channel)
    if not F.db.settings.sharing then return false,F.L('Обмен выключен: /fn share on') end
    if not N.available then return false,F.L('API обмена недоступен.') end
    channel=channel or N.Channel()
    if not channel then return false,F.L('Для обмена нужна гильдия или обычная группа.') end
    local ok,payload=pcall(F.Codec.Encode,{kind=kind,data=value})
    if not ok then return false,F.L('Сообщение превышает ограничения.') end
    if kind=='HELLO' or kind=='REQUEST' then
        for _,msg in ipairs(N.queue) do
            if msg.kind==kind and msg.channel==channel and msg.transfer and msg.transfer.payload==payload then return true end
        end
    end
    local total=math.ceil(#payload/200)
    if #N.queue+total>1000 then return false,F.L('Очередь заполнена; повторите позже.') end
    N.serial=N.serial+1
    local token=F.Now()..'.'..N.serial
    local urgent=kind=='REQUEST' or kind=='OFFER' or kind=='HELLO'
    local position=1
    if urgent then
        while N.queue[position] and N.queue[position].urgent do position=position+1 end
    end
    local transfer={parts={},payload=(kind=='HELLO' or kind=='REQUEST') and payload or nil}
    for i=1,total do transfer.parts[i]=payload:sub((i-1)*200+1,i*200) end
    for i=1,total do
        local msg={channel=channel,urgent=urgent,kind=kind,profileRev=kind=='PROFILE' and value.rev or nil,
            transfer=transfer,text='1|'..token..'|'..i..'|'..total..'|'..transfer.parts[i]}
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
    local profile=F.Copy(F.localProfile); profile.addonVersion=F.version; profile.characterName=F.me
    local ok,why=N.Send('PROFILE',profile,channel)
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
    local ok,why=N.Send('HELLO',{version=F.version},channel); if not ok then return false,why end
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
        N.queue,N.buffers,N.followupProfiles,N.pendingSync,N.pendingPublish,N.autoElapsed={},{},{},nil,nil,0
        N.paused=nil; N.lockdownEpisode=nil; N.lockdownDelay=nil; N.lastError=nil; N.elapsed=0
        N.throttled=nil; N.throttleDelay=nil; N.sendInterval=nil; N.pacedSuccesses=nil; N.pacingStableSince=nil; return
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
        if #N.queue==0 then
            N.paused=nil; N.lockdownEpisode=nil; N.lockdownDelay=nil; N.throttled=nil; N.throttleDelay=nil
        end
    end
    N.elapsed=N.elapsed+elapsed
    if N.elapsed<(N.sendInterval or .25) then return end
    N.elapsed=0
    local now=F.Now()
    for key,b in pairs(N.buffers) do
        if now-(b.updated or b.created)>150 or now-b.created>900 then N.buffers[key]=nil end
    end
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
    -- Outgoing CHAT restrictions are not an authoritative gate for addon
    -- comms. Use the SendAddonMessage result, as ChatThrottleLib does.
    msg=refreshTransfer(msg,now)
    local ok,result=pcall(send,N.prefix,msg.text,msg.channel)
    N.lastSendResult=ok and result or 'API exception'
    if ok and sendAccepted(result) then
        local wasPaused=N.paused or N.throttled
        N.paused=nil; N.lockdownDelay=nil; N.lastError=nil; N.lastSuccessAt=now
        N.throttled=nil; N.throttleDelay=nil
        N.pacedSuccesses=(N.pacedSuccesses or 0)+1
        if (N.sendInterval or .25)>.25 and N.pacingStableSince and now-N.pacingStableSince>=60 and N.pacedSuccesses>=32 then
            N.sendInterval=math.max(.25,N.sendInterval/2); N.pacingStableSince=now; N.pacedSuccesses=0
        end
        if msg.transfer then msg.transfer.started=msg.transfer.started or now; msg.transfer.lastSent=now end
        table.remove(N.queue,1); N.stats.sent=N.stats.sent+1
        if #N.queue==0 then N.lockdownEpisode=nil end
        if wasPaused then F.UI.DataChanged() end
    else
        local codes=Enum and Enum.SendAddonMessageResult
        if ok and result==(codes and codes.AddOnMessageLockdown or 11) then pause(); return end
        local throttle=ok and (result==(codes and codes.AddonMessageThrottle or 3) or result==(codes and codes.ChannelThrottle or 8))
        if throttle then
            local changed=not N.throttled or N.paused
            N.throttled=true; N.paused=nil; N.lockdownDelay=nil; N.lastError=F.L('NET_THROTTLE')
            N.stats.throttles=(N.stats.throttles or 0)+1; N.lastThrottleAt=now
            N.pacingStableSince=now; N.pacedSuccesses=0
            N.sendInterval=math.min(1,(N.sendInterval or .25)*2)
            N.throttleDelay=math.min(15,(N.throttleDelay or .5)*2)
            N.elapsed=N.sendInterval-N.throttleDelay
            if changed then F.UI.DataChanged() end
            return
        end
        N.queue={}; N.paused=nil; N.lockdownEpisode=nil; N.lockdownDelay=nil
        N.throttled=nil; N.throttleDelay=nil
        N.Error(F.L('NET_SEND_FAILED')..' ('..tostring(ok and result or 'API')..')')
    end
end

function N.Receive(prefix, text, channel, sender)
    if prefix ~= N.prefix or not F.db.settings.sharing or type(text) ~= 'string' or #text > 250 then return end
    if channel ~= 'GUILD' and channel ~= 'PARTY' and channel ~= 'RAID' then return end
    if type(sender)~='string' or sender=='' then return end
    N.stats.received=N.stats.received+1
    local transportSender=sender -- Stable across surname alias discovery mid-transfer.
    sender = F.Identity(sender); if sender == F.me then F.CleanSelfAliases(); return end
    local now = F.Now()
    local rate = N.rates[transportSender]
    if not rate then
        if #F.Keys(N.rates) >= 100 then return end
        rate = {start = now, count = 0}; N.rates[transportSender] = rate
    end
    if now - rate.start >= 30 then rate.start, rate.count = now, 0 end
    rate.count = rate.count + 1; if rate.count > 300 then return end
    local token, index, total, chunk = text:match('^1|([%d%.]+)|(%d+)|(%d+)|(.*)$')
    index, total = tonumber(index), tonumber(total)
    if not token or #token > 30 or not F.Integer(total, 1, 480) or not F.Integer(index, 1, total) or #chunk > 200 then return end
    local key = transportSender .. ':' .. channel .. ':' .. token
    local buffer = N.buffers[key]
    if not buffer then
        if #F.Keys(N.buffers) >= 16 then return end
        buffer = {total = total, chunks = {}, count = 0, created = now}; N.buffers[key] = buffer
    end
    if buffer.total ~= total then N.buffers[key] = nil; return end
    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk; buffer.count = buffer.count + 1; buffer.updated=now
    end
    if buffer.count ~= total then return end
    N.buffers[key] = nil
    local message = F.Codec.Decode(table.concat(buffer.chunks))
    if type(message) ~= 'table' then return end
    if message.kind == 'PROFILE' and F.ValidProfile(message.data) then
        sender=F.ResolveSender(sender,message.data.characterName) or sender
        F.Updates.Observe(message.data.addonVersion,sender)
        F.Prune()
        sender=F.Identity(sender)
        local previous = F.db.profiles[sender]
        if not previous and #F.Keys(F.db.profiles) >= 100 then return end
        -- A retained favorite can outlive the sender's SavedVariables/reinstall.
        -- After freshness expires, accept a new session with a reset revision.
        if previous and previous.rev > message.data.rev and not F.ProfileStale(previous) then return end
        message.data.seen = now; F.db.profiles[sender] = message.data; F.UI.DataChanged()
    elseif message.kind == 'HELLO' then
        if type(message.data)=='table' then F.Updates.Observe(message.data.version,sender) end
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
