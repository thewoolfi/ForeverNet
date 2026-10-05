local _,F=...
F.Queue={MAX_GOALS=50,MAX_SETS=10}
local Q=F.Queue
local function source(choice)
    return choice=='external' or type(choice)=='table' and F.Text(choice.owner) and F.ID(choice.recipeID)
end
local function choices(saved)
    local valid={}
    if type(saved)=='table' then
        for item,choice in pairs(saved) do
            if #F.Keys(valid)>=200 then break end
            if F.ID(item) and source(choice) then valid[item]=F.Copy(choice) end
        end
    end
    return valid
end
local function goalValid(goal)
    return type(goal)=='table' and F.ID(goal.item) and F.Integer(goal.quantity,1,10000) and
        (goal.owner==nil or F.Text(goal.owner)) and (goal.recipeID==nil or F.ID(goal.recipeID)) and
        (goal.mode==nil or goal.mode=='stock')
end
local function nameValid(name)
    if not F.Text(name) then return end
    name=name:match('^%s*(.-)%s*$')
    if #name>0 and #name<=80 then return name end
end
local function goalCopy(goal)
    return {item=goal.item,quantity=goal.quantity,owner=goal.owner,recipeID=goal.recipeID,mode=goal.mode}
end
local function duplicateStock(goals)
    local seen={}
    for _,goal in ipairs(goals) do
        if goal.mode=='stock' then
            if seen[goal.item] then return goal.item end
            seen[goal.item]=true
        end
    end
end
function Q.Init()
    F.db.queues=type(F.db.queues)=='table' and F.db.queues or {}
    local saved=F.db.queues[F.me]
    saved=type(saved)=='table' and saved or {}
    local goals={}
    for _,goal in ipairs(type(saved.goals)=='table' and saved.goals or {}) do
        if #goals>=Q.MAX_GOALS then break end
        if goalValid(goal) then
            goals[#goals+1]=goalCopy(goal)
            if duplicateStock(goals) then goals[#goals]=nil end
        end
    end
    local sets,names={},{}
    for name in pairs(type(saved.sets)=='table' and saved.sets or {}) do
        if nameValid(name)==name then names[#names+1]=name end
    end
    table.sort(names)
    for _,name in ipairs(names) do
        local set=saved.sets[name]
        local valid=type(set)=='table' and type(set.goals)=='table' and #set.goals>0 and #set.goals<=Q.MAX_GOALS
        if valid then
            local copied={}
            for index,goal in pairs(set.goals) do
                if not F.Integer(index,1,#set.goals) or not goalValid(goal) then valid=false; break end
                copied[index]=goalCopy(goal)
            end
            for i=1,#set.goals do if not copied[i] then valid=false end end
            if duplicateStock(copied) then valid=false end
            if valid then sets[name]={goals=copied,sources=choices(set.sources)} end
        end
        if #F.Keys(sets)>=Q.MAX_SETS then break end
    end
    Q.data={goals=goals,sources=choices(saved.sources),tracker=saved.tracker==true,sets=sets}
    Q.undo=nil
    F.db.queues[F.me]=Q.data
end
local function changed(keepUndo)
    if not keepUndo then Q.undo=nil end
    F.UI.DataChanged()
end
local function snapshot() return {goals=F.Copy(Q.data.goals),sources=F.Copy(Q.data.sources)} end
function Q.SaveSet(name)
    name=nameValid(name)
    if not name then return false,F.L('SETS_NAME_ERROR') end
    if #Q.data.goals==0 then return false,F.L('EMPTY_queue') end
    if not Q.data.sets[name] and #F.Keys(Q.data.sets)>=Q.MAX_SETS then return false,F.L('SETS_FULL') end
    Q.data.sets[name]=snapshot(); changed(true); return true
end
function Q.DeleteSet(name)
    if not Q.data.sets[name] then return false end
    Q.data.sets[name]=nil; changed(true); return true
end
function Q.LoadSet(name,append)
    local set=Q.data.sets[name]
    if not set then return false,F.L('SETS_MISSING') end
    local goals=append and F.Copy(Q.data.goals) or {}
    if #goals+#set.goals>Q.MAX_GOALS then return false,F.L('QUEUE_FULL') end
    local sources=append and F.Copy(Q.data.sources) or {}
    -- Appending must not change routes chosen for goals already in the queue.
    local conflicts=0
    for item,choice in pairs(set.sources) do
        local current=sources[item]
        if current==nil then sources[item]=F.Copy(choice)
        elseif current~=choice and not (type(current)=='table' and type(choice)=='table' and
            current.owner==choice.owner and current.recipeID==choice.recipeID) then conflicts=conflicts+1 end
    end
    if #F.Keys(sources)>200 then return false,F.L('SETS_SOURCES_FULL') end
    for _,goal in ipairs(set.goals) do goals[#goals+1]=F.Copy(goal) end
    if duplicateStock(goals) then return false,F.L('RESTOCK_DUPLICATE') end
    Q.undo=snapshot(); Q.data.goals,Q.data.sources=goals,sources
    changed(true); return true,conflicts
end
function Q.Undo()
    if not Q.undo then return false end
    Q.data.goals,Q.data.sources=Q.undo.goals,Q.undo.sources; Q.undo=nil
    changed(true); return true
end
function Q.Add(item,quantity,owner,recipeID,mode)
    if not F.ID(item) or not F.Integer(quantity,1,10000) or (owner and not F.Text(owner)) or (recipeID and not F.ID(recipeID)) then return false,F.L('QUANTITY_ERROR') end
    if mode~=nil and mode~='stock' then return false,F.L('QUANTITY_ERROR') end
    if mode=='stock' then
        for _,goal in ipairs(Q.data.goals) do if goal.item==item and goal.mode=='stock' then return false,F.L('RESTOCK_DUPLICATE') end end
    end
    if #Q.data.goals>=Q.MAX_GOALS then return false,F.L('QUEUE_FULL') end
    Q.data.goals[#Q.data.goals+1]={item=item,quantity=quantity,owner=owner,recipeID=recipeID,mode=mode}
    changed(); return true
end
function Q.Mode(index,mode)
    if not F.Integer(index,1,#Q.data.goals) or mode~=nil and mode~='stock' then return false,F.L('QUANTITY_ERROR') end
    local goal=Q.data.goals[index]
    if mode=='stock' then
        for i,other in ipairs(Q.data.goals) do
            if i~=index and other.item==goal.item and other.mode=='stock' then return false,F.L('RESTOCK_DUPLICATE') end
        end
    end
    goal.mode=mode; changed(); return true
end
function Q.Quantity(index,quantity)
    if not Q.data.goals[index] or not F.Integer(quantity,1,10000) then return false end
    Q.data.goals[index].quantity=quantity; changed(); return true
end
function Q.Remove(index)
    if not F.Integer(index,1,#Q.data.goals) then return false end
    table.remove(Q.data.goals,index); changed(); return true
end
function Q.MoveUp(index)
    if not F.Integer(index,2,#Q.data.goals) then return false end
    local goals=Q.data.goals; goals[index-1],goals[index]=goals[index],goals[index-1]; changed(); return true
end
function Q.SetSource(item,choice)
    if not F.ID(item) or choice~=nil and not source(choice) then return false end
    if choice~=nil and Q.data.sources[item]==nil and #F.Keys(Q.data.sources)>=200 then return false,F.L('SETS_SOURCES_FULL') end
    Q.data.sources[item]=F.Copy(choice); changed(); return true
end
function Q.RemoveOwned()
    local profiles=F.Profiles()
    local inventory=F.Adapter.Inventory(profiles)
    -- Bank snapshots are planning aids, not proof that finished goods are carried.
    for item in pairs(inventory) do inventory[item]=F.Adapter.ItemCount(item) end
    for _,goal in ipairs(Q.data.goals) do inventory[goal.item]=F.Adapter.ItemCount(goal.item) end
    local plan=F.Planner.BuildQueue(profiles,Q.data.goals,inventory,nil,{localOwner=F.me,sources=Q.data.sources})
    local incomplete={}
    for i,goal in ipairs(Q.data.goals) do
        if plan.goalStates[i].stock<goal.quantity then incomplete[goal.item]=true end
    end
    local goals,removed={},0
    for i,goal in ipairs(Q.data.goals) do
        -- Keep repeated targets together: successive clicks cannot reuse the same
        -- finished stock to clear the remainder of a partially covered item group.
        if goal.mode~='stock' and not incomplete[goal.item] then removed=removed+1 else goals[#goals+1]=F.Copy(goal) end
    end
    if removed>0 then Q.undo=snapshot(); Q.data.goals=goals; changed(true) end
    return removed
end
function Q.Build()
    local profiles=F.Profiles()
    local bags={}
    local inventory=F.Adapter.Inventory(profiles,bags)
    for _,goal in ipairs(Q.data.goals) do
        if inventory[goal.item]==nil then
            bags[goal.item]=F.Adapter.ItemCount(goal.item)
            inventory[goal.item]=bags[goal.item]+(F.db.settings.useBank~=false and F.Bank.Count(goal.item) or 0)
        end
    end
    local plan=F.Planner.BuildQueue(profiles,Q.data.goals,inventory,nil,{localOwner=F.me,sources=Q.data.sources,bags=bags})
    for item in pairs(plan.supplied) do plan.bagSupplied[item]=plan.bagSupplied[item] or 0 end
    return plan
end
