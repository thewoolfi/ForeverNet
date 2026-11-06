local _,F=...
local U,C,T=F.UI,F.Catalog,F.Theme
local function who(owner) return owner==F.me and F.L('YOU') or owner end
local function text(parent,size,gold)
    local region=parent:CreateFontString(nil,'OVERLAY',gold and 'GameFontNormal' or 'GameFontHighlightSmall')
    T.Text(region,gold,size); region:SetJustifyH('LEFT'); region:SetWordWrap(true)
    return region
end
local function tip(widget,title,detail,item)
    T.BindItemTooltip(widget,item,title,detail)
end
function U.HideGraphics()
    for _,group in ipairs({U.visualStats or {},U.visualTiles or {}}) do
        for _,widget in ipairs(group) do
            widget:Hide()
            if widget.icon and widget.icon.foreverNetBadge then
                widget.icon.foreverNetBadge:Hide()
                if U.badgeLayer and U.badgeLayer.activeBadges then
                    U.badgeLayer.activeBadges[widget.icon.foreverNetBadge]=nil
                end
            end
        end
    end
end
function U.ShortPrice(item,quantity)
    if not F.Market.Number(quantity,0,10000) then return '?' end
    local q=F.Market.Quote(item,math.max(1,quantity))
    if quantity==0 then return F.Market.Money(0) end
    if q.status~='known' then return '?' end
    return F.Market.Money(q.cost)..((q.stale or q.partial or q.approximate or q.remaining>0) and ' *' or '')
end
function U.ShortBudget(missing)
    local b=F.Market.Budget(missing)
    if b.unknown>0 and b.cost==0 then return '?' end
    return F.Market.Money(b.cost)..((b.uncovered>0 or b.stale>0 or b.partial>0 or b.approximate) and ' *' or '')
end
function U.ShowVisualStats(entries,offset)
    U.visualStats=U.visualStats or {}
    local y=offset or 0
    local width=(434-(#entries-1)*8)/math.max(1,#entries)
    local height=58
    for i,entry in ipairs(entries) do
        local card=U.visualStats[i]
        if not card then
            card=CreateFrame('Frame',nil,U.body,'BackdropTemplate'); T.Skin(card,true); card:EnableMouse(true)
            card.icon=card:CreateTexture(nil,'ARTWORK'); card.icon:SetSize(20,20); card.icon:SetPoint('TOPLEFT',8,-9)
            card.value=text(card,16,true); card.value:SetPoint('TOPLEFT',34,-8)
            card.caption=text(card,12); card.caption:SetPoint('TOPLEFT',8,-32)
            U.visualStats[i]=card
        end
        card:ClearAllPoints(); card:SetPoint('TOPLEFT',(i-1)*(width+8),-y); card:SetWidth(width)
        card.value:SetWidth(width-42); card.value:SetHeight(0); card.value:SetText(entry.value)
        card.icon:SetTexture(entry.icon); card.caption:SetWidth(width-16); card.caption:SetHeight(0); card.caption:SetText(entry.title)
        if entry.item then U.MaterialBadge(card.icon,entry.item) else U.MaterialBadge(card.icon,nil) end
        local valueHeight=card.value:GetStringHeight()
        card.caption:ClearAllPoints(); card.caption:SetPoint('TOPLEFT',8,-(valueHeight+14))
        height=math.max(height,valueHeight+card.caption:GetStringHeight()+22)
        T.Color(card.value,entry.tone or 'heading'); tip(card,entry.item and C.ItemName(entry.item) or entry.title,entry.hint,entry.item); card:Show()
    end
    for i=#entries+1,#U.visualStats do
        U.visualStats[i]:Hide()
        if U.visualStats[i].icon and U.visualStats[i].icon.foreverNetBadge then
            U.visualStats[i].icon.foreverNetBadge:Hide()
            if U.badgeLayer and U.badgeLayer.activeBadges then
                U.badgeLayer.activeBadges[U.visualStats[i].icon.foreverNetBadge]=nil
            end
        end
    end
    for i=1,#entries do U.visualStats[i]:SetHeight(height) end
    U.bodyText:Hide(); U.body:SetHeight(math.max(240,y+height+16))
    return y+height+10
end
-- Crafting-material badge. A small hammer in the top-right corner of an item icon
-- marks items that are used for professions: the client's own item class decides,
-- so a player who has scanned nothing still sees every trade good and reagent.
-- Every icon surface calls U.MaterialBadge right after it sets the item texture.
--
-- A texture cannot create child textures in this client, so the badge is created on
-- the icon's parent frame and anchored to the icon's own coordinates.
U.BADGE_ICON='Interface\\Icons\\INV_Hammer_20'
U.BADGE_BORDER_COLOR={0.92, 0.78, 0.20, 0.92}
U.BADGE_BORDER_OFFSET=2
-- One overlay frame owns every badge. It is created above everything else, so a
-- Blizzard item button can never cover the badge, and it keeps the badge's parent
-- under our control instead of a protected container frame.
U.MAX_BADGES=200
U.drawTrace={calls=0,noIcon=0,noBadge=0,notMaterial=0,noPosition=0,drawn=0}
function U.BadgesEnabled()
    return not (F.db and F.db.settings and F.db.settings.materialBadges == false)
end
function U.BadgeLayer()
    if U.badgeLayer then return U.badgeLayer end
    local layer=CreateFrame('Frame',nil,UIParent)
    layer:SetAllPoints(UIParent)
    if layer.SetFrameStrata then layer:SetFrameStrata('TOOLTIP') end
    if layer.SetFrameLevel then layer:SetFrameLevel(900) end
    layer.pool, layer.used = {}, 0
    layer.activeBadges = {}
    layer.elapsed = 0
    if layer.SetScript then
        layer:SetScript('OnUpdate', function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.08 then return end
            self.elapsed = 0
            local active = self.activeBadges
            if not active or not next(active) then return end
            for badge, target in pairs(active) do
                local visible = false
                if target then
                    if target.IsVisible then
                        local ok, vis = pcall(target.IsVisible, target)
                        if ok and vis then visible = true end
                    end
                    if not visible and target.IsShown then
                        local okShown, shown = pcall(target.IsShown, target)
                        if okShown and shown then
                            local parent = target.GetParent and target:GetParent()
                            if parent and parent.IsVisible then
                                local okP, pVis = pcall(parent.IsVisible, parent)
                                if okP and pVis then visible = true end
                            elseif parent and parent.IsShown then
                                local okP, pShown = pcall(parent.IsShown, parent)
                                if okP and pShown then visible = true end
                            elseif not parent then
                                visible = true
                            end
                        end
                    end
                end
                if not visible then
                    badge:Hide()
                    if badge.border then badge.border:Hide() end
                    if badge.mask then badge.mask:Hide() end
                    active[badge] = nil
                end
            end
        end)
    end
    U.badgeLayer=layer
    return layer
end
function U.GetScrollParent(region)
    local p = region and region.GetParent and region:GetParent()
    while p do
        if (p.GetObjectType and p:GetObjectType() == 'ScrollFrame') or p.GetScrollChild then
            return p
        end
        p = p.GetParent and p:GetParent()
    end
    return nil
end
function U.BadgeRegion(icon)
    if not icon then return nil end
    local badge=icon.foreverNetBadge
    local parent=icon.GetParent and icon:GetParent()
    local scrollFrame=U.GetScrollParent and U.GetScrollParent(icon)
    local layer=(scrollFrame and parent and parent.CreateTexture and parent) or U.BadgeLayer()
    if not layer then return nil end
    if not badge then
        badge=layer:CreateTexture(nil,'OVERLAY',nil,7)
        badge.isBadgeLayer=(layer==U.badgeLayer)
        local origHide=badge.Hide
        badge.Hide=function(self)
            origHide(self)
            if self.border then self.border:Hide() end
            if self.mask then self.mask:Hide() end
        end
        local origShow=badge.Show
        badge.Show=function(self)
            origShow(self)
            if self.border then self.border:Show() end
            if self.mask then self.mask:Show() end
        end
        local origSetShown=badge.SetShown
        badge.SetShown=function(self,shown)
            origSetShown(self,shown)
            if self.border then self.border:SetShown(shown) end
            if self.mask then self.mask:SetShown(shown) end
        end
        icon.foreverNetBadge=badge
        U.allBadges=U.allBadges or {}
        U.allBadges[#U.allBadges+1]=badge
        if layer==U.badgeLayer then
            layer.pool=layer.pool or {}
            layer.pool[#layer.pool+1]=badge
            layer.used=#layer.pool
        end
    end
    if not badge.border then
        local border=layer:CreateTexture(nil,'OVERLAY',nil,6)
        if border.SetColorTexture then
            local c=U.BADGE_BORDER_COLOR or {0.92,0.78,0.20,0.92}
            border:SetColorTexture(c[1],c[2],c[3],c[4] or 1.0)
        end
        badge.border=border
    end
    if layer.CreateMaskTexture then
        if badge.border and badge.border.AddMaskTexture and not badge.border.mask then
            local mask=layer:CreateMaskTexture()
            if mask then
                if mask.SetTexture then
                    mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask','CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
                end
                if mask.SetAllPoints then mask:SetAllPoints(badge.border) end
                badge.border:AddMaskTexture(mask)
                badge.border.mask=mask
            end
        end
        if badge.AddMaskTexture and not badge.mask then
            local mask=layer:CreateMaskTexture()
            if mask then
                if mask.SetTexture then
                    mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask','CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
                end
                if mask.SetAllPoints then mask:SetAllPoints(badge) end
                badge:AddMaskTexture(mask)
                badge.mask=mask
            end
        end
    end
    return badge
end
function U.MaterialBadge(icon,item)
    U.drawTrace=U.drawTrace or {calls=0,noIcon=0,noBadge=0,notMaterial=0,noPosition=0,drawn=0}
    U.drawTrace.calls=U.drawTrace.calls+1
    if not icon then U.drawTrace.noIcon=U.drawTrace.noIcon+1; return end
    local badge=U.BadgeRegion(icon)
    if not badge then U.drawTrace.noBadge=U.drawTrace.noBadge+1; return end
    local show=U.BadgesEnabled() and item~=nil and F.Catalog.IsCraftMaterial(item)
    badge:SetShown(show)
    if not show then
        U.drawTrace.notMaterial=U.drawTrace.notMaterial+1
        if U.badgeLayer and U.badgeLayer.activeBadges then U.badgeLayer.activeBadges[badge]=nil end
        return
    end
    -- Anchored to the icon region itself: the client resolves this correctly across
    -- frames, so no absolute screen maths is involved and the badge always lands in
    -- the icon's top-right corner, inside its bounds.
    if not (icon.GetWidth and icon.GetHeight) then
        badge:Hide(); U.drawTrace.noPosition=U.drawTrace.noPosition+1
        if U.badgeLayer and U.badgeLayer.activeBadges then U.badgeLayer.activeBadges[badge]=nil end
        return
    end
    local width,height=icon:GetWidth(),icon:GetHeight()
    if type(width)~='number' or width<=0 or type(height)~='number' or height<=0 then
        badge:Hide(); U.drawTrace.noPosition=U.drawTrace.noPosition+1
        if U.badgeLayer and U.badgeLayer.activeBadges then U.badgeLayer.activeBadges[badge]=nil end
        return
    end
    local size=math.max(8,math.min(13,width*0.42))
    badge:ClearAllPoints()
    badge:SetSize(size,size)
    badge:SetPoint('TOPRIGHT',icon,'TOPRIGHT',1,-1)
    badge:SetTexture(U.BADGE_ICON)
    badge:SetTexCoord(.07,.93,.07,.93)
    if badge.mask and badge.mask.SetAllPoints then
        badge.mask:SetAllPoints(badge)
    end
    if badge.border then
        local offset=U.BADGE_BORDER_OFFSET or 2
        badge.border:ClearAllPoints()
        badge.border:SetPoint('TOPLEFT',badge,'TOPLEFT',-offset,offset)
        badge.border:SetPoint('BOTTOMRIGHT',badge,'BOTTOMRIGHT',offset,-offset)
        if badge.border.SetColorTexture then
            local c=U.BADGE_BORDER_COLOR or {0.92,0.78,0.20,0.92}
            badge.border:SetColorTexture(c[1],c[2],c[3],c[4] or 1.0)
        end
        if badge.border.mask and badge.border.mask.SetAllPoints then
            badge.border.mask:SetAllPoints(badge.border)
        end
    end
    badge:Show()
    if U.badgeLayer and U.badgeLayer.activeBadges then
        local onLayer=badge.isBadgeLayer or (badge.GetParent and badge:GetParent()==U.badgeLayer)
        if onLayer then U.badgeLayer.activeBadges[badge]=icon end
    end
    U.drawTrace.drawn=U.drawTrace.drawn+1
    -- TEMPORARY COUNTER: proves in the saved file whether a badge was really drawn.
    U.badgeDrawn=U.badgeDrawn or {shown=0,noGeometry=0,materials=0}
    U.badgeDrawn.shown=U.badgeDrawn.shown+1
    F.db=F.db or {}; F.db.diagnostics=F.db.diagnostics or {}
    F.db.diagnostics.badgeDrawn=U.badgeDrawn
end
-- Container frames that can hold item buttons. ContainerFrame1..N are empty XML
-- placeholders in this client, so the combined bag frame and the bank frame are
-- included explicitly.
function U.BagContainers()
    local found={}
    local seen={}
    local function add(frame)
        if type(frame)~='table' or seen[frame] then return end
        seen[frame]=true
        found[#found+1]=frame
    end
    add(_G.ContainerFrameCombinedBags)
    local total=math.max(NUM_CONTAINER_FRAMES or 0, NUM_TOTAL_BAG_FRAMES or 0, 14)
    for index=1,total do add(_G['ContainerFrame'..index]) end
    return found
end
-- Blizzard fills a container's Items table while drawing it, so a sweep driven only by
-- the bag event sees an empty table. Each container is therefore given a post-hook on
-- its own OnShow, and the sweep runs from a short timer after that, when the buttons
-- exist. hooksecurefunc does not replace the original handler.
U.bagHooked={}
U.BAG_SWEEP_DELAY=0.15
function U.HookBagContainers()
    local containers=U.BagContainers()
    local bankPanel=_G.BankPanel or (_G.BankFrame and _G.BankFrame.BankPanel)
    local extra={_G.BankFrame,_G.BankSlotsFrame,bankPanel}
    for _,f in ipairs(extra) do
        if type(f)=='table' then containers[#containers+1]=f end
    end
    for _,container in ipairs(containers) do
        if not U.bagHooked[container] then
            U.bagHooked[container]=true
            if container.HookScript then
                container:HookScript('OnShow',function()
                    local isBank=(container==_G.BankFrame or container==bankPanel or container==_G.BankSlotsFrame)
                    if C_Timer and C_Timer.After then
                        C_Timer.After(U.BAG_SWEEP_DELAY,function()
                            if isBank then
                                if U.BankBadges then U.BankBadges() end
                                if U.BagBadges then U.BagBadges() end
                            else
                                if U.BagBadges then U.BagBadges() end
                            end
                        end)
                        C_Timer.After(0.35,function()
                            if isBank then
                                if U.BankBadges then U.BankBadges() end
                                if U.BagBadges then U.BagBadges() end
                            else
                                if U.BagBadges then U.BagBadges() end
                            end
                        end)
                    else
                        if isBank then
                            if U.BankBadges then U.BankBadges() end
                            if U.BagBadges then U.BagBadges() end
                        else
                            if U.BagBadges then U.BagBadges() end
                        end
                    end
                end)
                container:HookScript('OnHide',function()
                    local isBank=(container==_G.BankFrame or container==bankPanel or container==_G.BankSlotsFrame)
                    if isBank then
                        if U.HideBankBadges then U.HideBankBadges() end
                    else
                        if U.BagBadges then U.BagBadges() end
                    end
                end)
            end
        end
    end
    -- Hook global bag open/toggle functions
    if hooksecurefunc and not U.globalBagFunctionsHooked then
        U.globalBagFunctionsHooked=true
        for _,fnName in ipairs({'OpenAllBags','ToggleAllBags','OpenBag','ToggleBag','OpenBackpack','ToggleBackpack'}) do
            if type(_G[fnName])=='function' then
                pcall(hooksecurefunc,fnName,function()
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0.08,function() if U.BagBadges then U.BagBadges() end end)
                        C_Timer.After(0.25,function() if U.BagBadges then U.BagBadges() end end)
                    elseif U.BagBadges then
                        U.BagBadges()
                    end
                end)
            end
        end
    end
    if bankPanel and not U.bankPanelHooked and hooksecurefunc then
        U.bankPanelHooked=true
        for _,method in ipairs({'SetBankType','SelectTab','GenerateItemSlotsForSelectedTab','Refresh','Update'}) do
            if type(bankPanel[method])=='function' then
                hooksecurefunc(bankPanel,method,function()
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0.05,function() if U.BankBadges then U.BankBadges() end end)
                        C_Timer.After(0.25,function() if U.BankBadges then U.BankBadges() end end)
                    else
                        if U.BankBadges then U.BankBadges() end
                    end
                end)
            end
        end
    end
end
-- Bag buttons are Blizzard's protected container buttons: nothing on them is replaced
-- or hooked. The item comes from the read-only container API and the badge is our own
-- texture on the parent frame. The walk is bounded and stops at the first gap, like
-- the client's own iterator.
function U.BagContainersWithItems()
    local count=0
    for _,container in ipairs(U.BagContainers()) do
        if type(container.Items)=='table' and next(container.Items)~=nil then count=count+1 end
    end
    return count
end
U.MAX_BAG_SLOTS=400
-- TEMPORARY CHAT DIAGNOSTIC: prints what the sweep sees, on demand, in chat.
function U.BagDiagnose()
    local get=C_Container and C_Container.GetContainerItemInfo
    F.Print('bag API: '..(get and 'yes' or 'no'))
    U.HookBagContainers()
    local frames=U.BagContainers()
    F.Print('containers found: '..#frames)
    F.Print('non-empty Items: '..tostring(U.BagContainersWithItems()))
    local visited,withItem,material,noTexture=0,0,0,0
    local samples={}
    for _,container in ipairs(frames) do
        local name='?'
        if container.GetName and container:GetName() then name=tostring(container:GetName()) end
        local count=0
        if type(container.Items)=='table' then
            for _ in pairs(container.Items) do count=count+1 end
        end
        F.Print('  '..name..' items='..count)
        if get and type(container.Items)=='table' then
            local index=1
            while index<=U.MAX_BAG_SLOTS do
                local button=container.Items[index]
                if button==nil then break end
                visited=visited+1
                if type(button)=='table' and button.GetBagID and button.GetID then
                    local okBag,bagID=pcall(button.GetBagID,button)
                    local okSlot,slotID=pcall(button.GetID,button)
                    if okBag and okSlot and type(bagID)=='number' and type(slotID)=='number' then
                        local got,info=pcall(get,bagID,slotID)
                        local itemID=got and type(info)=='table' and info.itemID or nil
                        if itemID then
                            withItem=withItem+1
                            local item='item:'..itemID
                            local isMaterial=F.Catalog.IsCraftMaterial(item)
                            if isMaterial then material=material+1 end
                            if #samples<6 then
                                samples[#samples+1]=bagID..'/'..slotID..'='..itemID..
                                    (isMaterial and ' MATERIAL' or ' no')..
                                    ' icon='..(button.icon and 'yes' or 'NO')
                            end
                        end
                        if not button.icon then noTexture=noTexture+1 end
                    end
                end
                index=index+1
            end
        end
    end
    F.Print('visited='..visited..' withItem='..withItem..' material='..material..
        ' noIcon='..noTexture)
    for _,line in ipairs(samples) do F.Print('  '..line) end
    F.Print('badge layer: '..(U.BadgeLayer and 'yes' or 'no')..
        ' drawn='..tostring(U.badgeDrawn and U.badgeDrawn.shown or 0))
    local layer=U.BadgeLayer and U.BadgeLayer()
    F.Print('layer frame: '..tostring(layer~=nil)..
        ' strata='..tostring(layer and layer.GetFrameStrata and layer:GetFrameStrata())..
        ' level='..tostring(layer and layer.GetFrameLevel and layer:GetFrameLevel()))
    local t=U.drawTrace
    F.Print('trace calls='..t.calls..' noIcon='..t.noIcon..' noBadge='..t.noBadge..
        ' notMaterial='..t.notMaterial..' noPosition='..t.noPosition..' drawn='..t.drawn)
end
function U.HideBankBadges()
    if U.bankBadges then
        for badge in pairs(U.bankBadges) do
            if badge and badge.Hide then
                badge:Hide()
                if badge.border then badge.border:Hide() end
                if badge.mask then badge.mask:Hide() end
            end
        end
        U.bankBadges={}
    end
end
function U.BankBadges()
    if not U.BadgesEnabled() then
        if U.HideBankBadges then U.HideBankBadges() end
        return
    end
    local get=C_Container and C_Container.GetContainerItemInfo
    if not get and GetContainerItemInfo then get=GetContainerItemInfo end
    local getItemID=C_Container and C_Container.GetContainerItemID
    local bankFrame=_G.BankFrame
    local bankPanel=_G.BankPanel or (bankFrame and bankFrame.BankPanel)
    local isFrameShown=bankFrame and bankFrame.IsShown and bankFrame:IsShown()
    local isPanelShown=bankPanel and bankPanel.IsShown and bankPanel:IsShown()
    local isBankOpen=F.Bank and F.Bank.open==true
    local bankShown=false
    if isFrameShown or isPanelShown then
        bankShown=true
    elseif (not bankFrame and not bankPanel) and isBankOpen then
        bankShown=true
    end

    if not bankShown then
        if U.HideBankBadges then U.HideBankBadges() end
        return
    end
    local bankBagID=(Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_CONTAINER or -1
    local seen={}

    local function processButton(btn,defaultBag,defaultSlot)
        if type(btn)~='table' or seen[btn] then return end
        seen[btn]=true

        local texture=btn.icon or btn.Icon or btn.iconTexture or btn.IconTexture or btn.ItemIcon
        if not texture and btn.GetName then
            local name=btn:GetName()
            if name then
                texture=_G[name..'IconTexture'] or _G[name..'Icon'] or _G[name..'Texture']
            end
        end
        if not texture and btn.GetRegions then
            for _,reg in ipairs({btn:GetRegions()}) do
                if reg and reg.GetObjectType and reg:GetObjectType()=='Texture' then
                    local tex=reg.GetTexture and reg:GetTexture()
                    if (type(tex)=='number' and tex>0) or (type(tex)=='string' and not tex:find('Border') and not tex:find('Slot')) then
                        texture=reg
                        break
                    end
                end
            end
        end
        if not texture then return end

        local isShown=bankShown and (not btn.IsShown or btn:IsShown())
        if not isShown then
            U.MaterialBadge(texture,nil)
            return
        end

        local itemID=nil
        local bagID=defaultBag
        local slotID=defaultSlot

        -- 1. Try GetItemLocation
        if btn.GetItemLocation then
            local ok,loc=pcall(btn.GetItemLocation,btn)
            if ok and type(loc)=='table' then
                if loc.GetBagAndSlot then
                    local ok2,b,s=pcall(loc.GetBagAndSlot,loc)
                    if ok2 and type(b)=='number' and type(s)=='number' then bagID,slotID=b,s end
                end
                if not itemID and C_Item and C_Item.GetItemID then
                    local ok3,id=pcall(C_Item.GetItemID,loc)
                    if ok3 and type(id)=='number' and id>0 then itemID=id end
                end
            end
        end

        -- 2. Try GetBankTabID and GetContainerSlotID (modern BankPanelItemButton)
        if not bagID and btn.GetBankTabID then
            local ok,b=pcall(btn.GetBankTabID,btn)
            if ok and type(b)=='number' then bagID=b end
        end
        if not slotID and btn.GetContainerSlotID then
            local ok,s=pcall(btn.GetContainerSlotID,btn)
            if ok and type(s)=='number' then slotID=s end
        end

        -- 3. Try GetBagAndSlot
        if (not bagID or not slotID) and btn.GetBagAndSlot then
            local ok,b,s=pcall(btn.GetBagAndSlot,btn)
            if ok and type(b)=='number' and type(s)=='number' then bagID,slotID=b,s end
        end

        -- 4. Try GetBagID and GetID
        if not bagID and btn.GetBagID then
            local ok,b=pcall(btn.GetBagID,btn)
            if ok and type(b)=='number' then bagID=b end
        end
        if not slotID and btn.GetID then
            local ok,s=pcall(btn.GetID,btn)
            if ok and type(s)=='number' then slotID=s end
        end

        -- 5. Try fields on btn
        if not bagID and type(btn.bagID)=='number' then bagID=btn.bagID end
        if not bagID and type(btn.tabID)=='number' then bagID=btn.tabID end
        if not slotID and type(btn.slotID)=='number' then slotID=btn.slotID end
        if not slotID and type(btn.containerSlotID)=='number' then slotID=btn.containerSlotID end

        -- 6. Fallback bagID if slotID is known
        if not bagID and slotID then
            local selTab=(bankPanel and bankPanel.GetSelectedTabID and bankPanel:GetSelectedTabID())
                or (bankPanel and bankPanel.selectedTabID)
                or bankBagID
            bagID=selTab
        end

        -- 7. Direct button item methods
        if not itemID and btn.GetItemID then
            local ok,id=pcall(btn.GetItemID,btn)
            if ok and type(id)=='number' and id>0 then itemID=id end
        end
        if not itemID and btn.GetItemLink then
            local ok,link=pcall(btn.GetItemLink,btn)
            if ok and type(link)=='string' then
                local id=tonumber(link:match('item:(%d+)'))
                if id then itemID=id end
            end
        end
        if not itemID and type(btn.itemID)=='number' and btn.itemID>0 then itemID=btn.itemID end
        if not itemID and type(btn.itemLink)=='string' then
            local id=tonumber(btn.itemLink:match('item:(%d+)'))
            if id then itemID=id end
        end

        -- 8. Query container APIs
        local itemQuality=nil
        if bagID and slotID then
            if get then
                local ok,info=pcall(get,bagID,slotID)
                if ok and type(info)=='table' then
                    if type(info.itemID)=='number' and info.itemID>0 then itemID=info.itemID end
                    if type(info.quality)=='number' then itemQuality=info.quality end
                elseif ok and type(info)=='string' then
                    local _,_,_,q=get(bagID,slotID)
                    itemQuality=q
                end
            end
            if not itemID and getItemID then
                local ok,id=pcall(getItemID,bagID,slotID)
                if ok and type(id)=='number' and id>0 then itemID=id end
            end
        end

        if not itemQuality and itemID and F.Catalog and F.Catalog.ItemQuality then
            itemQuality=F.Catalog.ItemQuality(itemID)
        end

        if itemQuality==0 then
            U.MaterialBadge(texture,nil)
        else
            U.MaterialBadge(texture,itemID and ('item:'..itemID) or nil)
        end
        if texture and texture.foreverNetBadge then
            U.bankBadges=U.bankBadges or {}
            U.bankBadges[texture.foreverNetBadge]=true
        end
    end

    -- Sweep Classic BankFrame generic slots (BankFrameItem1..28)
    local bankSlotsFrame=_G.BankSlotsFrame or (_G.BankFrame and _G.BankFrame.BankSlotsFrame)
    local totalBankSlots=NUM_BANKGENERIC_SLOTS or 28
    for i=1,totalBankSlots do
        local btn=(bankSlotsFrame and bankSlotsFrame['Item'..i]) or _G['BankFrameItem'..i]
        if btn then
            local slotID=(btn.GetID and btn:GetID()) or i
            processButton(btn,bankBagID,slotID)
        end
    end

    -- Sweep Modern BankPanel
    if bankPanel then
        -- EnumerateValidItems (safe 3-arg iterator call)
        if bankPanel.EnumerateValidItems then
            local ok,iter,state,init=pcall(bankPanel.EnumerateValidItems,bankPanel)
            if ok and type(iter)=='function' then
                pcall(function()
                    for a,b in iter,state,init do
                        local btn=(type(a)=='table' and a) or (type(b)=='table' and b)
                        if btn then processButton(btn) end
                    end
                end)
            elseif ok and type(iter)=='table' then
                for _,btn in pairs(iter) do
                    if type(btn)=='table' then processButton(btn) end
                end
            end
        end
        -- itemButtonPool
        local pool=bankPanel.itemButtonPool
        if pool then
            if pool.EnumerateActive then
                local ok,iter,state,init=pcall(pool.EnumerateActive,pool)
                if ok and type(iter)=='function' then
                    pcall(function()
                        for a,b in iter,state,init do
                            local btn=(type(a)=='table' and a) or (type(b)=='table' and b)
                            if btn then processButton(btn) end
                        end
                    end)
                end
            end
            if type(pool.activeObjects)=='table' then
                for btn in pairs(pool.activeObjects) do
                    if type(btn)=='table' then processButton(btn) end
                end
            end
        end
        -- Items / ItemSlots / itemSlots / Buttons tables
        for _,key in ipairs({'Items','ItemSlots','itemSlots','Buttons'}) do
            if type(bankPanel[key])=='table' then
                for _,btn in pairs(bankPanel[key]) do
                    if type(btn)=='table' then processButton(btn) end
                end
            end
        end
        -- Child frames of bankPanel
        if bankPanel.GetChildren then
            for _,child in ipairs({bankPanel:GetChildren()}) do
                if type(child)=='table' and (child.icon or child.Icon or child.GetItemLocation or child.GetBankTabID or child.GetBagAndSlot) then
                    processButton(child)
                end
            end
        end
    end

    -- Sweep extra bank frames (BankFrame, BankSlotsFrame)
    local extraFrames={_G.BankFrame,bankSlotsFrame}
    for _,frame in ipairs(extraFrames) do
        if frame then
            if type(frame.Items)=='table' then
                for _,btn in pairs(frame.Items) do
                    if type(btn)=='table' then processButton(btn) end
                end
            end
            if frame.EnumerateValidItems then
                local ok,iter,state,init=pcall(frame.EnumerateValidItems,frame)
                if ok and type(iter)=='function' then
                    pcall(function()
                        for a,b in iter,state,init do
                            local btn=(type(a)=='table' and a) or (type(b)=='table' and b)
                            if btn then processButton(btn) end
                        end
                    end)
                elseif ok and type(iter)=='table' then
                    for _,btn in pairs(iter) do
                        if type(btn)=='table' then processButton(btn) end
                    end
                end
            end
        end
    end
end
function U.BagBadges()
    if not U.BadgesEnabled() then return end
    local get=C_Container and C_Container.GetContainerItemInfo
    if not get and GetContainerItemInfo then get=GetContainerItemInfo end
    local getItemID=C_Container and C_Container.GetContainerItemID
    if U.HookBagContainers then pcall(U.HookBagContainers) end
    local visited=0

    for _,container in ipairs(U.BagContainers()) do
        local containerShown=not container.IsShown or container:IsShown()
        local buttons={}
        if type(container.Items)=='table' then
            local index=1
            while index<=U.MAX_BAG_SLOTS do
                local b=container.Items[index]
                if b==nil then break end
                buttons[#buttons+1]=b
                index=index+1
            end
            if #buttons==0 then
                for _,b in pairs(container.Items) do
                    if type(b)=='table' then buttons[#buttons+1]=b end
                end
            end
        else
            local maxSlots=container.size or 36
            local name=container.GetName and container:GetName()
            for i=1,maxSlots do
                local b=container['Item'..i] or (name and _G[name..'Item'..i])
                if b then buttons[#buttons+1]=b end
            end
        end

        for _,button in ipairs(buttons) do
            if visited>=U.MAX_BAG_SLOTS then break end
            visited=visited+1
            if type(button)=='table' then
                local okBag,bagID=pcall(button.GetBagID,button)
                local okSlot,slotID=pcall(button.GetID,button)
                if (not okBag or not bagID or type(bagID)~='number') and button.GetBagAndSlot then
                    local ok,b,s=pcall(button.GetBagAndSlot,button)
                    if ok and type(b)=='number' and type(s)=='number' then bagID,slotID=b,s; okBag,okSlot=true,true end
                end
                if (not okBag or not bagID or type(bagID)~='number') then
                    local parent=button.GetParent and button:GetParent()
                    if parent and parent.GetID then
                        local ok,b=pcall(parent.GetID,parent)
                        if ok and type(b)=='number' then bagID=b; okBag=true end
                    end
                end
                if (not okSlot or not slotID or type(slotID)~='number') and button.GetID then
                    local ok,s=pcall(button.GetID,button)
                    if ok and type(s)=='number' then slotID=s; okSlot=true end
                end

                local texture=button.icon or button.Icon or button.iconTexture or button.IconTexture
                if not texture and button.GetName and _G[button:GetName()..'IconTexture'] then
                    texture=_G[button:GetName()..'IconTexture']
                end

                if texture and okBag and okSlot and type(bagID)=='number' and type(slotID)=='number' then
                    if containerShown and (not button.IsShown or button:IsShown()) then
                        local itemID, itemQuality
                        if get then
                            local got,info=pcall(get,bagID,slotID)
                            if got and type(info)=='table' then
                                itemID=info.itemID
                                itemQuality=info.quality
                            elseif got and type(info)=='string' then
                                local _,_,_,q=get(bagID,slotID)
                                itemQuality=q
                            end
                        end
                        if not itemID and getItemID then
                            local ok,id=pcall(getItemID,bagID,slotID)
                            if ok and type(id)=='number' and id>0 then itemID=id end
                        end
                        if not itemQuality and itemID and F.Catalog and F.Catalog.ItemQuality then
                            itemQuality=F.Catalog.ItemQuality(itemID)
                        end
                        if itemQuality==0 then
                            U.MaterialBadge(texture,nil)
                        else
                            U.MaterialBadge(texture,itemID and ('item:'..itemID) or nil)
                        end
                    else
                        U.MaterialBadge(texture,nil)
                    end
                end
            end
        end
    end
    if U.BankBadges then pcall(U.BankBadges) end
end
function U.UpdateBadges()
    if not U.BadgesEnabled() then
        if U.HideBankBadges then U.HideBankBadges() end
        if U.allBadges then
            for _,badge in ipairs(U.allBadges) do
                badge:Hide()
            end
        end
        if U.badgeLayer and U.badgeLayer.pool then
            for _,badge in ipairs(U.badgeLayer.pool) do
                badge:Hide()
            end
        end
        if U.badgeLayer and U.badgeLayer.activeBadges then
            U.badgeLayer.activeBadges={}
        end
    else
        if U.BagBadges then pcall(U.BagBadges) end
        if U.BankBadges then pcall(U.BankBadges) end
    end
end
function U.ShowVisualTiles(entries,offset)
    U.visualTiles=U.visualTiles or {}
    for _,tile in ipairs(U.visualTiles) do
        tile:Hide()
        if tile.icon and tile.icon.foreverNetBadge then
            tile.icon.foreverNetBadge:Hide()
            if U.badgeLayer and U.badgeLayer.activeBadges then
                U.badgeLayer.activeBadges[tile.icon.foreverNetBadge]=nil
            end
        end
    end
    local y=offset or 0
    for start=1,#entries,2 do
        local height,pair=64,{}
        for i=start,math.min(start+1,#entries) do
            local entry=entries[i]
            local tile=U.visualTiles[i]
            if not tile then
                tile=CreateFrame('Button',nil,U.body,'BackdropTemplate'); T.Skin(tile,true); tile:SetWidth(212)
                tile.icon=tile:CreateTexture(nil,'ARTWORK'); tile.icon:SetSize(36,36); tile.icon:SetPoint('TOPLEFT',8,-8)
                tile.title=text(tile,12,true); tile.title:SetPoint('TOPLEFT',52,-8); tile.title:SetWidth(152)
                tile.detail=text(tile,12); tile.detail:SetWidth(152)
                tile.track=tile:CreateTexture(nil,'BACKGROUND'); tile.track:SetColorTexture(.22,.19,.14,1)
                tile.track:SetHeight(4); tile.track:SetPoint('BOTTOMLEFT',8,8); tile.track:SetWidth(196)
                tile.fill=tile:CreateTexture(nil,'ARTWORK'); tile.fill:SetHeight(4); tile.fill:SetPoint('BOTTOMLEFT',8,8)
                tile:SetScript('OnClick',function(self) if self.entry.run then T.HideTooltip(); self.entry.run() end end)
                U.visualTiles[i]=tile
            end
            tile.entry=entry; tile:ClearAllPoints(); tile:SetPoint('TOPLEFT',(i-start)*222,-y)
            tile.icon:SetTexture(entry.icon or C.Icon(entry.item)); tile.title:SetHeight(0); tile.title:SetText(C.Safe(entry.title))
            U.MaterialBadge(tile.icon,entry.item)
            tile.detail:ClearAllPoints(); tile.detail:SetPoint('TOPLEFT',52,-(12+tile.title:GetStringHeight()))
            tile.detail:SetHeight(0); tile.detail:SetText(C.Safe(entry.text or ''))
            height=math.max(height,tile.title:GetStringHeight()+tile.detail:GetStringHeight()+32)
            local tone=entry.tone or 'muted'; local color=T.colors[tone] or T.colors.muted
            if T.IsNeon() then
                tile:SetBackdropColor(0.040, 0.065, 0.105, 0.98)
                tile:SetBackdropBorderColor(0.094, 0.145, 0.210, 0.85)
                tile.track:SetColorTexture(0.060, 0.095, 0.150, 1.0)
            else
                tile:SetBackdropBorderColor(.22,.20,.17,1)
                tile.track:SetColorTexture(.22,.19,.14,1)
            end
            T.Color(tile.detail,tone)
            local progress=entry.maximum and entry.maximum>0
            tile.track:SetShown(not not progress); tile.fill:SetShown(not not progress and (entry.current or 0)>0)
            if progress then
                tile.fill:SetWidth(math.max(1,196*math.min(1,(entry.current or 0)/entry.maximum)))
                if T.IsNeon() then
                    tile.fill:SetColorTexture(0.0, 0.80, 1.0, 1.0)
                else
                    tile.fill:SetColorTexture(color[1],color[2],color[3],1)
                end
            end
            tip(tile,entry.title,entry.hint,entry.item); tile:Show(); pair[#pair+1]=tile
        end
        for _,tile in ipairs(pair) do tile:SetHeight(height) end
        y=y+height+8
    end
    U.bodyText:Hide(); U.body:SetHeight(math.max(240,y+8)); return y
end
-- Each reagent retains its own name/count tooltip. No links to secure bag buttons.
function U.DrawIngredients(row,reagents,top)
    row.ingredients=row.ingredients or {}
    for _,widget in ipairs(row.ingredients) do widget:Hide() end
    local keys=F.Keys(reagents or {})
    local y,height=top,0
    for i,item in ipairs(keys) do
        if i>1 and (i-1)%7==0 then y=y+height+4; height=0 end
        local widget=row.ingredients[i]
        if not widget then
            widget=CreateFrame('Frame',nil,row); widget:SetSize(54,46); widget:EnableMouse(true)
            widget.icon=widget:CreateTexture(nil,'ARTWORK'); widget.icon:SetSize(26,26); widget.icon:SetPoint('TOPLEFT',14,0)
            widget.count=text(widget,12); widget.count:SetPoint('TOPLEFT',0,-28); widget.count:SetWidth(54); widget.count:SetJustifyH('CENTER')
            row.ingredients[i]=widget
        end
        widget:ClearAllPoints(); widget:SetPoint('TOPLEFT',10+((i-1)%7)*59,-y)
        widget.icon:SetTexture(C.Icon(item)); widget.count:SetText(tostring(reagents[item]))
        U.MaterialBadge(widget.icon,item)
        widget:SetHeight(28+widget.count:GetStringHeight()+4); height=math.max(height,widget:GetHeight())
        tip(widget,C.ItemName(item),'x'..reagents[item],item); widget:Show()
    end
    return #keys>0 and y+height+4 or top
end
function U.ToggleVisual(key)
    U.visualExpanded=U.visualExpanded or {}
    U.visualExpanded[key]=not U.visualExpanded[key]
    local position=U.details:GetVerticalScroll() or 0
    U.RenderSelection(); U.LayoutDetails()
    U.details:SetVerticalScroll(math.min(position,U.details:GetVerticalScrollRange()))
end
function U.NextCraft(plan)
    for i,step in ipairs(plan.steps) do
        if step.owner==F.me then
            local ready=true
            for item,quantity in pairs(step.reagents) do if F.Adapter.ItemCount(item)<quantity then ready=false; break end end
            if ready then return i end
        end
    end
end
function U.RenderRecipe(entry)
    local r,qty=entry.recipe,U.Quantity()
    if not F.Integer(qty,1,10000) then U.Show(F.L('QUANTITY_ERROR'),entry.title); return end
    local owned=F.Adapter.StockCount(entry.item)
    local batches=math.ceil(math.max(0,qty-owned)/r.quantity)
    U.Show('',entry.title,who(entry.owner))
    U.detailItem=entry.item; U.hero:SetTexture(C.Icon(entry.item)); U.MaterialBadge(U.hero,entry.item)
    U.crafter:SetText(F.L('CHANGE_CRAFTER')); U.crafter:SetShown(#entry.providers>1)
    U.crafter:SetScript('OnEnter',function(self)
        local names,seen={},{}
        for _,p in ipairs(U.selectedEntry.providers) do if not seen[p.owner] then seen[p.owner]=true; names[#names+1]=who(p.owner) end end
        T.ShowTooltip(self,F.L('AVAILABLE_CRAFTERS'),table.concat(names,' / '))
    end)
    U.crafter:SetScript('OnLeave',T.HideTooltip)
    U.enqueue:SetText(F.L('QUEUE_ADD')); U.enqueue:Show()
    local y=U.ShowVisualStats({
        {item=entry.item,title=F.L('VIS_TARGET'),value=tostring(qty),icon=C.Icon(entry.item)},
        {title=F.L('VIS_OWNED'),value=tostring(owned),icon='Interface\\Icons\\INV_Misc_Bag_08',tone=owned>=qty and 'good' or 'muted'},
        {title=F.L('VIS_CRAFTS'),value=tostring(batches),icon='Interface\\Icons\\Trade_Engineering',hint=string.format(F.L('RECIPE_OVERVIEW'),qty,owned,r.quantity,batches)},
    })
    local tiles={}
    for _,item in ipairs(F.Keys(r.reagents)) do
        local needed=r.reagents[item]*batches; local have=F.Adapter.StockCount(item)
        local shortage=math.max(0,needed-have)
        tiles[#tiles+1]={item=item,title=C.ItemName(item),current=math.min(have,needed),maximum=needed,
            text=have..' / '..needed..(shortage>0 and '  '..U.ShortPrice(item,shortage) or ''),tone=have>=needed and 'good' or 'missing',
            hint=string.format(F.L('MATERIAL_CARD'),F.Adapter.ItemCount(item),F.Bank.Count(item),needed)..
                (shortage>0 and '\n'..U.PriceText(item,shortage) or ''),
            run=function() U.FindCrafters(item,math.max(1,shortage)) end}
    end
    y=U.ShowVisualTiles(tiles,y)
    local notes={}
    if #tiles==0 then notes[#notes+1]={title=F.L('NO_REAGENTS')} end
    for _,station in ipairs(F.Keys(r.stations)) do notes[#notes+1]={title=F.L('CAMP')..station,tone='missing'} end
    if r.blueprint then notes[#notes+1]={title=F.L('FILTER_BLUEPRINT'),tone='blueprint'} end
    if #notes>0 then U.ShowSourceRows(notes,y) end
end
function U.RenderHome()
    local plan=F.Queue.Build()
    U.Show('',F.me,(UnitClass and UnitClass('player') or '?')..'  '..(UnitLevel and UnitLevel('player') or 0))
    if SetPortraitTexture then SetPortraitTexture(U.hero,'player') end
    local tiles={}
    local peers=math.max(0,#F.Keys(F.Profiles())-1)
    local channel=F.Net.Channel()
    local ready=0
    for _,state in ipairs(plan.goalStates) do if state.ready then ready=ready+1 end end
    tiles[#tiles+1]={title=F.L('PAGE_queue'),icon='Interface\\Icons\\INV_Misc_Note_05',
        text=string.format(F.L('VIS_QUEUE_MINI'),#plan.goals,#F.Keys(plan.missing)),hint=string.format(F.L('QUEUE_SUMMARY'),#plan.goals,ready,#F.Keys(plan.missing)),
        run=function() U.Navigate('queue') end}
    tiles[#tiles+1]={title=F.L('PAGE_network'),icon='Interface\\Icons\\INV_Misc_GroupLooking',
        text=tostring(peers),tone=channel and F.db.settings.sharing and 'good' or 'muted',
        hint=F.L('NETWORK_CHANNEL')..(channel and F.L('CHANNEL_'..channel) or F.L('NETWORK_NO_CHANNEL'))..(F.Net.lastError and '\n'..F.Net.lastError or ''),
        run=function() U.Navigate('network') end}
    local y=U.ShowVisualTiles(tiles)
    local notes=U.BankNotes()
    if next(F.localProfile.professions)==nil then
        table.insert(notes,1,{title=F.L('START_SCAN'),actions={{text=F.L('Сканировать'),run=function() F.Command('scan') end}}})
    end
    U.ShowSourceRows(notes,y)
end

-- "Bank materials" card. Collapsed it shows the snapshot age and how many
-- crafting materials are stored; expanding it lists those materials with their
-- amounts, so the counts come from the saved snapshot and stay private.
U.MAX_BANK_MATERIAL_ROWS=12
function U.BankNotes()
    local notes={}
    local materials=F.Bank.Materials()
    local card={title=F.L('BANK_SECTION'),icon='Interface\\Icons\\INV_Misc_Bag_08',
        text=F.Bank.Status()..'\n'..string.format(F.L('BANK_MATERIAL_LIST'),#materials),
        hint=F.L('BANK_REMINDER'),visual=true,key='bank/materials'}
    notes[#notes+1]=card
    if not (U.visualExpanded and U.visualExpanded['bank/materials']) then return notes end
    if #materials==0 then
        notes[#notes+1]={title=F.L('BANK_MATERIAL_EMPTY'),tone='muted'}
        return notes
    end
    for index,material in ipairs(materials) do
        if index>U.MAX_BANK_MATERIAL_ROWS then
            notes[#notes+1]={title='+'..(#materials-U.MAX_BANK_MATERIAL_ROWS),tone='muted'}
            break
        end
        notes[#notes+1]={title=C.ItemName(material.item),text='x'..material.count,item=material.item,tone='text'}
    end
    return notes
end

function U.RenderPlan()
    local p=U.planData
    U.recipeOptionsRendered={}
    U.Show('',C.ItemName(p.target)..' x'..p.quantity,F.L(p.complete and (#p.steps>0 and 'VIS_READY' or 'VIS_OWNED') or 'VIS_GET'),p.complete and 'good' or 'missing')
    U.detailItem=p.target; U.hero:SetTexture(C.Icon(p.target)); U.MaterialBadge(U.hero,p.target)
    local y=U.ShowVisualStats({
        {title=F.L('VIS_GET'),value=tostring(#F.Keys(p.missing)),icon='Interface\\Icons\\INV_Misc_Bag_08',tone=next(p.missing) and 'missing' or 'good'},
        {title=F.L('VIS_CRAFTS'),value=tostring(#p.steps),icon='Interface\\Icons\\Trade_Engineering'},
        {title=F.L('VIS_COST'),value=U.ShortBudget(p.missing),icon='Interface\\Icons\\INV_Misc_Coin_01',hint=U.BudgetText(p.missing)},
    })
    local rows={}
    if next(p.missing) then rows[#rows+1]={section=true,title=F.L('VIS_GET')} end
    for _,item in ipairs(F.Keys(p.missing)) do
        local id,m=item,p.materials and p.materials[item]
        local reason=p.missingReasons[item]
        local hint=F.L('MISSING_REASON_'..reason)..('\n'..U.PriceText(item,p.missing[item]))
        local actions={}
        local source
        if m then
            for _,candidate in ipairs(m.alternatives) do if candidate.ready then source=candidate; break end end
        end
        if source and id~=p.target then
            local owner,recipeID=source.owner,source.recipeID
            local batches=math.ceil(math.max(0,m.quantity-m.stock)/source.recipe.quantity)
            local inputs={}
            for reagent,count in pairs(source.recipe.reagents) do inputs[#inputs+1]=C.ItemName(reagent)..' x'..(count*batches) end
            hint=hint..'\n'..F.L('CHAIN_OR_MAKE')..'\n'..table.concat(inputs,', ')
            actions[#actions+1]={text=string.format(F.L('CHAIN_MAKE_BUTTON'),math.max(0,m.quantity-m.stock)),run=function() U.ChooseSource(id,{owner=owner,recipeID=recipeID}) end}
        end
        if m and id~=p.target and #m.alternatives>0 then
            actions[#actions+1]={text=F.L('VIS_SOURCES'),run=function() U.OpenSources(id) end}
        end
        rows[#rows+1]={key='get/'..id,visual=true,item=id,title=C.ItemName(id)..' x'..p.missing[id],tone='missing',
            text=U.ShortPrice(id,p.missing[id])..
                ((reason=='camp' or reason=='source' or reason=='cycle' or reason=='limit') and '\n'..F.L('MISSING_REASON_'..reason) or ''),hint=hint,actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    if #p.steps>0 then rows[#rows+1]={section=true,title=F.L('VIS_MAKE')} end
    local nextCraft=U.NextCraft(p)
    for i,step in ipairs(p.steps) do
        local id,m=step.item,p.materials and p.materials[step.item]
        local actions={}
        if m and id~=p.target then
            actions[#actions+1]={text=string.format(F.L('CHAIN_GET_BUTTON'),math.max(0,m.quantity-m.stock)),run=function() U.ChooseSource(id,'external') end}
            if #m.alternatives>1 then actions[#actions+1]={text=F.L('VIS_SOURCES'),run=function() U.OpenSources(id) end} end
        end
        local hint=F.L('MANUAL_CRAFT')
        for _,station in ipairs(F.Keys(step.stations)) do hint=hint..'\n'..F.L('CAMP')..station..': '..who(step.stations[station]) end
        rows[#rows+1]={key='make/'..i,visual=true,item=id,title=i..'. '..C.ItemName(id,step.name)..' x'..step.quantity,
            text=who(step.owner)..(i==nextCraft and '  /  '..F.L('VIS_READY') or ''),tone=i==nextCraft and 'good' or nil,reagents=step.reagents,hint=hint,actions=actions}
        if m then U.AddRecipeOptions(rows,id,m) end
    end
    if #p.steps==0 and p.complete then rows[#rows+1]={title=F.L('ALREADY_OWNED'),tone='good'} end
    if #p.warnings>0 then rows[#rows+1]={title=F.L('PLAN_NEEDS'),text=F.L('PLAN_CYCLE_WARNING'),tone='missing'} end
    rows[#rows+1]={section=true,title=F.L('VIS_DETAILS'),actions={{text=U.planDetails and '-' or '+',run=function() U.planDetails=not U.planDetails; U.RenderSelection(); U.LayoutDetails() end}}}
    if U.planDetails then
        for _,item in ipairs(F.Keys(p.supplied)) do
            local bags=p.bagSupplied and p.bagSupplied[item] or p.supplied[item]
            rows[#rows+1]={item=item,title=C.ItemName(item)..' x'..p.supplied[item],text=string.format(F.L('STOCK_CARD'),bags,p.supplied[item]-bags),tone='good'}
        end
        if F.db.settings.useBank~=false then rows[#rows+1]={title=F.L('BANK_SECTION'),text=F.Bank.Status()..'\n'..F.L('BANK_REMINDER')} end
        rows[#rows+1]={text=F.L('MANUAL_CRAFT')}
    end
    U.ShowSourceRows(rows,y)
end
