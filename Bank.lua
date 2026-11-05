local _,F=...
F.Bank={}
local B=F.Bank
function B.Snapshot() return F.db.banks and F.db.banks[F.me] end
function B.Count(item)
    local snapshot=B.Snapshot()
    return snapshot and snapshot.items[item] or 0
end
-- Crafting materials only: bank tabs also hold gear, quest items and junk that
-- the profession plan never uses. Sorted by amount, largest first.
function B.Materials()
    local snapshot=B.Snapshot()
    if not snapshot then return {} end
    local result={}
    for _,item in ipairs(F.Keys(snapshot.items)) do
        if F.Catalog.IsCraftMaterial(item) then
            result[#result+1]={item=item,count=snapshot.items[item]}
        end
    end
    table.sort(result,function(a,b)
        if a.count~=b.count then return a.count>b.count end
        return a.item<b.item
    end)
    return result
end
function B.MaterialCount()
    return #B.Materials()
end
function B.Scan()
    if not B.open or F.db.settings.autoBank==false then return false end
    F.BankTrace('scan:before')
    local api,bank=C_Container,C_Bank
    local kind=Enum and Enum.BankType and Enum.BankType.Character
    if not api or not bank or not kind or not bank.FetchPurchasedBankTabIDs or not bank.CanUseBank or
        not api.GetContainerNumSlots or not api.GetContainerItemInfo or not api.GetContainerItemID then return false end
    if not bank.CanUseBank(kind) then return false end
    local tabs=bank.FetchPurchasedBankTabIDs(kind)
    if type(tabs)~='table' or #tabs==0 then return false end
    local items={}
    for _,bag in ipairs(tabs) do
        local count=api.GetContainerNumSlots(bag)
        if not count or count<=0 then return false end -- Do not replace a snapshot while tabs are loading.
        for slot=1,count do
            local id=api.GetContainerItemID(bag,slot)
            local info=api.GetContainerItemInfo(bag,slot)
            if id and (not info or info.itemID~=id or not F.Integer(info.stackCount,1,1000000)) then return false end
            if info then
                if not F.Integer(info.itemID,1,2147483647) or not F.Integer(info.stackCount,1,1000000) then return false end
                local key='item:'..info.itemID; items[key]=(items[key] or 0)+info.stackCount
            end
        end
    end
    F.db.banks=F.db.banks or {}; F.db.banks[F.me]={items=items,seen=F.Now()}
    B.lastScanned=F.Now(); B.scanCount=(B.scanCount or 0)+1
    F.BankTrace('scan:read')
    F.UI.DataChanged(); if F.Settings then F.Settings.Refresh() end
    if F.UI and F.UI.BankBadges then pcall(F.UI.BankBadges) end
    F.BankTrace('scan:ui')
    return true
end
function B.Event(event)
    if event=='BANKFRAME_CLOSED' then
        if B.open and B.pending then pcall(B.Scan) end
        B.open=false; B.lastClosed=F.Now(); B.pending=nil; F.BankTrace('bank:close')
        if F.UI and F.UI.HideBankBadges then pcall(F.UI.HideBankBadges) end
        if F.UI and F.UI.BagBadges then pcall(F.UI.BagBadges) end
        return
    end
    -- Bags redraw independently of the bank window, so the crafting badge is
    -- refreshed for every bag change, not only while the bank is open.
    if (event=='BAG_UPDATE_DELAYED' or event=='BAG_CONTAINER_UPDATE' or event=='BAG_UPDATE' or event=='BAG_OPEN' or event=='BAG_CLOSED' or event=='PLAYERBANKSLOTS_CHANGED' or event=='BANK_TABS_CHANGED') and F.UI and F.UI.BagBadges then
        -- Containers are populated while the client draws them, so make sure each one
        -- is watched and then sweep once the buttons exist.
        if F.UI.HookBagContainers then pcall(F.UI.HookBagContainers) end
        pcall(F.UI.BagBadges)
        if (event=='BAG_OPEN' or event=='BAG_CONTAINER_UPDATE') and C_Timer and C_Timer.After then
            C_Timer.After(0.1,function() if F.UI and F.UI.BagBadges then pcall(F.UI.BagBadges) end end)
        end
    end
    -- Opening the bags or the bank can happen without a container event reaching
    -- us, so each of those frames also gets one pass when it appears.
    if event=='BANKFRAME_OPENED' and F.UI then
        if F.UI.HookBagContainers then pcall(F.UI.HookBagContainers) end
        if F.UI.BagBadges then pcall(F.UI.BagBadges) end
        if F.UI.BankBadges then pcall(F.UI.BankBadges) end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.15,function()
                if F.UI and F.UI.BagBadges then pcall(F.UI.BagBadges) end
                if F.UI and F.UI.BankBadges then pcall(F.UI.BankBadges) end
            end)
            C_Timer.After(0.4,function()
                if F.UI and F.UI.BagBadges then pcall(F.UI.BagBadges) end
                if F.UI and F.UI.BankBadges then pcall(F.UI.BankBadges) end
            end)
        end
    end
    if event=='BANKFRAME_OPENED' then B.open=true; B.lastOpened=F.Now(); B.pending=.3; B.retries=10; F.BankTrace('bank:open')
    elseif B.open and (event=='BAG_UPDATE_DELAYED' or event=='BAG_CONTAINER_UPDATE' or event=='PLAYERBANKSLOTS_CHANGED' or event=='BANK_TABS_CHANGED') then
        if event=='BAG_UPDATE_DELAYED' then pcall(B.Scan) end
        B.pending=.3; B.retries=10
        if F.UI and F.UI.BankBadges then pcall(F.UI.BankBadges) end
    end
end
function B.Tick(elapsed)
    if not B.pending then return end
    B.pending=B.pending-elapsed; if B.pending>0 then return end
    B.pending=nil
    local ok,success=pcall(B.Scan)
    if (not ok or not success) and B.open and (B.retries or 0)>0 then B.retries=B.retries-1; B.pending=.5 end
    if F.UI and F.UI.BankBadges then pcall(F.UI.BankBadges) end
end
function B.Status()
    local snapshot=B.Snapshot()
    if not snapshot then return F.L('BANK_UNSEEN') end
    return string.format(F.L('BANK_AGE'),math.max(0,math.floor((F.Now()-snapshot.seen)/60)),#F.Keys(snapshot.items))
end
