local F,N=ForeverNet,ForeverNet.Net
F.db.settings.sharing=true; F.db.settings.autoSync=false
F.localProfile.recipes={}
for i=1,20 do F.localProfile.recipes['r'..i]={name='Recipe '..i,output='item:'..i,quantity=1,profession='p',blueprint=false,reagents={},stations={}} end
local accepted,attempts={},0
C_ChatInfo.SendAddonMessage=function(_,text)
    attempts=attempts+1
    if attempts%2==0 then return 11 end
    accepted[#accepted+1]=text; return 0
end
assert(N.Publish('GUILD')); local fragments=#N.queue; assert(fragments>3)
local notices=#chatMessages
for i=1,fragments*2 do clock=clock+1; N.elapsed=0; N.Tick(.25) end
assert(#N.queue==0, 'Intermittent lockdown restarts the profile instead of completing it')
assert(#accepted==fragments and #chatMessages==notices+1)
local chunks,token={},nil
for _,text in ipairs(accepted) do
    local current,index,total,chunk=text:match('^1|([^|]+)|(%d+)|(%d+)|(.*)$')
    token=token or current; assert(current==token and tonumber(total)==fragments)
    chunks[tonumber(index)]=chunk
end
local message=F.Codec.Decode(table.concat(chunks))
assert(message.kind=='PROFILE' and #F.Keys(message.data.recipes)==20)

-- Consecutive rejections back off without growing or retokenizing the queue.
N.queue={}; attempts=0; N.elapsed=0
C_ChatInfo.SendAddonMessage=function() attempts=attempts+1; return 11 end
assert(N.Publish('GUILD')); local count=#N.queue; token=N.queue[1].text:match('^1|([^|]+)')
N.Tick(.25); assert(N.paused and attempts==1)
for i=1,120 do clock=clock+.25; N.Tick(.25) end
assert(attempts<=5 and attempts>=4, 'Repeated lockdown must use bounded backoff')
assert(#N.queue==count and N.queue[1].text:match('^1|([^|]+)')==token)
assert(N.lockdownDelay<=30 and N.lockdownDelay>=16)
F.db.settings.autoSync=true; F.db.settings.syncInterval=60
notices=#chatMessages; local previousAttempts=attempts
for i=1,300 do clock=clock+1; N.Tick(1) end
assert(#N.queue==count and attempts-previousAttempts<=11 and #chatMessages==notices)
assert(F.db.settings.syncInterval==60 and F.db.settings.autoSync==true)
local beforeDiagnostics=attempts
N.Diagnostics(); assert(attempts==beforeDiagnostics and #N.queue==count)
local found=false
for _,line in ipairs(chatMessages) do if line:find('Paused = true',1,true) then found=true end end
assert(found)
F.db.settings.autoSync=false; N.pendingSync=nil

-- Manual refreshes and duplicate request snapshots do not inflate a held queue.
N.queue={}; N.elapsed=0
assert(N.Sync('GUILD')); local syncCount=#N.queue
for i=1,25 do assert(N.Sync('GUILD')) end
assert(#N.queue==syncCount, 'Repeated sync adds duplicate HELLOs')
local request={id='test',status='open'}
assert(N.Send('REQUEST',request,'GUILD')); count=#N.queue
assert(N.Send('REQUEST',request,'GUILD')); assert(#N.queue==count)
request.status='cancelled'; assert(N.Send('REQUEST',request,'GUILD')); assert(#N.queue>count)

-- Partial messages expire by idle and total lifetime, even without code 11.
N.queue={}; N.elapsed=0
C_ChatInfo.SendAddonMessage=function() return 0 end
assert(N.Publish('GUILD')); count=#N.queue; token=N.queue[1].text:match('^1|([^|]+)')
N.Tick(.25); clock=clock+151; N.Tick(.25)
assert(#N.queue==count-1 and N.queue[1].text:match('^1|([^|]+)')~=token)
assert(N.stats.restarts>=1)
local transfer=N.queue[1].transfer
transfer.started=clock-850; transfer.lastSent=clock
token=N.queue[1].text:match('^1|([^|]+)'); N.elapsed=0; N.Tick(.25)
assert(#N.queue==count-1 and N.queue[1].text:match('^1|([^|]+)')~=token)
F.db.settings.sharing=false; N.Tick(.25)
assert(#N.queue==0 and not N.paused and not N.lockdownDelay and not N.lastError)
