local _,F=...
local V=F.Updates
V.prefix='ForeverNetVer'
V.pending,V.lastSent,V.time={},{},0
local function home() return Enum and Enum.PartyCategory and Enum.PartyCategory.Home or LE_PARTY_CATEGORY_HOME or 1 end
local function instance() return Enum and Enum.PartyCategory and Enum.PartyCategory.Instance or LE_PARTY_CATEGORY_INSTANCE or 2 end
function V.ChannelAvailable(channel)
    if channel=='GUILD' then return IsInGuild and IsInGuild() end
    if channel=='INSTANCE_CHAT' then return IsInGroup and IsInGroup(instance()) end
    if channel=='RAID' then return IsInRaid and IsInRaid(home()) end
    if channel=='PARTY' then return IsInGroup and IsInGroup(home()) and not (IsInRaid and IsInRaid(home())) end
    return false
end
function V.Start()
    local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    local ok,result=false,nil
    if register then ok,result=pcall(register,V.prefix) end
    local codes=Enum and Enum.RegisterAddonMessagePrefixResult
    V.available=ok and (result==true or result==nil or result==(codes and codes.Success or 0) or result==(codes and codes.DuplicatePrefix or 1))
end
function V.Schedule(channel,delay,reply)
    if not V.available or not V.ChannelAvailable(channel) then return false end
    local due=math.max(V.time+(delay or 0),(V.lastSent[channel] or -10)+10)
    local pending=V.pending[channel]
    if pending then
        pending.due=math.min(pending.due,due)
        pending.reply=pending.reply and reply or false
    else V.pending[channel]={due=due,attempts=0,reply=reply} end
    return true
end
function V.ScheduleAll(delay)
    local count=0
    for _,channel in ipairs({'GUILD','PARTY','RAID','INSTANCE_CHAT'}) do
        if V.Schedule(channel,delay,false) then count=count+1 end
    end
    return count
end
function V.CheckNow()
    if not V.available then return false,F.L('API обмена недоступен.') end
    if V.ScheduleAll(0)==0 then return false,F.L('UPDATE_VERSION_NO_CHANNEL') end
    return true,F.L('UPDATE_VERSION_QUEUED')
end
function V.Tick(elapsed)
    V.time=V.time+elapsed
    for channel,pending in pairs(V.pending) do
        if not V.ChannelAvailable(channel) then V.pending[channel]=nil
        elseif pending.due<=V.time then
            local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
            local ok,result=false,nil
            if send then ok,result=pcall(send,V.prefix,'1|'..F.version,channel) end
            local success=Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0
            if ok and (result==nil or result==true or result==success) then
                V.lastSent[channel]=V.time; V.pending[channel]=nil
            else
                pending.attempts=pending.attempts+1
                if pending.attempts>=5 then V.pending[channel]=nil
                else pending.due=V.time+math.min(30,2^pending.attempts) end
            end
        end
    end
end
function V.Receive(prefix,text,channel,sender)
    if prefix~=V.prefix or not V.available or not V.ChannelAvailable(channel) or not F.Text(sender) or sender=='' or
        F.IsSelf(sender) or type(text)~='string' or #text>66 then return end
    local version=text:match('^1|(.+)$')
    if not V.Parse(version) then return end
    sender=F.Identity(sender)
    if V.Newer(F.version,version) then
        -- One short delayed reply per channel; another current/newer peer can
        -- cancel it before it goes out. No recipes, profiles or bank data.
        V.Schedule(channel,1+math.random()*3,true)
    else
        if V.pending[channel] and V.pending[channel].reply then V.pending[channel]=nil end
        V.Observe(version,sender)
    end
end
