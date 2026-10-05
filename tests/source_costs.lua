local F,S,M=ForeverNet,ForeverNet.SourceCosts,ForeverNet.Market
local own,peer=F.NewProfile(),F.NewProfile()
local function recipe(item,inputs,quantity,stations)
    return {name=item,output=item,quantity=quantity or 1,profession='leatherworking',blueprint=false,reagents=inputs,stations=stations or {}}
end
own.professions.leatherworking=72
own.recipes.a=recipe('item:1',{['item:11']=6})
own.recipes.b=recipe('item:2',{['item:11']=4,['item:30']=1})
own.recipes.leather=recipe('item:11',{['item:10']=3},5)
own.recipes.cheap=recipe('item:11',{['item:12']=2},3)
own.recipes.camp=recipe('item:11',{['item:14']=1},20,{workshop=true})
peer.recipes.peer=recipe('item:11',{['item:13']=1},20)
local profiles={[F.me]=own,['Peer-Realm']=peer}
local goals={{item='item:1',quantity=1,owner=F.me,recipeID='a'},{item='item:2',quantity=1,owner=F.me,recipeID='b'}}
local inventory={['item:11']=1,['item:10']=2}
local options={localOwner=F.me,sources={['item:11']={owner=F.me,recipeID='leather'}}}
local prices={['item:10']=100,['item:11']=90,['item:12']=50,['item:13']=1,['item:14']=1,['item:30']=70}
local function save() for item,price in pairs(prices) do M.Save(item,{{quantity=100,price=price}},true,true) end end
save()
local function find(result,kind,id)
    for _,row in ipairs(result.rows) do if row.kind==kind and (not id or row.source and row.source.recipeID==id) then return row end end
end
local before=F.Codec.Encode({goal1=goals[1],goal2=goals[2],inventory=inventory,options=options,profile=own})
local result=S.Compare(profiles,goals,inventory,'item:11',options)
local base,cheap,buy,remote,camp=find(result,'recipe','leather'),find(result,'recipe','cheap'),find(result,'external'),find(result,'recipe','peer'),find(result,'recipe','camp')
assert(base.budget.cost==470 and base.made==10 and base.batches==2 and base.reagents['item:10']==6 and base.surplus==1)
assert(buy.get==9 and buy.budget.cost==880 and buy.delta==410)
assert(cheap.budget.cost==370 and cheap.delta==-100 and cheap.made==9 and cheap.batches==3 and cheap.surplus==0 and cheap.lowest)
assert(cheap.reagents['item:12']==6 and cheap.missing['item:30']==1) -- Whole queue, including the unrelated shortage.
assert(remote.budget.cost==71 and remote.fees and not remote.eligible and not remote.lowest)
assert(not camp.available and camp.blocked and not camp.eligible)
assert(F.Codec.Encode({goal1=goals[1],goal2=goals[2],inventory=inventory,options=options,profile=own})==before) -- No preference/profile/stock mutations.
assert(base.selected and not buy.selected)
M.Save('item:12',{{quantity=1,price=50}},true,true)
cheap=find(S.Compare(profiles,goals,inventory,'item:11',options),'recipe','cheap')
assert(cheap.budget.uncovered==1 and not cheap.eligible and not cheap.delta) -- Insufficient depth cannot win.
M.Save('item:12',{{quantity=100,price=50}},true,false)
cheap=find(S.Compare(profiles,goals,inventory,'item:11',options),'recipe','cheap')
assert(cheap.budget.partial==1 and not cheap.eligible)
M.data.snapshots['item:12']=nil
cheap=find(S.Compare(profiles,goals,inventory,'item:11',options),'recipe','cheap')
assert(cheap.budget.cost==70 and cheap.budget.unknown==1 and not cheap.eligible)
save(); clock=clock+1801
result=S.Compare(profiles,goals,inventory,'item:11',options)
for _,row in ipairs(result.rows) do assert(not row.eligible and not row.lowest) end
clock=clock-1801
result=S.Compare(profiles,goals,{['item:11']=10,['item:30']=1},'item:11',options)
base=find(result,'recipe','leather'); assert(base.budget.cost==0 and base.made==0 and base.surplus==0)
own.recipes.cycle=recipe('item:11',{['item:1']=1})
local cycle=find(S.Compare(profiles,goals,inventory,'item:11',options),'recipe','cycle')
assert(cycle.blocked and not cycle.eligible)
own.recipes.cycle=nil
-- Quotes are cached across previews and expensive whole-lot optimization is bounded.
local work=S.MAX_WORK; S.MAX_WORK=0
result=S.Compare(profiles,goals,inventory,'item:11',options)
assert(result.current.budget.limited and result.current.budget.unknown>0)
for _,row in ipairs(result.rows) do assert(not row.lowest) end
S.MAX_WORK=work
local quote=M.Quote; local calls=0
M.Quote=function(...) calls=calls+1; return quote(...) end
local context={quotes={},remaining=1000000}
M.Budget({['item:30']=1},context); M.Budget({['item:30']=1},context)
assert(calls==1); M.Quote=quote
-- A selected source beyond the list limit remains visible.
for i=1,12 do own.recipes['extra'..i]=recipe('item:11',{['item:10']=1}) end
own.recipes.zzPinned=recipe('item:11',{['item:10']=1})
local capped=S.Compare(profiles,goals,inventory,'item:11',{localOwner=F.me,sources={['item:11']={owner=F.me,recipeID='zzPinned'}}})
assert(capped.truncated and #capped.rows==S.MAX_RECIPES+2 and find(capped,'recipe','zzPinned').selected)
for i=1,12 do own.recipes['extra'..i]=nil end
own.recipes.zzPinned=nil
-- An intermediate choice must not replace a separately pinned final goal.
local mixed=F.Copy(goals); mixed[#mixed+1]={item='item:11',quantity=1,owner=F.me,recipeID='leather'}
local mixedBuy=find(S.Compare(profiles,mixed,inventory,'item:11',options),'external')
assert(mixedBuy.made==5 and mixedBuy.get==9 and mixedBuy.surplus==4)
F.localProfile.professions=own.professions; F.localProfile.recipes=own.recipes; F.db.profiles['Peer-Realm']=peer
C_Item={GetItemCount=function(id) return inventory['item:'..id] or 0 end}
F.Queue.data.goals=F.Copy(goals); F.Queue.data.sources=F.Copy(options.sources)
F.UI.Navigate('queue'); F.UI.queueSourceItem='item:11'; F.UI.Status()
local function titled(title)
    for _,row in ipairs(F.UI.sourceRows) do if row:IsShown() and row.entry.title==title then return row end end
end
local ready=titled(F.L('SOURCE_READY')); assert(ready and ready.detail:GetText():find(M.Money(880),1,true))
ready.buttons[1].scripts.OnClick(ready.buttons[1])
assert(F.Queue.data.sources['item:11']=='external' and F.Queue.Build().missing['item:11']==9 and #F.Queue.data.goals==2)
F.UI.queueSourceItem='item:11'; F.UI.Status()
local automatic=titled(F.L('SOURCE_AUTO')); automatic.buttons[1].scripts.OnClick(automatic.buttons[1])
assert(F.Queue.data.sources['item:11']==nil and #F.Queue.data.goals==2)
local single=F.Planner.Build(profiles,'item:1',1,inventory,nil,{owner=F.me,recipeID='a',localOwner=F.me,sources=options.sources})
single.owner,single.recipeID=F.me,'a'; F.UI.Plan(single); F.UI.OpenSources('item:11')
assert(titled(F.L('SOURCE_READY')) and titled(F.L('SOURCE_AUTO')))
local function queueSnapshot() return F.Codec.Encode({sources=F.Queue.data.sources,goal1=F.Queue.data.goals[1],goal2=F.Queue.data.goals[2]}) end
local queueBefore=queueSnapshot()
titled(F.L('SOURCE_READY')).buttons[1].scripts.OnClick(titled(F.L('SOURCE_READY')).buttons[1])
assert(F.UI.planData.sources['item:11']=='external' and F.UI.planData.missing['item:11']==5)
assert(queueSnapshot()==queueBefore) -- Single-chain choices don't overwrite saved queue choices.
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale
    assert(F.L('SOURCE_COMPARE')~='SOURCE_COMPARE' and F.L('SOURCE_FEES')~='SOURCE_FEES')
    assert(F.UI.SourceCostText(remote):find(F.L('SOURCE_FEES'),1,true))
end
