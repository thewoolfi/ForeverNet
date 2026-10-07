local _,F=...
F.Theme={background='Interface\\FrameGeneral\\UI-Background-Rock',
    colors={text={.92,.91,.87},heading={.96,.94,.88},muted={.72,.70,.66},
        good={.45,.90,.48},missing={1,.66,.28},blueprint={.82,.62,1}}}
local T=F.Theme
T.fontFiles={koKR='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKKR.ttf',
    zhCN='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKSC.ttf',
    zhTW='Interface\\AddOns\\ForeverNet\\Fonts\\ForeverNetCJKTC.ttf'}
T.defaultFont=T.fontFiles.zhCN -- The bundled Sans family includes Latin and Cyrillic.
T.fonts=setmetatable({}, {__mode='k'})
function T.Locale() return F.db and F.db.settings.locale or GetLocale() end
function T.IsClassic() return F.db and F.db.settings.uiStyle=='classic' or false end
local function applyFont(region,record)
    local native=record.file:lower()
    local standard=native:find('frizqt',1,true) or native:find('morpheus',1,true) or native:find('skurri',1,true) or native:find('arialn',1,true)
    local path=T.fontFiles[record.locale or T.Locale()] or T.fontFiles[GetLocale()] or (standard and not T.IsClassic() and T.defaultFont) or record.file
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
    if T.fontLocale==locale and T.fontClientLocale==GetLocale() and T.fontClassic==T.IsClassic() then return end
    T.fontLocale,T.fontClientLocale,T.fontClassic=locale,GetLocale(),T.IsClassic()
    for region,record in pairs(T.fonts) do applyFont(region,record) end
end
function T.Button(button,locale)
    -- Private state fonts preserve disabled/highlight colours without changing GameFont*.
    for _,state in ipairs({'Normal','Highlight','Disabled'}) do
        local base=button['Get'..state..'FontObject'](button)
        if base then
            T.fontCounter=(T.fontCounter or 0)+1
            local font=CreateFont('ForeverNetFont'..T.fontCounter)
            font:SetFontObject(base); T.Font(font,12,locale,'')
            local color=state=='Disabled' and T.colors.muted or T.colors.text
            font:SetTextColor(color[1],color[2],color[3],state=='Disabled' and .65 or 1)
            button['Set'..state..'FontObject'](button,font)
        end
    end
    if not button.flatFill then
        for _,key in ipairs({'Left','Middle','Right'}) do if button[key] then button[key]:Hide() end end
        for _,name in ipairs({'GetNormalTexture','GetPushedTexture','GetDisabledTexture'}) do
            if button[name] then local texture=button[name](button); if texture then texture:SetAlpha(0) end end
        end
        if button.GetHighlightTexture then
            local texture=button:GetHighlightTexture()
            if texture then texture:SetColorTexture(.35,.31,.24,.45); texture:ClearAllPoints(); texture:SetAllPoints() end
        end
        button.flatFill=button:CreateTexture(nil,'BACKGROUND'); button.flatFill:SetAllPoints(); button.flatFill:SetColorTexture(.18,.165,.14,1)
        button.flatEdge=button:CreateTexture(nil,'ARTWORK'); button.flatEdge:SetHeight(1); button.flatEdge:SetPoint('BOTTOMLEFT',0,0); button.flatEdge:SetPoint('BOTTOMRIGHT',0,0)
        button.flatEdge:SetColorTexture(.38,.32,.23,1)
    end
end
function T.Title(frame)
    T.Font(frame:GetTitleText(),14,nil,'')
    if frame.NineSlice then frame.NineSlice:Hide() end
    if frame.PortraitContainer then frame.PortraitContainer:Hide() end
    for _,key in ipairs({'Bg','TopTileStreaks','FrameGlow'}) do if frame[key] then frame[key]:Hide() end end
    if not frame.flatChrome then
        frame.flatBase=frame:CreateTexture(nil,'BACKGROUND',nil,-8); frame.flatBase:SetAllPoints(); frame.flatBase:SetColorTexture(.07,.065,.055,1)
        frame.flatChrome=CreateFrame('Frame',nil,frame,'BackdropTemplate'); frame.flatChrome:SetAllPoints(); T.Skin(frame.flatChrome)
        -- The child frame draws only the border: an opaque child backdrop would
        -- cover FontStrings and textures attached directly to the parent window.
        frame.flatChrome:SetBackdropColor(0,0,0,0)
        frame.brandIcon=frame.flatChrome:CreateTexture(nil,'OVERLAY'); frame.brandIcon:SetTexture(F.icon); frame.brandIcon:SetSize(24,24); frame.brandIcon:SetPoint('TOPLEFT',14,-8)
    end
    local title=frame:GetTitleText(); title:ClearAllPoints(); title:SetPoint('TOPLEFT',frame,'TOPLEFT',46,-13); title:SetJustifyH('LEFT'); T.Color(title,'text')
    title:SetWidth(frame:GetWidth()-92)
    if frame.CloseButton then
        local close=frame.CloseButton
        if close.GetNormalTexture then local texture=close:GetNormalTexture(); if texture then texture:SetAlpha(0) end end
        if close.GetPushedTexture then local texture=close:GetPushedTexture(); if texture then texture:SetAlpha(0) end end
        if close.GetHighlightTexture then local texture=close:GetHighlightTexture(); if texture then texture:SetColorTexture(.35,.31,.24,.5); texture:ClearAllPoints(); texture:SetAllPoints() end end
        if not close.flatText then close.flatText=close:CreateFontString(nil,'OVERLAY','GameFontHighlight'); close.flatText:SetPoint('CENTER'); T.Text(close.flatText,false,16); close.flatText:SetText('x') end
    end
end
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
    if text then
        text:SetWordWrap(true); text:SetWidth(math.max(1,width-20)); text:SetHeight(0)
        text:ClearAllPoints(); text:SetPoint('CENTER'); text:SetJustifyH('CENTER')
    end
    return height
end
function T.ShowTooltip(owner,title,line,anchor)
    if not T.tooltip then T.tooltip=CreateFrame('GameTooltip','ForeverNetTooltip',UIParent,'GameTooltipTemplate') end
    local tip=T.tooltip
    tip:SetOwner(owner,anchor or 'ANCHOR_RIGHT'); tip:SetText(title)
    if line then tip:AddLine(line,.86,.85,.80,true) end
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
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',
        tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(inset and .085 or .10,inset and .078 or .09,inset and .066 or .075,1)
    frame:SetBackdropBorderColor(.25,.225,.185,1)
end
function T.Section(frame)
    T.Skin(frame,true); frame:SetBackdropBorderColor(.22,.20,.17,1)
end
function T.Background(frame)
    local base=frame:CreateTexture(nil,'BACKGROUND',nil,0)
    base:SetPoint('TOPLEFT',6,-30); base:SetPoint('BOTTOMRIGHT',-6,6)
    base:SetColorTexture(.07,.065,.055,1)
    local texture=frame:CreateTexture(nil,'BACKGROUND',nil,1)
    texture:SetPoint('TOPLEFT',6,-30); texture:SetPoint('BOTTOMRIGHT',-6,6)
    texture:SetTexture(T.background)
    texture:SetAlpha(0)
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
