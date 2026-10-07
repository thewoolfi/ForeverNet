local F,Q,U=ForeverNet,ForeverNet.Queue,ForeverNet.UI
local bags={}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Item '..id end}
local function recipe(output,inputs,quantity)
    return {name=output,output=output,quantity=quantity or 1,profession='leatherworking',blueprint=false,reagents=inputs,stations={}}
end
F.localProfile.recipes={a=recipe('item:1',{['item:10']=2}),b=recipe('item:2',{['item:1']=1}),c=recipe('item:11',{['item:10']=1},2)}
Q.Add('item:1',3,F.me,'a'); Q.SetSource('item:10','external')
assert(Q.SaveSet('  Поход  ')); assert(Q.data.sets['Поход'].goals[1].quantity==3)
Q.Quantity(1,4); Q.SetSource('item:10',nil)
assert(Q.data.sets['Поход'].goals[1].quantity==3 and Q.data.sets['Поход'].sources['item:10']=='external')
assert(Q.LoadSet('Поход',false)); assert(Q.data.goals[1].quantity==3 and Q.data.sources['item:10']=='external')
Q.data.goals[1].quantity=2 -- No alias to the saved set.
assert(Q.data.sets['Поход'].goals[1].quantity==3)
assert(Q.Undo()); assert(Q.data.goals[1].quantity==4 and not Q.data.sources['item:10'])
assert(not Q.Undo())
-- Append retains existing routes, preserves root pins, reports conflicts and can be undone.
Q.SetSource('item:10',{owner=F.me,recipeID='missing'})
local ok,conflicts=Q.LoadSet('Поход',true)
assert(ok and conflicts==1 and #Q.data.goals==2)
assert(Q.data.sources['item:10'].recipeID=='missing' and Q.data.goals[2].owner==F.me and Q.data.goals[2].recipeID=='a')
assert(Q.Undo() and #Q.data.goals==1)
Q.SetSource('item:10',nil)
ok,conflicts=Q.LoadSet('Поход',true); assert(ok and conflicts==0 and Q.data.sources['item:10']=='external')
Q.Quantity(1,5); assert(not Q.undo) -- Undo cannot discard subsequent manual edits.
-- Failed operations are atomic; named-set updates remain possible at the cap.
assert(not Q.SaveSet('') and not Q.SaveSet(' |bad') and not Q.SaveSet(string.rep('a',81)))
for i=1,9 do assert(Q.SaveSet('Set '..i)) end
assert(not Q.SaveSet('Eleven') and #F.Keys(Q.data.sets)==10)
assert(Q.SaveSet('Поход'))
assert(Q.DeleteSet('Set 1') and not Q.DeleteSet('Set 1'))
assert(Q.SaveSet('New'))
local original=F.Copy(Q.data)
for i=#Q.data.goals+1,50 do Q.Add('item:1',1) end
local undo=Q.undo
assert(not Q.LoadSet('Поход',true) and #Q.data.goals==50 and Q.undo==undo)
Q.data.goals=original.goals; Q.data.sources={}
for i=1,200 do assert(Q.SetSource('item:'..(1000+i),'external')) end
assert(not Q.LoadSet('Поход',true) and #Q.data.goals==#original.goals and #F.Keys(Q.data.sources)==200)
assert(not Q.SetSource('item:9999','external') and Q.SetSource('item:1001',nil))
assert(Q.LoadSet('Поход',false) and Q.data.sources['item:10']=='external')
-- Reload restores private sets and tracker, rejects malformed sets without loading partial goals.
Q.data.tracker=true
Q.data.sets.Bad={goals={{item='item:1',quantity=1},{item='bad',quantity=0}},sources={}}
Q.data.sets[99]={goals={{item='item:1',quantity=1}}}
Q.data.sets[' Gap ']={goals={{item='item:1',quantity=1}}}
Q.Init(); assert(not Q.data.sets.Bad and not Q.data.sets[99] and not Q.data.sets[' Gap '] and Q.data.tracker)
local me=F.me
F.me='Other-Realm'; Q.Init(); assert(not next(Q.data.sets) and #Q.data.goals==0)
Q.Add('item:2',1); Q.SaveSet('Other')
F.me=me; Q.Init(); assert(Q.data.sets['Поход'] and not Q.data.sets.Other)
-- Root stock is allocated once: ready materials, planned surplus and bank are not finished bag goods.
Q.data.goals={}; Q.data.sources={}; Q.undo=nil
Q.Add('item:1',2); Q.Add('item:1',2); bags[1]=3
assert(Q.Build().goalStates[1].stock==2 and Q.Build().goalStates[2].stock==1)
assert(Q.RemoveOwned()==0 and Q.RemoveOwned()==0 and #Q.data.goals==2)
bags[1]=4; assert(Q.RemoveOwned()==2 and #Q.data.goals==0)
assert(Q.Undo() and #Q.data.goals==2)
bags[1]=0; bags[10]=100
assert(Q.Build().goalStates[1].ready and Q.RemoveOwned()==0 and #Q.data.goals==2)
F.db.banks={[F.me]={items={['item:1']=20},seen=clock}}
F.db.settings.useBank=true
assert(Q.Build().goalStates[1].stock==2 and Q.RemoveOwned()==0)
-- A batch remainder is planned output, not a finished goal currently owned.
Q.data.goals={{item='item:11',quantity=1},{item='item:11',quantity=1}}
local plan=Q.Build()
assert(#plan.steps==1 and plan.goalStates[2].ready and plan.goalStates[2].stock==0 and Q.RemoveOwned()==0)
-- The same actual stock cannot satisfy a preceding reagent need and a later root goal.
bags[1]=1; bags[10]=0; F.db.banks={}
Q.data.goals={{item='item:2',quantity=1},{item='item:1',quantity=1}}
plan=Q.Build(); assert(plan.supplied['item:1']==1 and plan.goalStates[2].stock==0 and Q.RemoveOwned()==0)
Q.data.goals={{item='item:1',quantity=1},{item='item:2',quantity=1}}
assert(Q.RemoveOwned()==1 and Q.data.goals[1].item=='item:2')
assert(Q.Undo() and Q.data.goals[1].item=='item:1')
-- Loading recomputes from live bags, not saved plans or bank/market data.
Q.data.goals={{item='item:1',quantity=3,owner=F.me,recipeID='a'}}; Q.data.sources={['item:10']='external'}
Q.data.sets={}; assert(Q.SaveSet('Поход'))
bags[1]=0; bags[10]=0; Q.LoadSet('Поход',false); assert(Q.Build().missing['item:10']==6)
bags[10]=6; Q.LoadSet('Поход',false); assert(Q.Build().complete)
local peerRevision=F.localProfile.rev
-- Exercise actual buttons, preview, replace/append, validation, clear and undo across every language.
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('queue'); U.QueueSetDialog('save')
    local d=U.setDialog
    assert(d.title==F.L('SETS_TITLE') and F.L('SETS_TITLE')~='SETS_TITLE')
    d.name:SetText(''); d.first.scripts.OnClick(d.first)
    assert(d:IsShown() and d.error:GetText()==F.L('SETS_NAME_ERROR'))
    d.name:SetText('UI'); d.name.scripts.OnEnterPressed(d.name)
    assert(not d:IsShown() and Q.data.sets.UI.goals[1].quantity==3)
    U.QueueSetDialog('load','Поход'); assert(d.preview:GetText():find(' x3',1,true))
    assert(-d.scroll.point[3]<364 and d.body:GetHeight()>=d.preview:GetStringHeight())
    d.first.scripts.OnClick(d.first); assert(not d:IsShown() and #Q.data.goals==1)
    U.QueueSetDialog('load','Поход'); d.second.scripts.OnClick(d.second)
    assert(#Q.data.goals==2 and Q.Undo())
    U.QueueMenu()
    local found=false
    for _,row in ipairs(U.queueBoard.menuRows) do
        if row:IsShown() and row.open:GetText()=='UI' then
            found=true; row.delete.scripts.OnClick(row.delete); break
        end
    end
    assert(found and not Q.data.sets.UI)
    U.QueueSetDialog('load','Поход'); U.Navigate('recipes'); assert(not d:IsShown())
end
F.db.settings.locale='enUS'; U.Navigate('queue'); bags[1]=3
if U.queueBoard.menu:IsShown() then U.queueBoard.menu:Hide() end
U.QueueMenu(); local cleanup=U.queueBoard.menuRows[2].open; cleanup.scripts.OnClick(cleanup)
assert(#Q.data.goals==0 and Q.undo)
U.QueueMenu(); local undo=U.queueBoard.menuRows[3].open; undo.scripts.OnClick(undo)
assert(#Q.data.goals==1 and not Q.undo and F.localProfile.rev==peerRevision)
Q.data.tracker=true
