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
function region:SetPoint(...) self.point = {...} end
function region:SetSize(w, h) self.width, self.height = w, h end
function region:SetWidth(w) self.width = w end
function region:SetHeight(h) self.height = h end
function region:GetWidth() return self.width end
function region:GetHeight() return self.height end
function region:GetObjectType() return self.kind end
function region:Show() self.shown = true end
function region:Hide() self.shown = false end
function region:IsShown() return self.shown end
function region:SetShown(shown) self.shown = shown end

local font = {}
function font:SetText(text) self.text = text end
function font:GetText() return self.text end
function font:GetStringHeight()
    local height, columns = 0, math.max(1, math.floor(self.width / 7))
    for line in (self.text .. '\n'):gmatch('(.-)\n') do
        height = height + math.max(1, math.ceil(#line / columns)) * 14
    end
    return height
end
for _, method in ipairs({'SetTextColor', 'SetJustifyH', 'SetJustifyV', 'SetWordWrap', 'SetFontObject'}) do font[method] = function() end end

local widget = {}
function widget:SetScript(event, callback) self.scripts[event] = callback end
function widget:RegisterEvent(event) self.events[event] = true end
for _, method in ipairs({'SetFrameStrata', 'SetBackdrop', 'SetBackdropColor', 'SetBackdropBorderColor',
    'SetMovable', 'EnableMouse', 'RegisterForDrag', 'StartMoving', 'StopMovingOrSizing'}) do widget[method] = function() end end
local edit = {}
function edit:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function edit:GetText() return self.text end
for _, method in ipairs({'SetMultiLine', 'SetAutoFocus', 'SetFontObject', 'SetNumeric', 'ClearFocus'}) do edit[method] = function() end end
local button = {SetText = edit.SetText, GetText = edit.GetText}
local scroll = {}
function scroll:SetScrollChild(child) self.child = child end
function scroll:SetVerticalScroll(value) self.verticalScroll = value end
function scroll:GetVerticalScroll() return self.verticalScroll end
local texture = {SetTexture = function(self, value) self.texture = value end}
local specific = {Frame = {}, Button = button, CheckButton = button, EditBox = edit, ScrollFrame = scroll, FontString = font, Texture = texture}
local function object(kind)
    assert(specific[kind], 'Unknown widget type: ' .. tostring(kind))
    return setmetatable({kind = kind, scripts = {}, events = {}, text = '', width = 0, height = 0, shown = true}, {
        __index = function(self, key)
            local common = kind ~= 'FontString' and kind ~= 'Texture' and widget[key]
            return specific[kind][key] or region[key] or common or nil
        end,
    })
end
function widget:CreateFontString() return object('FontString') end
function widget:CreateTexture() return object('Texture') end
function CreateFrame(kind, name, parent, template)
    local f = object(kind)
    if template == 'PortraitFrameTemplate' then
        function f:SetTitle(text) self.title = text end
        function f:SetPortraitToAsset(texture) self.portraitAsset = texture end
    end
    frames[#frames + 1] = f
    return f
end
C_ChatInfo = {RegisterAddonMessagePrefix = function() return true end, SendAddonMessage = function() end}

function button:SetEnabled(value) self.enabled=value end
function button:IsEnabled() return self.enabled~=false end
function button:RegisterForClicks(...) self.clicks={...} end
function button:SetHighlightTexture(value) self.highlight=value end
function texture:SetTexCoord(...) self.texCoord={...} end
function region:ClearAllPoints() self.point=nil end
function widget:GetFrameLevel() return self.level or 1 end
function widget:SetFrameLevel(value) self.level=value end
function widget:GetEffectiveScale() return 1 end
function widget:GetCenter() return 100,100 end
function GetCursorPosition() return 200,100 end
function GetTime() return clock end

function button:SetChecked(v) self.checked=v end
function button:GetChecked() return self.checked end

function widget:SetFrameStrata(value) self.strata=value end
function texture:SetColorTexture(...) self.color={...} end

function font:SetSpacing(value) self.spacing=value end
