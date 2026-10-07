"""Execute WoW-free Lua 5.1 tests. pip install -r requirements-dev.txt"""
import sys
from pathlib import Path
if len(sys.argv) > 1:
    sys.path.insert(0, sys.argv[1])
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOCK = (ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8')

def client(name, setup=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().playerName = name
    lua.execute(MOCK)
    if setup:
        lua.execute(setup)
    namespace = lua.table()
    for line in (ROOT / 'ForeverNet.toc').read_text(encoding='utf-8-sig').splitlines():
        if line.endswith('.lua'):
            lua.execute('return assert(loadstring(...))', (ROOT / line).read_text(encoding='utf-8'))('ForeverNet', namespace)
    lua.execute("frames[1].scripts.OnEvent(frames[1], 'ADDON_LOADED', 'ForeverNet')")
    lua.execute((ROOT/'tests/planner_fixture.lua').read_text(encoding='utf-8'))
    return lua

a, b = client('Alice'), client('Bob')
tests = [
('planner graph fixtures', r'''
local F = ForeverNet
local demo = F.TestProfiles()
local p = F.Planner.Build(demo, 'demo:bag', 2, {['demo:ore']=6, ['demo:cloth']=8})
assert(p.complete and #p.steps == 2 and p.steps[1].quantity == 2)
assert(p.steps[2].stations['demo:workshop'] == 'DemoEngineer-Realm')
assert(#F.SkillGraph(demo).edges >= 10)
local missing = F.Planner.Build(demo, 'demo:bag', 2, {['demo:ore']=3})
assert(not missing.complete and missing.missing['demo:ore']==3 and missing.missing['demo:cloth']==8)
demo['DemoEngineer-Realm'].camps['demo:workshop'] = clock + 5
assert(not F.Planner.Build(demo, 'demo:bag', 1, {}).complete)
'''),
('cycles and shared inventory', r'''
local F=ForeverNet; local p=F.NewProfile()
local function recipe(output, reagents, qty)
 return {name=output, output=output, quantity=qty or 1, profession='engineering', blueprint=false, reagents=reagents, stations={}}
end
p.recipes.a=recipe('a',{b=1}); p.recipes.b=recipe('b',{a=1})
assert(not F.Planner.Build({X=p},'a',1,{}).complete)
p.recipes.a=recipe('a',{b=1,c=1}); p.recipes.b=recipe('b',{ore=1},2); p.recipes.c=recipe('c',{b=1})
local plan=F.Planner.Build({X=p},'a',1,{ore=1})
assert(plan.complete and #plan.steps==3 and plan.steps[1].batches==1)
'''),
('codec and schema boundaries', r'''
local F=ForeverNet; local p=F.TestProfiles()['DemoEngineer-Realm']
local wire=F.Codec.Encode(p); assert(F.ValidProfile(F.Codec.Decode(wire)))
assert(F.Codec.Decode(wire..'bad')==nil)
assert(F.Codec.Decode('m2:s1:at s1:af')==nil)
assert(F.Codec.Decode('s9999999999:x')==nil)
p.recipes['demo:engine'].quantity=0; assert(not F.ValidProfile(p))
assert(F.Codec.Decode('n2147483648:')==nil)
'''),
('locale fallback and commands', r'''
local F=ForeverNet
assert(F.L('Сеть')=='Network')
F.Command('language ruRU'); assert(F.L('Сеть')=='Сеть')
F.Command('language auto'); clientLocale='xxXX'; assert(F.L('Сеть')=='Network')
clientLocale='enUS'
F.Command('profession engineering 300')
F.Command('recipe custom:gear item:999 1 engineering item:123=2')
F.Command('blueprint custom:gear on'); F.Command('station custom:gear workshop on'); F.Command('camp workshop 0')
assert(F.localProfile.recipes['custom:gear'].blueprint and F.localProfile.camps.workshop==clock)
F.Command('show'); F.Command('graph'); F.Command('help')
assert(F.ValidProfile(F.localProfile))
local before=F.Codec.Encode(F.localProfile); F.Command('recipe bad'); assert(before==F.Codec.Encode(F.localProfile))
F.Command('share on')
-- Normal transport refusals are user-facing notices, not Lua exceptions.
local savedGuild,savedGroup,savedRaid=IsInGuild,IsInGroup,IsInRaid
function IsInGuild() return false end
function IsInGroup() return false end
function IsInRaid() return false end
F.Net.queue={}; F.db.settings.locale='ruRU'
local function notice(command,expected)
    local count=#chatMessages
    F.Command(command)
    assert(#chatMessages==count+1)
    local text=chatMessages[#chatMessages]
    assert(text:find(expected,1,true))
    assert(not text:find('Bootstrap.lua',1,true) and not text:find(F.L('Ошибка: '),1,true))
end
notice('sync',F.L('Для обмена нужна гильдия или обычная группа.'))
local requests=F.Codec.Encode(F.db.requests)
notice('request item:999 1',F.L('Для обмена нужна гильдия или обычная группа.'))
assert(#F.Net.queue==0 and F.Codec.Encode(F.db.requests)==requests)
F.db.settings.locale='enUS'
notice('sync',F.L('Для обмена нужна гильдия или обычная группа.'))
F.db.settings.sharing=false
notice('sync',F.L('Обмен выключен: /fn share on'))
F.db.settings.sharing=true
local available=F.Net.available; F.Net.available=false
notice('sync',F.L('API обмена недоступен.'))
F.Net.available=available
IsInGuild,IsInGroup,IsInRaid=savedGuild,savedGroup,savedRaid
notice('sync',F.L('Синхронизация поставлена в очередь.'))
assert(#F.Net.queue>0)
F.Net.queue={}; F.db.settings.locale=nil
'''),
]
for name, body in tests:
    a.execute(body)
    print('PASS', name)

def drain(sender, receiver, name, reverse=False):
    queue = sender.globals().ForeverNet.Net.queue
    messages = [queue[i].text for i in range(1, len(queue) + 1)]
    sender.execute('ForeverNet.Net.queue = {}')
    if reverse: messages.reverse()
    for text in messages:
        receiver.globals().ForeverNet.Net.Receive('ForeverNet1', text, 'GUILD', name + '-Realm')
    return messages

b.execute('ForeverNet.db.settings.sharing=true')
a.execute('assert(ForeverNet.Net.Publish())')
wire = drain(a,b,'Alice',reverse=True)
b.execute("assert(ForeverNet.db.profiles['Alice-Realm'].recipes['custom:gear'].blueprint)")
for text in wire: b.globals().ForeverNet.Net.Receive('ForeverNet1',text,'GUILD','Alice-Realm')
b.execute("assert(ForeverNet.ValidProfile(ForeverNet.db.profiles['Alice-Realm']))")
print('PASS P2P profile reassembly, reverse order and duplicates')

ok, request_id = a.globals().ForeverNet.Requests.Create('item:999', 1)
assert ok
drain(a,b,'Alice')
assert b.globals().ForeverNet.Requests.Accept(request_id) is True
drain(b,a,'Bob')
drain(a,b,'Alice')
for lua in [a,b]:
    r=lua.globals().ForeverNet.db.requests[request_id]
    assert r.status=='accepted' and r.assignee=='Bob-Realm'
a.globals().ForeverNet.Requests.Receive('OFFER',a.table(id=request_id),'Charlie-Realm','GUILD')
assert a.globals().ForeverNet.db.requests[request_id].assignee=='Bob-Realm'
assert a.globals().ForeverNet.Requests.Close(request_id,'done') is True
drain(a,b,'Alice')
assert b.globals().ForeverNet.db.requests[request_id].status=='done'
print('PASS request lifecycle and first-offer arbitration')
b.execute("clock=clock+1801; ForeverNet.Prune(); assert(next(ForeverNet.db.requests)==nil); assert(ForeverNet.db.profiles['Alice-Realm']==nil)")
print('PASS request expiry and stale peer cleanup')
a.execute("ForeverNet.Command('share off'); assert(#ForeverNet.Net.queue==0); assert(not ForeverNet.Net.Publish())")
print('PASS sharing off clears queue')
a.execute(r'''
local F=ForeverNet
function GetTradeSkillLine() return 'Leatherworking',72 end
function GetNumTradeSkills() return 1 end
function GetTradeSkillInfo() return 'Test item','optimal' end
function GetTradeSkillItemLink() return 'item:222' end
function GetTradeSkillRecipeLink() return 'enchant:333' end
function GetTradeSkillNumReagents() return 1 end
function GetTradeSkillReagentInfo() return 'Test reagent',nil,2 end
function GetTradeSkillReagentItemLink() return 'item:444' end
function GetTradeSkillNumMade() return 1,1 end
assert(F.Adapter.Scan())
assert(F.localProfile.recipes['spell:333'].reagents['item:444']==2)
F.localProfile.recipes['spell:333'].blueprint=true
assert(F.Adapter.Scan() and F.localProfile.recipes['spell:333'].blueprint)
function IsTradeSkillLinked() return true end
assert(not F.Adapter.Scan())
function IsTradeSkillLinked() return false end
function GetTradeSkillReagentItemLink() return nil end
local snapshot=F.Codec.Encode(F.localProfile)
assert(not F.Adapter.Scan() and F.Codec.Encode(F.localProfile)==snapshot)
''')
print('PASS scan merge, Blueprint preservation, linked profession and cache miss')
a.execute(r'''
local F=ForeverNet
F.db.settings.sharing=true
local r={id='NewPeer-Realm:123:1',item='item:222',quantity=1,rev=2,expires=clock+100,status='accepted',assignee='Bob-Realm'}
F.Requests.Receive('REQUEST',r,'NewPeer-Realm','GUILD')
assert(F.db.requests[r.id].status=='accepted')
local forged=F.Copy(r); forged.id='Alice-Realm:forged'
F.Requests.Receive('REQUEST',forged,'NewPeer-Realm','GUILD')
assert(F.db.requests[forged.id]==nil)
local bad=F.Copy(r); bad.assignee=nil; assert(not F.Requests.Valid(bad))
F.Net.Receive('ForeverNet1','1|1.1|999|1|junk','GUILD','NewPeer-Realm')
F.Net.Receive('ForeverNet1','2|1.1|1|1|junk','GUILD','NewPeer-Realm')
assert(next(F.Net.buffers)==nil)
F.UI.page='recipes'; F.UI.Status()
F.UI.rows[1].scripts.OnClick(F.UI.rows[1]); assert(F.UI.item:GetText()~='')
F.UI.page='requests'; F.UI.Status(); F.UI.rows[1].scripts.OnClick(F.UI.rows[1]); assert(F.UI.requestID~=nil)
''')
print('PASS late snapshots, forged owners, malformed fragments and UI selections')
ui = client('UIRegression')
ui.execute(r'''
local F=ForeverNet
assert(CreateFrame('EditBox').GetTextHeight==nil)
assert(CreateFrame('EditBox').GetStringHeight==nil)
F.UI.Status() -- Direct call: no command pcall can conceal this regression.
assert(F.UI.body:GetObjectType()=='Frame')
assert(F.UI.bodyText:GetObjectType()=='FontString')
for _, page in ipairs({'network','recipes','requests','chain'}) do
    local nav=F.UI.navigation[page]; nav.scripts.OnMouseUp(nav,'LeftButton',true)
    assert(F.UI.page==page)
end
F.UI.Show(string.rep('Long line for testing text wrapping. ',100))
assert(F.UI.body:GetHeight()>290)
F.UI.details:SetVerticalScroll(200)
F.UI.Show('Short text')
assert(F.UI.body:GetHeight()==240 and F.UI.details:GetVerticalScroll()==0)
F.UI.Show('item|text'); assert(F.UI.bodyText:GetText()=='item||text')
''')
print('PASS UI regression: strict widget types, all tabs, long text and scroll reset')
modern = client('Modern')
modern.execute((ROOT/'tests/modern_scan.lua').read_text(encoding='utf-8'))
print('PASS Forever scan: no legacy API, learned recipes, atomic merge and unsupported costs')
workflow = client('Workflow')
workflow.execute((ROOT/'tests/workflow.lua').read_text(encoding='utf-8'))
print('PASS item selection, preferred crafter, shortages, requests, removed sample command and minimap')
bank = client('BankTest')
bank.execute((ROOT/'tests/bank_settings.lua').read_text(encoding='utf-8'))
print('PASS bank visits, transfers, loading, empty bank, character isolation and settings')
from network_transport import run_transport_tests
run_transport_tests(client)
updates=client('UpdatesTest')
updates.execute((ROOT/'tests/updates.lua').read_text(encoding='utf-8'))
print('PASS addon update hints: semantic versions, P2P advertisement, old clients, notification toggle and download URL')
locales=client('LocaleTest')
locales.execute((ROOT/'tests/localization.lua').read_text(encoding='utf-8'))
print('PASS all 12 locales: full dictionaries, format tokens, commands, language selector, UTF-8 search and localized update windows')
identity=client('IdentityTest')
identity.execute((ROOT/'tests/identity.lua').read_text(encoding='utf-8'))
print('PASS Forever name/surname identity: self aliases, saved profile/bank migration, distinct crafters and old request IDs')
from forever_transport import run_forever_transport_tests
run_forever_transport_tests(client)
run_forever_transport_tests(client,guild=True)
profile=client('ProfileTest')
profile.execute((ROOT/'tests/network_profile.lua').read_text(encoding='utf-8'))
print('PASS network profiles: profession groups, collapsible headers, measured cards, Blueprint styling, pinned crafter, empty profiles and all locales')
appearance=client('AppearanceTest')
appearance.execute((ROOT/'tests/appearance.lua').read_text(encoding='utf-8'))
print('PASS profession appearance: opaque dark panels, text contrast, readable fonts, native side tabs, click boundaries, selected state and distinct section strips')
filters=client('FiltersTest')
filters.execute((ROOT/'tests/recipe_filters.lua').read_text(encoding='utf-8'))
print('PASS recipe filters: provider deduplication, UI combinations/reset, all locales, channel names, native scrollbar wheel/thumb binding')
favorites=client('FavoriteTest')
favorites.execute((ROOT/'tests/favorites.lua').read_text(encoding='utf-8'))
import json
def saved_literal(value):
    if hasattr(value, 'items'):
        return '{'+','.join('['+saved_literal(k)+']='+saved_literal(v) for k,v in value.items())+'}'
    if isinstance(value,str): return json.dumps(value,ensure_ascii=False)
    if isinstance(value,bool): return 'true' if value else 'false'
    if value is None: return 'nil'
    return str(value)
saved=saved_literal(favorites.globals().ForeverNetDB)
reloaded=client('FavoriteTest',setup='clock=1800259200; ForeverNetDB='+saved)
reloaded.execute("""
local F=ForeverNet
F.Prune()
assert(#F.Keys(F.db.favorites.profiles)==4 and #F.Keys(F.db.favorites.recipes)==5)
assert(F.localProfile.recipes.r6 and F.Bank.Count('item:999')==17)
assert(not F.db.profiles['Crafter6-Realm'])
for owner in pairs(F.db.favorites.profiles) do assert(F.db.profiles[owner]) end
F.UI.Navigate('recipes'); assert(F.UI.recipeGroups[1].id=='favorite-recipes')
""")
print('PASS favorites: independent limits, star buttons, pinned ordering, expired ordinary peers, retained favorites, recipe/bank reload and all locales')
sources=client('SourcesTest')
sources.execute((ROOT/'tests/material_sources.lua').read_text(encoding='utf-8'))
print('PASS material sources: actual leather conversion, partial stock, alternate recipes/crafters, surplus, shared deficits, cycles, unavailable choices and full-chain UI rebuild')
cjk=client('FontsTest')
cjk.execute((ROOT/'tests/cjk_fonts.lua').read_text(encoding='utf-8'))
from fontTools.ttLib import TTFont
import hashlib
manifest=json.loads((ROOT/'Fonts/manifest.json').read_text(encoding='utf-8'))
for locale,file in [('koKR','ForeverNetCJKKR.ttf'),('zhCN','ForeverNetCJKSC.ttf'),('zhTW','ForeverNetCJKTC.ttf')]:
    font=TTFont(ROOT/'Fonts'/file)
    assert font.sfntVersion=='\x00\x01\x00\x00' and 'glyf' in font and 'fvar' not in font and 'gvar' not in font
    cmap=font.getBestCmap()
    text=(ROOT/'Locales'/f'{locale}.lua').read_text(encoding='utf-8')+(ROOT/'FeatureLocales.lua').read_text(encoding='utf-8')+'ForeverNet 简体中文 繁體中文 한국어 АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ абвгдеёжзийклмнопрстуфхцчшщъыьэюя éàößŒñçã'
    missing={c for c in text if ord(c)>127 and ord(c) not in cmap}
    assert not missing,(locale,sorted(missing))
    assert manifest['fonts'][file]['sha256']==hashlib.sha256((ROOT/'Fonts'/file).read_bytes()).hexdigest()
    assert font['name'].getDebugName(1).startswith('ForeverNet CJK')
    font.close()
assert 'SIL OPEN FONT LICENSE Version 1.1' in (ROOT/'Fonts/OFL.txt').read_text(encoding='utf-8')
print('PASS bundled CJK fonts: static TTF/glyph coverage/hashes/license, Russian-client language menu, all button states, titles, inputs, tooltips, live switch and native font isolation')
queue_client=client('QueueTest')
queue_client.execute((ROOT/'tests/queue.lua').read_text(encoding='utf-8'))
saved_queue=saved_literal(queue_client.globals().ForeverNetDB)
queue_reload=client('QueueTest',setup='ForeverNetDB='+saved_queue)
queue_reload.execute("assert(#ForeverNet.Queue.data.goals==1 and ForeverNet.Queue.data.goals[1].quantity==3)")
print('PASS shared crafting queue: inventory once, surplus reuse, source selection, editing, bounds, private character storage, dashboard, all locales and fresh-runtime reload')
lockdown=client('LockdownTest')
lockdown.execute((ROOT/'tests/network_lockdown.lua').read_text(encoding='utf-8'))
print('PASS messaging lockdown: actual enum 11, chat flags do not block addon comms, preserved queue, no notice spam, complete transfer restart after TTL and disabled sharing')
recovery=client('NetworkRecoveryTest')
recovery.execute((ROOT/'tests/network_recovery.lua').read_text(encoding='utf-8'))
print('PASS network recovery: intermittent rejections finish complete profiles, bounded backoff/notices, no duplicate sync/request snapshots, fresh tokens only for expired partial messages, private diagnostics and disabled-sharing reset')
throttle=client('NetworkThrottleTest')
throttle.execute((ROOT/'tests/network_throttle.lua').read_text(encoding='utf-8'))
print('PASS network rate limits: codes 3/8 retain the queue beyond 20 attempts, bounded silent backoff with one-minute auto sync, complete profile after recovery, learned pacing/stable recovery, distinct lockdown/throttle state, all locales and share-off reset')
market_client=client('MarketTest')
market_client.execute((ROOT/'tests/market.lua').read_text(encoding='utf-8'))
saved_market=saved_literal(market_client.globals().ForeverNetDB)
market_reload=client('MarketTest',setup='clock=1808899200; ForeverNetDB='+saved_market)
market_reload.execute("assert(ForeverNet.Market.Quote('item:2318',8).minimum==1100)")
print('PASS market prices/history: depth, whole-lot optimization, unavailable prices, overflow, stale/partial flags, daily retention, gap rendering, scope isolation and fresh-runtime reload')
auction_client=client('AuctionTest')
auction_client.execute((ROOT/'tests/auction.lua').read_text(encoding='utf-8'))
print('PASS auction integration: native fourth tab, readiness, pagination, own auctions, bid-only/variant exclusion, cancellations, external-search coexistence and bounded retries')
slow=client('SlowTransportTest')
slow.execute((ROOT/'tests/slow_transport.lua').read_text(encoding='utf-8'))
print('PASS slow profile reassembly: continuing transfers survive over 150 seconds; duplicates do not refresh idle expiry')
tracker=client('TrackerTest')
tracker.execute((ROOT/'tests/tracker.lua').read_text(encoding='utf-8'))
tracker.execute('ForeverNet.Tracker.Toggle(true)')
saved_tracker=saved_literal(tracker.globals().ForeverNetDB)
tracker_reload=client('TrackerTest',setup='ForeverNetDB='+saved_tracker)
tracker_reload.execute('assert(ForeverNet.Queue.data.tracker and ForeverNet.Tracker.frame:IsShown())')
print('PASS material tracker: shared stock, bank withdrawal, acquisition/crafting updates, bank preference, independent window, character persistence and all locales')
search=client('AuctionSearchTest')
search.execute((ROOT/'tests/auction_search.lua').read_text(encoding='utf-8'))
print('PASS native auction lookup: closed/not-ready guards, loading names, scanner handoff, category reset and native search without purchases')
profession_actions=client('ProfessionActionsTest')
profession_actions.execute((ROOT/'tests/profession_actions.lua').read_text(encoding='utf-8'))
print('PASS native profession actions: current selected recipe, read-only previews, finished-item quantities, shared bags/bank, pinned plans, own-mode/loading/unsupported guards, limits, metadata, layout and all locales')
source_costs=client('SourceCostsTest')
source_costs.execute((ROOT/'tests/source_costs.lua').read_text(encoding='utf-8'))
print('PASS source comparisons: whole-queue stock/surplus, batch rounding, cash deltas, unknown service fees, stale/partial/insufficient prices, cycles, bounded previews, pinned goals, UI choices and all locales')
queue_sets=client('QueueSetsTest')
queue_sets.execute((ROOT/'tests/queue_sets.lua').read_text(encoding='utf-8'))
saved_sets=saved_literal(queue_sets.globals().ForeverNetDB)
sets_reload=client('QueueSetsTest',setup='ForeverNetDB='+saved_sets)
sets_reload.execute("assert(ForeverNet.Queue.data.sets['Поход'].goals[1].quantity==3 and ForeverNet.Queue.data.sets['Поход'].sources['item:10']=='external' and ForeverNet.Queue.data.tracker)")
print('PASS queue sets: private persistence, pins/sources, preview/replace/append/undo, atomic caps, live stock recalculation, bag-only goal cleanup without surplus or double allocation and all locales')
restock=client('RestockTest')
restock.execute((ROOT/'tests/restock.lua').read_text(encoding='utf-8'))
saved_restock=saved_literal(restock.globals().ForeverNetDB)
restock_reload=client('RestockTest',setup='ForeverNetDB='+saved_restock)
restock_reload.execute("assert(ForeverNet.Queue.data.goals[1].mode=='stock' and ForeverNet.Queue.data.goals[1].quantity==20 and ForeverNet.Queue.data.sets.Supplies.goals[1].mode=='stock')")
print('PASS stock targets: use/refill events, bank-retained targets versus withdrawals, shared allocations, cleanup protection, duplicates/atomic loading, mode UI, pins/sources, all locales and fresh-runtime persistence')
crafters=client('CrafterFinderTest')
crafters.execute((ROOT/'tests/crafter_finder.lua').read_text(encoding='utf-8'))
print('PASS crafter finder: native learned/unlearned lookup, exact item IDs, no self/duplicate masters, favorites/age/skills, selected-crafter plans and facilities, changed-profile guards, read-only behavior and all locales')
layout=client('UILayoutTest')
layout.execute((ROOT/'tests/ui_layout.lua').read_text(encoding='utf-8'))
print('PASS compact interface: all locales, measured headers/actions, scrolling settings, inline language list, update/tracker bounds, CJK filters, recycled rows and actual-range scroll preservation')
toolbar=client('ToolbarLayoutTest')
toolbar.execute((ROOT/'tests/toolbar_layout.lua').read_text(encoding='utf-8'))
print('PASS horizontal layout: 12 locales, native toolbar 350/620/640/800/1000 widths, right-side action placement, adaptive natural widths, inline queue tools/goal actions, long-label fallback and read-only refresh')
right_panel=client('RightPanelTest')
right_panel.execute((ROOT/'tests/right_panel.lua').read_text(encoding='utf-8'))
print('PASS dense right panel: no overview/material/master overlap, measured multiline and empty-card offsets, two-column materials, bounded long text, no repeated master/item names, reusable blocks/cards, passive list rows, goal-first queue and expandable stock on all locales')
protected_diagnostics=client('ProtectedDiagnosticsTest')
protected_diagnostics.execute((ROOT/'tests/protected_diagnostics.lua').read_text(encoding='utf-8'))
print('PASS protected-action diagnostics: read-only bank scans, native item-use functions unchanged, own-event capture, bounded private stacks, no spam, explicit taint-log switch and original CVar restoration; no native taint reproduction claimed')
automation=client('AutomationTest')
automation.execute((ROOT/'tests/automation.lua').read_text(encoding='utf-8'))
saved_automation=saved_literal(automation.globals().ForeverNetDB)
automation_reload=client('AutomationTest',setup='ForeverNetDB='+saved_automation)
automation_reload.execute('assert(ForeverNet.db.settings.autoScan==false and ForeverNet.db.settings.autoSources==false)')
print('PASS automation: fresh eligible whole-plan costs, manual/root pins, transient choices, stale/partial/volume guards, bounded work, live inventory/quantity refresh, own-profession debounce/loading/close/disable and settings persistence')
graphical=client('GraphicalTest')
graphical.execute((ROOT/'tests/graphical_ui.lua').read_text(encoding='utf-8'))
print('PASS graphical interface: all locales, profession progress, counters, material tooltips, reagent icons, measured long text/counts, queue disclosure, contextual navigation and recycled widget cleanup')
modern=client('ModernBoardTest')
modern.execute((ROOT/'tests/modern_board.lua').read_text(encoding='utf-8'))
print('PASS modern theme/queue: owned flat chrome/buttons, private Sans fonts, all locales, single materials/crafts board, autosaved valid quantity, selection/reordering/stock controls, scrolling sets menu, unknown final items and widget/input cleanup')
styles=client('StyleTest')
styles.execute((ROOT/'tests/theme_styles.lua').read_text(encoding='utf-8'))
style_reload=client('StyleTest',setup='ForeverNetDB='+saved_literal(styles.globals().ForeverNetDB))
style_reload.execute("ForeverNet.UI.Status(); assert(ForeverNet.db.settings.uiStyle=='classic' and ForeverNet.UI.frame.NineSlice:IsShown() and ForeverNet.IsFavorite('market','item:777'))")
print('PASS live styles: owned native/flat chrome, restored button textures, side tabs, palette/fonts, CJK choices, stable font allocation, private data and fresh-runtime persistence')
sidebar=client('SidebarTest')
sidebar.execute((ROOT/'tests/sidebar_commands.lua').read_text(encoding='utf-8'))
print('PASS sidebar and commands: home progress without duplicate professions, independent market favourites/limit/group/search/collapse, commands button, removed sample, version-only startup and all locales')
large_buttons=client('LargeButtonTest',setup="GameFontNormal:SetFont('Fonts\\\\FRIZQT__.TTF',18,''); GameFontHighlight:SetFont('Fonts\\\\FRIZQT__.TTF',18,'')")
large_buttons.execute((ROOT/'tests/large_buttons.lua').read_text(encoding='utf-8'))
print('PASS larger Russian buttons: measured 18px state fonts, header/pane/filter spacing, bottom actions, language menu row heights and modal error/action separation in both styles')
version=client('VersionTest')
version.execute((ROOT/'tests/version_channel.lua').read_text(encoding='utf-8'))
version_reload=client('VersionTest',setup='ForeverNetDB='+saved_literal(version.globals().ForeverNetDB))
version_reload.execute("ForeverNet.Updates.Login(); assert(ForeverNet.Updates.latest=='1.1.2' and ForeverNet.Updates.cached and chatMessages[#chatMessages]:find('1.1.2',1,true))")
print('PASS built-in version checks: no external helper, sharing-independent metadata, guild/home/instance scopes, malformed/self guards, coalesced replies, bounded throttled retries, no chat spam, mute/cache/upgraded cleanup and fresh-runtime reminders')
print('All Lua 5.1 checks passed. Client rendering still requires an in-game check.')
