local F,A=ForeverNet,ForeverNet.Auction
local ready=true
C_AuctionHouse={IsThrottledMessageSystemReady=function() return ready end}
local frame=CreateFrame('Frame'); AuctionHouseFrame=frame
local starts=0
local categories={selected='armor',SetSelectedCategory=function(self,category) self.selected=category end}
function frame:GetCategoriesList() return categories end
AuctionHouseFrameDisplayMode={Buy={'Browse'},ForeverNet={'ForeverNetPanel'}}
function frame:SetDisplayMode(mode) self.mode=mode; self.SearchBar.text='' end
frame.SearchBar={SetSearchText=function(self,name) self.text=name end,StartSearch=function(self) starts=starts+1 end}
C_Item={GetItemInfo=function(id) if id==2318 then return 'Thin Leather' end end}
assert(not A.Search('item:2318') and starts==0) -- Auction closed.
A.open=true; frame:Hide(); assert(not A.Search('item:2318') and starts==0)
frame:Show(); ready=false; assert(not A.Search('item:2318') and starts==0 and categories.selected=='armor')
ready=true; A.running=true; A.pending={'item:1'}
assert(not A.Search('demo:ore') and A.running)
assert(not A.Search('item:999') and A.running and starts==0) -- Loading names never search an ID or fallback label.
assert(A.Search('item:2318'))
assert(starts==1 and frame.SearchBar.text=='Thin Leather' and frame.mode==AuctionHouseFrameDisplayMode.Buy)
assert(not A.running and #A.pending==0 and categories.selected==nil)
-- The native entry point owns search/result lifecycle. No purchase API is even required.
frame.SearchBar.StartSearch=nil; assert(not A.Search('item:2318') and starts==1)
