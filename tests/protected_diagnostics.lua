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
