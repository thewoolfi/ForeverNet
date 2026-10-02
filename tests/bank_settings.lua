local F=ForeverNet
Enum={BankType={Character=0,Account=2}}
local usable=true
local slots={[6]={{itemID=200,stackCount=7}},[7]={{itemID=200,stackCount=3},{itemID=300,stackCount=2}}}
local loading=false
C_Bank={CanUseBank=function(kind) assert(kind==0); return usable end,
 FetchPurchasedBankTabIDs=function(kind) assert(kind==0); return {6,7} end}
C_Container={GetContainerNumSlots=function(bag) assert(bag==6 or bag==7); return loading and 0 or 2 end,
 GetContainerItemID=function(bag,slot) return slots[bag][slot] and slots[bag][slot].itemID end,
 GetContainerItemInfo=function(bag,slot) return slots[bag][slot] end}
F.Bank.Event('BANKFRAME_OPENED'); F.Bank.Tick(.4)
assert(F.Bank.Count('item:200')==10 and F.Bank.Count('item:300')==2)
slots[6][1].stackCount=4
F.Bank.Event('BAG_UPDATE_DELAYED'); F.Bank.Tick(.4)
assert(F.Bank.Count('item:200')==7)
loading=true; F.Bank.Event('BANKFRAME_OPENED'); F.Bank.Tick(.4)
assert(F.Bank.Count('item:200')==7)
usable=false; F.Bank.Event('BANKFRAME_CLOSED'); usable=true; loading=false; slots[6]={}; slots[7]={}
F.Bank.Tick(1); assert(F.Bank.Count('item:200')==7)
F.Bank.Event('BANKFRAME_OPENED'); F.Bank.Tick(.4)
assert(F.Bank.Count('item:200')==0) -- A fully loaded, empty bank replaces the snapshot.
slots[6][1]={itemID=200,stackCount=8}; F.Bank.Event('PLAYERBANKSLOTS_CHANGED'); F.Bank.Tick(.4)
function GetItemCount(id) return id==200 and 2 or 0 end
assert(F.Adapter.StockCount('item:200')==10)
F.db.settings.useBank=false; assert(F.Adapter.StockCount('item:200')==2)
F.db.settings.useBank=true
local snapshot=F.Codec.Encode(F.localProfile); assert(not snapshot:find('items',1,true))
local me=F.me; F.me='Other-Realm'; assert(F.Bank.Count('item:200')==0); F.me=me
F.db.settings.autoBank=false; slots[6][1].stackCount=9
assert(not F.Bank.Scan() and F.Bank.Count('item:200')==8)
F.Settings.Open(); assert(F.Settings.frame:IsShown())
assert(F.Settings.about:GetText():find('Andrew Woolfi',1,true))
local check=F.Settings.checks[4]; check:SetChecked(false); check.scripts.OnClick(check)
assert(F.db.settings.showMinimap==false)
local use=F.Settings.checks[3]; use:SetChecked(false); use.scripts.OnClick(use)
assert(F.Adapter.StockCount('item:200')==2)
F.db.settings.locale='ruRU'; F.Settings.Refresh(); assert(F.Settings.languageLabel:GetText()=='Язык интерфейса')
F.db.settings.locale='enUS'; F.Settings.Refresh(); assert(F.Settings.languageLabel:GetText()=='Interface language')

-- Settings must stay above the main window, including after live refresh.
F.UI.Status(); F.Settings.Open()
assert(F.Settings.frame.strata=='FULLSCREEN_DIALOG')
assert(F.Settings.background.color[4]==1)
F.UI.DataChanged(); F.UI.Tick(1)
assert(F.Settings.frame:IsShown() and F.Settings.frame.strata=='FULLSCREEN_DIALOG')

-- External links are copyable and remain correct in both languages.
assert(F.version=='0.3.3')
for _,field in ipairs({F.Settings.githubLink,F.Settings.supportLink}) do
    field.scripts.OnMouseUp(field); assert(field.highlighted and field.focused)
    local url=field:GetText(); field:SetText('modified'); assert(field:GetText()==url)
end
assert(F.Settings.githubLink:GetText()=='https://github.com/thewoolfi/ForeverNet')
assert(F.Settings.supportLink:GetText()=='https://boosty.to/andrewwoolfi')
F.db.settings.locale='ruRU'; F.Settings.Refresh(); assert(F.Settings.supportLabel:GetText()=='Поддержать автора на Boosty')
F.db.settings.locale='enUS'; F.Settings.Refresh(); assert(F.Settings.supportLabel:GetText()=='Support the author on Boosty')
