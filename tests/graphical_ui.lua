local F,U=ForeverNet,ForeverNet.UI
local bags={[2]=1}
C_Item={GetItemCount=function(id) return bags[id] or 0 end,GetItemInfo=function(id) return 'Item '..id end}
F.localProfile.professions['skill:165']=50
F.localProfile.recipes.one={name='Test item',output='item:1',quantity=1,profession='skill:165',blueprint=false,reagents={['item:2']=2,['item:3']=1},stations={}}
F.db.professionScans={[F.me]={['skill:165']={seen=clock,maximum=75}}}
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('home')
    assert(U.rows[1].entry.maximum==75 and U.rows[1].fill:IsShown())
    assert(U.visualTiles[1].entry.title==F.L('PAGE_queue'))
    assert(not U.navigation.chain:IsShown() and U.sharing:GetText()=='')
    assert(U.navigation.requests:IsShown())
    U.rows[1].scripts.OnClick(U.rows[1]); assert(U.page=='recipes' and U.recipeFilters.profession=='skill:165')
    U.Select(U.entries[1])
    assert(U.visualStats[1].value:GetText()=='1' and U.visualStats[2].value:GetText()=='0')
    for i=1,2 do
        local tile=U.visualTiles[i]
        assert(tile:GetHeight()>=-tile.detail.point[3]+tile.detail:GetStringHeight()+16)
        tile.scripts.OnEnter(); assert(F.Theme.tooltip:IsShown())
        assert(F.Theme.tooltip.line:GetText():find(F.L('MARKET_UNKNOWN'),1,true))
        tile.scripts.OnLeave(); assert(not F.Theme.tooltip:IsShown())
    end
    U.BuildSelected(); assert(U.navigation.chain:IsShown())
    local row
    for _,r in ipairs(U.sourceRows) do if r:IsShown() and r.entry.reagents then row=r end end
    assert(row and row.ingredients[1]:IsShown())
    local bottom=0
    for _,ingredient in ipairs(row.ingredients) do
        if ingredient:IsShown() then
            assert(ingredient.point[2]+ingredient:GetWidth()<=434)
            bottom=math.max(bottom,-ingredient.point[3]+ingredient:GetHeight())
            ingredient.scripts.OnEnter(); assert(F.Theme.tooltip:IsShown()); ingredient.scripts.OnLeave()
        end
    end
    assert(row:GetHeight()>=bottom)
    U.Navigate('queue'); assert(U.right:GetHeight()==433-(U.paneTop-93) and not U.qty:IsShown())
    F.Queue.Add('item:1',1,F.me,'one'); U.Status()
    U.Select(U.entries[1])
    assert(U.queueBoard.goalBar:IsShown() and U.queueBoard.stock:IsShown())
    U.queueBoard.stock.scripts.OnClick(U.queueBoard.stock); assert(F.Queue.data.goals[1].mode=='stock')
    U.queueBoard.stock.scripts.OnClick(U.queueBoard.stock); assert(F.Queue.data.goals[1].mode==nil)
    U.filterButton.scripts.OnClick(); assert(U.queueBoard.menu:IsShown())
    U.filterButton.scripts.OnClick(); assert(not U.queueBoard.menu:IsShown())
    U.queueBoard.crafts.scripts.OnClick(); assert(U.queueBoard.steps[1]:IsShown())
    U.queueBoard.materials.scripts.OnClick(); assert(not U.queueBoard.steps[1]:IsShown())
    F.Queue.data.goals={}

end
-- Recycled cards must drop their old actions/progress/ingredients.
U.Show(''); U.ShowSourceRows({{key='long',visual=true,item='item:1',title=string.rep('Long ',70),text='Owner',reagents={}}})
local row=U.sourceRows[1]
local reagents={}; for i=1,15 do reagents['item:'..(100+i)]=123456789 end
U.ShowSourceRows({{visual=true,item='item:1',title='Craft',reagents=reagents}})
local previousY=nil
for _,widget in ipairs(row.ingredients) do
    assert(widget:GetHeight()>=28+widget.count:GetStringHeight()+4)
    assert(row:GetHeight()>=-widget.point[3]+widget:GetHeight())
    if previousY then assert(widget.point[3]<=previousY) end
    previousY=widget.point[3]
end
U.ShowSourceRows({{title='Reused'}})
assert(not row.more:IsShown() and not row.fill:IsShown())
for _,widget in ipairs(row.ingredients) do assert(not widget:IsShown()) end
U.ShowVisualTiles({{title=string.rep('Long translated profession ',20),icon=F.icon,text=string.rep('Metadata ',20)}})
local tile=U.visualTiles[1]; assert(tile:GetHeight()>=-tile.detail.point[3]+tile.detail:GetStringHeight()+16)
U.Show('Help'); assert(not tile:IsShown() and not U.visualStats[1]:IsShown())
assert(U.ShortPrice('item:1',100000000)=='?')
U.Navigate('recipes'); U.Select(U.entries[1]); assert(U.crafter.scripts.OnEnter)
U.Navigate('queue'); assert(not U.crafter.scripts.OnEnter) -- No stale recipe tooltip on tracker action.
U.Navigate('network'); assert(U.enqueue:IsShown() and U.enqueue:GetText()==F.L('PAGE_requests'))
U.enqueue.scripts.OnClick(); assert(U.page=='requests' and U.navigation.requests:IsShown())
