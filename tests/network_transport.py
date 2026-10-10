"""Exercise the actual send queue, CHAT_MSG_ADDON event, modern enums and party routing."""
def run_transport_tests(client):
    from pathlib import Path
    clients={}
    active=set()
    deliveries=[]
    throttles={}
    failures={}
    def add(name,enabled=True):
        lua=client(name)
        lua.execute('''
            LE_PARTY_CATEGORY_INSTANCE=nil; LE_PARTY_CATEGORY_HOME=nil
            Enum={PartyCategory={Home=1,Instance=2},
                RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1,InvalidPrefix=2,MaxPrefixes=3},
                SendAddonMessageResult={Success=0,AddonMessageThrottle=3,ChannelThrottle=8,NotInGroup=5}}
            function IsInGroup(category) return category==nil or category==Enum.PartyCategory.Home end
            function IsInRaid() return false end
            function IsInGuild() return false end
            C_ChatInfo.RegisterAddonMessagePrefix=function() return Enum.RegisterAddonMessagePrefixResult.Success end
            ForeverNet.Net.Start(); assert(ForeverNet.Net.available and ForeverNet.Net.Channel()=='PARTY')
        ''')
        def send(prefix,text,channel,*args):
            assert channel=='PARTY',channel
            if failures.get(name): return failures[name]
            if throttles.get(name,0)>0:
                throttles[name]-=1; return 3
            for other in tuple(active):
                if other!=name:
                    target=clients[other]
                    target.globals().frames[1].scripts.OnEvent(target.globals().frames[1],'CHAT_MSG_ADDON',prefix,text,channel,name+'-Realm')
            deliveries.append((name,channel,text))
            return 0
        lua.globals().C_ChatInfo.SendAddonMessage=send
        clients[name]=lua; active.add(name)
        lua.execute('ForeverNet.db.settings.sharing='+('true' if enabled else 'false'))
        return lua
    steps=0
    def tick(count=1):
        nonlocal steps
        for _ in range(count):
            steps+=1
            for name in tuple(active):
                lua=clients[name]; lua.globals().clock=1800000000+steps//4
                lua.globals().frames[1].scripts.OnUpdate(lua.globals().frames[1],.25)
    def settle():
        for _ in range(2000):
            tick()
            if all(c.execute('''local N=ForeverNet.Net; return #N.queue==0 and
                N.pendingSync==nil and N.pendingPublish==nil and next(N.followupProfiles)==nil''')
                for name,c in clients.items() if name in active): return
        raise AssertionError('Transport did not settle')
    alice=add('PartyAlice')
    alice.execute('''
        local F=ForeverNet
        F.localProfile.professions.engineering=300
        for i=1,180 do
            F.localProfile.recipes['spell:'..i]={name='Recipe '..i,output='item:'..i,quantity=1,
                profession='engineering',blueprint=false,reagents={['item:9000']=2},stations={}}
        end
    ''')
    settle()
    ok,rid=alice.globals().ForeverNet.Requests.Create('item:777',4)
    assert ok; settle()  # The request existed before the peer enabled sharing.
    bob=add('PartyBob',enabled=False)
    tick(4); assert bob.globals().ForeverNet.db.requests[rid] is None
    bob.execute("ForeverNet.db.settings.sharing=true; ForeverNet.UI.Navigate('network')")
    settle()
    assert bob.globals().ForeverNet.db.requests[rid].quantity==4
    assert bob.globals().ForeverNet.db.profiles['PartyAlice-Realm'] is not None
    assert alice.globals().ForeverNet.db.profiles['PartyBob-Realm'] is not None
    for lua in [alice,bob]:
        lua.execute('''
            local F=ForeverNet; F.UI.Navigate('network')
            assert(#F.UI.entries==1 and F.UI.entries[1].owner~=F.me)
            assert(F.UI.bodyText:GetText():find('Select a player',1,true))
        ''')
    # An offer is delivered through the real API/event path, followed by owner state.
    assert bob.globals().ForeverNet.Requests.Accept(rid) is True
    settle()
    assert alice.globals().ForeverNet.db.requests[rid].assignee=='PartyBob-Realm'
    assert bob.globals().ForeverNet.db.requests[rid].status=='accepted'
    assert alice.globals().ForeverNet.Requests.Close(rid,'done') is True
    settle(); assert bob.globals().ForeverNet.db.requests[rid].status=='done'
    # Requests must not wait behind a large profile transfer.
    alice.execute('assert(ForeverNet.Net.Publish())')
    ok,urgent=alice.globals().ForeverNet.Requests.Create('item:888',2)
    assert ok
    tick(8)
    assert bob.globals().ForeverNet.db.requests[urgent] is not None
    settle()
    # A throttled frame stays queued and eventually arrives intact.
    throttles['PartyAlice']=2
    ok,retry=alice.globals().ForeverNet.Requests.Create('item:999',3)
    assert ok
    settle(); assert bob.globals().ForeverNet.db.requests[retry].quantity==3
    # API failure enums used to look successful because pcall alone was checked.
    failures['PartyAlice']=5
    assert alice.globals().ForeverNet.Requests.Create('item:1010',1)[0]
    tick(4)
    assert alice.globals().ForeverNet.Net.lastError is not None
    assert len(alice.globals().ForeverNet.Net.queue)==0
    del failures['PartyAlice']
    # Group roster changes discover a newly connected party member without Sync.
    carol=add('PartyCarol')
    for lua in [alice,bob]:
        lua.globals().frames[1].scripts.OnEvent(lua.globals().frames[1],'GROUP_ROSTER_UPDATE')
    settle()
    assert carol.globals().ForeverNet.db.requests[urgent] is not None
    carol.execute('assert(#ForeverNet.Keys(ForeverNet.db.profiles)==3)')
    carol.execute('''
        local F=ForeverNet; F.UI.Navigate('network'); assert(#F.UI.entries==2)
        F.db.settings.sharing=false
    ''')
    previous=len(deliveries); tick(4)
    assert len(carol.globals().ForeverNet.Net.queue)==0
    # Manual mode never starts discovery or pushes edited recipes on its own.
    for lua in [alice,bob]: lua.execute('ForeverNet.db.settings.autoSync=false')
    settle()
    alice.execute('''
        local F=ForeverNet
        F.localProfile.recipes={}
        F.localProfile.recipes.changed={name='Changed recipe',output='item:2001',quantity=1,
            profession='engineering',blueprint=false,reagents={},stations={}}
        F.Touch(); F.Net.ScheduleSync()
    ''')
    previous=len(deliveries); tick(1300)
    assert len(deliveries)==previous
    assert bob.globals().ForeverNet.db.profiles['PartyAlice-Realm'].recipes.changed is None
    alice.execute('assert(ForeverNet.Net.Sync())')
    settle()
    assert bob.globals().ForeverNet.db.profiles['PartyAlice-Realm'].recipes.changed is not None
    # Default interval is 120s; selecting 60s produces an idle periodic refresh.
    alice.execute('''
        local F=ForeverNet
        assert(F.Net.Interval()==120)
        F.db.settings.autoSync=true; F.db.settings.syncInterval=60
    ''')
    settle()
    alice.execute('ForeverNet.Net.autoElapsed=0')
    serial=alice.globals().ForeverNet.Net.serial
    tick(236); assert alice.globals().ForeverNet.Net.serial==serial
    tick(4); assert alice.globals().ForeverNet.Net.serial>serial
    settle()
    # Recipe edits publish after a debounce without a HELLO roundtrip.
    alice.execute("ForeverNet.localProfile.recipes.changed.name='New recipe name'; ForeverNet.Touch()")
    settle()
    assert bob.globals().ForeverNet.db.profiles['PartyAlice-Realm'].recipes.changed.name=='New recipe name'
    # A manual refresh while an older revision is queued delivers the new revision
    # afterwards, even with automation disabled. Identical profiles are coalesced.
    alice.execute('''
        local F=ForeverNet; F.db.settings.autoSync=false
        assert(F.Net.Publish())
        local size=#F.Net.queue; assert(F.Net.Publish() and #F.Net.queue==size)
        F.localProfile.recipes.changed.name='Latest manual revision'; F.Touch()
        assert(F.Net.Sync())
    ''')
    settle()
    assert bob.globals().ForeverNet.db.profiles['PartyAlice-Realm'].recipes.changed.name=='Latest manual revision'
    print('PASS automatic/manual refresh: interval, disabled timer, manual catch-up, edit debounce and profile coalescing')
    bob.execute("ForeverNet.version='1.1.2'; assert(ForeverNet.Net.Sync())")
    settle()
    assert alice.globals().ForeverNet.Updates.latest=='1.1.2'
    carol.execute('''
        C_ChatInfo.RegisterAddonMessagePrefix=function() return Enum.RegisterAddonMessagePrefixResult.MaxPrefixes end
        ForeverNet.Net.Start(); assert(not ForeverNet.Net.available)
        C_ChatInfo.RegisterAddonMessagePrefix=function() return Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix end
        ForeverNet.Net.Start(); assert(ForeverNet.Net.available)
        function IsInGroup(category) return category==2 end
        function IsInGuild() return true end
        assert(ForeverNet.Net.Channel()=='GUILD')
    ''')
    print('PASS real party transport: modern enums, discovery, late requests, priority, retries, lifecycle and self exclusion')
