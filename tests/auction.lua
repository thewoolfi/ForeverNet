local F,A,M=ForeverNet,ForeverNet.Auction,ForeverNet.Market
local queries,pages,hooks=0,0,{}
local ready=true
local offers={{itemID=2318,quantity=4,unitPrice=1000,numOwnerItems=1,containsAccountItem=false},
    {itemID=2318,quantity=5,unitPrice=1200,numOwnerItems=0,containsAccountItem=false}}
local complete=false
C_AuctionHouse={
    GetItemKeyInfo=function(key) return {itemID=key.itemID,isCommodity=true,isEquipment=key.itemID==900,isPet=false} end,
    IsThrottledMessageSystemReady=function() return ready end,
    SendSearchQuery=function(key) queries=queries+1; if hooks.SendSearchQuery then hooks.SendSearchQuery() end end,
    GetNumCommoditySearchResults=function() return #offers end,
    HasFullCommoditySearchResults=function() return complete end,
    GetCommoditySearchResultInfo=function(_,i) return offers[i] end,
    RequestMoreCommoditySearchResults=function() pages=pages+1; return false end,
}
function hooksecurefunc(_,name,fn) hooks[name]=fn end
AuctionHouseFrameDisplayMode={Buy={'Browse'},Sell={'SellFrame'},Auctions={'AuctionsFrame'}}
AuctionHouseFrame=CreateFrame('Frame'); local frame=AuctionHouseFrame
frame.MoneyFrameInset=CreateFrame('Frame',nil,frame); frame.MoneyFrameInset:SetHeight(24)
frame.MoneyFrameBorder=CreateFrame('Frame',nil,frame); frame.MoneyFrameBorder:SetHeight(19)
frame.Tabs={CreateFrame('Button'),CreateFrame('Button'),CreateFrame('Button')}; frame.tabsForDisplayMode={}
function PanelTemplates_SetNumTabs(f,count)
    f.numTabs=count
    for i=2,count do f.Tabs[i]:SetPoint('TOPLEFT',f.Tabs[i-1],'TOPRIGHT',3,0) end
end


function frame:SetDisplayMode(mode)
    self.mode=mode
    for _,group in pairs(AuctionHouseFrameDisplayMode) do
        for _,child in ipairs(group) do
            local panel=self[child]
            if panel then
                if mode==group then panel:Show(); if panel.scripts.OnShow then panel.scripts.OnShow(panel) end
                else panel:Hide(); if panel.scripts.OnHide then panel.scripts.OnHide(panel) end end
            end
        end
    end
end
-- Restart registration against an API appearing after the test client loaded.
A.frame=nil; A.Start(); A.open=true
assert(frame.numTabs==4 and #frame.Tabs==4 and A.tab:GetID()==4)
assert(frame.tabsForDisplayMode[AuctionHouseFrameDisplayMode.ForeverNet]==4)
local seen={}
for _,tab in ipairs(frame.Tabs) do assert(not seen[tab]); seen[tab]=true end
A.Attach(); assert(#frame.Tabs==4)
A.tab.scripts.OnClick(); assert(frame.mode==AuctionHouseFrameDisplayMode.ForeverNet)
assert(A.panel.points.BOTTOMRIGHT[3]>=36)
for _,style in ipairs({'classic','modern'}) do
    F.Theme.SetStyle(style); A.Render()
    assert(A.panel.points.BOTTOMRIGHT[3]>=36 and frame.MoneyFrameInset:IsShown())
    frame.MoneyFrameInset:SetHeight(48); A.Render(); assert(A.panel.points.BOTTOMRIGHT[3]>=59)
    frame.MoneyFrameInset:SetHeight(24)
end
assert(A.Scan({'item:2318','item:2318'})); assert(#A.pending==1)
ready=false; A.Tick(1); assert(queries==0)
ready=true; A.Tick(1); assert(queries==1)
A.frame.scripts.OnEvent(A.frame,'COMMODITY_SEARCH_RESULTS_RECEIVED')
assert(M.Quote('item:2318',8).cost==9000 and M.Quote('item:2318',8).partial)
A.Tick(2); assert(pages==1 and A.active.sent and not A.active.more)
complete=true; A.frame.scripts.OnEvent(A.frame,'COMMODITY_SEARCH_RESULTS_ADDED',2318)
assert(not A.running and not M.Quote('item:2318',8).partial)
assert(A.Scan({'item:2318'})); A.Tick(2)
C_AuctionHouse.SendSearchQuery(A.Key(1)); assert(not A.running and A.status=='MARKET_INTERRUPTED')
assert(A.Scan({'item:2318'})); A.Tick(2)
frame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy); assert(not A.running)
assert(not A.Scan({'item:2318'}))
A.tab.scripts.OnClick()
assert(A.Scan({'item:900'})); A.Tick(1); assert(not A.running and A.skipped==1 and not M.data.snapshots['item:900'])
assert(A.Scan({'item:2318'})); A.Tick(1)
A.frame.scripts.OnEvent(A.frame,'AUCTION_HOUSE_CLOSED'); assert(not A.running and #A.pending==0)
A.open=true; assert(A.Scan({'item:2318'}))
for i=1,150 do A.Tick(1) end
assert(not A.running and A.skipped==1) -- Bounded retries, no infinite loading.
-- Bid-only / own lots / different item variants never become buyout prices.
C_AuctionHouse.GetItemKeyInfo=function(key) return {itemID=key.itemID,isCommodity=false,isEquipment=false,isPet=false} end
local key=A.Key(200)
local lots={{itemKey=key,quantity=2,buyoutAmount=600,containsOwnerItem=false,containsAccountItem=false},
    {itemKey=key,quantity=9,buyoutAmount=1,containsOwnerItem=true},
    {itemKey=key,quantity=1,buyoutAmount=nil,containsOwnerItem=false},
    {itemKey={itemID=200,itemLevel=30,itemSuffix=0,battlePetSpeciesID=0},quantity=1,buyoutAmount=1}}
C_AuctionHouse.GetNumItemSearchResults=function() return #lots end
C_AuctionHouse.HasFullItemSearchResults=function() return true end
C_AuctionHouse.GetItemSearchResultInfo=function(_,i) return lots[i] end
A.Read(200,false,key)
local quote=M.Quote('item:200',1); assert(quote.cost==600 and quote.bought==2 and quote.partial)
offers[1].unitPrice='secret'; A.Read(2318,true,A.Key(2318))
assert(M.data.snapshots['item:2318'].complete==false)
-- Preserve a tab added by another addon; use the actual registered index.
local otherFrame=CreateFrame('Frame'); otherFrame.Tabs={CreateFrame('Button'),CreateFrame('Button'),CreateFrame('Button')}
otherFrame.tabsForDisplayMode={}; otherFrame.SetDisplayMode=frame.SetDisplayMode
local thirdParty=CreateFrame('Button',nil,otherFrame,'AuctionHouseFrameDisplayModeTabTemplate')
thirdParty.displayMode={'ThirdPartyPanel'}; otherFrame.tabsForDisplayMode[thirdParty.displayMode]=4
AuctionHouseFrame=otherFrame; A.panel=nil; A.Attach()
assert(#otherFrame.Tabs==5 and A.tab:GetID()==5 and otherFrame.Tabs[4]==thirdParty)
assert(otherFrame.tabsForDisplayMode[thirdParty.displayMode]==4 and otherFrame.tabsForDisplayMode[A.tab.displayMode]==5)
A.Attach(); assert(#otherFrame.Tabs==5)
-- Long translated controls/progress must not overlap or use hard-coded widths.
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale
    for _,width in ipairs({600,800}) do
        A.panel:SetWidth(width); A.status=nil; A.total=nil; A.Render()
        local y=-A.scanButton.point[3]
        assert(y>=12+A.description:GetStringHeight())
        assert(A.progress:GetText()=='' and A.results:GetWidth()==width-48)
        local maxHeight=0
        for _,b in ipairs({A.scanButton,A.stopButton,A.marketButton}) do
            assert(b:GetHeight()>=b.measure:GetStringHeight()+8)
            assert(b.point[2]+b:GetWidth()<=width-14)
            maxHeight=math.max(maxHeight,b:GetHeight())
        end
        assert(-A.scroll.points.TOPLEFT[3]>=y+maxHeight+10)
        A.status='MARKET_INTERRUPTED'; A.Render()
        assert(-A.scroll.points.TOPLEFT[3]>=-A.progress.point[3]+A.progress:GetStringHeight()+8)
    end
end

-- An empty-deficit targeted scan includes the independent market watch list
-- and old recipe bookmarks once each, without starting a real scan here.
local savedScan,savedBuild=A.Scan,F.Queue.Build
F.Queue.Build=function() return {missing={}} end
F.db.favorites.market={['item:700']=true,['item:701']=true}
F.db.favorites.recipes={['item:700']=true,['item:702']=true}
local scanned
A.Scan=function(items) scanned=items; return true end
A.scanButton.scripts.OnClick()
assert(#scanned==3 and scanned[1]=='item:700' and scanned[2]=='item:701' and scanned[3]=='item:702')
A.Scan,F.Queue.Build=savedScan,savedBuild
