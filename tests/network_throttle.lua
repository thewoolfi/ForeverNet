local F,N=ForeverNet,ForeverNet.Net
F.db.settings.sharing=true; F.db.settings.autoSync=false
for i=1,12 do F.localProfile.recipes['r'..i]={name='Recipe '..i,output='item:'..i,quantity=1,profession='p',blueprint=false,reagents={},stations={}} end
local result,attempts=3,0
C_ChatInfo.SendAddonMessage=function() attempts=attempts+1; return result end
assert(N.Publish('GUILD')); local count=#N.queue; local token=N.queue[1].text:match('^1|([^|]+)')
local notices=#chatMessages
for i=1,25 do N.elapsed=0; N.Tick(2) end
assert(#N.queue==count, 'Rate limits discard the entire queue after 20 retries')
assert(N.throttled and not N.paused and N.lastSendResult==3 and #chatMessages==notices)
assert(N.throttleDelay==15 and N.sendInterval==1 and N.stats.throttles==25)
result=8
for i=1,25 do N.elapsed=0; N.Tick(2) end
assert(#N.queue==count and N.throttled and N.lastSendResult==8)
assert(N.queue[1].text:match('^1|([^|]+)')==token)

-- Five minutes of one-minute auto refresh under a continuous rate limit.
F.db.settings.autoSync=true; F.db.settings.syncInterval=60
local before=attempts
for i=1,300 do clock=clock+1; N.Tick(1) end
assert(attempts-before<=21 and #N.queue==count and #chatMessages==notices)
assert(F.db.settings.syncInterval==60)
local diagnosticAttempts=attempts
N.Diagnostics(); assert(attempts==diagnosticAttempts and #N.queue==count)
local found=false
for _,line in ipairs(chatMessages) do if line:find('Throttled = true',1,true) then found=true end end
assert(found and N.lastError==F.L('NET_THROTTLE'))
F.db.settings.autoSync=false; N.pendingSync=nil

-- Once accepted, finish every fragment and decode the complete profile.
local accepted={}; result=0
C_ChatInfo.SendAddonMessage=function(_,text) attempts=attempts+1; accepted[#accepted+1]=text; return result end
for i=1,count do clock=clock+1; N.elapsed=0; N.Tick(1) end
assert(#N.queue==0 and not N.throttled and not N.paused and not N.lastError)
local chunks={}
for _,text in ipairs(accepted) do
    local current,index,total,chunk=text:match('^1|([^|]+)|(%d+)|(%d+)|(.*)$')
    assert(current==token and tonumber(total)==count); chunks[tonumber(index)]=chunk
end
assert(F.Codec.Decode(table.concat(chunks)).kind=='PROFILE')

-- Learned pacing respects send intervals and recovers slowly after a stable minute.
N.queue={}; N.sendInterval=1; N.elapsed=0; N.lastThrottleAt=clock; N.pacingStableSince=clock
assert(N.Publish('GUILD')); before=attempts
for i=1,3 do clock=clock+.25; N.Tick(.25) end
assert(attempts==before)
clock=clock+.25; N.Tick(.25); assert(attempts==before+1)
N.pacedSuccesses=31; clock=clock+61; N.elapsed=0; N.Tick(1)
assert(N.sendInterval==.5)

-- Status distinguishes code 11 and rate limits; share off clears transient pacing.
C_ChatInfo.SendAddonMessage=function() return result end
result=11; N.elapsed=0; N.Tick(1); assert(N.paused and not N.throttled)
result=3; N.elapsed=0; N.Tick(1); assert(N.throttled and not N.paused)
for _,locale in ipairs(F.LocaleOrder) do F.db.settings.locale=locale; assert(F.L('NET_THROTTLE')~='NET_THROTTLE') end
F.db.settings.sharing=false; N.Tick(.25)
assert(#N.queue==0 and not N.throttled and not N.throttleDelay and not N.lastError and N.sendInterval==nil)

-- Permanent failures still surface instead of being treated as rate limits.
F.db.settings.sharing=true; F.db.settings.autoSync=false
assert(N.Send('HELLO',{version=F.version},'GUILD'))
result=5; N.elapsed=0; N.Tick(.25)
assert(#N.queue==0 and not N.throttled and N.lastError:find('(5)',1,true))
