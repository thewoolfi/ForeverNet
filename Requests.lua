local _, F = ...
F.Requests = {offers={}}
local R = F.Requests
function R.IsOfferPending(id) return (R.offers[id] or 0)>F.Now() end
function R.Valid(r)
    return type(r) == 'table' and F.Text(r.id) and F.ID(r.item) and F.Integer(r.quantity, 1, 10000) and
        F.Integer(r.rev, 1, 1000000) and F.Integer(r.expires, F.Now() + 1, F.Now() + 3600) and
        (r.status == 'open' or r.status == 'accepted' or r.status == 'done' or r.status == 'cancelled') and
        F.Text(r.assignee)
end
function R.Create(item, quantity)
    if not F.ID(item) or not F.Integer(quantity, 1, 10000) then return false, F.L('Неверный предмет или количество.') end
    F.Prune(); if #F.Keys(F.db.requests) >= 100 then return false, F.L('Лимит: 100 запросов.') end
    F.db.counter = (F.db.counter or 0) + 1
    local id = F.me .. ':' .. F.Now() .. ':' .. F.db.counter
    local r = {id = id, item = item, quantity = quantity, rev = 1, expires = F.Now() + 1800, status = 'open', assignee = ''}
    local channel = F.Net.Channel()
    local ok, err = F.Net.Send('REQUEST', r, channel)
    if not ok then return false, err end
    r.owner, r.channel = F.me, channel; F.db.requests[id] = r
    return true, id
end
function R.Accept(id)
    F.Prune(); local r = F.db.requests[id]
    if not r or r.status ~= 'open' or r.owner == F.me then return false, F.L('Запрос недоступен.') end
    if R.IsOfferPending(id) then return false,F.L('OFFER_PENDING') end
    local ok,why=F.Net.Send('OFFER', {id=id}, r.channel)
    if ok then R.offers[id]=F.Now()+15 end
    if ok then return true end; return false,why
end
function R.Close(id, status)
    if status ~= 'done' and status ~= 'cancelled' then return false, 'Invalid status' end
    F.Prune(); local r = F.db.requests[id]
    if not r or r.owner ~= F.me then return false, F.L('Изменять запрос может только автор.') end
    if status == 'done' and r.status ~= 'accepted' then return false, F.L('Сначала нужен исполнитель.') end
    if r.status == 'done' or r.status == 'cancelled' then return false, F.L('Запрос уже закрыт.') end
    local nextRequest = F.Copy(r); nextRequest.status, nextRequest.rev = status, r.rev + 1
    local ok, err = F.Net.Send('REQUEST', nextRequest, r.channel)
    if not ok then return false, err end
    F.db.requests[id] = nextRequest; return true
end
function R.Receive(kind, data, sender, channel)
    F.Prune()
    if kind == 'OFFER' then
        if type(data) ~= 'table' or not F.Text(data.id) then return end
        local r = F.db.requests[data.id]
        if not r or r.owner ~= F.me or r.status ~= 'open' or sender == F.me then return end
        -- The author is the single writer. First received offer wins; no competing remote edits.
        local accepted = F.Copy(r); accepted.status, accepted.assignee, accepted.rev = 'accepted', sender, r.rev + 1
        if F.Net.Send('REQUEST', accepted, channel) then
            F.db.requests[r.id] = accepted; F.UI.DataChanged(); F.Print(F.L('Исполнитель запроса: ') .. sender)
        end
        return
    end
    if not R.Valid(data) or data.id:sub(1, #sender + 1) ~= sender .. ':' then return end
    local old = F.db.requests[data.id]
    if old then
        if old.owner ~= sender or data.rev <= old.rev or old.status == 'done' or old.status == 'cancelled' then return end
    elseif #F.Keys(F.db.requests) >= 100 then return end
    data.owner, data.channel = sender, channel; F.db.requests[data.id] = data; R.offers[data.id]=nil; F.UI.DataChanged()
end

