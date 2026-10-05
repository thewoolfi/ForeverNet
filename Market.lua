local _,F=...
F.Market={MAX_ITEMS=300,MAX_OFFERS=500,STALE=1800}
local M=F.Market
function M.Number(value,low,high)
    if issecretvalue and issecretvalue(value) then return false end
    return F.Integer(value,low,high)
end
function M.Scope()
    -- Keep factions separate until Forever's auction-pool rules are verified.
    return tostring(GetCurrentRegion and GetCurrentRegion() or '?')..':'..
        tostring(GetRealmName and GetRealmName() or '?')..':'..tostring(UnitFactionGroup and UnitFactionGroup('player') or '?')
end
function M.Init()
    F.db.markets=type(F.db.markets)=='table' and F.db.markets or {}
    local saved=F.db.markets[M.Scope()]
    saved=type(saved)=='table' and saved or {}
    M.data={snapshots={},history={}}
    for _,item in ipairs(F.Keys(type(saved.snapshots)=='table' and saved.snapshots or {})) do
        local snapshot=saved.snapshots[item]
        if #F.Keys(M.data.snapshots)<M.MAX_ITEMS and F.ID(item) and type(snapshot)=='table' and
            M.Number(snapshot.seen,0,2147483647) and type(snapshot.commodity)=='boolean' and type(snapshot.offers)=='table' then
            local offers={}
            for i,offer in ipairs(snapshot.offers) do
                if i>M.MAX_OFFERS then break end
                if type(offer)=='table' and M.Number(offer.quantity,1,1000000) and M.Number(offer.price,1,9007199254740991) then
                    offers[#offers+1]={quantity=offer.quantity,price=offer.price}
                end
            end
            M.data.snapshots[item]={seen=snapshot.seen,commodity=snapshot.commodity,offers=offers,complete=snapshot.complete==true and #offers==#snapshot.offers}
        end
    end
    for item,history in pairs(type(saved.history)=='table' and saved.history or {}) do
        if M.data.snapshots[item] and type(history)=='table' then
            local records={}
            for _,record in ipairs(history) do
                if type(record)=='table' and M.Number(record.seen,math.max(0,F.Now()-90*86400),2147483647) and
                    M.Number(record.price,1,9007199254740991) and M.Number(record.quantity,0,1000000000) then
                    records[#records+1]=F.Copy(record)
                end
            end
            table.sort(records,function(a,b) return a.seen<b.seen end)
            while #records>90 do table.remove(records,1) end
            M.data.history[item]=records
        end
    end
    M.scope=M.Scope(); F.db.markets[M.scope]=M.data
end
function M.EnsureScope() if M.scope~=M.Scope() then M.Init() end end
function M.Save(item,offers,commodity,complete)
    M.EnsureScope()
    if not F.ID(item) or type(offers)~='table' or type(commodity)~='boolean' then return false end
    local clean={}
    for i,offer in ipairs(offers) do
        if i>M.MAX_OFFERS then complete=false; break end
        if type(offer)~='table' or not M.Number(offer.quantity,1,1000000) or not M.Number(offer.price,1,9007199254740991) then return false end
        clean[#clean+1]={quantity=offer.quantity,price=offer.price}
    end
    if not M.data.snapshots[item] and #F.Keys(M.data.snapshots)>=M.MAX_ITEMS then
        local oldest
        for id,snapshot in pairs(M.data.snapshots) do
            if not oldest or snapshot.seen<M.data.snapshots[oldest].seen then oldest=id end
        end
        M.data.snapshots[oldest]=nil; M.data.history[oldest]=nil
    end
    table.sort(clean,function(a,b)
        local unitA=commodity and a.price or a.price/a.quantity
        local unitB=commodity and b.price or b.price/b.quantity
        if unitA~=unitB then return unitA<unitB end
        return a.quantity<b.quantity
    end)
    local snapshot={seen=F.Now(),offers=clean,commodity=commodity,complete=complete==true}
    M.data.snapshots[item]=snapshot
    -- Only real, complete observations; an empty market is not a zero price.
    if snapshot.complete and #clean>0 then
        local minimum=math.ceil(commodity and clean[1].price or clean[1].price/clean[1].quantity)
        local quantity=0; for _,offer in ipairs(clean) do quantity=quantity+offer.quantity end
        local history=M.data.history[item] or {}; M.data.history[item]=history
        local day=math.floor(F.Now()/86400)
        local last=history[#history]
        if last and math.floor(last.seen/86400)==day then
            last.price=math.min(last.price,minimum); last.seen=F.Now(); last.quantity=quantity
        else history[#history+1]={seen=F.Now(),price=minimum,quantity=quantity} end
        while #history>90 or history[1] and history[1].seen<F.Now()-90*86400 do table.remove(history,1) end
    end
    F.UI.DataChanged(); return true
end
function M.Quote(item,quantity)
    M.EnsureScope()
    assert(M.Number(quantity,1,10000),'invalid quote quantity')
    local snapshot=M.data.snapshots[item]
    if not snapshot then return {status='unknown',remaining=quantity} end
    local quote={status='known',seen=snapshot.seen,stale=F.Now()-snapshot.seen>M.STALE,partial=not snapshot.complete,
        cost=0,bought=0,covered=0,remaining=quantity}
    local total=0
    for _,offer in ipairs(snapshot.offers) do total=total+offer.quantity end
    quote.listed=total
    if #snapshot.offers==0 then quote.status=snapshot.complete and 'empty' or 'unknown'; return quote end
    local first=snapshot.offers[1]
    quote.minimum=math.ceil(snapshot.commodity and first.price or first.price/first.quantity)
    if snapshot.commodity then
        for _,offer in ipairs(snapshot.offers) do
            local buy=math.min(quote.remaining,offer.quantity)
            quote.cost=quote.cost+buy*offer.price; quote.bought=quote.bought+buy; quote.remaining=quote.remaining-buy
            if quote.remaining==0 then break end
        end
    elseif quantity*#snapshot.offers<=200000 then
        -- Bounded 0/1 covering knapsack: whole auctions, not fictional partial lots.
        local target=math.min(quantity,total)
        local cost,bought={[0]=0},{[0]=0}
        for _,offer in ipairs(snapshot.offers) do
            for count=target-1,0,-1 do
                if cost[count] then
                    local nextCount=math.min(target,count+offer.quantity)
                    local paid=cost[count]+offer.price
                    if not cost[nextCount] or paid<cost[nextCount] then
                        cost[nextCount]=paid; bought[nextCount]=bought[count]+offer.quantity
                    end
                end
            end
        end
        quote.cost,quote.bought=cost[target] or 0,bought[target] or 0
        quote.remaining=math.max(0,quantity-quote.bought)
    else
        quote.approximate=true
        for _,offer in ipairs(snapshot.offers) do
            quote.cost=quote.cost+offer.price; quote.bought=quote.bought+offer.quantity
            if quote.bought>=quantity then break end
        end
        quote.remaining=math.max(0,quantity-quote.bought)
    end
    quote.covered=math.min(quantity,quote.bought)
    quote.surplus=math.max(0,quote.bought-quantity)
    if not M.Number(quote.cost,0,9007199254740991) then return {status='unknown',remaining=quantity} end
    return quote
end
function M.Budget(missing,context)
    M.EnsureScope()
    local result={cost=0,unknown=0,stale=0,partial=0,uncovered=0,approximate=false}
    for item,quantity in pairs(missing) do
        if M.Number(quantity,1,10000) then
            local cached=context and context.quotes[item]
            local quote=cached and cached[quantity]
            if not quote then
                local snapshot=M.data.snapshots[item]
                local count=snapshot and #snapshot.offers or 0
                local work=snapshot and not snapshot.commodity and quantity*count<=200000 and quantity*count or math.max(1,count)
                if context and work>context.remaining then
                    quote={status='unknown',remaining=quantity,limited=true}
                else
                    if context then context.remaining=context.remaining-work end
                    quote=M.Quote(item,quantity)
                end
                if context then
                    context.quotes[item]=context.quotes[item] or {}
                    context.quotes[item][quantity]=quote
                end
            end
            result.cost=result.cost+(quote.cost or 0)
            if quote.status~='known' then result.unknown=result.unknown+1 end
            if quote.stale then result.stale=result.stale+1 end
            if quote.partial then result.partial=result.partial+1 end
            if quote.remaining>0 then result.uncovered=result.uncovered+1 end
            result.approximate=result.approximate or quote.approximate or false
            result.limited=result.limited or quote.limited or false
        else result.unknown=result.unknown+1; result.uncovered=result.uncovered+1 end
    end
    return result
end
function M.History(item,days)
    M.EnsureScope()
    local points={}
    for _,record in ipairs(M.data.history[item] or {}) do
        if record.seen>=F.Now()-(days or 30)*86400 then points[#points+1]=record end
    end
    return points
end
function M.Money(copper)
    copper=math.floor(copper)
    return string.format(F.L('MONEY_FORMAT'),math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
end
