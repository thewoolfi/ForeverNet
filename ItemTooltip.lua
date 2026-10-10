local _,F=...
local T=F.Theme
local function ensure()
    if not T.tooltip then T.tooltip=CreateFrame('GameTooltip','ForeverNetTooltip',UIParent,'GameTooltipTemplate') end
    return T.tooltip
end
local function fonts(tip)
    for _,region in ipairs({tip:GetRegions()}) do
        if region:GetObjectType()=='FontString' then T.Font(region,12) end
    end
end
local function clear(tip)
    if tip.ClearHandlerInfo then tip:ClearHandlerInfo() end
    if tip.ClearLines then tip:ClearLines() end
end
function T.HideTooltipFor(owner)
    if T.tooltipOwner==owner then T.HideTooltip() end
end
local function watch(owner)
    if owner.foreverNetTooltipWatch then return end
    owner.foreverNetTooltipWatch=true
    owner:HookScript('OnHide',function(self) T.HideTooltipFor(self) end)
end
function T.HideTooltip()
    T.itemHover,T.tooltipOwner=nil,nil
    if T.tooltip then T.tooltip:Hide(); clear(T.tooltip) end
end
function T.ShowTooltip(owner,title,line,anchor)
    T.itemHover=nil; T.tooltipOwner=owner; watch(owner)
    local tip=ensure(); clear(tip); tip:SetOwner(owner,anchor or 'ANCHOR_RIGHT'); tip:SetText(title)
    if line and line~='' then tip:AddLine(line,.86,.85,.80,true) end
    fonts(tip); tip:Show()
end
local function footer(tip,state)
    if state.hint and state.hint~='' then
        tip:AddLine(' '); tip:AddLine(state.hint,.86,.85,.80,true)
    end
    fonts(tip); tip:Show()
end
function T.ShowItemTooltip(owner,item,title,hint,anchor)
    local id=type(item)=='string' and tonumber(item:match('^item:(%d+)$'))
    if not F.Integer(id,1,2147483647) then T.ShowTooltip(owner,title or item or '',hint,anchor); return false end
    local previous=T.itemHover
    local state={owner=owner,item=item,id=id,title=title or F.Catalog.ItemName(item),hint=hint,anchor=anchor,
        requested=previous and previous.owner==owner and previous.item==item and previous.requested or false}
    T.itemHover,T.tooltipOwner=state,owner; watch(owner)
    local tip=ensure(); clear(tip); tip:SetOwner(owner,anchor or 'ANCHOR_RIGHT')
    local ok,result=false,false
    if tip.SetItemByID then ok,result=pcall(tip.SetItemByID,tip,id)
    elseif tip.SetHyperlink then ok,result=pcall(tip.SetHyperlink,tip,'item:'..id) end
    local ready=ok and result~=false and (not tip.NumLines or tip:NumLines()>0)
    if ready then
        -- Blizzard renders armor/stats/effects/requirements and quality colors.
        -- Keep only an owned tooltip's post-rebuild callback, never a global hook.
        local info=tip.GetPrimaryTooltipInfo and tip:GetPrimaryTooltipInfo()
        if info then
            info.rebuildPostCall=function(self)
                if T.itemHover==state and state.owner:IsVisible() then footer(self,state) end
            end
        end
        footer(tip,state); return true
    end
    clear(tip); tip:SetText(state.title)
    tip:AddLine(F.L('ITEM_TOOLTIP_LOADING'),.72,.70,.66,true); footer(tip,state)
    if not state.requested then
        state.requested=true
        local request=C_Item and C_Item.RequestLoadItemDataByID
        if request then pcall(request,id)
        else
            local getInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
            if getInfo then pcall(getInfo,id) end
        end
    end
    return false
end
function T.BindItemTooltip(widget,item,title,hint,anchor)
    widget:EnableMouse(true)
    local function value(source,self)
        if type(source)=='function' then return source(self) end
        return source
    end
    widget:SetScript('OnEnter',function(self)
        self=self or widget
        local key,caption=value(item,self),value(title,self)
        if not key and (not caption or caption=='') then return end
        T.ShowItemTooltip(self,key,caption,value(hint,self),anchor)
    end)
    widget:SetScript('OnLeave',function(self) T.HideTooltipFor(self or widget) end)
    watch(widget)
    T.HideTooltipFor(widget) -- A recycled visible widget may now describe another item.
end
function T.TooltipEvent(event,id,success)
    if event~='GET_ITEM_INFO_RECEIVED' and event~='ITEM_DATA_LOAD_RESULT' then return end
    local state=T.itemHover
    if not state or state.id~=id or not state.owner:IsVisible() then return end
    if success==false then
        local tip=ensure(); clear(tip); tip:SetText(state.title)
        tip:AddLine(F.L('ITEM_TOOLTIP_UNAVAILABLE'),.72,.70,.66,true); footer(tip,state); return
    end
    T.ShowItemTooltip(state.owner,state.item,state.title,state.hint,state.anchor)
end
