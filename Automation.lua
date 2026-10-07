local _,F=...
F.Automation={MAX_CHOICES=6,MAX_WORK=200000}
local A=F.Automation
-- Greedy, bounded cash comparison. Explicit choices and final recipe pins win.
-- Only complete fresh quotes with known local crafting costs may be selected.
function A.Build(profiles,goals,inventory,options)
    options=F.Copy(options or {})
    options.localOwner=options.localOwner or F.me
    -- All hypothetical routes share the same recipe/facility snapshot.
    -- A closure avoids deep-copying a large recipe index for every candidate.
    local index=F.Planner.SourceIndex(profiles,F.Now(),options.localOwner)
    options.sourceIndex=function() return index end
    local manual=F.Copy(options.sources or {})
    local plan=F.Planner.BuildQueue(profiles,goals,inventory,nil,options)
    plan.manualSources=manual; plan.autoSources={}
    if F.db.settings.autoSources==false then return plan end
    local roots={}
    for _,goal in ipairs(goals) do roots[goal.item]=true end
    local remaining=A.MAX_WORK
    local compared={}
    for attempt=1,A.MAX_CHOICES do
        local candidate
        for _,item in ipairs(F.Keys(plan.materials)) do
            local material=plan.materials[item]
            if not roots[item] and not manual[item] and not compared[item] and #material.alternatives>0 and material.quantity>material.stock then
                candidate=item; break
            end
        end
        if not candidate or remaining<=0 then break end
        compared[candidate]=true
        local opts=F.Copy(options); opts.maxWork=remaining
        local result=F.SourceCosts.Compare(profiles,goals,inventory,candidate,opts)
        remaining=math.max(0,remaining-(result.workUsed or A.MAX_WORK))
        local best=result.current.eligible and result.current or nil
        for _,row in ipairs(result.rows) do
            if row.eligible and not row.budget.limited and (not best or row.budget.cost<best.budget.cost) then best=row end
        end
        if best and best~=result.current then
            options.sources=options.sources or {}; options.sources[candidate]=F.Copy(best.choice)
            plan=F.Planner.BuildQueue(profiles,goals,inventory,nil,options)
            plan.autoSources=F.Copy(options.sources)
            for item in pairs(manual) do plan.autoSources[item]=nil end
            plan.manualSources=manual
        end
    end
    return plan
end
function A.RefreshPlan()
    local U=F.UI; local old=U.planData
    if not old then return end
    local profiles=F.Profiles(); local inventory=F.Adapter.Inventory(profiles)
    inventory[old.target]=F.Adapter.StockCount(old.target)
    local p=A.Build(profiles,{{item=old.target,quantity=old.quantity,owner=old.owner,recipeID=old.recipeID}},inventory,
        {localOwner=F.me,sources=old.manualSources or old.sources})
    p.target,p.quantity,p.owner,p.recipeID=old.target,old.quantity,old.owner,old.recipeID
    p.bagSupplied={}
    for item,count in pairs(p.supplied) do p.bagSupplied[item]=math.min(F.Adapter.ItemCount(item),count) end
    U.planData=p
end
function A.Event(event)
    if event=='TRADE_SKILL_CLOSE' then A.scanPending=nil; return end
    if F.db.settings.autoScan==false then return end
    if event=='TRADE_SKILL_SHOW' or event=='TRADE_SKILL_LIST_UPDATE' or event=='TRADE_SKILL_DATA_SOURCE_CHANGED' then
        A.scanPending=.7; A.scanAttempts=0
    end
end
function A.Tick(elapsed)
    if not A.scanPending then return end
    if F.db.settings.autoScan==false then A.scanPending=nil; return end
    A.scanPending=A.scanPending-elapsed
    if A.scanPending>0 then return end
    if ProfessionsFrame and not ProfessionsFrame:IsShown() then A.scanPending=nil; return end
    local api=C_TradeSkillUI
    if (IsTradeSkillLinked and IsTradeSkillLinked()) or (Professions and Professions.InLocalCraftingMode and not Professions.InLocalCraftingMode()) then A.scanPending=nil; return end
    for _,flag in ipairs({'IsTradeSkillLinked','IsTradeSkillGuild','IsTradeSkillGuildMember','IsNPCCrafting'}) do
        if api and api[flag] and api[flag]() then A.scanPending=nil; return end
    end
    local ok,scanned=pcall(F.Adapter.Scan)
    if ok and scanned then A.scanPending=nil; F.UI.DataChanged(); return end
    A.scanAttempts=(A.scanAttempts or 0)+1
    A.scanPending=A.scanAttempts<3 and 1.5 or nil
end
