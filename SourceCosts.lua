local _,F=...
F.SourceCosts={MAX_RECIPES=8,MAX_WORK=1000000}
local S=F.SourceCosts
local function equal(a,b)
    if type(a)~='table' or type(b)~='table' then return a==b end
    return a.owner==b.owner and a.recipeID==b.recipeID
end
-- Compare one intermediate-material choice by rebuilding the entire plan.
-- Results are private previews, not price optimization or a purchase command.
function S.Compare(profiles,goals,inventory,item,options)
    options=options or {}
    local now=F.Now()
    local context={quotes={},remaining=S.MAX_WORK}
    local baseOptions=F.Copy(options)
    baseOptions.localOwner=baseOptions.localOwner or F.me
    baseOptions.sources=baseOptions.sources or {}
    local function evaluate(choice,kind,source)
        local opts=F.Copy(baseOptions); opts.sources[item]=F.Copy(choice)
        local plan=F.Planner.BuildQueue(profiles,goals,inventory,now,opts)
        local budget=F.Market.Budget(plan.missing,context)
        local fees,staleProvider,blocked=false,false,#plan.warnings>0
        local made,batches,reagents=0,0,{}
        for _,step in ipairs(plan.steps) do
            if step.owner~=baseOptions.localOwner then fees=true end
            if F.ProfileStale(profiles[step.owner]) then staleProvider=true end
            if step.item==item and (not source or step.owner==source.owner and step.recipeID==source.recipeID) then
                made=made+step.quantity; batches=batches+step.batches
                for reagent,count in pairs(step.reagents) do reagents[reagent]=(reagents[reagent] or 0)+count end
            end
        end
        for _,reason in pairs(plan.missingReasons) do
            if reason=='camp' or reason=='source' or reason=='cycle' or reason=='limit' then blocked=true end
        end
        local available=not source or source.ready
        local eligible=available and not blocked and not fees and not staleProvider and budget.uncovered==0 and
            budget.unknown==0 and budget.stale==0 and budget.partial==0 and not budget.approximate and not budget.limited and
            F.Market.Number(budget.cost,0,9007199254740991)~=nil
        return {choice=F.Copy(choice),kind=kind,source=source,budget=budget,fees=fees,staleProvider=staleProvider,
            blocked=blocked,available=available,eligible=not not eligible,selected=equal(choice,baseOptions.sources[item]),
            made=made,batches=batches,reagents=reagents,get=plan.missing[item] or 0,missing=F.Copy(plan.missing),
            surplus=math.max(0,(plan.inventory[item] or 0)-math.max(0,(inventory[item] or 0)-(plan.supplied[item] or 0)))}
    end
    local current=baseOptions.sources[item]
    local result={item=item,rows={},help='SOURCE_COST_HELP'}
    result.current=evaluate(current,'current')
    result.rows[1]=evaluate(nil,'auto')
    result.rows[2]=evaluate('external','external')
    local sources=F.Planner.Sources(profiles,item,now,baseOptions.localOwner)
    local included={}
    -- Keep a pinned source visible even if it lies beyond the preview limit.
    if type(current)=='table' then
        for _,source in ipairs(sources) do
            if equal(current,source) then included[#included+1]=source; break end
        end
    end
    for _,source in ipairs(sources) do
        if #included>=S.MAX_RECIPES then break end
        if not equal(current,source) then included[#included+1]=source end
    end
    result.truncated=#sources>#included
    for _,source in ipairs(included) do
        result.rows[#result.rows+1]=evaluate({owner=source.owner,recipeID=source.recipeID},'recipe',source)
    end
    local best,count=nil,0
    for _,row in ipairs(result.rows) do
        if row.eligible then best=math.min(best or row.budget.cost,row.budget.cost); count=count+1 end
    end
    for _,row in ipairs(result.rows) do
        row.lowest=count>1 and row.eligible and row.budget.cost==best
        if row.eligible and result.current.eligible then row.delta=row.budget.cost-result.current.budget.cost end
    end
    return result
end
