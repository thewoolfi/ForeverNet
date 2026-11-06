local F=ForeverNet
local L=F.LootAdvisor

assert(L and type(L.ScanCandidates)=='function', 'LootAdvisor module missing')
F.Init()

-- 1. Hardcoded & Baseline Protections
assert(L.IsProtected(6948, 1, 0, 0), 'Hearthstone must be protected')
assert(L.IsProtected(140192, 1, 0, 0), 'Dalaran Hearthstone must be protected')
assert(L.IsProtected(2901, 1, 0, 0), 'Mining Pick must be protected')
assert(L.IsProtected(7005, 1, 0, 0), 'Skinning Knife must be protected')
assert(L.IsProtected(5956, 1, 0, 0), 'Blacksmith Hammer must be protected')
assert(L.IsProtected(6256, 1, 2, 20), 'Fishing Pole must be protected')
assert(L.IsProtected(4471, 1, 0, 0), 'Flint and Tinder must be protected')
assert(L.IsProtected(99991, 7, 12, 0), 'Quest item must be protected')
assert(L.IsProtected(99992, 4, 4, 1), 'Epic item must be protected')
assert(L.IsProtected(99993, 5, 4, 1), 'Legendary item must be protected')

-- 2. User Blacklist
F.db.settings.lootBlacklist={}
assert(not L.IsProtected(88881, 0, 0, 0), 'Unprotected grey item was marked protected')
L.ToggleBlacklist(88881)
assert(F.db.settings.lootBlacklist[88881]==true, 'ToggleBlacklist did not add item')
assert(L.IsProtected(88881, 0, 0, 0), 'Blacklisted item was not protected')
L.ToggleBlacklist(88881)
assert(F.db.settings.lootBlacklist[88881]==nil, 'ToggleBlacklist did not remove item')
assert(not L.IsProtected(88881, 0, 0, 0), 'Removed item remained protected')

-- 3. Reagents & Gear Protections
F.db.settings.lootProtectReagents=true
assert(L.IsProtected(2840, 1, 7, 0), 'Trade good must be protected when protectReagents=true')
assert(L.IsProtected(2447, 1, 5, 0), 'Reagent must be protected when protectReagents=true')
F.db.settings.lootProtectReagents=false
-- With protectReagents=false, non-grey trade goods can be suggested only if quality allows
F.db.settings.lootMaxQuality=1
assert(not L.IsProtected(2840, 1, 7, 0), 'Trade good remained protected when protectReagents=false and maxQuality=1')
F.db.settings.lootProtectReagents=true
F.db.settings.lootMaxQuality=0

F.db.settings.lootProtectGear=true
assert(L.IsProtected(19019, 1, 2, 0), 'Weapon must be protected when protectGear=true')
assert(L.IsProtected(4237, 1, 4, 0), 'Armor must be protected when protectGear=true')
F.db.settings.lootProtectGear=false
F.db.settings.lootMaxQuality=2
assert(not L.IsProtected(19019, 2, 2, 0), 'Weapon remained protected when protectGear=false and maxQuality=2')
F.db.settings.lootProtectGear=true
F.db.settings.lootMaxQuality=0

-- 4. Quality Thresholds
assert(not L.IsProtected(7073, 0, 0, 0), 'Grey junk 0 must be allowed when maxQuality=0')
assert(L.IsProtected(12345, 1, 0, 0), 'Common item 1 must be protected when maxQuality=0')
assert(L.IsProtected(23456, 2, 0, 0), 'Uncommon item 2 must be protected when maxQuality=0')

F.db.settings.lootMaxQuality=1
assert(not L.IsProtected(7073, 0, 0, 0))
assert(not L.IsProtected(12345, 1, 0, 0), 'Common item 1 must be allowed when maxQuality=1')
assert(L.IsProtected(23456, 2, 0, 0), 'Uncommon item 2 must be protected when maxQuality=1')

F.db.settings.lootMaxQuality=2
assert(not L.IsProtected(23456, 2, 0, 0), 'Uncommon item 2 must be allowed when maxQuality=2')
assert(L.IsProtected(34567, 3, 0, 0), 'Rare item 3 must be protected when maxQuality=2')

F.db.settings.lootMaxQuality=0

-- 5. Bag Scanner & Sorting
local mockItems={
    [0]={
        [1]={itemID=6948,count=1,quality=1,sellPrice=0},             -- Hearthstone (excluded)
        [2]={itemID=7073,count=5,quality=0,sellPrice=6},             -- Broken Fang (grey, total 30c)
        [3]={itemID=7074,count=1,quality=0,sellPrice=1},             -- Chipped Claw (grey, total 1c)
        [4]={itemID=8888,count=1,quality=0,sellPrice=0},             -- Ruined Pelt (grey, total 0c)
    },
    [1]={
        [1]={itemID=2840,count=20,quality=1,sellPrice=50,classID=7}, -- Copper Bar (reagent, excluded)
        [2]={itemID=9901,count=1,quality=1,sellPrice=10,classID=0},  -- White food (excluded when maxQuality=0)
    }
}

C_Container=C_Container or {}
C_Container.GetContainerNumSlots=function(bag) return bag<=1 and 4 or 0 end
C_Container.GetContainerItemInfo=function(bag,slot)
    local item=mockItems[bag] and mockItems[bag][slot]
    if not item then return nil end
    return {itemID=item.itemID,stackCount=item.count,quality=item.quality}
end

local savedGetItemInfo=GetItemInfo
GetItemInfo=function(id)
    for _,bagItems in pairs(mockItems) do
        for _,item in pairs(bagItems) do
            if item.itemID==id then
                return 'Item '..id,'|cffffffff|Hitem:'..id..'|h[Item '..id..']|h|r',item.quality,1,1,'Misc','Junk',1,'',
                    'Interface\\Icons\\INV_Misc_QuestionMark',item.sellPrice,item.classID or 0,0
            end
        end
    end
    return nil
end

local candidates=L.ScanCandidates()
assert(#candidates==3, 'Expected 3 grey candidates, got '..#candidates)
-- Order must be: 8888 (0c total), then 7074 (1c total), then 7073 (30c total)
assert(candidates[1].itemID==8888 and candidates[1].totalPrice==0, '1st candidate must be 0c unsellable trash')
assert(candidates[2].itemID==7074 and candidates[2].totalPrice==1, '2nd candidate must be 1c trash')
assert(candidates[3].itemID==7073 and candidates[3].totalPrice==30, '3rd candidate must be 30c trash')

-- Test sort modes (price vs quality)
mockItems[1][3] = {itemID = 9902, count = 1, quality = 1, sellPrice = 2, classID = 0} -- White item (2c)
F.db.settings.lootMaxQuality = 1

-- In 'price' mode: sorted strictly by total price from cheap to expensive
F.db.settings.lootSortMode = 'price'
local sortPrice = L.ScanCandidates()
assert(sortPrice[3].itemID == 9902 and sortPrice[3].totalPrice == 2, 'In price mode, 2c white item must precede 10c white item')
assert(sortPrice[4].itemID == 9901 and sortPrice[4].totalPrice == 10, 'In price mode, 10c white item must precede 30c grey item')
assert(sortPrice[5].itemID == 7073 and sortPrice[5].totalPrice == 30, 'In price mode, 30c grey item must follow 10c white item')

-- In 'quality' mode: all grey items (quality 0) come first, THEN white items (quality 1)
F.db.settings.lootSortMode = 'quality'
local sortQuality = L.ScanCandidates()
assert(sortQuality[3].itemID == 7073 and sortQuality[3].quality == 0, 'In quality mode, all grey items must come before white items')
assert(sortQuality[4].itemID == 9902 and sortQuality[4].quality == 1, 'In quality mode, white items come after grey items')
assert(sortQuality[5].itemID == 9901 and sortQuality[5].quality == 1, 'In quality mode, 10c white item follows 2c white item')

mockItems[1][3] = nil
F.db.settings.lootMaxQuality = 0
F.db.settings.lootSortMode = 'price' 

-- 6. UI & Discard Action
L.EnsureUI()
assert(L.frame and L.frame.SetPoint)
assert(#L.rows==5)

assert(L.scroll and L.body, 'ScrollFrame and body must be initialized')
L.Render(candidates)
assert(L.rows[1]:IsShown() and L.rows[1].entry.itemID==8888)
assert(L.rows[1].lock.icon and (L.rows[1].lock.icon:GetTexture() or L.rows[1].lock.icon:GetAtlas()), 'Lock button must have a valid texture icon')
assert(L.rows[1].lock:GetText() == nil or L.rows[1].lock:GetText() == '', 'Lock button must not use emoji text')
assert(L.rows[1].lock.icon:GetWidth() >= 20 and L.rows[1].lock.icon:GetHeight() >= 20, 'Lock icon must be >=20px')
assert(L.rows[1].price:GetText():find('UI-CopperIcon', 1, true), '0c price must include copper coin icon')
assert(L.rows[2]:IsShown() and L.rows[2].entry.itemID==7074)
assert(L.rows[3]:IsShown() and L.rows[3].entry.itemID==7073)
-- Row 3 has count=5 and totalPrice=30: must show ONLY total price with coin icon, no unit price or stack multipliers
assert(L.rows[3].price:GetText() == L.FormatMoney(30), 'Row price must show only total price')
assert(not L.rows[3].price:GetText():find('5x'), 'Row price must not include stack multiplier text')
assert(L.FormatMoney(10050):find('UI-GoldIcon', 1, true) and L.FormatMoney(10050):find('UI-CopperIcon', 1, true), 'Multi-denomination price must include respective coin icons')
assert(not L.rows[4]:IsShown())

-- Test scrolling with 12 items
local many = {}
for m=1,12 do
    many[m]={bag=0,slot=m,itemID=2000+m,name='Junk '..m,icon='Interface\\Icons\\INV_Misc_QuestionMark',count=1,quality=0,sellPrice=m,totalPrice=m}
end
L.Render(many)
assert(#L.rows >= 12, 'Rows pool must expand to at least 12')
assert(L.rows[12]:IsShown() and L.rows[12].entry.itemID==2012, '12th row must be displayed')
assert(L.body:GetHeight() == 12 * 38, 'Body height must be 12*38')
L.Render(candidates) -- restore original 3 candidates

-- Mock Pick & Delete
local pickedUp,deleted=nil,false
C_Container.PickupContainerItem=function(bag,slot) pickedUp={bag,slot} end
DeleteCursorItem=function() deleted=true end

local ok=L.DiscardItem(candidates[1])
assert(ok and pickedUp and pickedUp[1]==0 and pickedUp[2]==4 and deleted, 'DiscardItem did not pick and delete')

-- 7. Trigger & Show/Hide
local mockFreeSlots=0
local mockPendingLoot=1
C_Container.GetContainerNumFreeSlots=function(bag) return bag==0 and mockFreeSlots or 0 end
GetNumLootItems=function() return mockPendingLoot end

L.Hide()
assert(not L.frame:IsShown())

-- Free slots > 0 -> should not show
mockFreeSlots=2
L.CheckAndShow()
assert(not L.frame:IsShown(), 'Loot advisor showed while bags had free slots')

-- Free slots == 0 and pending loot > 0 -> should show!
mockFreeSlots=0
L.CheckAndShow()
assert(L.frame:IsShown(), 'Loot advisor did not show when bags were full during loot')

-- LOOT_CLOSED hides the frame
L.Event('LOOT_CLOSED')
assert(not L.frame:IsShown(), 'LOOT_CLOSED did not hide frame')

-- UI_ERROR_MESSAGE with full inventory
LootFrame=CreateFrame('Frame')
LootFrame:Show()
L.Event('UI_ERROR_MESSAGE', 1, 'Inventory is full.')
assert(L.frame:IsShown(), 'UI_ERROR_MESSAGE ERR_INV_FULL did not trigger loot advisor')
L.Hide(); LootFrame:Hide()

-- In-combat setting
InCombatLockdown = function() return true end
F.db.settings.lootInCombat = false
L.CheckAndShow()
assert(not L.frame:IsShown(), 'Loot advisor showed in combat when lootInCombat was false')

F.db.settings.lootInCombat = true
L.CheckAndShow()
assert(L.frame:IsShown(), 'Loot advisor did not show in combat when lootInCombat was true')
L.Hide()
InCombatLockdown = function() return false end

-- Dynamic positioning: right vs left of LootFrame
LootFrame:Show()
UIParent.GetWidth = function() return 1000 end
LootFrame.GetRight = function() return 400 end
L.Show(candidates)
assert(L.frame.point and L.frame.point[1] == 'TOPLEFT', 'Must anchor TOPLEFT when fitting on right')
assert(L.frame.point[3] == 'TOPRIGHT' and L.frame.point[4] == 12, 'Must anchor to TOPRIGHT with 12 offset')

-- When LootFrame is near right edge (e.g. 700 with width 365 -> 700 + 365 + 12 = 1077 > 996)
LootFrame.GetRight = function() return 700 end
L.UpdatePosition()
assert(L.frame.point and L.frame.point[1] == 'TOPRIGHT', 'Must anchor TOPRIGHT when not fitting on right')
assert(L.frame.point[3] == 'TOPLEFT' and L.frame.point[4] == -12, 'Must anchor to TOPLEFT with -12 offset')
L.Hide(); LootFrame:Hide()

-- 8. Slash Command
F.Command('loot off')
assert(F.db.settings.lootAdvisor==false)
L.CheckAndShow()
assert(not L.frame:IsShown(), 'Loot advisor showed while setting was off')

F.Command('loot on')
assert(F.db.settings.lootAdvisor==true)

-- 9. Settings Integration
F.Settings.Open()
local lootCheck=F.Settings.checks[9]
local combatCheck=F.Settings.checks[10]
local protectReagentsCheck=F.Settings.checks[11]
local protectGearCheck=F.Settings.checks[12]

assert(lootCheck and lootCheck.key=='lootAdvisor', 'Check 9 must be lootAdvisor')
assert(combatCheck and combatCheck.key=='lootInCombat', 'Check 10 must be lootInCombat')
assert(protectReagentsCheck and protectReagentsCheck.key=='lootProtectReagents', 'Check 11 must be lootProtectReagents')
assert(protectGearCheck and protectGearCheck.key=='lootProtectGear', 'Check 12 must be lootProtectGear')

-- Quality buttons in Settings
assert(F.Settings.lootQualities and F.Settings.lootQualities[0] and F.Settings.lootQualities[2])
F.Settings.lootQualities[2].scripts.OnClick()
assert(F.db.settings.lootMaxQuality==2, 'Clicking quality button did not update lootMaxQuality')
F.Settings.lootQualities[0].scripts.OnClick()
assert(F.db.settings.lootMaxQuality==0)

-- Sort mode buttons in Settings
assert(F.Settings.lootSortModes and F.Settings.lootSortModes.price and F.Settings.lootSortModes.quality)
F.Settings.lootSortModes.quality.scripts.OnClick()
assert(F.db.settings.lootSortMode == 'quality', 'Clicking quality sort button did not update lootSortMode')
F.Settings.lootSortModes.price.scripts.OnClick()
assert(F.db.settings.lootSortMode == 'price')

-- Blacklist in Settings
F.db.settings.lootBlacklist={[123]=true,[456]=true}
F.Settings.Refresh()
assert(F.Settings.lootBlacklistClear:IsEnabled())
F.Settings.lootBlacklistClear.scripts.OnClick()
assert(next(F.db.settings.lootBlacklist)==nil, 'Blacklist clear button did not empty blacklist')

GetItemInfo=savedGetItemInfo
