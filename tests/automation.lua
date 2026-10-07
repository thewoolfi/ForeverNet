local F,A,Q,U,M=ForeverNet,ForeverNet.Automation,ForeverNet.Queue,ForeverNet.UI,ForeverNet.Market
local function recipe(output,reagents,quantity)
    return {name=output,output=output,quantity=quantity or 1,profession='skill:165',blueprint=false,reagents=reagents,stations={}}
end
local bags={}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Item '..id end}
F.localProfile.recipes={goal=recipe('item:1',{['item:2']=2}),convert=recipe('item:2',{['item:3']=3})}
M.Save('item:2',{{quantity=100,price=10}},true,true)
M.Save('item:3',{{quantity=100,price=20}},true,true)
Q.Add('item:1',1,F.me,'goal')
local p=Q.Build()
assert(p.sources['item:2']=='external' and p.missing['item:2']==2 and #p.steps==1)
assert(not Q.data.sources['item:2'] and not p.manualSources['item:2']) -- Automatic routes are transient.
M.Save('item:2',{{quantity=100,price=100}},true,true)
M.Save('item:3',{{quantity=100,price=1}},true,true)
p=Q.Build(); assert(not p.sources['item:2'] and p.missing['item:3']==6 and #p.steps==2)
Q.SetSource('item:2','external'); p=Q.Build(); assert(p.sources['item:2']=='external')
Q.SetSource('item:2',{owner=F.me,recipeID='convert'})
M.Save('item:2',{{quantity=100,price=1}},true,true)
p=Q.Build(); assert(p.sources['item:2'].recipeID=='convert' and p.missing['item:3']==6)
Q.SetSource('item:2',nil)
-- Stale/partial/no-volume prices cannot drive a known cheapest choice.
M.data.snapshots['item:2'].seen=clock-1900
p=Q.Build(); assert(not p.sources['item:2'])
M.Save('item:2',{{quantity=100,price=1}},true,false)
p=Q.Build(); assert(not p.sources['item:2'])
M.Save('item:2',{{quantity=1,price=1}},true,true)
p=Q.Build(); assert(not p.sources['item:2'])
M.Save('item:2',{{quantity=100,price=1}},true,true)
F.db.settings.autoSources=false; p=Q.Build(); assert(not p.sources['item:2'])
F.db.settings.autoSources=true
local compare=F.SourceCosts.Compare; local count=0
local sourceIndex=F.Planner.SourceIndex; local indexCount=0
F.Planner.SourceIndex=function(...) indexCount=indexCount+1; return sourceIndex(...) end
F.SourceCosts.Compare=function(...) count=count+1; return compare(...) end
Q.Build(); assert(count<=A.MAX_CHOICES and indexCount==1); F.SourceCosts.Compare=compare; F.Planner.SourceIndex=sourceIndex
-- Live refresh respects manual choices, target pins, quantity and scroll state.
U.Navigate('recipes'); U.SetTarget('item:1',2,F.me,'goal'); U.BuildSelected()
assert(U.planData.sources['item:2']=='external')
U.ChooseSource('item:2',{owner=F.me,recipeID='convert'})
bags[3]=12; U.DataChanged(); U.Tick(1)
assert(U.planData.complete and U.planData.quantity==2 and U.planData.recipeID=='goal')
assert(U.planData.manualSources['item:2'].recipeID=='convert')
bags[3]=0; U.DataChanged(); U.Tick(1); assert(U.planData.missing['item:3']==12)
F.db.banks={[F.me]={items={['item:3']=12},seen=clock}}
U.DataChanged(); U.Tick(1); assert(U.planData.complete and U.planData.bagSupplied['item:3']==0)
F.db.settings.useBank=false; U.DataChanged(); U.Tick(1); assert(U.planData.missing['item:3']==12)
F.db.settings.useBank=true; F.db.banks={}
U.qty:SetText('3'); assert(U.planData.quantity==3 and U.planData.missing['item:3']==18)
U.qty:SetText('0'); assert(U.planData.quantity==3)
U.ChooseSource('item:2',nil); assert(U.planData.sources['item:2']=='external')
U.Navigate('queue')
-- Debounced scans read current native filters without changing them or opening Net.
local calls=0
C_TradeSkillUI={GetBaseProfessionInfo=function() return {professionID=165,skillLevel=50,maxSkillLevel=75} end,
    GetFilteredRecipeIDs=function() calls=calls+1; return {101} end,
    GetRecipeInfo=function() return {name='Learned',learned=true} end,
    GetRecipeSchematic=function() return {outputItemID=20,quantityMin=1,reagentSlotSchematics={}} end}
ProfessionsFrame=CreateFrame('Frame',nil,UIParent); ProfessionsFrame:Show()
local page=U.page
A.Event('TRADE_SKILL_SHOW'); A.Tick(.3); assert(calls==0)
A.Tick(.5); assert(calls==1 and F.localProfile.recipes['spell:101'] and U.page==page)
assert(F.localProfile.recipes.goal and #Q.data.goals==1)
C_TradeSkillUI.IsTradeSkillLinked=function() return true end
A.Event('TRADE_SKILL_LIST_UPDATE'); A.Tick(1); assert(calls==1)
C_TradeSkillUI.IsTradeSkillLinked=nil
F.db.settings.autoScan=false; A.Event('TRADE_SKILL_SHOW'); A.Tick(1); assert(calls==1)
F.db.settings.autoScan=true; A.Event('TRADE_SKILL_SHOW'); A.Event('TRADE_SKILL_CLOSE'); A.Tick(1); assert(calls==1)
A.Event('TRADE_SKILL_SHOW'); ProfessionsFrame:Hide(); A.Tick(1); assert(calls==1)
ProfessionsFrame:Show(); C_TradeSkillUI.GetFilteredRecipeIDs=function() calls=calls+1; return nil end
A.Event('TRADE_SKILL_SHOW'); for i=1,8 do A.Tick(2) end
assert(calls==4 and A.scanPending==nil and F.localProfile.recipes.goal)
F.Settings.Open()
for _,check in ipairs(F.Settings.checks) do
    if check.key=='autoSources' or check.key=='autoScan' then
        check:SetChecked(false); check.scripts.OnClick(check); assert(F.db.settings[check.key]==false)
    end
end
assert(#F.Net.queue==0 and not F.Net.lastSendResult)
