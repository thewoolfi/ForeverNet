local F,T,U=ForeverNet,ForeverNet.Theme,ForeverNet.UI
local nativeFont=GameFontNormal:GetFont()
GameTooltip={sentinel=true}; local globalTooltip=GameTooltip
local requests={}
local bags={}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Item '..id end,
    RequestLoadItemDataByID=function(id) requests[id]=(requests[id] or 0)+1 end}
mockItemTooltips={
    [1]={{'Test armor',{.1,.7,1,1}},{'120 Armor'},{'+8 Stamina'},{'Requires Level 15',{1,.1,.1}}, {'Equip: Test effect',{.1,1,.1}}},
    [2]={{'Test leather'},{'Crafting material'}},[3]={{'Test thread'},{'Crafting material'}}}
local function has(value)
    for _,line in ipairs(T.tooltip.tooltipLines) do if line:GetText()==value then return true end end
end
local function enter(widget,id)
    assert(widget and widget:IsVisible() and widget.scripts.OnEnter)
    widget.scripts.OnEnter(widget)
    assert(T.tooltip.owner==widget and T.tooltip.nativeItem==id and T.tooltip:IsShown())
    assert(T.itemHover.id==id)
end
local owner=CreateFrame('Frame',nil,UIParent)
T.BindItemTooltip(owner,'item:1','Fallback name','Bags: 2 / Bank: 3')
enter(owner,1)
assert(has('120 Armor') and has('+8 Stamina') and has('Equip: Test effect') and has('Requires Level 15'))
assert(T.tooltip.title.color[1]==.1 and T.tooltip.title.color[2]==.7)
assert(T.tooltip.tooltipLines[4].color[1]==1 and T.tooltip.tooltipLines[4].color[2]==.1)
assert(T.tooltip.tooltipLines[7]:GetText()=='Bags: 2 / Bank: 3')
local info=T.tooltip:GetPrimaryTooltipInfo()
-- Native asynchronous rebuilds render native lines again; our footer follows once.
T.tooltip:ClearLines(); T.tooltip:SetItemByID(1); info.rebuildPostCall(T.tooltip)
assert(T.tooltip:NumLines()==7 and has('Bags: 2 / Bank: 3'))
owner.scripts.OnLeave(owner); assert(not T.tooltip:IsShown() and not T.itemHover)
info.rebuildPostCall(T.tooltip); assert(not T.tooltip:IsShown())

-- Legacy method fallback preserves native data instead of emulating statistics.
T.tooltip.SetItemByID=false
enter(owner,1); assert(T.tooltip.nativeLink=='item:1' and has('120 Armor'))
T.tooltip.SetItemByID=nil

-- Missing cache: bounded request, matching event refresh, no stale owner/item updates.
T.BindItemTooltip(owner,'item:99','Loading test','Planning hint')
owner.scripts.OnEnter(owner)
assert(requests[99]==1 and has(F.L('ITEM_TOOLTIP_LOADING')) and not has('120 Armor'))
owner.scripts.OnEnter(owner); assert(requests[99]==1)
T.TooltipEvent('ITEM_DATA_LOAD_RESULT',98,true); assert(has(F.L('ITEM_TOOLTIP_LOADING')))
mockItemTooltips[99]={{'Loaded armor'},{'300 Armor'}}
frames[1].scripts.OnEvent(frames[1],'ITEM_DATA_LOAD_RESULT',99,true)
assert(has('300 Armor') and has('Planning hint') and requests[99]==1)
T.BindItemTooltip(owner,'item:100','Failed test','Retained hint'); owner.scripts.OnEnter(owner)
T.TooltipEvent('GET_ITEM_INFO_RECEIVED',100,false)
assert(has(F.L('ITEM_TOOLTIP_UNAVAILABLE')) and has('Retained hint') and not has('300 Armor'))
owner:Hide(); T.TooltipEvent('ITEM_DATA_LOAD_RESULT',100,true)
assert(not T.tooltip:IsShown() and not T.itemHover) -- Hidden owner never refreshes.
owner:Show(); T.BindItemTooltip(owner,'item:1','Armor'); enter(owner,1)
T.BindItemTooltip(owner,'item:2','Leather'); assert(not T.tooltip:IsShown())
T.TooltipEvent('GET_ITEM_INFO_RECEIVED',1,true); assert(not T.tooltip:IsShown())
enter(owner,2); assert(not has('120 Armor'))
for _,key in ipairs({'custom:ore','item:0','item:2147483648','item:1:bogus'}) do
    T.ShowItemTooltip(owner,key,'Custom entry','Custom hint')
    assert(not T.itemHover and T.tooltip.title:GetText()=='Custom entry' and has('Custom hint'))
end
assert(not requests[1] and not requests[2] and GameTooltip==globalTooltip)

F.localProfile.professions={['skill:165']=50}
F.localProfile.recipes={armor={name='Test armor',output='item:1',quantity=1,profession='skill:165',blueprint=false,
    reagents={['item:2']=2,['item:3']=1},stations={}}}
local peer=F.NewProfile(); peer.recipes=F.Copy(F.localProfile.recipes); peer.professions={['skill:165']=75}
F.db.profiles['Peer-Realm']=peer
F.Queue.data.goals={}; F.Queue.Add('item:1',1,F.me,'armor')
for _,style in ipairs({'modern','classic'}) do
    T.SetStyle(style)
    for _,locale in ipairs(F.LocaleOrder) do
        F.db.settings.locale=locale
        U.Navigate('recipes'); U.Select(U.entries[1])
        enter(U.rows[1],1); assert(has('120 Armor'))
        enter(U.heroHover,1); enter(U.chosen,1); enter(U.visualStats[1],1)
        enter(U.visualTiles[1],2); assert(has('Crafting material') and T.tooltip.line:GetText():find(F.L('MATERIAL_CARD'):sub(1,4),1,true))
        U.BuildSelected(); enter(U.heroHover,1)
        local craft
        for _,row in ipairs(U.sourceRows) do if row:IsShown() and row.entry.reagents then craft=row end end
        assert(craft); enter(craft,1); enter(craft.ingredients[1],2)
        U.Navigate('queue'); U.Select(U.entries[1]); enter(U.rows[1],1); enter(U.heroHover,1)
        U.queueBoard.materials.scripts.OnClick()
        enter(U.queueBoard.next,1); enter(U.visualTiles[1],2)
        U.queueBoard.crafts.scripts.OnClick(); enter(U.queueBoard.steps[1],1)
        enter(U.queueBoard.steps[1].ingredients[1],2)
        U.Navigate('network'); U.Select(U.entries[1]); enter(U.profileCards[1],1)
        U.Navigate('market'); U.Select(U.entries[1]); enter(U.rows[1],2); enter(U.heroHover,2)
        enter(U.sourceRows[1],2)
        F.Tracker.Toggle(true)
        local material,nextCraft
        for _,row in ipairs(F.Tracker.rows) do
            if row:IsShown() and row.item=='item:2' then material=row
            elseif row:IsShown() and row.item=='item:1' then nextCraft=row end
        end
        enter(material,2); enter(nextCraft,1); enter(material,2)
        assert(T.tooltip.title:GetFont()==(T.fontFiles[locale] or (style=='modern' and T.defaultFont or nativeFont)))
    end
end
-- The root header must describe the plan's result, even if a missing material is selected.
U.Navigate('recipes'); U.SetTarget('item:2',1); U.planData=F.Planner.Build(F.Profiles(),'item:1',1,{})
U.RenderPlan(); enter(U.heroHover,1); enter(U.chosen,2)
U.ShowCards({{item='item:1',title='Armor',text='Hint'}}); enter(U.cards[1],1)
U.Show('Help'); assert(not T.itemHover)
U.Help(); U.heroHover.scripts.OnEnter(U.heroHover); assert(not T.tooltip:IsShown() and not U.detailItem)
U.Commands(); U.heroHover.scripts.OnEnter(U.heroHover); assert(not T.tooltip:IsShown() and not U.detailItem)
assert(GameTooltip==globalTooltip and GameFontNormal:GetFont()==nativeFont)
