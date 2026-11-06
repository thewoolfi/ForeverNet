local _, F = ...
F.LootAdvisor = {
    rows = {},
    candidates = {},
    maxRows = 5,
}
local L = F.LootAdvisor

local HARD_BLACKLIST = {
    [6948] = true,   -- Hearthstone
    [140192] = true, -- Dalaran Hearthstone
    [110560] = true, -- Garrison Hearthstone
    [128353] = true, -- Admiral's Compass
    [2901] = true,   -- Mining Pick
    [7005] = true,   -- Skinning Knife
    [5956] = true,   -- Blacksmith Hammer
    [6256] = true,   -- Fishing Pole
    [6365] = true,   -- Strong Fishing Pole
    [6367] = true,   -- Big Iron Fishing Pole
    [4471] = true,   -- Flint and Tinder
}

function L.IsProtected(itemID, quality, classID, subClassID)
    if not itemID or itemID <= 0 then return true end
    if HARD_BLACKLIST[itemID] then return true end

    -- Quest items (class 12 or quality 7)
    if quality == 7 or classID == 12 then return true end

    -- High quality items (Epic, Legendary, Artifact: quality >= 4)
    if quality and quality >= 4 then return true end

    -- User custom blacklist
    local s = F.db and F.db.settings
    if s and s.lootBlacklist and s.lootBlacklist[itemID] then return true end

    -- ForeverNet Favorites
    if F.IsFavorite and (F.IsFavorite('recipes', 'item:' .. itemID) or F.IsFavorite('market', 'item:' .. itemID)) then
        return true
    end

    -- Quality threshold check (default 0 / Poor)
    local maxQ = s and s.lootMaxQuality or 0
    if quality and quality > maxQ then return true end

    -- Reagents protection (Trade Goods class 7, Reagents class 5)
    if not s or s.lootProtectReagents ~= false then
        if classID == 7 or classID == 5 then return true end
        if F.Catalog and (F.Catalog.IsReagentFamily('item:' .. itemID) or F.Catalog.IsCraftMaterial('item:' .. itemID)) then
            return true
        end
    end

    -- Gear protection (Weapons class 2, Armor class 4, Containers class 1)
    if not s or s.lootProtectGear ~= false then
        if classID == 2 or classID == 4 or classID == 1 then return true end
    end

    return false
end

function L.FreeSlotsCount()
    local free = 0
    for bag = 0, 4 do
        local count = 0
        if C_Container and C_Container.GetContainerNumFreeSlots then
            count = C_Container.GetContainerNumFreeSlots(bag) or 0
        elseif GetContainerNumFreeSlots then
            count = GetContainerNumFreeSlots(bag) or 0
        end
        free = free + count
    end
    return free
end

function L.PendingLootCount()
    local count = 0
    local num = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, num do
        local has = LootSlotHasItem and LootSlotHasItem(i)
        if has or has == nil then
            count = count + 1
        end
    end
    return count
end

function L.ScanCandidates()
    local list = {}
    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        end

        for slot = 1, numSlots do
            local itemID, stackCount, itemQuality, hasNoValue
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end

            if C_Container and C_Container.GetContainerItemInfo then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and type(info) == 'table' then
                    itemID = info.itemID
                    stackCount = info.stackCount or 1
                    itemQuality = info.quality
                    hasNoValue = info.hasNoValue
                    link = link or info.hyperlink
                end
            elseif GetContainerItemInfo then
                local _, count, _, q, _, _, _, _, _, id = GetContainerItemInfo(bag, slot)
                itemID = id
                stackCount = count or 1
                itemQuality = q
            end

            if itemID and itemID > 0 then
                local name, itemLink, q, _, _, _, _, _, _, icon, sellPrice, classID, subClassID
                local query = link or itemID
                if C_Item and C_Item.GetItemInfo then
                    name, itemLink, q, _, _, _, _, _, _, icon, sellPrice, classID, subClassID = C_Item.GetItemInfo(query)
                end
                if not name and GetItemInfo then
                    name, itemLink, q, _, _, _, _, _, _, icon, sellPrice, classID, subClassID = GetItemInfo(query)
                end
                if not name and query ~= itemID then
                    if C_Item and C_Item.GetItemInfo then
                        name, itemLink, q, _, _, _, _, _, _, icon, sellPrice, classID, subClassID = C_Item.GetItemInfo(itemID)
                    end
                    if not name and GetItemInfo then
                        name, itemLink, q, _, _, _, _, _, _, icon, sellPrice, classID, subClassID = GetItemInfo(itemID)
                    end
                end

                if not name and not hasNoValue then
                    if C_Item and C_Item.RequestLoadItemDataByID then
                        C_Item.RequestLoadItemDataByID(itemID)
                    elseif C_Item and C_Item.RequestLoadItemDataByItemInfo and query then
                        C_Item.RequestLoadItemDataByItemInfo(query)
                    end
                else
                    if itemQuality == nil then
                        itemQuality = q
                    end
                    if itemQuality == nil and C_Item and C_Item.GetItemQualityByID then
                        itemQuality = C_Item.GetItemQualityByID(itemID)
                    end
                    if not icon and C_Item and C_Item.GetItemIconByID then
                        icon = C_Item.GetItemIconByID(itemID)
                    end
                    if not classID and C_Item and C_Item.GetItemInfoInstant then
                        _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
                    end

                    itemQuality = itemQuality or 0
                    if not L.IsProtected(itemID, itemQuality, classID, subClassID) then
                        sellPrice = sellPrice or 0
                        local totalPrice = sellPrice * (stackCount or 1)
                        list[#list + 1] = {
                            bag = bag,
                            slot = slot,
                            itemID = itemID,
                            name = name or ('item:' .. itemID),
                            link = link or itemLink,
                            icon = icon or 'Interface\\Icons\\INV_Misc_QuestionMark',
                            count = stackCount or 1,
                            quality = itemQuality,
                            sellPrice = sellPrice,
                            totalPrice = totalPrice,
                        }
                    end
                end
            end
        end
    end

    local sortMode = F.db and F.db.settings and F.db.settings.lootSortMode or 'price'
    table.sort(list, function(a, b)
        local totalA = a.totalPrice or 0
        local totalB = b.totalPrice or 0
        local unitA = a.sellPrice or 0
        local unitB = b.sellPrice or 0
        local qA = a.quality or 0
        local qB = b.quality or 0

        if sortMode == 'quality' then
            if qA ~= qB then
                return qA < qB
            end
            if totalA ~= totalB then
                return totalA < totalB
            end
            if unitA ~= unitB then
                return unitA < unitB
            end
            return (a.count or 1) < (b.count or 1)
        else
            if totalA ~= totalB then
                return totalA < totalB
            end
            if unitA ~= unitB then
                return unitA < unitB
            end
            if qA ~= qB then
                return qA < qB
            end
            return (a.count or 1) < (b.count or 1)
        end
    end)

    L.candidates = list
    return list
end

local GOLD_ICON = '|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t'
local SILVER_ICON = '|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t'
local COPPER_ICON = '|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t'

function L.FormatMoney(copper)
    copper = math.floor(copper or 0)
    if copper <= 0 then
        return '0' .. COPPER_ICON
    end
    if GetCoinTextureString then
        local s = GetCoinTextureString(copper)
        if s and s ~= '' then return s end
    end
    local g = math.floor(copper / 10000)
    local s = math.floor(copper / 100) % 100
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. GOLD_ICON end
    if s > 0 then parts[#parts + 1] = s .. SILVER_ICON end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. COPPER_ICON end
    return table.concat(parts, ' ')
end

function L.DiscardItem(entry)
    if not entry or not entry.bag or not entry.slot then return false end

    pcall(function()
        if C_Container and C_Container.PickupContainerItem then
            C_Container.PickupContainerItem(entry.bag, entry.slot)
        elseif PickupContainerItem then
            PickupContainerItem(entry.bag, entry.slot)
        end

        if DeleteCursorItem then
            DeleteCursorItem()
        end
    end)

    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            if L.frame and L.frame:IsShown() then
                local free = L.FreeSlotsCount()
                if free > 0 and L.PendingLootCount() <= 0 then
                    L.Hide()
                else
                    local updated = L.ScanCandidates()
                    if #updated == 0 then
                        L.Hide()
                    else
                        L.Render(updated)
                    end
                end
            end
        end)
    else
        local updated = L.ScanCandidates()
        if #updated == 0 then L.Hide() else L.Render(updated) end
    end
    return true
end

function L.ToggleBlacklist(itemID)
    if not itemID then return end
    F.db.settings.lootBlacklist = F.db.settings.lootBlacklist or {}
    if F.db.settings.lootBlacklist[itemID] then
        F.db.settings.lootBlacklist[itemID] = nil
    else
        F.db.settings.lootBlacklist[itemID] = true
    end
    if L.frame and L.frame:IsShown() then
        L.Render(L.ScanCandidates())
    end
    if F.Settings and F.Settings.Refresh then
        F.Settings.Refresh()
    end
end

local function makeLockIcon(lock)
    if lock.lockHolder then return lock.lockHolder end
    local holder = CreateFrame('Frame', nil, lock)
    holder:SetSize(18, 18)
    holder:SetPoint('CENTER', 0, 0)
    holder:EnableMouse(false)

    -- Shackle (дужка):
    local shackleTop = holder:CreateTexture(nil, 'OVERLAY', nil, 2)
    shackleTop:SetSize(8, 2)
    shackleTop:SetPoint('TOP', holder, 'TOP', 0, -1)

    local shackleLeft = holder:CreateTexture(nil, 'OVERLAY', nil, 2)
    shackleLeft:SetSize(2, 5)
    shackleLeft:SetPoint('TOPLEFT', shackleTop, 'BOTTOMLEFT', 0, 0)

    local shackleRight = holder:CreateTexture(nil, 'OVERLAY', nil, 2)
    shackleRight:SetSize(2, 5)
    shackleRight:SetPoint('TOPRIGHT', shackleTop, 'BOTTOMRIGHT', 0, 0)

    -- Body (корпус):
    local body = holder:CreateTexture(nil, 'OVERLAY', nil, 1)
    body:SetSize(12, 9)
    body:SetPoint('BOTTOM', holder, 'BOTTOM', 0, 1)

    -- Keyhole (скважина):
    local keyDot = holder:CreateTexture(nil, 'OVERLAY', nil, 3)
    keyDot:SetSize(2, 2)
    keyDot:SetPoint('CENTER', body, 'CENTER', 0, 1)

    local keySlot = holder:CreateTexture(nil, 'OVERLAY', nil, 3)
    keySlot:SetSize(1.5, 3)
    keySlot:SetPoint('TOP', keyDot, 'BOTTOM', 0, 0)

    local parts = {shackleTop, shackleLeft, shackleRight, body}
    local keyhole = {keyDot, keySlot}

    local function setLockColors(isLocked, isHover)
        if isLocked then
            local r = isHover and 1.0 or 0.98
            local g = isHover and 0.92 or 0.82
            local b = isHover and 0.30 or 0.12
            for _, p in ipairs(parts) do p:SetColorTexture(r, g, b, 1.0) end
            for _, k in ipairs(keyhole) do k:SetColorTexture(0.25, 0.15, 0.0, 1.0) end
            shackleRight:SetHeight(5)
            shackleRight:ClearAllPoints()
            shackleRight:SetPoint('TOPRIGHT', shackleTop, 'BOTTOMRIGHT', 0, 0)
            if lock.flatFill then lock.flatFill:SetColorTexture(0.38, 0.30, 0.08, 1) end
            if lock.flatEdge then lock.flatEdge:SetColorTexture(0.90, 0.75, 0.18, 1) end
        else
            local r = isHover and 0.95 or 0.70
            local g = isHover and 0.98 or 0.78
            local b = isHover and 1.0 or 0.88
            for _, p in ipairs(parts) do p:SetColorTexture(r, g, b, isHover and 1.0 or 0.85) end
            for _, k in ipairs(keyhole) do k:SetColorTexture(0.12, 0.14, 0.18, 1.0) end
            shackleRight:SetHeight(2.5)
            shackleRight:ClearAllPoints()
            shackleRight:SetPoint('TOPRIGHT', shackleTop, 'BOTTOMRIGHT', 0, 0)
            if lock.flatFill then lock.flatFill:SetColorTexture(0.18, 0.20, 0.24, 1) end
            if lock.flatEdge then lock.flatEdge:SetColorTexture(0.40, 0.45, 0.55, 1) end
        end
    end

    local testTex = lock:CreateTexture(nil, 'BACKGROUND')
    testTex:SetSize(20, 20)
    testTex:SetTexture('Interface\\Buttons\\LockButton-Locked-Up')
    testTex:SetAlpha(0)
    lock.icon = testTex

    lock.lockHolder = holder
    lock.setLockColors = setLockColors
    return holder
end

local function applyLockIcon(lock, isLocked)
    makeLockIcon(lock)
    lock.isLocked = isLocked
    if lock.setLockColors then
        lock.setLockColors(isLocked, false)
    end
end

local function makeTrashIcon(drop)
    if drop.trashIcon then return drop.trashIcon end
    local holder = CreateFrame('Frame', nil, drop)
    holder:SetSize(18, 18)
    holder:SetPoint('CENTER', 0, 0)
    holder:EnableMouse(false)

    -- Top handle: 6x2
    local handle = holder:CreateTexture(nil, 'OVERLAY', nil, 2)
    handle:SetSize(6, 2)
    handle:SetPoint('TOP', holder, 'TOP', 0, 0)

    -- Lid: 14x2
    local lid = holder:CreateTexture(nil, 'OVERLAY', nil, 2)
    lid:SetSize(14, 2)
    lid:SetPoint('TOP', handle, 'BOTTOM', 0, 0)

    -- Bin body: 11x10
    local body = holder:CreateTexture(nil, 'OVERLAY', nil, 1)
    body:SetSize(11, 10)
    body:SetPoint('TOP', lid, 'BOTTOM', 0, 0)

    -- Vertical ribs
    local rib1 = holder:CreateTexture(nil, 'OVERLAY', nil, 3)
    rib1:SetSize(1.5, 7)
    rib1:SetPoint('CENTER', body, 'CENTER', -2.5, 0)

    local rib2 = holder:CreateTexture(nil, 'OVERLAY', nil, 3)
    rib2:SetSize(1.5, 7)
    rib2:SetPoint('CENTER', body, 'CENTER', 2.5, 0)

    local parts = {handle, lid, body}
    local ribs = {rib1, rib2}

    local function setColor(r, g, b, a)
        for _, p in ipairs(parts) do p:SetColorTexture(r, g, b, a or 1) end
        for _, rib in ipairs(ribs) do rib:SetColorTexture(r * 0.30, g * 0.30, b * 0.30, a or 1) end
    end
    setColor(0.92, 0.28, 0.28, 1)

    drop.trashHolder = holder
    drop.setTrashColor = setColor
    drop.trashIcon = holder
    return holder
end

function L.GetRow(i)
    if L.rows[i] then return L.rows[i] end
    local parent = L.body or L.frame
    local row = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    row:SetSize(330, 36)
    row:SetPoint('TOPLEFT', 0, -(i - 1) * 38)

    local bg = row:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.11, 0.09, 0.6)
    row.bg = bg

    local icon = row:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(28, 28)
    icon:SetPoint('LEFT', 4, 0)
    row.icon = icon

    local iconBorder = CreateFrame('Frame', nil, row, 'BackdropTemplate')
    iconBorder:SetPoint('TOPLEFT', icon, -1, 1)
    iconBorder:SetPoint('BOTTOMRIGHT', icon, 1, -1)
    iconBorder:SetBackdrop({
        edgeFile = 'Interface\\Buttons\\WHITE8X8',
        edgeSize = 1,
    })
    iconBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)
    row.iconBorder = iconBorder

    local count = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    count:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', -2, 2)
    F.Theme.Text(count, false, 10)
    row.count = count

    local name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    name:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 6, -1)
    name:SetWidth(210)
    name:SetHeight(16)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    F.Theme.Text(name, false, 12)
    row.name = name

    local price = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    price:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 6, 1)
    price:SetWidth(210)
    price:SetJustifyH('LEFT')
    F.Theme.Text(price, false, 11)
    F.Theme.Color(price, 'muted')
    row.price = price

    local drop = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
    drop:SetSize(28, 28)
    drop:SetPoint('RIGHT', -12, 0)
    F.Theme.Button(drop)
    drop:SetText('')
    makeTrashIcon(drop)
    if drop.flatFill then
        drop.flatFill:SetColorTexture(0.35, 0.12, 0.10, 1)
    end
    row.drop = drop

    local lock = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
    lock:SetSize(28, 28)
    lock:SetPoint('RIGHT', drop, 'LEFT', -6, 0)
    F.Theme.Button(lock)
    lock:SetText('')
    applyLockIcon(lock, false)
    row.lock = lock

    row:EnableMouse(true)
    row:SetScript('OnEnter', function(self)
        if self.entry then
            if GameTooltip and GameTooltip.SetHyperlink and self.entry.link then
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:SetHyperlink(self.entry.link)
                GameTooltip:Show()
            elseif GameTooltip and GameTooltip.SetBagItem then
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:SetBagItem(self.entry.bag, self.entry.slot)
                GameTooltip:Show()
            end
        end
    end)
    row:SetScript('OnLeave', function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)

    L.rows[i] = row
    return row
end

function L.EnsureUI()
    if L.frame then return L.frame end
    local frame = CreateFrame('Frame', 'ForeverNetLootAdvisorFrame', UIParent, 'BackdropTemplate')
    L.frame = frame
    frame:SetSize(365, 266)
    frame:SetFrameStrata('DIALOG')
    frame:SetClampedToScreen(true)
    F.Theme.Skin(frame, true)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)

    if not L.lootFrameHooked and LootFrame and LootFrame.HookScript then
        L.lootFrameHooked = true
        pcall(function()
            LootFrame:HookScript('OnShow', function()
                if L.frame and L.frame:IsShown() then
                    L.UpdatePosition()
                end
            end)
        end)
    end

    local isNeon = F.Theme.IsNeon()
    local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    title:SetPoint('TOPLEFT', 10, -10)
    title:SetWidth(300)
    title:SetJustifyH('LEFT')
    F.Theme.Text(title, true, 13)
    title:SetText((isNeon and '|cff00e5ff▌|r ' or '') .. F.L('LOOT_ADVISOR_TITLE'))
    L.title = title

    local close = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    close:SetSize(22, 22)
    close:SetPoint('TOPRIGHT', -6, -6)
    F.Theme.Button(close)
    if not close.neonText then
        local t = close:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        t:SetPoint('CENTER', 0, 0)
        t:SetText('X')
        F.Theme.Text(t, true, 12)
        close.neonText = t
    end
    close.neonText:SetTextColor(0.0, 0.85, 1.0, 1)
    close:SetText('')
    close:SetScript('OnClick', function() L.Hide() end)
    L.close = close

    local sub = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    sub:SetPoint('TOPLEFT', 10, -28)
    sub:SetWidth(300)
    sub:SetJustifyH('LEFT')
    F.Theme.Text(sub, false, 11)
    F.Theme.Color(sub, 'muted')
    sub:SetText(F.L('LOOT_ADVISOR_SUBTITLE'))
    L.subtitle = sub

    if isNeon then
        if not frame.neonGlowBeam then
            local beam = frame:CreateTexture(nil, 'BORDER', nil, 2)
            beam:SetPoint('TOPLEFT', 4, -44); beam:SetPoint('TOPRIGHT', -4, -44); beam:SetHeight(2)
            beam:SetColorTexture(0.0, 0.88, 1.0, 0.95)
            frame.neonGlowBeam = beam
        end
        frame.neonGlowBeam:Show()
        if not frame.neonGlowSpread then
            local spread = frame:CreateTexture(nil, 'BORDER', nil, 1)
            spread:SetPoint('TOPLEFT', frame.neonGlowBeam, 'BOTTOMLEFT', 0, 0)
            spread:SetPoint('TOPRIGHT', frame.neonGlowBeam, 'BOTTOMRIGHT', 0, 0)
            spread:SetHeight(8)
            spread:SetColorTexture(0.0, 0.88, 1.0, 0.16)
            frame.neonGlowSpread = spread
        end
        frame.neonGlowSpread:Show()
    end

    L.scroll = F.Theme.ScrollFrame(frame)
    L.scroll:SetPoint('TOPLEFT', 8, -48)
    L.scroll:SetPoint('BOTTOMRIGHT', -24, 6)

    L.body = CreateFrame('Frame', nil, L.scroll)
    L.body:SetSize(330, 1)
    L.scroll:SetScrollChild(L.body)

    L.rows = {}
    for i = 1, L.maxRows do
        L.GetRow(i)
    end

    frame:Hide()
    return frame
end

function L.Render(candidates)
    L.EnsureUI()
    local isNeon = F.Theme.IsNeon()
    if L.title then
        L.title:SetText((isNeon and '|cff00e5ff▌|r ' or '') .. F.L('LOOT_ADVISOR_TITLE'))
    end
    if L.frame then
        if isNeon then
            if not L.frame.neonGlowBeam then
                local beam = L.frame:CreateTexture(nil, 'BORDER', nil, 2)
                beam:SetPoint('TOPLEFT', 4, -46); beam:SetPoint('TOPRIGHT', -4, -46); beam:SetHeight(2)
                beam:SetColorTexture(0.0, 0.88, 1.0, 0.95)
                L.frame.neonGlowBeam = beam
            end
            L.frame.neonGlowBeam:Show()
            if not L.frame.neonGlowSpread then
                local spread = L.frame:CreateTexture(nil, 'BORDER', nil, 1)
                spread:SetPoint('TOPLEFT', L.frame.neonGlowBeam, 'BOTTOMLEFT', 0, 0)
                spread:SetPoint('TOPRIGHT', L.frame.neonGlowBeam, 'BOTTOMRIGHT', 0, 0)
                spread:SetHeight(8)
                spread:SetColorTexture(0.0, 0.88, 1.0, 0.16)
                L.frame.neonGlowSpread = spread
            end
            L.frame.neonGlowSpread:Show()
        else
            if L.frame.neonGlowBeam then L.frame.neonGlowBeam:Hide() end
            if L.frame.neonGlowSpread then L.frame.neonGlowSpread:Hide() end
        end
    end
    candidates = candidates or L.candidates or {}

    local total = #candidates
    for i = 1, total do
        local row = L.GetRow(i)
        local entry = candidates[i]
        row.entry = entry
        row.icon:SetTexture(entry.icon)
        row.count:SetText(entry.count > 1 and tostring(entry.count) or '')

        if isNeon then
            row.bg:SetColorTexture(0.022, 0.040, 0.075, 0.85)
            if row.drop.flatFill then row.drop.flatFill:SetColorTexture(0.40, 0.08, 0.08, 1) end
            if row.drop.flatEdge then row.drop.flatEdge:SetColorTexture(1.0, 0.35, 0.35, 1) end
        else
            row.bg:SetColorTexture(0.12, 0.11, 0.09, 0.6)
            if row.drop.flatFill then row.drop.flatFill:SetColorTexture(0.35, 0.12, 0.10, 1) end
            if row.drop.flatEdge then row.drop.flatEdge:SetColorTexture(0.55, 0.20, 0.15, 1) end
        end

        local q = entry.quality or 0
        local r, g, b, hex
        if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
            local qc = ITEM_QUALITY_COLORS[q]
            r, g, b, hex = qc.r, qc.g, qc.b, qc.hex
        elseif GetItemQualityColor then
            local red, green, blue, h = GetItemQualityColor(q)
            r, g, b = red, green, blue
            if h then hex = '|c' .. h end
        end
        r = r or 0.62
        g = g or 0.62
        b = b or 0.62
        hex = hex or string.format('|cff%02x%02x%02x', math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))

        if row.iconBorder then
            row.iconBorder:SetBackdropBorderColor(r, g, b, 1.0)
        end

        row.name:SetTextColor(r, g, b, 1)
        row.name:SetText(hex .. (entry.name or '') .. '|r')

        row.price:SetText(L.FormatMoney(entry.totalPrice))

        local isLocked = not not (F.db and F.db.settings and F.db.settings.lootBlacklist and F.db.settings.lootBlacklist[entry.itemID])
        applyLockIcon(row.lock, isLocked)
        row.lock:SetScript('OnClick', function()
            L.ToggleBlacklist(entry.itemID)
        end)
        row.lock:SetScript('OnEnter', function(self)
            if self.setLockColors then self.setLockColors(self.isLocked, true) end
            local tipTitle = self.isLocked and (F.L('LOOT_ADVISOR_LOCKED') or 'В чёрном списке') or F.L('LOOT_ADVISOR_LOCK')
            local tipDesc = self.isLocked and 'Нажмите, чтобы убрать из чёрного списка' or F.L('LOOT_ADVISOR_LOCK_HINT')
            F.Theme.ShowTooltip(self, tipTitle, tipDesc)
        end)
        row.lock:SetScript('OnLeave', function(self)
            if self.setLockColors then self.setLockColors(self.isLocked, false) end
            F.Theme.HideTooltip()
        end)

        row.drop:SetScript('OnClick', function()
            L.DiscardItem(entry)
        end)
        row.drop:SetScript('OnEnter', function(self)
            if self.setTrashColor then self.setTrashColor(1.0, 0.65, 0.65, 1) end
            if self.flatFill then self.flatFill:SetColorTexture(0.50, 0.12, 0.12, 1) end
            F.Theme.ShowTooltip(self, F.L('LOOT_ADVISOR_DISCARD'), 'Выбросить предмет и освободить место в сумках')
        end)
        row.drop:SetScript('OnLeave', function(self)
            if self.setTrashColor then self.setTrashColor(0.92, 0.28, 0.28, 1) end
            if self.flatFill then self.flatFill:SetColorTexture(0.35, 0.12, 0.10, 1) end
            F.Theme.HideTooltip()
        end)

        row:Show()
    end

    for i = total + 1, #L.rows do
        local row = L.rows[i]
        row.entry = nil
        row:Hide()
    end

    local scrollHeight = math.max(1, total * 38)
    L.body:SetHeight(scrollHeight)

    local maxDisplayRows = math.min(total, 6)
    local windowHeight = math.max(120, 62 + maxDisplayRows * 38)
    L.frame:SetHeight(windowHeight)
end

function L.UpdatePosition()
    if not L.frame then return end
    L.frame:ClearAllPoints()

    if LootFrame and LootFrame:IsShown() then
        local spacing = 12
        local frameWidth = (L.frame.GetWidth and L.frame:GetWidth()) or 365
        local uiWidth = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 0
        if uiWidth <= 0 and GetScreenWidth then
            uiWidth = GetScreenWidth() or 0
        end
        if uiWidth <= 0 then
            uiWidth = 1024
        end

        local lootScale = (LootFrame.GetEffectiveScale and LootFrame:GetEffectiveScale()) or 1
        local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
        local scaleRatio = (uiScale > 0) and (lootScale / uiScale) or 1
        local lootRight = LootFrame.GetRight and LootFrame:GetRight()

        local fitsOnRight = true
        if lootRight then
            local rightInUI = lootRight * scaleRatio
            if (rightInUI + frameWidth + spacing) > (uiWidth - 4) then
                fitsOnRight = false
            end
        end

        if fitsOnRight then
            L.frame:SetPoint('TOPLEFT', LootFrame, 'TOPRIGHT', spacing, 0)
        else
            L.frame:SetPoint('TOPRIGHT', LootFrame, 'TOPLEFT', -spacing, 0)
        end
    else
        L.frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 100)
    end
end

function L.Show(candidates)
    if F.db and F.db.settings and F.db.settings.lootInCombat == false and InCombatLockdown and InCombatLockdown() then return end
    candidates = candidates or L.ScanCandidates()
    if #candidates == 0 then return end

    L.EnsureUI()
    L.Render(candidates)
    L.UpdatePosition()
    L.frame:Show()
end

function L.Hide()
    if L.frame then
        L.frame:Hide()
    end
end

function L.CheckAndShow()
    if F.db and F.db.settings and F.db.settings.lootAdvisor == false then return end
    if F.db and F.db.settings and F.db.settings.lootInCombat == false and InCombatLockdown and InCombatLockdown() then return end

    local freeSlots = L.FreeSlotsCount()
    local pending = L.PendingLootCount()

    if freeSlots <= 0 and pending > 0 then
        local candidates = L.ScanCandidates()
        if #candidates > 0 then
            L.Show(candidates)
        end
    end
end

function L.Event(event, ...)
    if event == 'LOOT_OPENED' then
        L.CheckAndShow()
    elseif event == 'LOOT_CLOSED' then
        L.Hide()
    elseif event == 'UI_ERROR_MESSAGE' then
        local _, msg = ...
        local errFull = ERR_INV_FULL or 'Inventory is full.'
        if msg == errFull or (type(msg) == 'string' and (msg:find('full', 1, true) or msg:find('полон', 1, true))) then
            if LootFrame and LootFrame:IsShown() then
                L.CheckAndShow()
            end
        end
    elseif event == 'BAG_UPDATE_DELAYED' or event == 'BAG_UPDATE' or event == 'GET_ITEM_INFO_RECEIVED' or event == 'ITEM_DATA_LOAD_RESULT' then
        if L.frame and L.frame:IsShown() then
            if L.FreeSlotsCount() > 0 and L.PendingLootCount() <= 0 then
                L.Hide()
            else
                local updated = L.ScanCandidates()
                if #updated == 0 then
                    L.Hide()
                else
                    L.Render(updated)
                end
            end
        end
    end
end

function L.Start()
    if F.db and F.db.settings then
        if F.db.settings.lootAdvisor == nil then F.db.settings.lootAdvisor = true end
        if F.db.settings.lootInCombat == nil then F.db.settings.lootInCombat = true end
        if F.db.settings.lootMaxQuality == nil then F.db.settings.lootMaxQuality = 0 end
        if F.db.settings.lootProtectReagents == nil then F.db.settings.lootProtectReagents = true end
        if F.db.settings.lootProtectGear == nil then F.db.settings.lootProtectGear = true end
        if type(F.db.settings.lootBlacklist) ~= 'table' then F.db.settings.lootBlacklist = {} end
        if F.db.settings.lootSortMode == nil then F.db.settings.lootSortMode = 'price' end
    end
end
