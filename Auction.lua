local _,F=...
F.Auction={pending={},cooldown=0}
local A,M=F.Auction,F.Market
local function call(name,...)
    local fn=C_AuctionHouse and C_AuctionHouse[name]
    if not fn then return nil end
    local ok,value=pcall(fn,...)
    if ok then return value end
end
function A.Key(id)
    return {itemID=id,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0}
end
-- Hand the player to Blizzard's normal name search, including their filters.
-- No purchase, quantity selection, or fabricated browse result is performed.
function A.Search(item)
    local frame=AuctionHouseFrame
    local bar=frame and frame.SearchBar
    local id=type(item)=='string' and tonumber(item:match('^item:(%d+)$'))
    if not id or not M.Number(id,1,2147483647) then return false,F.L('MARKET_API_UNAVAILABLE') end
    if not A.open or not frame or not frame:IsShown() then return false,F.L('TRACK_AH_CLOSED') end
    if not bar or not bar.SetSearchText or not bar.StartSearch or not frame.SetDisplayMode or
        not frame.GetCategoriesList or not AuctionHouseFrameDisplayMode or not AuctionHouseFrameDisplayMode.Buy then
        return false,F.L('MARKET_API_UNAVAILABLE')
    end
    if call('IsThrottledMessageSystemReady')~=true then return false,F.L('TRACK_WAIT_SEARCH') end
    local getInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
    local ok,name=false,nil
    if getInfo then ok,name=pcall(getInfo,id) end
    if not ok or type(name)~='string' or name=='' then return false,F.L('TRACK_LOADING') end
    local categories=frame:GetCategoriesList()
    if not categories or not categories.SetSelectedCategory then return false,F.L('MARKET_API_UNAVAILABLE') end
    A.Cancel()
    frame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    categories:SetSelectedCategory(nil)
    bar:SetSearchText(name)
    bar:StartSearch()
    return true
end
local function sameKey(a,b)
    if type(a)~='table' or type(b)~='table' then return false end
    for _,field in ipairs({'itemID','itemLevel','itemSuffix','battlePetSpeciesID'}) do
        if a[field]~=b[field] then return false end
    end
    return true
end
local function state(key)
    A.status=key; F.UI.DataChanged()
    if A.panel and A.panel:IsShown() then A.Render() end
end
function A.Cancel(reason)
    A.pending={}; A.active=nil; A.running=false; state(reason or 'MARKET_STOPPED')
end
function A.Read(id,commodity,key)
    local offers,valid={},true
    local count=call(commodity and 'GetNumCommoditySearchResults' or 'GetNumItemSearchResults',commodity and id or key)
    if not M.Number(count,0,1000000) then return end
    local complete=call(commodity and 'HasFullCommoditySearchResults' or 'HasFullItemSearchResults',commodity and id or key)==true
    local info=call('GetItemKeyInfo',key or A.Key(id))
    -- Inventory/plans have item IDs, not gear variants. Do not price arbitrary
    -- equipment levels/suffixes as the player's exact item.
    if not info or info.isEquipment~=false or info.isPet~=false then return end
    for i=1,math.min(count,M.MAX_OFFERS) do
        local row=call(commodity and 'GetCommoditySearchResultInfo' or 'GetItemSearchResultInfo',commodity and id or key,i)
        if type(row)~='table' or not M.Number(row.quantity,1,1000000) then valid=false
        elseif commodity then
            if row.itemID~=id or not M.Number(row.unitPrice,1,9007199254740991) or not M.Number(row.numOwnerItems,0,row.quantity) then valid=false
            elseif row.containsAccountItem~=true then
                local quantity=row.quantity-row.numOwnerItems
                if quantity>0 then offers[#offers+1]={quantity=quantity,price=row.unitPrice} end
            end
        elseif sameKey(row.itemKey,key) then
            if row.containsOwnerItem~=true and row.containsAccountItem~=true and row.buyoutAmount~=nil then
                if M.Number(row.buyoutAmount,1,9007199254740991) then offers[#offers+1]={quantity=row.quantity,price=row.buyoutAmount}
                elseif not M.Number(row.buyoutAmount,0,0) then valid=false end
            end
        else valid=false end
    end
    complete=complete and valid and count<=M.MAX_OFFERS
    if not valid and #offers==0 then return end
    M.Save('item:'..id,offers,commodity,complete)
    return complete,count>=M.MAX_OFFERS
end
function A.Scan(items)
    if not A.open or not A.panel or not A.panel:IsShown() then return false,F.L('MARKET_AT_AH') end
    if not C_AuctionHouse or not C_AuctionHouse.SendSearchQuery or not C_AuctionHouse.GetItemKeyInfo or not C_AuctionHouse.IsThrottledMessageSystemReady then return false,F.L('MARKET_UNSUPPORTED') end
    A.Cancel()
    local unique={}
    for _,item in ipairs(items) do
        local id=type(item)=='string' and tonumber(item:match('^item:(%d+)$'))
        if M.Number(id,1,2147483647) and not unique[id] and #A.pending<100 then
            unique[id]=true; A.pending[#A.pending+1]={id=id,key=A.Key(id),retries=0}
        end
    end
    A.total=#A.pending; A.finished=0; A.skipped=0; A.running=#A.pending>0; A.cooldown=0
    state(A.running and 'MARKET_SCANNING' or 'MARKET_NO_TARGETS')
    return A.running
end
local function nextItem(skipped)
    A.finished=(A.finished or 0)+1
    if skipped then A.skipped=(A.skipped or 0)+1 end
    A.active=nil
    if #A.pending==0 then A.running=false; state('MARKET_FINISHED') else state('MARKET_SCANNING') end
end
function A.Results(id,commodity,key)
    local active=A.active
    local matches=active and active.sent and active.id==id and active.commodity==commodity and (commodity or sameKey(active.key,key))
    local complete,capped=A.Read(id,commodity,key or A.Key(id))
    if matches then
        if complete or capped then nextItem()
        else active.more=true; active.waited=0 end
    end
    if A.panel and A.panel:IsShown() then A.Render() end
end
local function send(name,...)
    local fn=C_AuctionHouse and C_AuctionHouse[name]
    if not fn then return false end
    A.ours=true; local ok,value=pcall(fn,...); A.ours=false
    A.cooldown=2 -- At most 30 queries/page requests per minute, plus native API readiness.
    -- RequestMore* returns hasFullResults: false means an unfinished page
    -- request, not an API rejection. Search APIs have no return value.
    return ok,value
end
function A.Tick(elapsed)
    if not A.running then return end
    if not A.open or not A.panel or not A.panel:IsShown() then A.Cancel(); return end
    A.cooldown=math.max(0,A.cooldown-elapsed)
    if not A.active then A.active=table.remove(A.pending,1) end
    local active=A.active; if not active then return end
    active.waited=(active.waited or 0)+elapsed
    if active.waited>15 then
        active.retries=active.retries+1; active.waited=0; active.sent=false; active.more=nil
        if active.retries>2 then nextItem(true); return end
    end
    if A.cooldown>0 or call('IsThrottledMessageSystemReady')~=true then return end
    if not active.sent then
        local info=call('GetItemKeyInfo',active.key)
        if not info then return end
        if info.isEquipment~=false or info.isPet~=false or type(info.isCommodity)~='boolean' then nextItem(true); return end
        active.commodity=info.isCommodity; active.sent=true; active.waited=0
        if not send('SendSearchQuery',active.key,{},true) then active.sent=false; active.waited=15 end
    elseif active.more then
        active.more=nil; active.waited=0
        local ok,full=send(active.commodity and 'RequestMoreCommoditySearchResults' or 'RequestMoreItemSearchResults',active.commodity and active.id or active.key)
        if not ok then
            active.sent=false; active.waited=15
        elseif full==true and A.active==active then
            A.Results(active.id,active.commodity,active.key)
        end
    end
end
local function text(parent,width,x,y,size)
    local label=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    label:SetPoint('TOPLEFT',x,y); label:SetWidth(width); label:SetJustifyH('LEFT'); label:SetWordWrap(true)
    F.Theme.Text(label,false,size or 14); return label
end
function A.Render()
    if not A.panel then return end
    A.LayoutPanel()
    F.Theme.RefreshFonts()
    A.description:SetText(F.L('MARKET_SCAN_HELP'))
    A.scanButton:SetText(F.L('MARKET_SCAN')); A.scanButton:SetEnabled(A.open and not A.running)
    A.stopButton:SetText(F.L('CANCEL')); A.stopButton:SetEnabled(not not A.running)
    A.marketButton:SetText(F.L('PAGE_market'))
    A.progress:SetText((A.status and F.L(A.status) or '')..(A.total and ' '..string.format(F.L('MARKET_PROGRESS'),A.finished or 0,A.total,A.skipped or 0) or ''))
    local width=math.max(340,A.panel:GetWidth()>0 and A.panel:GetWidth() or 768)
    A.description:SetWidth(width-28); A.description:SetHeight(0)
    local y=12+A.description:GetStringHeight()+10
    local controlWidth=(width-44)/3
    local height=0
    for i,b in ipairs({A.scanButton,A.stopButton,A.marketButton}) do
        b:ClearAllPoints(); b:SetPoint('TOPLEFT',14+(i-1)*(controlWidth+8),-y)
        height=math.max(height,F.Theme.FitButton(b,controlWidth))
    end
    y=y+height+10
    A.progress:SetWidth(width-28); A.progress:SetHeight(0)
    A.progress:ClearAllPoints(); A.progress:SetPoint('TOPLEFT',14,-y)
    if A.progress:GetText()~='' then y=y+A.progress:GetStringHeight()+8 end
    A.scroll:ClearAllPoints(); A.scroll:SetPoint('TOPLEFT',14,-y); A.scroll:SetPoint('BOTTOMRIGHT',-28,14)
    A.scrollChild:SetWidth(width-42); A.results:SetWidth(width-48)
    local plan=F.Queue.Build(); local lines={}
    for _,item in ipairs(F.Keys(plan.missing)) do
        lines[#lines+1]=F.Catalog.ItemName(item)..' x'..plan.missing[item]..'\n'..F.UI.PriceText(item,plan.missing[item])
    end
    A.results:SetText(F.Catalog.Safe(#lines>0 and table.concat(lines,'\n\n') or F.L('MARKET_NO_TARGETS')))
    A.scrollChild:SetHeight(math.max(300,A.results:GetStringHeight()+20))
end
function A.LayoutPanel()
    if not A.panel or not A.host then return end
    -- Native MoneyFrameInset ends 27px above the window bottom (XML), not
    -- inside the content area. Reserve its strip in either addon theme.
    local frame=A.host
    local bottom=math.max(36,frame.MoneyFrameInset and frame.MoneyFrameInset:GetHeight()+11 or 0,
        frame.MoneyFrameBorder and frame.MoneyFrameBorder:GetHeight()+14 or 0)
    A.panel:ClearAllPoints(); A.panel:SetPoint('TOPLEFT',16,-40); A.panel:SetPoint('BOTTOMRIGHT',-16,bottom)
end
function A.Attach()
    local frame=AuctionHouseFrame
    if A.panel or not frame or type(frame.Tabs)~='table' or not frame.tabsForDisplayMode or not AuctionHouseFrameDisplayMode or
        not frame.SetDisplayMode or not PanelTemplates_SetNumTabs then return end
    local panel=CreateFrame('Frame',nil,frame,'BackdropTemplate'); panel:SetPoint('TOPLEFT',16,-40); panel:SetPoint('BOTTOMRIGHT',-16,10)
    F.Theme.Skin(panel,true); panel:Hide()
    A.panel,A.host=panel,frame; frame.ForeverNetPanel=panel; A.LayoutPanel()
    local mode={'ForeverNetPanel'}; AuctionHouseFrameDisplayMode.ForeverNet=mode
    local tab=CreateFrame('Button',nil,frame,'AuctionHouseFrameDisplayModeTabTemplate'); tab:SetText('ForeverNet'); tab.displayMode=mode
    -- PanelTabButtonTemplate inherits parentArray="Tabs": CreateFrame has
    -- already registered the tab in the real client. Do not append it twice.
    local index
    for i,registered in ipairs(frame.Tabs) do if registered==tab then index=i; break end end
    if not index then frame.Tabs[#frame.Tabs+1]=tab; index=#frame.Tabs end
    tab:SetID(index); frame.tabsForDisplayMode[mode]=index
    PanelTemplates_SetNumTabs(frame,#frame.Tabs)
    tab:SetScript('OnClick',function() frame:SetDisplayMode(mode) end)
    A.tab=tab
    if hooksecurefunc and frame.UpdateTitle then
        hooksecurefunc(frame,'UpdateTitle',function()
            if frame.displayMode==mode then frame:SetTitle('ForeverNet') end
        end)
    end
    A.description=text(panel,730,14,-12,14)
    local function control(x,width,action)
        local b=CreateFrame('Button',nil,panel,'UIPanelButtonTemplate'); b:SetPoint('TOPLEFT',x,-70); b:SetSize(width,24); F.Theme.Button(b); b:SetScript('OnClick',action); return b
    end
    A.scanButton=control(14,270,function()
        local items=F.Keys(F.Queue.Build().missing)
        if #items==0 then
            local favorites=F.Copy(F.db.favorites.recipes)
            for item in pairs(F.db.favorites.market) do favorites[item]=true end
            items=F.Keys(favorites)
        end
        local ok,why=A.Scan(items); if why then F.Print(why) end
    end)
    A.stopButton=control(296,160,function() A.Cancel() end)
    A.marketButton=control(468,270,function() F.UI.Navigate('market') end)
    A.progress=text(panel,728,14,-102,12)
    local scroll=F.Theme.ScrollFrame(panel); A.scroll=scroll; scroll:SetPoint('TOPLEFT',14,-140); scroll:SetPoint('BOTTOMRIGHT',-28,14)
    A.scrollChild=CreateFrame('Frame',nil,scroll); A.scrollChild:SetSize(700,300); scroll:SetScrollChild(A.scrollChild)
    A.results=text(A.scrollChild,694,0,0,14)
    panel:SetScript('OnShow',function() A.Render() end)
    panel:SetScript('OnSizeChanged',function() A.Render() end)
    panel:SetScript('OnHide',function() if A.running then A.Cancel() end end)
end
function A.Start()
    if A.frame then return end
    local frame=CreateFrame('Frame'); A.frame=frame
    for _,event in ipairs({'ADDON_LOADED','AUCTION_HOUSE_SHOW','AUCTION_HOUSE_CLOSED','COMMODITY_SEARCH_RESULTS_RECEIVED',
        'COMMODITY_SEARCH_RESULTS_ADDED','COMMODITY_SEARCH_RESULTS_UPDATED','ITEM_SEARCH_RESULTS_UPDATED','ITEM_SEARCH_RESULTS_ADDED','AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED'}) do frame:RegisterEvent(event) end
    frame:SetScript('OnEvent',function(_,event,arg)
        if event=='ADDON_LOADED' then A.Attach()
        elseif event=='AUCTION_HOUSE_SHOW' then A.open=true; A.Attach(); A.Render()
        elseif event=='AUCTION_HOUSE_CLOSED' then A.open=false; A.Cancel()
        elseif event=='AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED' and A.active then A.active.waited=15
        elseif event=='COMMODITY_SEARCH_RESULTS_RECEIVED' then
            if A.active and A.active.commodity then A.Results(A.active.id,true,A.active.key) end
        elseif event:find('COMMODITY_SEARCH_RESULTS_',1,true) and M.Number(arg,1,2147483647) then A.Results(arg,true,A.Key(arg))
        elseif event:find('ITEM_SEARCH_RESULTS_',1,true) and type(arg)=='table' then A.Results(arg.itemID,false,arg) end
    end)
    frame:SetScript('OnUpdate',function(_,elapsed) A.Tick(elapsed) end)
    -- A secure post-hook leaves the native API intact and yields when the
    -- player/another addon searches. Never fight over auction result buffers.
    if hooksecurefunc and C_AuctionHouse then
        for _,name in ipairs({'SendSearchQuery','SendSellSearchQuery','SendBrowseQuery','ReplicateItems'}) do
            if C_AuctionHouse[name] then
                hooksecurefunc(C_AuctionHouse,name,function() if A.running and not A.ours then A.Cancel('MARKET_INTERRUPTED') end end)
            end
        end
    end
    A.Attach()
end
