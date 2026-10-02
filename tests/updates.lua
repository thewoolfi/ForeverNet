local F,V=ForeverNet,ForeverNet.Updates
local ascending={'0.3.3-alpha','0.3.3-alpha.1','0.3.3-alpha.beta','0.3.3-beta','0.3.3-beta.2','0.3.3-beta.11','0.3.3-rc.1','0.3.3','0.3.10','0.10.0','1.0.0'}
for i=2,#ascending do assert(V.Newer(ascending[i],ascending[i-1]) and not V.Newer(ascending[i-1],ascending[i])) end
assert(not V.Newer('0.3.3+build1','0.3.3+build2'))
for _,value in ipairs({'garbage','0.3','0.3.3|cff00ff00','01.3.3','0.3.3-beta..1','0.3.3-beta.01','0.3.3+','0.3.3+bad+meta','999999.1.1'}) do
    assert(not V.Parse(value),value)
end
F.db.settings.sharing=true
local serial=0
local function message(kind,data,sender)
    serial=serial+1
    local payload=F.Codec.Encode({kind=kind,data=data})
    for i=1,math.ceil(#payload/200) do
        F.Net.Receive(F.Net.prefix,'1|'..clock..'.'..serial..'|'..i..'|'..math.ceil(#payload/200)..'|'..payload:sub((i-1)*200+1,i*200),'GUILD',sender)
    end
end
V.Open(); assert(V.frame:IsShown() and V.frame.strata=='FULLSCREEN_DIALOG')
local count=#chatMessages
message('HELLO',{version='0.3.4'},'Newer-Realm')
assert(V.latest=='0.3.4' and V.source=='Newer-Realm' and #chatMessages==count+1)
assert(V.status:GetText():find('0.3.4',1,true))
message('HELLO',{version='0.3.4'},'Another-Realm'); assert(#chatMessages==count+1)
message('HELLO',{version='9999.0.0'},F.me); assert(V.latest=='0.3.4')
message('HELLO',{version='invalid'},'Bad-Realm'); assert(V.latest=='0.3.4')
V.notify:SetChecked(false); V.notify.scripts.OnClick(V.notify)
local p=F.NewProfile(); p.addonVersion='0.3.10'
message('PROFILE',p,'Newest-Realm')
assert(V.latest=='0.3.10' and #chatMessages==count+1)
assert(F.ValidProfile(F.db.profiles['Newest-Realm']))
p.addonVersion=nil; message('PROFILE',p,'OldClient-Realm')
assert(F.db.profiles['OldClient-Realm'] and V.latest=='0.3.10')
V.link.scripts.OnMouseUp(V.link); assert(V.link.focused and V.link.highlighted)
V.link:SetText('https://wrong.example'); assert(V.link:GetText()==V.releasesURL)
F.db.settings.sharing=false; F.Net.queue={}; V.check.scripts.OnClick(); assert(#F.Net.queue==0)
F.Command('updates'); assert(V.frame:IsShown())
F.Settings.Open(); F.Settings.updates.scripts.OnClick(); assert(V.frame:IsShown())
