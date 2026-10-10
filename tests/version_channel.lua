local F,V=ForeverNet,ForeverNet.Updates
local sent={}; local guild,party,raid,instanceGroup=true,false,false,false
function IsInGuild() return guild end
function IsInGroup(category) return category==2 and instanceGroup or category==1 and party end
function IsInRaid(category) return category==1 and raid end
C_ChatInfo.SendAddonMessage=function(prefix,text,channel)
    sent[#sent+1]={prefix=prefix,text=text,channel=channel}; return 0
end
F.db.settings.sharing=false; F.db.settings.autoSync=false
V.Login(); V.Login(); V.Tick(7); assert(#sent==0)
V.Tick(1); assert(#sent==1 and sent[1].prefix==V.prefix and sent[1].text=='1|'..F.version and sent[1].channel=='GUILD')
assert(#F.Net.queue==0 and next(F.localProfile.recipes)==nil) -- No profile sharing needed or performed.
for i=1,20 do assert(V.CheckNow()) end
V.Tick(0); assert(#sent==1); V.Tick(10); assert(#sent==2 and next(V.pending)==nil)
local baseline=#chatMessages
V.Receive(V.prefix,'1|1.1.2','GUILD','New-Realm')
assert(V.latest=='1.1.2' and #chatMessages==baseline+1 and F.db.newerAddonVersion.source=='New-Realm')
V.Receive(V.prefix,'1|1.1.3','GUILD','Newer-Realm')
assert(V.latest=='1.1.3' and #chatMessages==baseline+1) -- One notice/session; keep highest for the next login.
for _,text in ipairs({'1|1.0.3|code','1|invalid','2|1.0.3',string.rep('1',100)}) do V.Receive(V.prefix,text,'GUILD','Bad-Realm') end
V.Receive(V.prefix,'1|9.0.0','GUILD',F.me); V.Receive(V.prefix,'1|9.0.0','WHISPER','Other-Realm')
assert(V.latest=='1.1.3')
-- Reply coalescing and cancellation in crowded guilds.
V.Receive(V.prefix,'1|0.4.0','GUILD','Old-Realm'); assert(V.pending.GUILD and V.pending.GUILD.reply)
V.Receive(V.prefix,'1|0.4.0','GUILD','Another-Realm'); assert(#F.Keys(V.pending)==1)
V.Receive(V.prefix,'1|'..F.version,'GUILD','Same-Realm'); assert(not V.pending.GUILD)
V.Receive(V.prefix,'1|0.4.0','GUILD','Old-Realm'); V.Tick(10); assert(#sent==3)
-- Membership/category guards: no home-group profile leak into instance chat.
guild=false; party=true; instanceGroup=true
V.ScheduleAll(0); V.Tick(10)
assert(sent[#sent-1].channel=='INSTANCE_CHAT' or sent[#sent].channel=='INSTANCE_CHAT')
assert(#F.Net.queue==0 and not V.ChannelAvailable('RAID'))
raid=true; V.ScheduleAll(0); assert(not V.ChannelAvailable('PARTY')); V.Tick(10)
assert(sent[#sent].channel=='RAID' or sent[#sent-1].channel=='RAID')
party,raid,instanceGroup=false,false,false
local ok,why=V.CheckNow(); assert(not ok and why==F.L('UPDATE_VERSION_NO_CHANNEL'))
V.Receive(V.prefix,'1|9.0.0','GUILD','NotMyGuild-Realm'); assert(V.latest=='1.1.3')
guild=true; V.pending,V.lastSent={},{}
local attempts=0
C_ChatInfo.SendAddonMessage=function() attempts=attempts+1; return 11 end
V.CheckNow(); V.Tick(0); V.Tick(2); V.Tick(4); V.Tick(8); V.Tick(16)
assert(attempts==5 and next(V.pending)==nil and #chatMessages==baseline+1)
C_ChatInfo.SendAddonMessage=function(prefix,text,channel) sent[#sent+1]={prefix=prefix,text=text,channel=channel}; return 0 end
V.CheckNow(); guild=false; V.Tick(30); assert(not V.pending.GUILD)
-- Mute only chat notifications; still store reports for a future login.
guild=true; F.db.settings.updateNotifications=false
V.latest,V.notified=nil,nil
V.Receive(V.prefix,'1|1.1.3','GUILD','Newer-Realm'); assert(#chatMessages==baseline+1)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; assert(F.L('UPDATE_PEER_CACHED')~='UPDATE_PEER_CACHED')
    V.Open(); assert(not V.status:GetText():find('Windows',1,true))
end
F.db.settings.updateNotifications=true
-- Updating the installed version stops old reminders and clears the cached hint.
local installed=F.version; F.version='1.1.3'; V.latest,V.cached=nil,nil; V.Startup()
assert(not F.db.newerAddonVersion)
F.version=installed; V.latest,V.cached,V.notified=nil,nil,nil
V.Observe('1.1.3','Newer-Realm')
