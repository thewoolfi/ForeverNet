local F,T,U=ForeverNet,ForeverNet.Theme,ForeverNet.UI
local owner=CreateFrame('Frame',nil,UIParent)
local shift=false
IsShiftKeyDown=function() return shift end
local native=CreateFrame('GameTooltip')
local nativeShopping={CreateFrame('GameTooltip'),CreateFrame('GameTooltip')}
GameTooltip=native; ShoppingTooltip1,ShoppingTooltip2=unpack(nativeShopping)
local normalFont=GameFontNormal:GetFont()
local forbidden=function() error('Comparison must not equip or use an item') end
C_Item={GetItemCount=function() return 0 end,GetItemInfo=function(id) return 'Item '..id end,EquipItemByName=forbidden}
C_Container={UseContainerItem=forbidden,PickupContainerItem=forbidden}
C_TooltipComparison={CompareItem=forbidden}
GameTooltip_ShowCompareItem=forbidden
mockItemTooltips={[1]={{'New armor'},{'120 Armor'}},[2]={{'Crafting material'}}}
local comparisons=0
local paired=false
local equipped='Equipped armor'
TooltipComparisonManager={tooltip=native}
function TooltipComparisonManager:Clear(tooltip)
    if self.tooltip==tooltip then
        for _,tip in ipairs(tooltip.shoppingTooltips) do tip:Hide() end
        self.tooltip=nil
    end
end
local function compare(self,item,tooltip)
    comparisons=comparisons+1
    assert(self~=TooltipComparisonManager and item.hyperlink=='item:'..tooltip.nativeItem)
    assert(tooltip~=native and tooltip.shoppingTooltips[1]~=ShoppingTooltip1 and tooltip.shoppingTooltips[2]~=ShoppingTooltip2)
    self.tooltip=tooltip
    if tooltip.nativeItem~=1 then return end -- The native engine decides whether it can compare.
    for i,tip in ipairs(tooltip.shoppingTooltips) do
        tip:SetOwner(tooltip,'ANCHOR_NONE')
        tip.CompareHeader.Label:SetText('Equipped')
        tip:SetText(i==1 and equipped or 'Second equipped item')
        tip:AddLine(i==1 and '100 Armor' or '80 Armor')
        tip:AddLine('|cff00ff00+20 Armor|r') -- Client-supplied colored stat delta remains intact.
        tip:SetShown(i==1 or paired)
    end
end
TooltipComparisonManager.CompareItem=compare
local function enter(item)
    T.BindItemTooltip(owner,item,'Item','Planning hint')
    owner.scripts.OnEnter(owner)
end
local function key(name,value)
    frames[1].scripts.OnEvent(frames[1],'MODIFIER_STATE_CHANGED',name,value)
end
assert(frames[1].events.MODIFIER_STATE_CHANGED and frames[1].events.PLAYER_EQUIPMENT_CHANGED)
enter('item:1')
assert(comparisons==0 and not T.shoppingTooltips[1]:IsShown())
assert(T.tooltip.shoppingTooltips==T.shoppingTooltips)
assert(T.shoppingTooltips[1].template=='ShoppingTooltipTemplate' and T.shoppingTooltips[1].clamped)
-- Shift works without moving the mouse and must not trigger a full UI repaint.
U.dirty=false; shift=true; key('LSHIFT',1)
assert(not U.dirty and T.tooltip:IsShown() and comparisons==1)
assert(T.shoppingTooltips[1]:IsShown() and not T.shoppingTooltips[2]:IsShown())
assert(T.shoppingTooltips[1].title:GetText()=='Equipped armor')
assert(T.shoppingTooltips[1].line:GetText()=='|cff00ff00+20 Armor|r')
assert(nativeShopping[1]:IsShown() and nativeShopping[2]:IsShown())
key('RSHIFT',1); key('LCTRL',1); assert(comparisons==1)
-- Equipment changes request fresh native slot information, including paired items.
paired=true; equipped='New equipped armor'
frames[1].scripts.OnEvent(frames[1],'PLAYER_EQUIPMENT_CHANGED',5,true)
assert(comparisons==2 and T.shoppingTooltips[1].title:GetText()==equipped and T.shoppingTooltips[2]:IsShown())
U.dirty=false; key('LSHIFT',0)
assert(T.shoppingTooltips[1]:IsShown()) -- Right Shift remains held.
shift=false; key('RSHIFT',0)
assert(not U.dirty and T.tooltip:IsShown() and not T.shoppingTooltips[1]:IsShown() and not T.shoppingTooltips[2]:IsShown())
-- Holding Shift before hover, rebuilding item data and leaving/reusing cards.
shift=true; enter('item:1'); assert(T.shoppingTooltips[2]:IsShown())
local prior=comparisons
T.tooltip:GetPrimaryTooltipInfo().rebuildPostCall(T.tooltip); assert(comparisons==prior+1)
owner.scripts.OnLeave(owner); assert(not T.tooltip:IsShown() and not T.shoppingTooltips[1]:IsShown())
enter('item:1'); owner:Hide(); assert(not T.shoppingTooltips[1]:IsShown()); owner:Show()
enter('item:1'); T.BindItemTooltip(owner,'item:2','Material'); assert(not T.shoppingTooltips[1]:IsShown())
owner.scripts.OnEnter(owner); assert(T.tooltip:IsShown() and not T.shoppingTooltips[1]:IsShown())
-- Uncached candidate items wait for the native item description before comparing.
enter('item:99'); prior=comparisons; assert(not T.shoppingTooltips[1]:IsShown())
key('LSHIFT',1); assert(comparisons==prior)
mockItemTooltips[99]={{'Loaded material'}}
T.TooltipEvent('ITEM_DATA_LOAD_RESULT',99,true); assert(comparisons==prior+1)
enter('item:1'); T.TooltipEvent('GET_ITEM_INFO_RECEIVED',1,false); assert(not T.shoppingTooltips[1]:IsShown())
-- Generic text, custom IDs and missing/failed comparison APIs leave basic info usable.
prior=comparisons; enter('custom:ore'); assert(comparisons==prior and T.tooltip:IsShown())
enter('item:1'); T.ShowTooltip(owner,'Help','Text'); assert(not T.shoppingTooltips[1]:IsShown())
T.itemComparison=nil; TooltipComparisonManager.CompareItem=nil
enter('item:1'); assert(T.tooltip:IsShown() and not T.shoppingTooltips[1]:IsShown())
TooltipComparisonManager.CompareItem=function(self,item,tooltip) tooltip.shoppingTooltips[1]:Show(); error('Unavailable') end
enter('item:1'); assert(T.tooltip:IsShown() and not T.shoppingTooltips[1]:IsShown())
TooltipComparisonManager.CompareItem=compare; T.itemComparison=nil
for _,style in ipairs({'modern','classic'}) do
    T.SetStyle(style)
    for _,locale in ipairs(F.LocaleOrder) do
        F.db.settings.locale=locale; enter('item:1')
        for _,tip in ipairs(T.shoppingTooltips) do
            assert(tip:IsShown() and tip.CompareHeader:GetWidth()>=tip.CompareHeader.Label:GetUnboundedStringWidth()+30)
            assert(tip.title:GetFont()==(T.fontFiles[locale] or (style=='modern' and T.defaultFont or normalFont)))
            assert(tip.CompareHeader.Label:GetFont()==tip.title:GetFont())
        end
    end
end
-- Hiding our tooltip must not clear another tooltip's active comparison.
TooltipComparisonManager.tooltip=native
T.HideTooltip(); assert(TooltipComparisonManager.tooltip==native)
assert(nativeShopping[1]:IsShown() and nativeShopping[2]:IsShown())
assert(GameTooltip==native and GameFontNormal:GetFont()==normalFont)
assert(C_Container.UseContainerItem==forbidden and C_Item.EquipItemByName==forbidden)
