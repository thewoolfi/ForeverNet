"""Two native Forever identities sharing recipes and requests, including self echoes."""
def run_forever_transport_tests(client, guild=False):
    setup = '''
        NameUtil={GetUnmodifiedUnitFullName=function() end}
        function GetRealmName() return 'Classic Beta PvE 2' end
        function GetNormalizedRealmName() return 'ClassicBetaPvE2' end
        function UnitNameUnmodified(unit)
            local first=unit=='player' and playerName or unit=='party1' and peerName
            return first, first and 'Alchemist'
        end
        function UnitFullName(unit) return UnitNameUnmodified(unit) end
        function GetNumGroupMembers() return 2 end
        function IsInGroup() return true end
        function IsInRaid() return false end
        function IsInGuild() return false end
    '''
    if guild:
        setup+='''
            function GetNumGroupMembers() return 0 end
            function IsInGroup() return false end
            function IsInGuild() return true end
        '''
    clients=[client('Alice',setup),client('Bob',setup)]
    for i,lua in enumerate(clients):
        lua.globals().peerName=['Bob','Alice'][i]
        lua.execute('''
            local F=ForeverNet
            F.RefreshIdentityAliases()
            F.db.settings.sharing=true; F.db.settings.autoSync=false
            F.localProfile.professions['skill:171']=150
            F.localProfile.recipes['spell:100']={name='Potion',output='item:200',quantity=1,
                profession='skill:171',blueprint=false,reagents={},stations={}}
        ''')
        def send(prefix,text,channel,*args,index=i):
            sender=['AliceAlchemist-ClassicBetaPvE2','BobAlchemist-ClassicBetaPvE2'][index]
            for target in clients:  # Real channels may echo a sender's own messages.
                target.globals().frames[1].scripts.OnEvent(target.globals().frames[1],
                    'CHAT_MSG_ADDON',prefix,text,channel,sender)
            return 0
        lua.globals().C_ChatInfo.SendAddonMessage=send
    elapsed=0
    def settle():
        nonlocal elapsed
        for _ in range(1000):
            elapsed+=1
            for lua in clients:
                lua.globals().clock=1800000000+elapsed//4
                lua.globals().frames[1].scripts.OnUpdate(lua.globals().frames[1],.25)
            if all(lua.execute('local N=ForeverNet.Net; return #N.queue==0 and N.pendingPublish==nil and N.pendingSync==nil') for lua in clients):
                return
        raise AssertionError('Forever transport did not settle')
    for lua in clients: lua.execute('assert(ForeverNet.Net.Sync())')
    settle()
    for lua in clients:
        lua.execute('''
            local F=ForeverNet
            assert(#F.Keys(F.db.profiles)==2)
            F.UI.Navigate('network'); assert(#F.UI.entries==1 and F.UI.entries[1].owner~=F.me)
            F.UI.Navigate('recipes'); assert(#F.UI.entries==1 and #F.UI.entries[1].providers==2)
            assert(F.UI.entries[1].subtitle==string.format(F.L('CRAFTER_COUNT'),2))
        ''')
    alice,bob=clients
    ok,rid=alice.globals().ForeverNet.Requests.Create('item:200',2)
    assert ok; settle()
    assert bob.globals().ForeverNet.db.requests[rid].owner=='Alice-Alchemist'
    assert bob.globals().ForeverNet.Requests.Accept(rid) is True
    settle()
    for lua in clients:
        assert lua.globals().ForeverNet.db.requests[rid].assignee=='Bob-Alchemist'
        assert lua.globals().ForeverNet.db.requests[rid].status=='accepted'
    assert alice.globals().ForeverNet.Requests.Close(rid,'done') is True
    settle(); assert bob.globals().ForeverNet.db.requests[rid].status=='done'
    # A roster refresh must not cause the next profile to duplicate a known peer.
    for lua in clients:
        lua.globals().frames[1].scripts.OnEvent(lua.globals().frames[1],'GROUP_ROSTER_UPDATE')
        lua.execute('assert(ForeverNet.Net.Publish())')
    settle()
    for lua in clients: lua.execute('assert(#ForeverNet.Keys(ForeverNet.Profiles())==2)')
    print('PASS two Forever alchemists ('+('guild without party units' if guild else 'party')+'): self echoes, one item/two crafters, mutual discovery and request lifecycle')
