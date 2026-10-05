local F,Q=ForeverNet,ForeverNet.Queue
local p=F.NewProfile()
local function recipe(output,reagents,quantity)
    return {name=output,output=output,quantity=quantity or 1,profession='leatherworking',blueprint=false,reagents=reagents,stations={}}
end
p.recipes.a=recipe('item:1',{['item:10']=12})
p.recipes.b=recipe('item:2',{['item:10']=8})
local stock={['item:10']=5}
local plan=F.Planner.BuildQueue({[F.me]=p},{{item='item:1',quantity=1},{item='item:2',quantity=1}},stock,nil,{localOwner=F.me})
assert(plan.missing['item:10']==15 and plan.supplied['item:10']==5 and stock['item:10']==5)
assert(plan.goalStates[1].missing['item:10']==7 and plan.goalStates[2].missing['item:10']==8)
-- Shared intermediate surplus, without double reserving final goals.
p.recipes.a=recipe('item:1',{['item:11']=1})
p.recipes.b=recipe('item:2',{['item:11']=1})
p.recipes.c=recipe('item:11',{['item:10']=1},2)
plan=F.Planner.BuildQueue({[F.me]=p},{{item='item:1',quantity=1},{item='item:2',quantity=1}},{['item:10']=1},nil,{localOwner=F.me})
assert(plan.complete and #plan.steps==3 and plan.supplied['item:10']==1)
assert(plan.steps[1].quantity==2 and plan.materials['item:11'].quantity==2)
local blocked=F.Planner.BuildQueue({[F.me]=p},{{item='item:1',quantity=1},{item='item:2',quantity=1}},{},nil,{localOwner=F.me})
assert(not blocked.goalStates[1].ready and not blocked.goalStates[2].ready and blocked.missing['item:10']==1)
assert(not pcall(F.Planner.BuildQueue,{},{{item='x',quantity=0}},{}))
assert(not pcall(F.Planner.BuildQueue,{},{{item='x',quantity=10001}},{}))
F.localProfile.professions=p.professions; F.localProfile.recipes=p.recipes
C_Item={GetItemCount=function(id) return id==10 and 1 or 0 end}
assert(Q.Add('item:1',1,F.me,'a')); assert(Q.Add('item:2',1,F.me,'b'))
assert(Q.Build().complete)
assert(Q.SetSource('item:11','external'))
assert(Q.Build().missing['item:11']==2)
assert(Q.SetSource('item:11',{owner=F.me,recipeID='c'})); assert(Q.Build().complete)
assert(Q.SetSource('item:11',{owner=F.me,recipeID='vanished'})); assert(Q.Build().missingReasons['item:11']=='source')
assert(Q.SetSource('item:11',nil))
assert(Q.Quantity(1,2)); assert(not Q.Quantity(1,0)); assert(Q.MoveUp(2)); assert(Q.data.goals[1].item=='item:2')
F.UI.Navigate('queue'); assert(#F.UI.entries==2 and F.UI.queuePlan)
F.UI.Select(F.UI.entries[1]); F.UI.qty:SetText('3'); F.UI.enqueue.scripts.OnClick()
assert(Q.data.goals[1].quantity==3)
Q.Remove(2); assert(#Q.data.goals==1)
F.UI.Navigate('home'); assert(F.UI.detailTitle:GetText()==F.me and not F.UI.plan.enabled)
local saved=F.Copy(F.db.queues)
Q.Init(); assert(#Q.data.goals==1 and Q.data.goals[1].quantity==3)
for i=2,50 do assert(Q.Add('item:1',1)) end
assert(not Q.Add('item:1',1))
F.db.queues=saved
F.db.queues[F.me].goals[2]={item='bad',quantity=0}
Q.Init(); assert(#Q.data.goals==1)
local other=F.me; F.me='Other-Realm'; Q.Init(); assert(#Q.data.goals==0)
F.me=other; Q.Init(); assert(#Q.data.goals==1)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; F.UI.Navigate('home'); F.UI.Navigate('queue')
    assert(F.UI.heading:GetText()==F.L('PAGE_queue'))
end
F.db.settings.locale=nil
