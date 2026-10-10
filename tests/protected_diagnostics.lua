local F=ForeverNet
local initial=F.Codec.Encode(F.localProfile)
local forbidden=0
local function protected() forbidden=forbidden+1; error('Protected action must not be called') end
Enum={BankType={Character=1}}
C_Bank={CanUseBank=function() return true end,FetchPurchasedBankTabIDs=function() return {6} end}
C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemID=function() return 1 end,
    GetContainerItemInfo=function() return {itemID=1,stackCount=3} end,UseContainerItem=protected,
    PickupContainerItem=protected,SetBagPortraitTexture=protected}
BankFrame=setmetatable({bankType=1},{__newindex=function() error('No native bank frame writes') end})
local bankPointer=BankFrame
F.Bank.Event('BANKFRAME_OPENED'); F.Bank.Tick(.31); F.Bank.Event('BANKFRAME_CLOSED')
assert(F.Bank.Count('item:1')==3 and not F.Bank.open and BankFrame==bankPointer)
assert(C_Container.UseContainerItem==protected and forbidden==0)
local frame=frames[1]
assert(frame.events.ADDON_ACTION_BLOCKED and frame.events.ADDON_ACTION_FORBIDDEN)
frame.scripts.OnEvent(frame,'ADDON_ACTION_FORBIDDEN','OtherAddon','UseContainerItem')
assert(not F.db.diagnostics)
debugstack=function() return string.rep('Private stack ',1000) end
local before=#chatMessages
for i=1,7 do frame.scripts.OnEvent(frame,'ADDON_ACTION_FORBIDDEN',F.name,'UseContainerItem') end
assert(#F.db.diagnostics.protectedActions==5 and #chatMessages==before+1)
local last=F.db.diagnostics.protectedActions[5]
assert(last.event=='ADDON_ACTION_FORBIDDEN' and last.action=='UseContainerItem' and #last.stack==4096 and not last.bankOpen)
local value='1'; local writes=0
C_CVar={GetCVar=function(key) assert(key=='taintLog'); return value end,
    SetCVar=function(key,v) assert(key=='taintLog'); writes=writes+1; value=v end}
F.Command('taint on'); assert(value=='2' and F.db.diagnostics.taintOriginal=='1')
F.Command('taint on'); assert(F.db.diagnostics.taintOriginal=='1')
F.Command('taint status'); assert(value=='2' and writes==2)
F.Command('taint off'); assert(value=='1' and not F.db.diagnostics.taintOriginal)
C_CVar.SetCVar=function() error('CVar unavailable') end
F.Command('taint on'); assert(not F.db.diagnostics.taintOriginal)
assert(forbidden==0 and F.Codec.Encode(F.localProfile)==initial)

-- Capture a bounded read-only sequence across bank reads and addon refreshes.
local secure=true
BankPanel=setmetatable({bankType=1},{__newindex=function() error('No native bank panel writes') end})
issecurevariable=function(object,key)
    if object==BankPanel and key=='bankType' then return secure,secure and nil or 'ReportedSource' end
    return true
end
InCombatLockdown=function() return false end
F.db.diagnostics.taintOriginal='0'; value='2'
C_CVar.SetCVar=function(_,v) value=v end
local refresh=F.Settings.Refresh
F.Settings.Refresh=function() secure=false end -- Simulate a state change; do not edit native fields.
F.Bank.Event('BANKFRAME_OPENED'); clock=clock+1; F.Bank.Tick(.31)
clock=clock+2; F.Bank.Event('BANKFRAME_CLOSED')
local trace=F.db.diagnostics.bankTrace
assert(#trace==5 and trace[1].stage=='bank:open' and trace[2].stage=='scan:before')
assert(trace[3].stage=='scan:read' and trace[3].security['BankPanel.bankType'].secure)
assert(trace[4].stage=='scan:ui' and trace[4].security['BankPanel.bankType'].source=='ReportedSource')
assert(trace[5].stage=='bank:close' and not trace[5].bankOpen)
F.Settings.Refresh=refresh
F.ProtectedAction('ADDON_ACTION_FORBIDDEN',F.name,'UseContainerItem()')
local captured=F.db.diagnostics.protectedActions[5]
assert(captured.context.bankScanned==clock-2 and captured.context.bankClosed==clock and captured.context.bankScans==2)
assert(captured.context.inCombat==false and captured.context.taintLog=='2')
assert(captured.context.security['BankPanel.bankType'].secure==false)
assert(captured.bankTrace[4].security['BankPanel.bankType'].source=='ReportedSource')
for i=1,30 do F.BankTrace('test') end
assert(#F.db.diagnostics.bankTrace==12 and #captured.bankTrace==5) -- Snapshot is isolated from later events.
local count=#chatMessages; F.Command('taint status')
local text=table.concat(chatMessages,'\n')
assert(#chatMessages>count and text:find('taintLog=2',1,true) and text:find('ReportedSource',1,true))
assert(C_Container.UseContainerItem==protected and forbidden==0 and BankPanel.bankType==1)
F.Command('taint off'); assert(value=='0' and not F.db.diagnostics.bankTrace)
F.BankTrace('disabled'); assert(not F.db.diagnostics.bankTrace)
issecurevariable=nil; assert(not F.ProtectedContext().security)
issecurevariable=function() error('Unavailable') end; assert(not F.ProtectedContext().security)
