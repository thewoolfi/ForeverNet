local _,F=...
F.Bank={}
local B=F.Bank
function B.Snapshot() return F.db.banks and F.db.banks[F.me] end
function B.Count(item)
    local snapshot=B.Snapshot()
    return snapshot and snapshot.items[item] or 0
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
    F.BankTrace('scan:ui')
    return true
end
function B.Event(event)
    if event=='BANKFRAME_OPENED' then B.open=true; B.lastOpened=F.Now(); B.pending=.3; B.retries=10; F.BankTrace('bank:open')
    elseif event=='BANKFRAME_CLOSED' then
        if B.open and B.pending then pcall(B.Scan) end
        B.open=false; B.lastClosed=F.Now(); B.pending=nil; F.BankTrace('bank:close')
    elseif B.open and (event=='BAG_UPDATE_DELAYED' or event=='BAG_CONTAINER_UPDATE' or event=='PLAYERBANKSLOTS_CHANGED' or event=='BANK_TABS_CHANGED') then
        if event=='BAG_UPDATE_DELAYED' then pcall(B.Scan) end
        B.pending=.3; B.retries=10
    end
end
function B.Tick(elapsed)
    if not B.pending then return end
    B.pending=B.pending-elapsed; if B.pending>0 then return end
    B.pending=nil
    local ok,success=pcall(B.Scan)
    if (not ok or not success) and B.open and (B.retries or 0)>0 then B.retries=B.retries-1; B.pending=.5 end
end
function B.Status()
    local snapshot=B.Snapshot()
    if not snapshot then return F.L('BANK_UNSEEN') end
    return string.format(F.L('BANK_AGE'),math.max(0,math.floor((F.Now()-snapshot.seen)/60)),#F.Keys(snapshot.items))
end
