local _,F=...
F.Theme={background='Interface\\FrameGeneral\\UI-Background-Rock',
    colors={text={.90,.88,.83},heading={1,.82,.22},muted={.72,.69,.63},
        good={.45,.90,.48},missing={1,.66,.28},blueprint={.82,.62,1}}}
local T=F.Theme
T.fontFiles={koKR='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKKR.ttf',
    zhCN='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKSC.ttf',
    zhTW='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKTC.ttf'}
T.fonts=setmetatable({}, {__mode='k'})
function T.Locale() return F.db and F.db.settings.locale or GetLocale() end
local function applyFont(region,record)
    local path=T.fontFiles[record.locale or T.Locale()] or T.fontFiles[GetLocale()] or record.file
    local current,height,flags=region:GetFont()
    if current~=path or height~=record.size or flags~=record.flags then
        if region:SetFont(path,record.size,record.flags)==false then region:SetFont(record.file,record.size,record.flags) end
    end
end
function T.Font(region,minSize,locale,flags)
    if not region then return end
    local record=T.fonts[region]
    if not record then
        local file,height,originalFlags=region:GetFont()
        if not file then return end
        record={file=file,size=height or 12,flags=originalFlags or ''}; T.fonts[region]=record
    end
    record.size=math.max(record.size,minSize or 12)
    record.locale=locale
    if flags~=nil then record.flags=flags end
    applyFont(region,record)
end
function T.RefreshFonts()
    local locale=T.Locale()
    if T.fontLocale==locale and T.fontClientLocale==GetLocale() then return end
    T.fontLocale,T.fontClientLocale=locale,GetLocale()
    for region,record in pairs(T.fonts) do applyFont(region,record) end
end
function T.Button(button,locale)
    -- Private state fonts preserve disabled/highlight colours without changing GameFont*.
    for _,state in ipairs({'Normal','Highlight','Disabled'}) do
        local base=button['Get'..state..'FontObject'](button)
        if base then
            T.fontCounter=(T.fontCounter or 0)+1
            local font=CreateFont('ForeverNetFont'..T.fontCounter)
            font:SetFontObject(base); T.Font(font,12,locale)
            button['Set'..state..'FontObject'](button,font)
        end
    end
end
function T.Title(frame) T.Font(frame:GetTitleText(),12) end
local function measureButton(button)
    -- Measure the private normal-state font; never shrink translated labels.
    if not button.measure then
        button.measure=button:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        button.measure:Hide(); button.measure:SetWordWrap(true)
    end
    button.measure:SetFontObject(button:GetNormalFontObject())
    button.measure:SetText(button:GetText() or '')
    return button.measure
end
function T.ButtonWidth(button)
    return math.ceil(measureButton(button):GetUnboundedStringWidth()+20)
end
function T.FitButton(button,width)
    measureButton(button):SetWidth(math.max(1,width-20))
    local height=math.max(24,button.measure:GetStringHeight()+8)
    button:SetSize(width,height)
    local text=button.GetFontString and button:GetFontString()
    if text then text:SetWordWrap(true); text:SetWidth(math.max(1,width-20)) end
    return height
end
function T.ShowTooltip(owner,title,line,anchor)
    if not T.tooltip then T.tooltip=CreateFrame('GameTooltip','ForeverNetTooltip',UIParent,'GameTooltipTemplate') end
    local tip=T.tooltip
    tip:SetOwner(owner,anchor or 'ANCHOR_RIGHT'); tip:SetText(title)
    if line then tip:AddLine(line,1,.82,.25,true) end
    for _,region in ipairs({tip:GetRegions()}) do
        if region:GetObjectType()=='FontString' then T.Font(region,12) end
    end
    tip:Show()
end
function T.HideTooltip() if T.tooltip then T.tooltip:Hide() end end
function T.Color(text,tone)
    local color=T.colors[tone or 'text'] or T.colors.text
    text:SetTextColor(color[1],color[2],color[3])
end
function T.Text(text,heading,minSize)
    T.Font(text,minSize or 12,nil,'')
    text:SetShadowOffset(0,0)
    T.Color(text,heading and 'heading' or 'text')
end
function T.Skin(frame,inset)
    frame:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        tile=false,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(inset and .09 or .105,inset and .075 or .087,inset and .06 or .070,1)
    frame:SetBackdropBorderColor(.50,.35,.14,1)
end
function T.Section(frame)
    frame:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        tile=true,tileSize=16,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
    frame:SetBackdropColor(.15,.09,.035,1); frame:SetBackdropBorderColor(.53,.36,.13,1)
end
function T.Background(frame)
    local base=frame:CreateTexture(nil,'BACKGROUND',nil,0)
    base:SetPoint('TOPLEFT',6,-30); base:SetPoint('BOTTOMRIGHT',-6,6)
    base:SetColorTexture(.12,.10,.08,1)
    local texture=frame:CreateTexture(nil,'BACKGROUND',nil,1)
    texture:SetPoint('TOPLEFT',6,-30); texture:SetPoint('BOTTOMRIGHT',-6,6)
    texture:SetTexture(T.background)
    texture:SetAlpha(.10)
    return texture,base
end
function T.ScrollFrame(parent)
    local frame=CreateFrame('ScrollFrame',nil,parent)
    frame:EnableMouseWheel(true)
    local bar=CreateFrame('EventFrame',nil,parent,'MinimalScrollBar')
    bar:SetPoint('TOPLEFT',frame,'TOPRIGHT',10,0)
    bar:SetPoint('BOTTOMLEFT',frame,'BOTTOMRIGHT',10,0)
    ScrollUtil.InitScrollFrameWithScrollBar(frame,bar)
    frame.ScrollBar=bar
    return frame
end
