local F,N=ForeverNet,ForeverNet.Net
F.db.settings.sharing=true; F.db.settings.autoSync=false
N.queue={}; N.followupProfiles={}; N.pendingSync=nil; N.pendingPublish=nil
local sends,restricted,code=0,false,11
C_ChatInfo.SendAddonMessage=function() sends=sends+1; return code end
assert(N.Publish('GUILD')); local count=#N.queue
N.Tick(1); assert(N.paused and #N.queue==count and N.lastError==F.L('NET_LOCKDOWN'))
local notices=#chatMessages
for i=1,100 do N.Tick(.25) end
assert(#chatMessages==notices and #N.queue==count)
C_ChatInfo.InChatMessagingLockdown=function() return restricted end
C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=function() return restricted end
restricted=true; code=0; local before=sends
N.elapsed=0; N.Tick(.25)
assert(sends==before+1 and #N.queue==count-1)
N.Diagnostics(); assert(chatMessages[#chatMessages-4]:find('AreOutgoingAddonChatMessagesRestricted = true',1,true))
assert(not N.paused and not N.lastError and N.stats.sent>=1)
-- Restart even a partially delivered logical profile after receiver TTL.
N.queue={}; F.localProfile.recipes={}
for i=1,10 do F.localProfile.recipes['r'..i]={name='Recipe '..i,output='item:'..i,quantity=1,profession='p',blueprint=false,reagents={},stations={}} end
assert(N.Publish('GUILD')); count=#N.queue
local token=N.queue[1].text:match('^1|([^|]+)')
N.elapsed=0; N.Tick(.25); assert(#N.queue==count-1)
code=11; N.Tick(.25); assert(N.paused)
clock=clock+200; code=0; N.elapsed=0; N.Tick(.25)
assert(#N.queue==count-1 and N.queue[1].text:match('^1|([^|]+)')~=token)
assert(N.queue[1].text:find('|2|',1,true))
code=11; N.elapsed=0; N.Tick(.25); assert(N.paused)
F.db.settings.sharing=false; N.Tick(.25); assert(#N.queue==0 and not N.paused and not N.lastError)
