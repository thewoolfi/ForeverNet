local _,F=...
local T=F.Theme
local function registry() return setmetatable({},{__mode='k'}) end
T.buttons,T.windows,T.skins,T.sections,T.backgrounds,T.tabs,T.tones=registry(),registry(),registry(),registry(),registry(),registry(),registry()
local modern={Button=T.Button,Title=T.Title,Skin=T.Skin,Section=T.Section,Background=T.Background,Color=T.Color}
local palettes={modern={text={.92,.91,.87},heading={.96,.94,.88},muted={.72,.70,.66}},
    classic={text={.90,.88,.83},heading={1,.82,.22},muted={.72,.69,.63}}}
local function points(region)
    local result={}
    if region.GetNumPoints and region.GetPoint then
        for i=1,region:GetNumPoints() do result[#result+1]={region:GetPoint(i)} end
    elseif region.point then result[1]=region.point end
    return result
end
local function restorePoints(region,saved)
    region:ClearAllPoints(); for _,point in ipairs(saved) do region:SetPoint(unpack(point)) end
    return #saved>0
end
local function snapshot(region)
    return {texture=region.GetTexture and region:GetTexture(),atlas=region.GetAtlas and region:GetAtlas(),
        alpha=region.GetAlpha and region:GetAlpha() or 1,shown=region:IsShown(),points=points(region),
        width=region:GetWidth(),height=region:GetHeight(),
        coords=region.GetTexCoord and {region:GetTexCoord()},vertex=region.GetVertexColor and {region:GetVertexColor()}}
end
local function restore(region,saved)
    if saved.atlas then region:SetAtlas(saved.atlas) else region:SetTexture(saved.texture) end
    if saved.coords and region.SetTexCoord then region:SetTexCoord(unpack(saved.coords)) end
    if saved.vertex and region.SetVertexColor then region:SetVertexColor(unpack(saved.vertex)) end
    region:SetAlpha(saved.alpha); restorePoints(region,saved.points)
    if saved.width and saved.height and saved.width>0 and saved.height>0 then region:SetSize(saved.width,saved.height) end
end
local function textures(button)
    local result={}
    for _,name in ipairs({'GetNormalTexture','GetPushedTexture','GetDisabledTexture','GetHighlightTexture'}) do
        if button[name] then local texture=button[name](button); if texture then result[texture]=snapshot(texture) end end
    end
    return result
end
local function applyButton(button,record)
    local classic=T.IsClassic()
    button.flatFill:SetShown(not classic); button.flatEdge:SetShown(not classic)
    for region,saved in pairs(record.parts) do region:SetShown(classic and saved or false) end
    for region,saved in pairs(record.textures) do
        if classic then restore(region,saved)
        elseif button.GetHighlightTexture and region==button:GetHighlightTexture() then
            region:SetColorTexture(.35,.31,.24,.45); region:ClearAllPoints(); region:SetAllPoints()
        else region:SetAlpha(0) end
    end
    for _,state in ipairs({'Normal','Highlight','Disabled'}) do
        local font=button['Get'..state..'FontObject'](button)
        local color=state=='Disabled' and T.colors.muted or classic and state=='Normal' and T.colors.heading or T.colors.text
        if font then font:SetTextColor(color[1],color[2],color[3],state=='Disabled' and .65 or 1) end
    end
    if button:GetWidth()>0 then T.FitButton(button,button:GetWidth()) end
end
function T.Button(button,locale)
    local record=T.buttons[button]
    if not record then
        record={parts={},textures=textures(button)}; T.buttons[button]=record
        for _,name in ipairs({'Left','Middle','Right'}) do if button[name] then record.parts[button[name]]=button[name]:IsShown() end end
        modern.Button(button,locale)
        -- This instance belongs to ForeverNet. Native/global button APIs are not replaced.
        local setText=button.SetText
        button.SetText=function(self,value)
            setText(self,value)
            if self:GetWidth()>0 then T.FitButton(self,self:GetWidth()) end
        end
    end
    applyButton(button,record)
end
local function skin(frame,inset,section)
    if not T.IsClassic() then
        modern.Skin(frame,inset)
        if section then frame:SetBackdropBorderColor(.22,.20,.17,1) end
        return
    end
    frame:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
        tile=false,edgeSize=section and 10 or 16,insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(section and .15 or inset and .09 or .105,section and .09 or inset and .075 or .087,section and .035 or inset and .06 or .070,1)
    frame:SetBackdropBorderColor(.50,.35,.14,1)
end
function T.Skin(frame,inset) T.skins[frame]={inset=inset}; T.sections[frame]=nil; skin(frame,inset) end
function T.Section(frame) T.sections[frame]=true; T.skins[frame]=nil; skin(frame,true,true) end
local function applyWindow(frame,record)
    if not T.IsClassic() then
        modern.Title(frame); frame.flatChrome:SetBackdropColor(0,0,0,0)
        frame.flatChrome:Show(); frame.flatBase:Show(); frame.brandIcon:Show()
        if frame.CloseButton.flatText then frame.CloseButton.flatText:Show() end
        return
    end
    frame.flatChrome:Hide(); frame.flatBase:Hide(); frame.brandIcon:Hide()
    for region,shown in pairs(record.parts) do region:SetShown(shown) end
    for region,saved in pairs(record.close) do restore(region,saved) end
    if frame.CloseButton.flatText then frame.CloseButton.flatText:Hide() end
    local title=frame:GetTitleText()
    if not restorePoints(title,record.points) then title:ClearAllPoints(); title:SetPoint('CENTER',frame.TitleContainer,'CENTER') end
    title:SetWidth(record.width and record.width>0 and record.width or frame:GetWidth()-100); title:SetJustifyH('CENTER'); T.Color(title,'heading')
end
function T.Title(frame)
    local record=T.windows[frame]
    if not record then
        record={parts={},close=textures(frame.CloseButton),points=points(frame:GetTitleText()),width=frame:GetTitleText():GetWidth()}
        for _,name in ipairs({'NineSlice','PortraitContainer','Bg','TopTileStreaks','FrameGlow'}) do if frame[name] then record.parts[frame[name]]=frame[name]:IsShown() end end
        T.windows[frame]=record; modern.Title(frame)
    end
    applyWindow(frame,record)
end
function T.Background(frame)
    local texture,base=modern.Background(frame)
    T.backgrounds[texture]=base
    if T.IsClassic() then texture:SetAlpha(.1); base:SetColorTexture(.12,.10,.08,1) end
    return texture,base
end
function T.Color(region,tone) T.tones[region]=tone or 'text'; modern.Color(region,tone) end
function T.SideTab(nav)
    local record=T.tabs[nav]
    if not record then
        record={width=nav:GetWidth(),height=nav:GetHeight(),regions={}}
        for _,name in ipairs({'Icon','Background','Mask','SelectedTexture','HighlightTexture','TabGlow'}) do if nav[name] then record.regions[nav[name]]=snapshot(nav[name]) end end
        T.tabs[nav]=record
    end
    if T.IsClassic() then
        nav:SetSize(record.width,record.height)
        for region,saved in pairs(record.regions) do restore(region,saved) end
    else
        nav:SetSize(44,44); nav.Icon:SetSize(32,32); nav.Icon:ClearAllPoints(); nav.Icon:SetPoint('CENTER')
        if nav.Background then nav.Background:SetColorTexture(.13,.12,.10,1); nav.Background:ClearAllPoints(); nav.Background:SetAllPoints() end
        if nav.Mask then nav.Mask:SetTexture('Interface\\Buttons\\WHITE8X8') end
        nav.SelectedTexture:SetColorTexture(.78,.60,.30,1); nav.SelectedTexture:ClearAllPoints(); nav.SelectedTexture:SetPoint('TOPLEFT'); nav.SelectedTexture:SetSize(2,44)
        if nav.HighlightTexture then nav.HighlightTexture:SetColorTexture(.24,.21,.16,.6); nav.HighlightTexture:ClearAllPoints(); nav.HighlightTexture:SetAllPoints() end
        if nav.TabGlow then nav.TabGlow:SetTexture(nil) end
    end
end
function T.ApplyStyles()
    local palette=palettes[T.IsClassic() and 'classic' or 'modern']
    for key,color in pairs(palette) do T.colors[key]=color end
    T.fontLocale=nil; T.RefreshFonts()
    for region,tone in pairs(T.tones) do modern.Color(region,tone) end
    for frame,record in pairs(T.skins) do skin(frame,record.inset) end
    for frame in pairs(T.sections) do skin(frame,true,true) end
    for button,record in pairs(T.buttons) do applyButton(button,record) end
    for frame,record in pairs(T.windows) do applyWindow(frame,record) end
    for texture,base in pairs(T.backgrounds) do
        texture:SetAlpha(T.IsClassic() and .1 or 0)
        if T.IsClassic() then base:SetColorTexture(.12,.10,.08,1) else base:SetColorTexture(.07,.065,.055,1) end
    end
    for nav in pairs(T.tabs) do T.SideTab(nav) end
end
function T.SetStyle(style)
    if style~='classic' and style~='modern' then return false end
    F.db.settings.uiStyle=style; T.HideTooltip(); T.ApplyStyles()
    local U=F.UI
    if U.frame and U.frame:IsShown() then
        local right,left=U.details:GetVerticalScroll() or 0,U.listScroll:GetVerticalScroll() or 0
        U.Status(); U.details:SetVerticalScroll(math.min(right,U.details:GetVerticalScrollRange()))
        U.listScroll:SetVerticalScroll(math.min(left,U.listScroll:GetVerticalScrollRange()))
    else U.DataChanged() end
    F.Settings.Refresh(); F.Updates.Refresh()
    if F.Tracker.frame and F.Tracker.frame:IsShown() then F.Tracker.Render() end
    if F.ProfessionActions.panel then F.ProfessionActions.Refresh() end
    if F.Auction.panel and F.Auction.panel:IsShown() then F.Auction.Render() end
    return true
end
