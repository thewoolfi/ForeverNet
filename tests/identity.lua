local F=ForeverNet
-- Match Forever's native NameUtil: UnitNameUnmodified returns first name/surname.
NameUtil={GetUnmodifiedUnitFullName=function(unit)
    local first,last=UnitNameUnmodified(unit); return first and first..'-'..last
end}
function GetRealmName() return 'Classic Beta PvE 2' end
function GetNormalizedRealmName() return 'ClassicBetaPvE2' end
function UnitNameUnmodified(unit)
    if unit=='player' then return 'Andrew','Woolfi' end
    if unit=='party1' then return 'Kynaretth','Athmora' end
end
function UnitFullName(unit)
    if unit=='player' then return 'Andrew','Woolfi' end
    if unit=='party1' then return 'KynaretthAthmora','ClassicBetaPvE2' end
end
function GetNumGroupMembers() return 2 end
local function profile(id)
    local p=F.NewProfile(); p.rev=2
    p.recipes[id]={name='Murloc boots',output='item:100',quantity=1,profession='skill:165',blueprint=false,reagents={},stations={}}
    return p
end
ForeverNetDB={schema=1,settings={sharing=true},profiles={
    ['Andrew-Woolfi']=profile('spell:1'),['AndrewWoolfi-ClassicBetaPvE2']=profile('spell:2'),
    ['KynaretthAthmora-ClassicBetaPvE2']=profile('spell:3')},requests={},banks={
    ['Andrew-Woolfi']={items={['item:100']=1},seen=10},
    ['AndrewWoolfi-ClassicBetaPvE2']={items={['item:100']=2},seen=20}}}
assert(F.Init())
assert(F.me=='Andrew-Woolfi' and F.db.profiles['AndrewWoolfi-ClassicBetaPvE2']==nil)
assert(F.localProfile.recipes['spell:1'] and F.localProfile.recipes['spell:2'])
assert(F.Bank.Count('item:100')==2 and F.db.banks['AndrewWoolfi-ClassicBetaPvE2']==nil)
assert(F.IsSelf('Andrew-Woolfi') and F.IsSelf('Andrew Woolfi') and F.IsSelf('AndrewWoolfi-ClassicBetaPvE2'))
assert(F.IsSelf('Andrew-Woolfi-Classic Beta PvE 2'))
assert(not F.IsSelf('Andrew-Woolfi-AnotherRealm') and not F.IsSelf(nil))
F.Prune(); assert(F.db.profiles['Kynaretth-Athmora'] and not F.db.profiles['KynaretthAthmora-ClassicBetaPvE2'])
F.UI.Navigate('network'); assert(#F.UI.entries==1 and F.UI.entries[1].owner=='Kynaretth-Athmora')
F.UI.Navigate('recipes'); assert(#F.UI.entries==1 and #F.UI.entries[1].providers==3)
assert(F.UI.entries[1].subtitle==string.format(F.L('CRAFTER_COUNT'),2)) -- two people, not three recipes
F.db.profiles['Kynaretth-Athmora']=nil
F.UI.Status(); assert(#F.UI.entries==1 and F.UI.entries[1].subtitle==F.L('YOU'))
F.UI.Select(F.UI.entries[1])
local _,mentions=F.UI.blocks[1].text:GetText():gsub(F.L('YOU'),'')
assert(mentions==1) -- one person can know several variants of the same item
F.UI.Navigate('network'); assert(#F.UI.entries==0)
local payload=F.Codec.Encode({kind='PROFILE',data=profile('spell:99')})
local parts=math.ceil(#payload/200)
for i=1,parts do F.Net.Receive(F.Net.prefix,'1|1.1|'..i..'|'..parts..'|'..payload:sub((i-1)*200+1,i*200),'PARTY','AndrewWoolfi-ClassicBetaPvE2') end
assert(not F.db.profiles['AndrewWoolfi-ClassicBetaPvE2'] and not F.localProfile.recipes['spell:99'])
local r={id='KynaretthAthmora-ClassicBetaPvE2:123:1',item='item:100',quantity=1,rev=1,expires=clock+60,status='open',assignee=''}
F.Requests.Receive('REQUEST',r,'Kynaretth-Athmora','PARTY')
assert(F.db.requests[r.id] and F.db.requests[r.id].owner=='Kynaretth-Athmora')
local forged=F.Copy(r); forged.id='Andrew-Woolfi:123:2'
F.Requests.Receive('REQUEST',forged,'Kynaretth-Athmora','PARTY'); assert(not F.db.requests[forged.id])
assert(not F.ResolveSender('Stranger','Unrelated-Identity'))
assert(not F.identityAliases['unrelatedidentity']) -- Rejected names cannot teach aliases.
local gp=profile('spell:70'); gp.characterName='Guild-Alchemist'
local wire=F.Codec.Encode({kind='PROFILE',data=gp}); local count=math.ceil(#wire/200)
assert(count>1)
F.Net.Receive(F.Net.prefix,'1|2.1|1|'..count..'|'..wire:sub(1,200),'GUILD','GuildAlchemist-ClassicBetaPvE2')
local gr=F.Copy(r); gr.id='Guild-Alchemist:123:1'
F.Requests.Receive('REQUEST',gr,'GuildAlchemist','GUILD')
assert(F.db.requests[gr.id] and F.db.requests[gr.id].owner=='Guild-Alchemist')
for i=2,count do
    F.Net.Receive(F.Net.prefix,'1|2.1|'..i..'|'..count..'|'..wire:sub((i-1)*200+1,i*200),'GUILD','GuildAlchemist-ClassicBetaPvE2')
end
assert(F.db.profiles['Guild-Alchemist'] and F.db.profiles['Guild-Alchemist'].recipes['spell:70'])
NameUtil=nil; UnitNameUnmodified=nil
function UnitFullName(unit) if unit=='player' then return 'Alice','' elseif unit=='party1' then return 'Alice','OtherRealm' end end
F.me=F.UnitIdentity('player'); F.RefreshIdentityAliases()
assert(F.me=='Alice-ClassicBetaPvE2' and F.IsSelf('Alice-Classic Beta PvE 2'))
assert(not F.IsSelf('Alice-OtherRealm'))
