-- Crafting-material badge and the bank material list on the home page.
local F,U=ForeverNet,ForeverNet.UI
local C=F.Catalog
U.Status() -- build the window so the widgets the badge attaches to exist
assert(U.body and U.body.CreateTexture)

-- A known recipe makes its reagents crafting materials; anything else is not.
F.localProfile.recipes['spell:testbadge']={name='Test badge',output='item:9500',quantity=1,
    profession='skill:202',blueprint=false,reagents={['item:9501']=2,['item:9502']=1},stations={}}
C.InvalidateMaterials()
assert(C.IsCraftMaterial('item:9501'))
assert(C.IsCraftMaterial('item:9502'))
assert(not C.IsCraftMaterial('item:9503'))
-- Only real item keys qualify; pseudo keys and malformed input never match.
assert(not C.IsCraftMaterial('spell:testbadge'))
assert(not C.IsCraftMaterial('custom:gear'))
assert(not C.IsCraftMaterial(nil))
assert(not C.IsCraftMaterial(9501))

-- The cache must not outlive the data, even when a caller forgets to clear it.
F.localProfile.recipes['spell:testbadge2']={name='Test badge 2',output='item:9504',quantity=1,
    profession='skill:202',blueprint=false,reagents={['item:9503']=1},stations={}}
F.Touch()
assert(C.IsCraftMaterial('item:9503'))
-- Dropping the recipe again has to be reflected as well.
F.localProfile.recipes['spell:testbadge2']=nil
C.InvalidateMaterials()
assert(not C.IsCraftMaterial('item:9503'))

-- The rule is deliberately narrow: the badge means "a craft consumes this". The
-- client's item class alone is not enough, because it also covers items nobody
-- crafts with.
local itemClasses={[2589]=7,[4359]=7,[6948]=15,[118]=0,[19019]=2,[2447]=5}
C_Item=C_Item or {}
local savedInstant=C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant=function(id) return id,'Trade Goods','', '', 134, itemClasses[id], itemClasses[id] end
C.InvalidateMaterials()

-- Reagent families are recognised as a family.
assert(C.IsReagentFamily('item:2589'), 'trade goods are not a reagent family')
assert(C.IsReagentFamily('item:2447'), 'reagents are not a reagent family')
assert(not C.IsReagentFamily('item:6948'), 'a miscellaneous item counts as a reagent family')
assert(not C.IsReagentFamily('item:19019'), 'a weapon counts as a reagent family')

-- Vendor junk (quality 0 / poor) must NEVER be craft materials or show badges.
assert(not C.IsCraftMaterial('item:7073'), 'Broken Fang (grey junk) was marked as material')
assert(not C.IsCraftMaterial('item:7074'), 'Chipped Claw (grey junk) was marked as material')
assert(not C.IsCraftMaterial('item:2590'), 'Forest Spider Webbing was marked as material')
assert(not C.IsCraftMaterial('item:4361'), 'Bent Copper Tube was marked as material')

-- Item with quality 0 reported via API is rejected even if in a recipe
local savedQuality=C_Item.GetItemQualityByID
C_Item.GetItemQualityByID=function(id) if id==99999 then return 0 end return nil end
F.localProfile.recipes['spell:junktest']={name='JunkTest',output='item:9500',quantity=1,
    profession='skill:202',blueprint=false,reagents={['item:99999']=1},stations={}}
C.InvalidateMaterials()
assert(not C.IsCraftMaterial('item:99999'), 'quality 0 item in recipe must not be marked as material')
F.localProfile.recipes['spell:junktest']=nil
C_Item.GetItemQualityByID=savedQuality
C.InvalidateMaterials()

-- Known materials are marked even with nothing scanned.
assert(C.IsCraftMaterial('item:2589'), 'a bundled material was not marked')
assert(C.IsCraftMaterial('item:4359'), 'a bundled material was not marked')
assert(C.IsCraftMaterial('item:1210'), 'Shadowgem was not marked')
-- Reagent and trade good families are marked for all professions, even with no recipes scanned.
assert(C.IsCraftMaterial('item:2447'), 'a reagent-family item was not marked')
assert(not C.IsCraftMaterial('item:6948'), 'a miscellaneous item was marked')
assert(not C.IsCraftMaterial('item:19019'), 'a weapon was marked')

-- A recipe that consumes a non-trade-good item marks it as a material.
F.localProfile.recipes['spell:uses']={name='Uses',output='item:9500',quantity=1,
    profession='skill:202',blueprint=false,reagents={['item:118']=1},stations={}}
C.InvalidateMaterials()
assert(C.IsCraftMaterial('item:118'), 'a consumed non-trade item was not marked')
F.localProfile.recipes['spell:uses']=nil
C.InvalidateMaterials()
assert(not C.IsCraftMaterial('item:118'), 'a consumed non-trade item stayed marked after removal')

-- A client without the class API falls back to the rest of the rule quietly.
C_Item.GetItemInfoInstant=nil
C.InvalidateMaterials()
assert(not C.ItemUsedForProfessions('item:2589'))
assert(not C.ItemUsedForProfessions(nil))
assert(not C.ItemUsedForProfessions('custom:gear'))
assert(C.IsCraftMaterial('item:2589'), 'the bundled list stopped working without the API')
C_Item.GetItemInfoInstant=savedInstant
C.InvalidateMaterials()

-- A recipe output is craftable stock only when it is also a reagent-family item, so
-- ordinary crafted gear is never marked. 4455 is a reagent-family item, 4456 is a
-- weapon; both are produced by a recipe below.
itemClasses[4455]=7; itemClasses[4456]=2
F.localProfile.recipes['spell:output']={name='Out',output='item:4455',quantity=1,
    profession='skill:202',blueprint=false,reagents={},stations={}}
F.localProfile.recipes['spell:gear']={name='Gear',output='item:4456',quantity=1,
    profession='skill:202',blueprint=false,reagents={},stations={}}
F.Touch()
C.InvalidateMaterials()
assert(C.KnownRecipeOutput('item:4455'), 'the fixture recipe output is not visible')
assert(C.KnownRecipeOutput('item:4456'), 'the fixture recipe output is not visible')
assert(not C.IsCraftMaterial('item:4456'), 'crafted equipment was marked as a material')
F.localProfile.recipes['spell:output']=nil
F.localProfile.recipes['spell:gear']=nil
F.Touch()
C.InvalidateMaterials()

-- The badge lives on one overlay frame we own for standalone frames (such as
-- Blizzard container buttons), so a Blizzard item button can never cover it.
local holder=CreateFrame('Frame',nil,UIParent)
local icon=holder:CreateTexture(nil,'ARTWORK'); icon:SetSize(32,32); icon:SetPoint('TOPLEFT',0,0)
U.MaterialBadge(icon,'item:9501')
assert(icon.foreverNetBadge and icon.foreverNetBadge.shown)
assert(icon.foreverNetBadge.texture==U.BADGE_ICON)
assert(icon.foreverNetBadge.width>0 and icon.foreverNetBadge.width<=13)
assert(icon.foreverNetBadge.parent==U.BadgeLayer(), 'badge is not on the overlay layer')
assert(U.BadgeLayer().strata=='TOOLTIP', 'overlay layer is not above the UI')

-- For icons inside a scrollable container (e.g. recipe list rows in U.list or network cards in U.body),
-- the badge must be created directly on the item's parent frame so that Blizzard's ScrollFrame
-- clips it natively and prevents it from leaking outside the window.
local scrollHolder=CreateFrame('Frame',nil,U.body)
local scrollIcon=scrollHolder:CreateTexture(nil,'ARTWORK'); scrollIcon:SetSize(32,32); scrollIcon:SetPoint('TOPLEFT',0,0)
U.MaterialBadge(scrollIcon,'item:9501')
assert(scrollIcon.foreverNetBadge and scrollIcon.foreverNetBadge.shown)
assert(scrollIcon.foreverNetBadge.parent==scrollHolder, 'scrollable badge must be parented to its container for clipping')
assert(scrollIcon.foreverNetBadge.border and scrollIcon.foreverNetBadge.border.parent==scrollHolder, 'scrollable border must be parented to container')
-- The badge sits inside the icon's top-right corner, anchored to the icon region
-- itself so no absolute screen maths is involved.
local point,relativeTo,relativePoint,offsetX,offsetY=icon.foreverNetBadge:GetPoint(1)
assert(point=='TOPRIGHT', 'badge anchor point is '..tostring(point))
assert(relativeTo==icon and relativePoint=='TOPRIGHT',
    'badge is not anchored to the icon region')
assert(offsetX==1 and offsetY==-1, 'badge offsets do not place it inside the corner')
assert(icon.foreverNetBadge:GetWidth()<icon:GetWidth(),
    'badge is not smaller than the icon')
assert(icon.foreverNetBadge.border and icon.foreverNetBadge.border.shown, 'badge border is missing or hidden')
local bpoint1,brelTo1,brelPoint1,boffsetX1,boffsetY1=icon.foreverNetBadge.border:GetPoint(1)
local bpoint2,brelTo2,brelPoint2,boffsetX2,boffsetY2=icon.foreverNetBadge.border:GetPoint(2)
assert((bpoint1=='TOPLEFT' and boffsetX1==-2 and boffsetY1==2) or (bpoint2=='TOPLEFT' and boffsetX2==-2 and boffsetY2==2),
    'badge border TOPLEFT offset is not -2, 2')
assert((bpoint1=='BOTTOMRIGHT' and boffsetX1==2 and boffsetY1==-2) or (bpoint2=='BOTTOMRIGHT' and boffsetX2==2 and boffsetY2==-2),
    'badge border BOTTOMRIGHT offset is not 2, -2')
local cr,cg,cb,ca=icon.foreverNetBadge.border:GetColorTexture()
assert(cr==0.92 and cg==0.78 and cb==0.20 and ca==0.92, 'badge border color is not soft yellow')
assert(icon.foreverNetBadge.border.mask and icon.foreverNetBadge.border.mask.texture=='Interface\\CharacterFrame\\TempPortraitAlphaMask',
    'badge border missing rounded corner mask')
assert(icon.foreverNetBadge.mask and icon.foreverNetBadge.mask.texture=='Interface\\CharacterFrame\\TempPortraitAlphaMask',
    'badge icon missing rounded corner mask')
U.MaterialBadge(icon,'item:9503')
assert(not icon.foreverNetBadge.shown)
assert(not icon.foreverNetBadge.border.shown, 'badge border remained shown when badge hidden')
U.MaterialBadge(icon,nil)
assert(not icon.foreverNetBadge.shown)
assert(not icon.foreverNetBadge.border.shown, 'badge border remained shown when item is nil')
-- Icons whose parent cannot host a texture simply go without a badge, and an
-- unlaid-out icon must not raise or leave a visible badge behind.
U.MaterialBadge(setmetatable({},{__index=function() return nil end}),'item:9501')
local bare=holder:CreateTexture(nil,'ARTWORK')
U.MaterialBadge(bare,'item:9501')
assert(bare.foreverNetBadge and not bare.foreverNetBadge.shown)
-- An icon with no usable position must not draw a badge in the wrong place. A frame
-- that was never given a size reports no geometry, which is exactly that case.
local unsized=CreateFrame('Frame',nil,U.body)
local unsizedIcon=unsized:CreateTexture(nil,'ARTWORK')
U.MaterialBadge(unsizedIcon,'item:9501')
assert(unsizedIcon.foreverNetBadge==nil or not unsizedIcon.foreverNetBadge.shown,
    'a badge was drawn for an icon with no position')

-- The bank list keeps crafting materials only, largest amount first.
F.db.banks=F.db.banks or {}
F.db.banks[F.me]={seen=F.Now(),items={['item:9501']=4,['item:9502']=40,['item:9503']=7}}
assert(F.Bank.Count('item:9501')==4)
local materials=F.Bank.Materials()
assert(#materials==2)
assert(materials[1].item=='item:9502' and materials[1].count==40)
assert(materials[2].item=='item:9501' and materials[2].count==4)
assert(F.Bank.MaterialCount()==2)

-- Collapsed the card reports the snapshot age and the material count; expanded
-- it adds one row per material, capped so a full bank cannot flood the page.
U.visualExpanded=U.visualExpanded or {}
U.visualExpanded['bank/materials']=nil
local collapsed=U.BankNotes()
assert(#collapsed==1)
assert(collapsed[1].title==F.L('BANK_SECTION') and collapsed[1].visual and collapsed[1].hint)
assert(collapsed[1].text:find((F.L('BANK_MATERIAL_LIST'):gsub('%%d','2')),1,true))
U.visualExpanded['bank/materials']=true
local expanded=U.BankNotes()
assert(#expanded==3)
assert(expanded[2].item=='item:9502' and expanded[2].text=='x40')
assert(expanded[3].item=='item:9501' and expanded[3].text=='x4')
for i=2,#expanded do assert(expanded[i].item) end

-- The new strings must reach F.Locales for every language. Building them into a
-- private table instead used to make F.L return the raw key name on screen.
local previousLocale=F.db.settings.locale
for _,locale in ipairs(F.LocaleOrder or F.Keys(F.Locales)) do
    if F.Locales[locale] then
        for _,key in ipairs({'BANK_MATERIAL_LIST','BANK_MATERIAL_EMPTY','BANK_EXPAND','BANK_COLLAPSE'}) do
            local value=F.Locales[locale][key]
            assert(type(value)=='string' and value~='' and value~=key,
                'missing translation '..key..' for '..locale)
        end
        assert(F.Locales[locale].BANK_MATERIAL_LIST:find('%d',1,true),
            'bank material count lost its placeholder for '..locale)
    end
end
F.db.settings.locale='ruRU'
assert(F.L('BANK_MATERIAL_LIST'):find('банке',1,true))
assert(F.L('BANK_EXPAND')~='BANK_EXPAND' and F.L('BANK_COLLAPSE')~='BANK_COLLAPSE')
F.db.settings.locale='enUS'
assert(F.L('BANK_MATERIAL_LIST'):find('bank',1,true))
F.db.settings.locale=previousLocale

-- An expanded card with nothing stored says so instead of listing nothing.
F.db.banks[F.me]={seen=F.Now(),items={['item:9503']=1}}
local empty=U.BankNotes()
assert(#empty==2 and empty[2].title==F.L('BANK_MATERIAL_EMPTY'))
U.visualExpanded['bank/materials']=nil

-- The cap keeps the page readable when many materials are stored.
local many={}
for index=1,40 do many['item:'..(9600+index)]=index end
F.db.banks[F.me]={seen=F.Now(),items=many}
F.localProfile.recipes['spell:bulk']={name='Bulk',output='item:9700',quantity=1,
    profession='skill:202',blueprint=false,reagents=many,stations={}}
C.InvalidateMaterials()
U.visualExpanded['bank/materials']=true
local capped=U.BankNotes()
assert(#capped==1+U.MAX_BANK_MATERIAL_ROWS+1)
assert(capped[#capped].title=='+'..(40-U.MAX_BANK_MATERIAL_ROWS))
U.visualExpanded['bank/materials']=nil
F.localProfile.recipes['spell:bulk']=nil
F.localProfile.recipes['spell:testbadge']=nil
C.InvalidateMaterials()
F.db.banks[F.me]=nil

-- The bag sweep reads the containers' own Items tables through the read-only
-- container API. ContainerFrame1..N are empty placeholders in this client, so the
-- sweep must also look at the combined bag frame.
assert(type(U.BagBadges)=='function')
assert(type(U.BagContainers)=='function')
C_Container=C_Container or {}

-- The bank block above removed the recipe that makes item:9501 a crafting material.
F.localProfile.recipes['spell:testbadge']={name='Test badge',output='item:9500',quantity=1,
    profession='skill:202',blueprint=false,reagents={['item:9501']=2,['item:9502']=1},stations={}}
C.InvalidateMaterials()
assert(C.IsCraftMaterial('item:9501'))

-- A combined-bag style container: the Items table holds the real buttons.
local combined=CreateFrame('Frame','ContainerFrameCombinedBags',UIParent)
local bagButton=CreateFrame('Button',nil,combined)
bagButton.icon=bagButton:CreateTexture(nil,'ARTWORK'); bagButton.icon:SetSize(36,36)
bagButton.icon:SetPoint('TOPLEFT',0,0)
bagButton.GetBagID=function() return 0 end
bagButton.GetID=function() return 1 end
combined.Items={bagButton}
C_Container.GetContainerItemInfo=function() return {itemID=9501,stackCount=3} end
U.BagBadges()
assert(bagButton.icon.foreverNetBadge and bagButton.icon.foreverNetBadge.shown,
    'badge missing on a combined-bag button')
-- When a container is closed, its badges must be hidden even if slots contain materials.
combined:Hide()
U.BagBadges()
assert(not bagButton.icon.foreverNetBadge.shown, 'closed container showed badges')
combined:Show()
U.BagBadges()
assert(bagButton.icon.foreverNetBadge.shown, 'reopened container did not restore badges')
-- A slot holding something that is not a crafting material loses the badge again.
-- 88888 is deliberately absent from every signal: not a known material, no recipe.
C_Container.GetContainerItemInfo=function() return {itemID=88888,stackCount=1} end
U.BagBadges()
assert(not bagButton.icon.foreverNetBadge.shown)
-- A slot holding a grey junk item (quality 0) never shows a badge even if itemID is a known material.
C_Container.GetContainerItemInfo=function() return {itemID=9501,quality=0,stackCount=1} end
U.BagBadges()
assert(not bagButton.icon.foreverNetBadge.shown, 'junk item with quality 0 showed badge')
C_Container.GetContainerItemInfo=function() return nil end
U.BagBadges()
assert(not bagButton.icon.foreverNetBadge.shown)

-- A gap in the Items table must stop that container like the client's own iterator,
-- and a nil entry must never abort the sweep for the other containers.
local numbered=CreateFrame('Frame','ContainerFrame1',UIParent)
local good=CreateFrame('Button',nil,numbered)
good.icon=good:CreateTexture(nil,'ARTWORK'); good.icon:SetSize(36,36); good.icon:SetPoint('TOPLEFT',0,0)
good.GetBagID=function() return 1 end
good.GetID=function() return 2 end
numbered.Items={good}
C_Container.GetContainerItemInfo=function() return {itemID=9501,stackCount=3} end
U.BagBadges()
assert(good.icon.foreverNetBadge and good.icon.foreverNetBadge.shown,
    'the numbered container was not swept')

-- A container whose first table entry is nil is skipped without raising.
local weird=CreateFrame('Frame','ContainerFrame2',UIParent)
weird.Items={}
U.BagBadges()
assert(good.icon.foreverNetBadge.shown, 'an odd container broke the sweep')

-- A button without an icon field is skipped, not fatal.
local noIcon=CreateFrame('Button',nil,numbered)
noIcon.GetBagID=function() return 1 end
noIcon.GetID=function() return 3 end
numbered.Items={noIcon,good}
U.BagBadges()
assert(good.icon.foreverNetBadge.shown, 'a button without an icon broke the sweep')

-- Classic container frame: has no .Items table, button has no GetBagID,
-- button is named ContainerFrame3Item1 and bagID comes from parent container:GetID().
local classicBag=CreateFrame('Frame','ContainerFrame3',UIParent)
classicBag:SetID(2)
classicBag.size=16
local classicBtn=CreateFrame('Button','ContainerFrame3Item1',classicBag)
classicBtn:SetID(1)
classicBtn.GetBagID=nil -- explicitly absent in Classic
classicBtn.icon=classicBtn:CreateTexture(nil,'ARTWORK'); classicBtn.icon:SetSize(36,36); classicBtn.icon:SetPoint('TOPLEFT',0,0)
classicBag.Item1=classicBtn
C_Container.GetContainerItemInfo=function(b, s)
    if b==2 and s==1 then return {itemID=9501,stackCount=2} end
    return nil
end
classicBag:Show()
U.BagBadges()
assert(classicBtn.icon.foreverNetBadge and classicBtn.icon.foreverNetBadge.shown,
    'classic container button without GetBagID missing badge')
classicBag:Hide()
U.BagBadges()
assert(not classicBtn.icon.foreverNetBadge.shown,
    'hidden classic container button showed badge')
classicBag=nil; ContainerFrame3=nil; ContainerFrame3Item1=nil

-- A client without the container API, or without any container at all, stays quiet.
ContainerFrameCombinedBags=nil; ContainerFrame1=nil; ContainerFrame2=nil
NUM_CONTAINER_FRAMES=nil
U.BagBadges()
local savedApi=C_Container.GetContainerItemInfo
C_Container.GetContainerItemInfo=nil
U.BagBadges()
C_Container.GetContainerItemInfo=savedApi
assert(U.MaterialBadge(holder.icon,nil)==nil)

-- The sweep is bounded, so a huge container cannot lock up the client.
local huge=CreateFrame('Frame','ContainerFrame1',UIParent)
huge.Items={}
for index=1,U.MAX_BAG_SLOTS+50 do
    local button=CreateFrame('Button',nil,huge)
    button.icon=button:CreateTexture(nil,'ARTWORK'); button.icon:SetSize(36,36)
    button.icon:SetPoint('TOPLEFT',0,0)
    button.GetBagID=function() return 1 end
    button.GetID=function() return 1 end
    huge.Items[index]=button
end
C_Container.GetContainerItemInfo=function() return {itemID=9501,stackCount=1} end
U.BagBadges()
assert(huge.Items[1].icon.foreverNetBadge.shown)
ContainerFrame1=nil

-- The expand control carries a word, not a bare symbol, and flips its label.
local collapsedText=F.L('BANK_EXPAND')
local expandedText=F.L('BANK_COLLAPSE')
assert(collapsedText~='BANK_EXPAND' and expandedText~='BANK_COLLAPSE')
assert(collapsedText~=expandedText)
U.visualExpanded=U.visualExpanded or {}
U.visualExpanded['bank/materials']=nil
U.RenderHome()
local checked=0
for _,row in ipairs(U.sourceRows or {}) do
    if row.more and row.more.expandKey then
        assert(row.more:GetText()==F.L(row.more.expandKey))
        assert(row.more:GetText()~='+' and row.more:GetText()~='-')
        checked=checked+1
    end
end
assert(checked>0, 'no expandable row rendered on the home page')
U.visualExpanded['bank/materials']=true
U.RenderHome()
for _,row in ipairs(U.sourceRows or {}) do
    if row.more and row.more.expandKey=='BANK_COLLAPSE' then
        assert(row.more:GetText()==F.L('BANK_COLLAPSE'))
    end
end
U.visualExpanded['bank/materials']=nil

-- U.BagDiagnose must execute without crashing on drawTrace.
U.BagDiagnose()

-- Badges beyond 200 get independent textures, never colliding or stealing #200.
local badgeIcons={}
for index=1,210 do
    local f=CreateFrame('Frame',nil,U.body)
    f:SetSize(32,32)
    local ic=f:CreateTexture(nil,'ARTWORK'); ic:SetSize(32,32)
    badgeIcons[index]=ic
    U.MaterialBadge(ic,'item:9501')
end
assert(badgeIcons[200].foreverNetBadge~=badgeIcons[201].foreverNetBadge,
    'badge 201 shared texture with badge 200')
assert(badgeIcons[201].foreverNetBadge~=badgeIcons[202].foreverNetBadge,
    'badge 202 shared texture with badge 201')
assert(badgeIcons[200].foreverNetBadge.shown, 'badge 200 was lost')
assert(badgeIcons[201].foreverNetBadge.shown, 'badge 201 was lost')

-- Active badge ticker: if an icon becomes hidden, the ticker hides its badge.
local testFrame=CreateFrame('Frame',nil,UIParent)
testFrame:SetSize(32,32); testFrame:Show()
local testIcon=testFrame:CreateTexture(nil,'ARTWORK'); testIcon:SetSize(32,32); testIcon:Show()
U.MaterialBadge(testIcon,'item:9501')
assert(testIcon.foreverNetBadge and testIcon.foreverNetBadge.shown)
testIcon:Hide()
assert(not testIcon:IsVisible())
if U.BadgeLayer().scripts and U.BadgeLayer().scripts.OnUpdate then
    U.BadgeLayer().scripts.OnUpdate(U.BadgeLayer(), 0.1)
end
assert(not testIcon.foreverNetBadge.shown, 'badge stayed shown after target icon was hidden')
assert(not testIcon.foreverNetBadge.border.shown, 'badge border stayed shown after target icon was hidden')

-- Bank slots sweep: bank items in BankSlotsFrame / BankFrameItem1..N show badges when bank is open.
local bankFrame=CreateFrame('Frame','BankFrame',UIParent)
local bankSlots=CreateFrame('Frame','BankSlotsFrame',bankFrame)
local bankItem1=CreateFrame('Button','BankFrameItem1',bankSlots)
bankItem1:SetID(1)
bankItem1.icon=bankItem1:CreateTexture(nil,'ARTWORK'); bankItem1.icon:SetSize(36,36); bankItem1.icon:SetPoint('TOPLEFT',0,0)
bankSlots.Item1=bankItem1
C_Container.GetContainerItemInfo=function(bag, slot)
    if (bag==-1 or bag==BANK_CONTAINER) and slot==1 then return {itemID=9501,stackCount=5} end
    return nil
end
bankFrame:Hide()
U.BagBadges()
assert(bankItem1.icon.foreverNetBadge==nil or not bankItem1.icon.foreverNetBadge.shown,
    'bank item showed badge while bank was closed')
bankFrame:Show()
U.BagBadges()
assert(bankItem1.icon.foreverNetBadge and bankItem1.icon.foreverNetBadge.shown,
    'bank item missing badge while bank was open')
assert(bankItem1.icon.foreverNetBadge.border and bankItem1.icon.foreverNetBadge.border.shown,
    'bank item missing yellow border on badge')
-- Changing bank item to non-material hides badge.
C_Container.GetContainerItemInfo=function() return {itemID=88888,stackCount=1} end
U.BagBadges()
assert(not bankItem1.icon.foreverNetBadge.shown, 'non-material bank item showed badge')
assert(not bankItem1.icon.foreverNetBadge.border.shown, 'non-material bank item showed border')
-- Closing bank frame hides badge even if item is a material.
C_Container.GetContainerItemInfo=function(bag, slot)
    if (bag==-1 or bag==BANK_CONTAINER) and slot==1 then return {itemID=9501,stackCount=5} end
    return nil
end
U.BagBadges()
assert(bankItem1.icon.foreverNetBadge.shown)
bankFrame:Hide()
U.BagBadges()
assert(not bankItem1.icon.foreverNetBadge.shown, 'closed bank frame showed badge')
assert(not bankItem1.icon.foreverNetBadge.border.shown, 'closed bank frame showed border')
-- PLAYERBANKSLOTS_CHANGED event triggers bank badge sweep.
bankFrame:Show()
F.Bank.Event('PLAYERBANKSLOTS_CHANGED')
assert(bankItem1.icon.foreverNetBadge.shown, 'PLAYERBANKSLOTS_CHANGED did not refresh bank badges')
bankFrame:Hide()
F.Bank.Event('BANKFRAME_CLOSED')
BankFrame=nil; BankSlotsFrame=nil; BankFrameItem1=nil

-- Modern BankPanel sweep: item buttons with EnumerateValidItems / GetBankTabID / GetContainerSlotID
local modernBankFrame=CreateFrame('Frame','BankFrame',UIParent)
local modernBankPanel=CreateFrame('Frame','BankPanel',modernBankFrame)
local modernBtn=CreateFrame('Button',nil,modernBankPanel)
modernBtn.icon=modernBtn:CreateTexture(nil,'ARTWORK'); modernBtn.icon:SetSize(36,36); modernBtn.icon:SetPoint('TOPLEFT',0,0)
modernBtn.GetBankTabID=function() return 100 end
modernBtn.GetContainerSlotID=function() return 1 end
modernBankPanel.EnumerateValidItems=function()
    return function(_, prev)
        if prev==nil then return modernBtn end
        return nil
    end
end
C_Container.GetContainerItemInfo=function(bag, slot)
    if bag==100 and slot==1 then return {itemID=1210,stackCount=2} end -- Shadowgem
    return nil
end
modernBankFrame:Show(); modernBankPanel:Show()
F.Bank.Event('BANKFRAME_OPENED')
assert(modernBtn.icon.foreverNetBadge and modernBtn.icon.foreverNetBadge.shown,
    'modern BankPanel button missing badge')
modernBankFrame:Hide(); modernBankPanel:Hide()
F.Bank.Event('BANKFRAME_CLOSED')
assert(not modernBtn.icon.foreverNetBadge.shown,
    'BANKFRAME_CLOSED did not hide modern BankPanel badge')
BankFrame=nil; BankPanel=nil

-- Setting to toggle material badges on and off
F.Settings.Open()
local badgeCheck=F.Settings.checks[8]
assert(badgeCheck and badgeCheck.key=='materialBadges', 'checkbox 8 is not materialBadges')
assert(badgeCheck.locale=='SETTING_MATERIAL_BADGES', 'checkbox 8 has wrong locale key')
assert(badgeCheck:GetChecked(), 'badge setting should be checked by default')
assert(U.BadgesEnabled(), 'badges should be enabled by default')

-- Unchecking hides badges in UI and prevents drawing
badgeCheck:SetChecked(false); badgeCheck.scripts.OnClick(badgeCheck)
assert(F.db.settings.materialBadges==false)
assert(not U.BadgesEnabled())
local testIcon=CreateFrame('Frame',nil,UIParent):CreateTexture(nil,'ARTWORK'); testIcon:SetSize(32,32)
U.MaterialBadge(testIcon,'item:9501')
assert(not testIcon.foreverNetBadge or not testIcon.foreverNetBadge.shown, 'badge drawn while setting disabled')

-- Slash command /fn badges on / off
F.Command('badges on')
assert(F.db.settings.materialBadges==true and U.BadgesEnabled())
assert(badgeCheck:GetChecked(), 'settings checkbox did not reflect badges on')
U.MaterialBadge(testIcon,'item:9501')
assert(testIcon.foreverNetBadge and testIcon.foreverNetBadge.shown, 'badge missing after badges on')

F.Command('badges off')
assert(F.db.settings.materialBadges==false and not U.BadgesEnabled())
assert(not badgeCheck:GetChecked(), 'settings checkbox did not reflect badges off')
assert(not testIcon.foreverNetBadge.shown, 'badge not hidden after badges off')

-- Re-enabling via checkbox restores badges
badgeCheck:SetChecked(true); badgeCheck.scripts.OnClick(badgeCheck)
assert(F.db.settings.materialBadges==true and U.BadgesEnabled())
U.MaterialBadge(testIcon,'item:9501')
assert(testIcon.foreverNetBadge.shown, 'badge not shown after re-enabling setting')

-- Tooltip on hover
badgeCheck.scripts.OnEnter(badgeCheck)
assert(F.Theme.tooltip and F.Theme.tooltip.title:GetText()==F.L('SETTING_MATERIAL_BADGES'))
badgeCheck.scripts.OnLeave(badgeCheck)

