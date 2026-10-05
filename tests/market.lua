local F,M=ForeverNet,ForeverNet.Market
assert(M.Quote('item:2318',8).status=='unknown')
assert(M.Save('item:2318',{{price=1000,quantity=3},{price=1200,quantity=5}},true,true))
local quote=M.Quote('item:2318',8)
assert(quote.minimum==1000 and quote.cost==9000 and quote.remaining==0)
quote=M.Quote('item:2318',10); assert(quote.cost==9000 and quote.remaining==2 and quote.covered==8)
assert(M.Save('item:100',{{price=50,quantity=50},{price=6,quantity=2}},false,true))
quote=M.Quote('item:100',2); assert(quote.minimum==1 and quote.cost==6 and quote.bought==2)
quote=M.Quote('item:100',3); assert(quote.cost==50 and quote.bought==50 and quote.surplus==47)
assert(M.Save('item:101',{},true,true)); assert(M.Quote('item:101',2).status=='empty')
assert(#M.History('item:101')==0)
assert(M.Save('item:102',{},true,false)); assert(M.Quote('item:102',2).status=='unknown')
assert(not M.Save('item:103',{{price=0,quantity=3}},true,true))
assert(not M.Save('item:103',{{price=1/0,quantity=3}},true,true))
assert(not M.Save('item:103',{{price=0/0,quantity=3}},true,true))
assert(M.Save('item:104',{{price=9007199254740991,quantity=2}},true,true))
assert(M.Quote('item:104',2).status=='unknown') -- No silent floating-point overflow.
local budget=M.Budget({['item:2318']=8,['item:999']=2,['item:101']=1})
assert(budget.cost==9000 and budget.unknown==2 and budget.uncovered==2)
assert(M.Save('item:2318',{{price=800,quantity=8}},true,false)); assert(M.Quote('item:2318',8).partial)
assert(#M.History('item:2318')==1 and M.History('item:2318')[1].price==1000)
clock=clock+86400
assert(M.Quote('item:2318',8).stale)
assert(M.Save('item:2318',{{price=1100,quantity=8}},true,true))
assert(M.Save('item:2318',{{price=1050,quantity=8}},true,true))
assert(#M.History('item:2318')==2 and M.History('item:2318')[2].price==1050)
clock=clock+2*86400
assert(M.Save('item:2318',{{price=1200,quantity=8}},true,true))
F.UI.Navigate('market')
for _,entry in ipairs(F.UI.entries) do if entry.item=='item:2318' then F.UI.Select(entry); break end end
assert(F.UI.marketPlot:IsShown())
local lines=0; for _,line in pairs(F.UI.marketPlot.lines) do if line:IsShown() then lines=lines+1 end end
assert(lines==1) -- Do not interpolate over the unobserved day.
F.UI.Navigate('home'); assert(not F.UI.marketPlot:IsShown())
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; F.UI.Navigate('market')
    assert(F.UI.heading:GetText()==F.L('PAGE_market'))
end
F.db.settings.locale=nil
for i=1,100 do clock=clock+86400; M.Save('item:2318',{{price=1000+i,quantity=8}},true,true) end
assert(#M.data.history['item:2318']<=90)
M.Init(); assert(M.Quote('item:2318',8).minimum==1100)
local oldScope=M.scope
function UnitFactionGroup() return 'OtherFaction' end
assert(M.Quote('item:2318',8).status=='unknown' and M.scope~=oldScope)
UnitFactionGroup=nil; M.EnsureScope(); assert(M.Quote('item:2318',8).minimum==1100)
