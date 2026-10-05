local F,N=ForeverNet,ForeverNet.Net
F.db.settings.sharing=true; F.db.settings.autoSync=false
local profile=F.NewProfile()
for i=1,40 do
    profile.recipes['recipe:'..i]={name='Recipe '..i,output='item:'..i,quantity=1,profession='p',blueprint=false,reagents={['item:400']=2},stations={}}
end
local payload=F.Codec.Encode({kind='PROFILE',data=profile})
local total=math.ceil(#payload/200); assert(total>16)
for i=1,total do
    N.Receive('ForeverNet1','1|123.1|'..i..'|'..total..'|'..payload:sub((i-1)*200+1,i*200),'GUILD','SlowPeer-Realm')
    clock=clock+12; N.Tick(.25)
end
assert(F.db.profiles['SlowPeer-Realm'] and #F.Keys(F.db.profiles['SlowPeer-Realm'].recipes)==40)
-- Duplicates cannot indefinitely extend a buffer, and idle buffers expire.
N.Receive('ForeverNet1','1|123.2|1|2|partial','GUILD','SlowPeer-Realm')
clock=clock+100
N.Receive('ForeverNet1','1|123.2|1|2|partial','GUILD','SlowPeer-Realm')
clock=clock+51; N.Tick(.25); assert(next(N.buffers)==nil)
