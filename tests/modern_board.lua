local F,U,T,Q=ForeverNet,ForeverNet.UI,ForeverNet.Theme,ForeverNet.Queue
local normal=GameFontNormal:GetFont()
U.Status(); F.Settings.Open(); F.Updates.Open()
for _,frame in ipairs({U.frame,F.Settings.frame,F.Updates.frame}) do
    assert(frame.flatChrome and frame.flatChrome.backdrop.edgeSize==1)
    assert(frame.flatChrome.backdropColor[4]==0 and frame.flatBase.color[4]==1)
    assert(not frame.NineSlice:IsShown() and not frame.PortraitContainer:IsShown())
    assert(frame:GetTitleText():GetFont()==T.defaultFont)
end
assert(GameFontNormal:GetFont()==normal)
local sample=CreateFrame('Button',nil,UIParent,'UIPanelButtonTemplate')
sample.Left=sample:CreateTexture(); sample.Middle=sample:CreateTexture(); sample.Right=sample:CreateTexture()
sample.Left:Show(); sample.Middle:Show(); sample.Right:Show()
sample.normal=sample:CreateTexture(); sample.highlight=sample:CreateTexture()
function sample:GetNormalTexture() return self.normal end
function sample:GetHighlightTexture() return self.highlight end
T.Button(sample); sample:SetText('Sample'); T.FitButton(sample,100)
assert(not sample.Left:IsShown() and not sample.Middle:IsShown() and not sample.Right:IsShown())
assert(sample.normal.alpha==0 and sample.flatFill and sample:GetFontString().point[1]=='CENTER')
assert(sample:GetNormalFontObject():GetFont()==T.defaultFont)
local inventory={[2]=2,[3]=4}
C_Item={GetItemInfo=function(id) return 'Item '..id end,GetItemCount=function(id) return inventory[id] or 0 end}
local function recipe(id,reagents)
    return {name=id,output=id,quantity=1,profession='skill:165',blueprint=false,reagents=reagents,stations={}}
end
F.localProfile.recipes={first=recipe('item:1',{['item:2']=3}),second=recipe('item:4',{['item:3']=2})}
Q.Add('item:1',2,F.me,'first'); Q.Add('item:4',1,F.me,'second')
local function savedGoals()
    local map={}; for i,goal in ipairs(Q.data.goals) do map[tostring(i)]=goal end
    return F.Codec.Encode({goals=map,sources=Q.data.sources})
end
local stored=savedGoals()
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('queue')
    local b=U.queueBoard
    assert(U.right:GetHeight()==433-(U.paneTop-93) and not U.chosen:IsShown() and not U.plan:IsShown())
    assert(#U.chainRows==0 and (not U.visualStats or not U.visualStats[1] or not U.visualStats[1]:IsShown())) -- No duplicate goal cards or statistic boxes.
    assert(b.materials:IsShown() and b.crafts:IsShown() and b.next:IsShown())
    assert(b.bar:GetHeight()>=b.costValue:GetStringHeight()+8)
    for _,tile in ipairs(U.visualTiles) do if tile:IsShown() then assert(tile:GetHeight()>=-tile.detail.point[3]+tile.detail:GetStringHeight()+16) end end
    U.Select(U.entries[2]); assert(U.qty.parent==b.goalBar and U.qty:IsShown())
    local hide,setShown=0,U.qty.SetShown
    U.qty.SetShown=function(self,show) if not show then hide=hide+1 end; return setShown(self,show) end
    U.qty:SetText('3'); assert(Q.data.goals[2].quantity==3)
    assert(hide==0) -- Typing must not hide the edit box and lose native keyboard focus.
    U.qty.SetShown=setShown
    U.qty:SetText('0'); assert(Q.data.goals[2].quantity==3 and U.qty.color[1]>.9)
    U.qty:SetText('1'); assert(Q.data.goals[2].quantity==1)
    assert(b.goalBar:GetHeight()>=-b.stock.point[3]+b.stock:GetHeight())
    b.up.scripts.OnClick(); assert(U.selectedEntry.index==1 and Q.data.goals[1].item=='item:4')
    assert(not b.up.enabled)
    b.stock.scripts.OnClick(); assert(Q.data.goals[1].mode=='stock')
    b.stock.scripts.OnClick(); assert(not Q.data.goals[1].mode)
    b.crafts.scripts.OnClick(); assert(b.steps[1]:IsShown() and not b.next:IsShown())
    b.materials.scripts.OnClick(); assert(not b.steps[1]:IsShown())
    -- Restore ordering for the next locale.
    Q.MoveUp(2); U.selectionKey=nil; U.Status()
    U.Navigate('recipes'); assert(U.qty.parent==U.frame and not b.goalBar:IsShown() and not b.menu:IsShown())
end
assert(savedGoals()==stored)
U.Navigate('queue'); Q.data.sets={}
for i=1,10 do assert(Q.SaveSet(string.rep('Long name ',7)..i)) end
U.QueueMenu(); local b=U.queueBoard
assert(b.menu:GetHeight()<=330 and b.menuBody:GetHeight()>b.menu:GetHeight())
assert(#b.menuRows==13 and b.menuRows[1].open:IsShown())
for _,row in ipairs(b.menuRows) do if row:IsShown() then assert(row:GetHeight()>=row.open:GetHeight()) end end
local last=b.menuRows[13]; last.delete.scripts.OnClick(last.delete); assert(#F.Keys(Q.data.sets)==9)
U.frame.scripts.OnHide(); assert(not b.menu:IsShown())
-- Unknown final items appear as missing materials, not an empty board.
Q.data.goals={{item='item:999',quantity=2}}; U.Navigate('queue')
assert(U.visualTiles[1]:IsShown() and U.visualTiles[1].entry.item=='item:999')
inventory[999]=2; U.DataChanged(); U.Tick(1)
assert(U.queueBoard.next.title:GetText()==F.L('ALREADY_OWNED'))
