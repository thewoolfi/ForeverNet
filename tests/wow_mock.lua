-- Deliberately small widget API: unknown methods return nil, like the client.
-- In particular, EditBox does NOT implement GetTextHeight/GetStringHeight.
clock = 1800000000
function time() return clock end
function GetRealmName() return 'Realm' end
function UnitFullName() return playerName, 'Realm' end
function GetLocale() return clientLocale or 'enUS' end
chatMessages = {}
DEFAULT_CHAT_FRAME = {AddMessage = function(self, s) chatMessages[#chatMessages + 1] = s end}
UIParent, GameFontHighlight, UISpecialFrames, SlashCmdList = {}, {}, {}, {}
C_Timer = {After = function(_, callback) callback() end}
function IsInGuild() return true end
function IsInGroup() return false end
function IsInRaid() return false end
frames = {}
local region = {}
function region:SetPoint(...)
    assert(select(2,...)~=self,'Cannot anchor to itself')
    self.point = {...}
    self.points=self.points or {}; self.points[select(1,...)]=self.point
end
function region:SetAllPoints(...) self.allPoints={...} end
function region:SetSize(w, h) self.width, self.height = w, h end
function region:SetWidth(w) self.width = w end
function region:SetHeight(h) self.height = h end
function region:GetWidth() return self.width end
function region:GetHeight() return self.height end
function region:GetObjectType() return self.kind end
function region:Show() self.shown = true end
function region:Hide()
    local wasShown=self.shown; self.shown=false
    if wasShown and self.scripts and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function region:IsShown() return self.shown end
function region:IsVisible() return self.shown and (not self.parent or not self.parent.IsVisible or self.parent:IsVisible()) end
function region:SetShown(shown) self.shown = shown end
function region:SetAlpha(alpha) self.alpha=alpha end
function region:GetAlpha() return self.alpha or 1 end
function region:GetNumPoints() local n=0; for _ in pairs(self.points or {}) do n=n+1 end; return n end
function region:GetPoint(i) local n=0; for _,point in pairs(self.points or {}) do n=n+1; if n==i then return unpack(point) end end end
function region:SetParent(parent) self.parent=parent end

local font = {}
function font:SetText(text) self.text = text end
function font:GetText() return self.text end
function font:GetUnboundedStringWidth()
    local width=0
    for line in ((self.text or '')..'\n'):gmatch('(.-)\n') do
        width=math.max(width,#line:gsub('[\128-\191]','')*(self.fontSize or 12)*.55)
    end
    return width
end
function font:GetStringHeight()
    local size=self.fontSize or 12
    local height, lines, columns = 0, 0, math.max(1, math.floor(self.width / (size*.55)))
    for line in (self.text .. '\n'):gmatch('(.-)\n') do
        local chars=#line:gsub('[\128-\191]','')
        local count=math.max(1,math.ceil(chars / columns))
        height=height+count*(size+2); lines=lines+count
    end
    return height+math.max(0,lines-1)*(self.spacing or 0)
end
function font:GetFont() return self.fontFile or 'Fonts\\FRIZQT__.TTF',self.fontSize or 12,self.fontFlags or 'OUTLINE' end
function font:SetFont(file,size,flags) self.fontFile,self.fontSize,self.fontFlags=file,size,flags; return true end
function font:SetShadowOffset(x,y) self.shadow={x,y} end
function font:SetTextColor(...) self.color={...} end
for _, method in ipairs({'SetJustifyH', 'SetJustifyV', 'SetWordWrap', 'SetFontObject'}) do font[method] = function() end end

local widget = {}
function widget:SetScript(event, callback) self.scripts[event] = callback end
function widget:HookScript(event,callback)
    local prior=self.scripts[event]
    self.scripts[event]=function(...) if prior then prior(...) end; callback(...) end
end
function widget:RegisterEvent(event) self.events[event] = true end
for _, method in ipairs({'SetFrameStrata', 'SetBackdrop', 'SetBackdropColor', 'SetBackdropBorderColor',
    'SetMovable', 'EnableMouse', 'RegisterForDrag', 'StartMoving', 'StopMovingOrSizing'}) do widget[method] = function() end end
local edit = {}
function edit:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function edit:GetText() return self.text end
function edit:SetTextColor(...) self.color={...} end
for _, method in ipairs({'SetMultiLine', 'SetAutoFocus', 'SetFontObject', 'SetNumeric', 'ClearFocus'}) do edit[method] = function() end end
local button = {SetText = edit.SetText, GetText = edit.GetText}
local scroll = {}
function scroll:SetScrollChild(child) self.child = child end
function scroll:SetVerticalScroll(value) self.verticalScroll = value end
function scroll:GetVerticalScroll() return self.verticalScroll end
function scroll:GetVerticalScrollRange() return math.max(0,(self.child and self.child:GetHeight() or 0)-self:GetHeight()) end
function scroll:EnableMouseWheel(value) self.mouseWheelEnabled=value end
local texture = {SetTexture = function(self, value) self.texture = value end}
function texture:GetTexture() return self.texture end
function texture:GetAtlas() return self.atlas end
function texture:GetTexCoord() return unpack(self.texCoord or {0,1,0,1}) end
function texture:GetVertexColor() return unpack(self.vertex or {1,1,1,1}) end
function texture:SetVertexColor(...) self.vertex={...} end
local line = {}
function line:SetThickness(value) self.thickness=value end
function line:SetStartPoint(...) self.start={...} end
function line:SetEndPoint(...) self.finish={...} end
function line:SetColorTexture(...) self.color={...} end
local specific = {Frame = {}, GameTooltip={}, EventFrame={}, Button = button, CheckButton = button, EditBox = edit, ScrollFrame = scroll, FontString = font, Font=font, Texture = texture, Line=line}
local function object(kind)
    assert(specific[kind], 'Unknown widget type: ' .. tostring(kind))
    return setmetatable({kind = kind, scripts = {}, events = {}, text = '', width = 0, height = 0, shown = true}, {
        __index = function(self, key)
            local common = kind ~= 'FontString' and kind ~= 'Texture' and widget[key]
            return specific[kind][key] or region[key] or common or nil
        end,
    })
end
function widget:CreateFontString(_,_,template)
    local f=object('FontString')
    f.fontSize=template and template:find('Large') and 16 or (template and template:find('Small') and 10 or 12)
    self.regions=self.regions or {}; self.regions[#self.regions+1]=f
    return f
end
function button:GetFontString()
    if not self.buttonText then self.buttonText=self:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall') end
    self.buttonText:SetFontObject(self:GetNormalFontObject()); self.buttonText:SetText(self:GetText())
    return self.buttonText
end
function widget:CreateTexture() return object('Texture') end
function widget:CreateLine() return object('Line') end
function widget:SetID(id) self.id=id end
function widget:GetID() return self.id end
function CreateFrame(kind, name, parent, template)
    local f = object(kind)
    f.template=template
    f.parent=parent
    if template=='ShoppingTooltipTemplate' then
        f.CompareHeader=object('Frame')
        f.CompareHeader.Label=object('FontString'); f.CompareHeader.Label:SetText('Equipped')
    end
    if template=='AuctionHouseFrameDisplayModeTabTemplate' then
        -- Inherited PanelTabButtonTemplate declares parentArray="Tabs".
        parent.Tabs=parent.Tabs or {}; parent.Tabs[#parent.Tabs+1]=f
    end
    if template == 'PortraitFrameTemplate' then
        function f:SetTitle(text) self.title = text; self.TitleContainer.TitleText:SetText(text) end
        function f:GetTitleText() return self.TitleContainer.TitleText end
        function f:SetPortraitToAsset(texture) self.portraitAsset = texture end
        local levels={NineSlice=500,PortraitContainer=400,TitleContainer=510,CloseButton=510}
        for key,level in pairs(levels) do
            f[key]=object(key=='CloseButton' and 'Button' or 'Frame')
            f[key].level=level
        end
        f.TitleContainer.TitleText=object('FontString'); f.TitleContainer.TitleText.fontSize=14
        function f:SetFrameLevelsFromBaseLevel(base)
            for key,offset in pairs(levels) do self[key]:SetFrameLevel(base+offset) end
        end
    elseif template=='LargeSideTabButtonTemplate' then
        f:SetSize(60,48); f.Icon=object('Texture'); f.SelectedTexture=object('Texture')
        function f:SetFillToInterior(fill,extent) self.fillToInterior=fill; self.Icon:SetSize(extent,extent) end
        function f:SetChecked(value) self.checked=value; self.SelectedTexture:SetShown(value) end
        function f:SetCustomOnMouseUpHandler(callback) self.customMouseUpHandler=callback end
        f:SetScript('OnMouseUp',function(self,button,inside)
            if self.customMouseUpHandler then self.customMouseUpHandler(self,button,inside) end
        end)
    end
    frames[#frames + 1] = f
    return f
end
function CreateFont(name) local f=object('Font'); _G[name]=f; return f end
for _,name in ipairs({'GameFontNormal','GameFontHighlight','GameFontDisable','GameFontHighlightSmall'}) do
    _G[name]=object('Font'); _G[name].fontSize=name:find('Small') and 10 or 12
end
function font:SetFontObject(base)
    if type(base)=='string' then base=_G[base] end
    self.fontFile,self.fontSize,self.fontFlags=base:GetFont()
    self.baseFont=base
end
edit.GetFont=font.GetFont; edit.SetFont=font.SetFont; edit.SetFontObject=font.SetFontObject
for _,state in ipairs({'Normal','Highlight','Disabled'}) do
    local key=state..'Font'
    button['Get'..state..'FontObject']=function(self) return self[key] or _G[state=='Disabled' and 'GameFontDisable' or state=='Highlight' and 'GameFontHighlight' or 'GameFontNormal'] end
    button['Set'..state..'FontObject']=function(self,value) self[key]=value end
end
function widget:GetRegions() return unpack(self.regions or {}) end
function specific.GameTooltip:SetOwner(owner,anchor) self.owner,self.anchor=owner,anchor end
function specific.GameTooltip:SetText(value)
    if not self.title then self.title=self:CreateFontString(nil,'OVERLAY','GameFontNormal'); self.title:SetWidth(260) end
    self.title:SetText(value)
    self.tooltipLines={self.title}
end
function specific.GameTooltip:AddLine(value,r,g,b)
    if not self.line then self.line=self:CreateFontString(nil,'OVERLAY','GameFontHighlight'); self.line:SetWidth(260) end
    self.line:SetText(value)
    self.tooltipLines=self.tooltipLines or {}
    local row=self:CreateFontString(nil,'OVERLAY','GameFontHighlight'); row:SetWidth(260); row:SetText(value)
    row:SetTextColor(r or 1,g or 1,b or 1,1); self.tooltipLines[#self.tooltipLines+1]=row
end
function specific.GameTooltip:ClearLines()
    self.tooltipLines={}; if self.title then self.title:SetText('') end; if self.line then self.line:SetText('') end
end
function specific.GameTooltip:ClearHandlerInfo() self.primaryInfo=nil end
function specific.GameTooltip:NumLines() return #(self.tooltipLines or {}) end
function specific.GameTooltip:GetPrimaryTooltipInfo() return self.primaryInfo end
function specific.GameTooltip:SetItemByID(id)
    assert(type(id)=='number'); self.nativeItem=id
    local rows=mockItemTooltips and mockItemTooltips[id]
    if not rows then return false end
    self:SetText(rows[1][1]); self.title:SetTextColor(unpack(rows[1][2] or {1,1,1,1}))
    for i=2,#rows do self:AddLine(rows[i][1],unpack(rows[i][2] or {1,1,1})) end
    self.primaryInfo={getterName='GetItemByID'}; return true
end
function specific.GameTooltip:SetHyperlink(link)
    self.nativeLink=link; return specific.GameTooltip.SetItemByID(self,tonumber(link:match('^item:(%d+)$')))
end
C_ChatInfo = {RegisterAddonMessagePrefix = function() return true end, SendAddonMessage = function() end}

function button:SetEnabled(value) self.enabled=value end
function button:IsEnabled() return self.enabled~=false end
function button:RegisterForClicks(...) self.clicks={...} end
function button:SetHighlightTexture(value) self.highlight=value end
function texture:SetTexCoord(...) self.texCoord={...} end
function region:ClearAllPoints() self.point=nil; self.points={} end
function widget:GetFrameLevel() return self.level or 1 end
function widget:SetFrameLevel(value) self.level=value end
function widget:GetEffectiveScale() return 1 end
function widget:GetCenter() return 100,100 end
function GetCursorPosition() return 200,100 end
function GetTime() return clock end

function button:SetChecked(v) self.checked=v end
function button:GetChecked() return self.checked end

function widget:SetFrameStrata(value) self.strata=value end
function widget:SetClampedToScreen(value) self.clamped=value end
function widget:SetBackdrop(value) self.backdrop=value end
function widget:SetBackdropColor(...) self.backdropColor={...} end
function texture:SetColorTexture(...) self.color={...} end
function texture:SetAtlas(value) self.atlas=value end
C_Texture={GetAtlasInfo=function(atlas)
    if atlas:find('Profession%-background%-card%-') or atlas=='Professions-Recipe-Background' then return {width=300,height=280} end
end}
ScrollUtil={InitScrollFrameWithScrollBar=function(frame,bar)
    frame.boundScrollBar=bar
    function bar:SetScrollPercentage(value)
        self.percentage=math.max(0,math.min(1,value))
        frame:SetVerticalScroll(self.percentage*frame:GetVerticalScrollRange())
    end
    function bar:ScrollStepInDirection(direction)
        local range=frame:GetVerticalScrollRange()
        if range>0 then self:SetScrollPercentage((frame:GetVerticalScroll() or 0)/range+direction*30/range) end
    end
    frame:SetScript('OnMouseWheel',function(_,value) bar:ScrollStepInDirection(-value) end)
end}

function font:SetSpacing(value) self.spacing=value end

function edit:SetFocus() self.focused=true; if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end end
function edit:HighlightText() self.highlighted=true end
