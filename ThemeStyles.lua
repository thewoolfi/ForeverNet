local _,F=...
local T=F.Theme
local function registry() return setmetatable({},{__mode='k'}) end
T.buttons,T.windows,T.skins,T.sections,T.backgrounds,T.tabs,T.tones=registry(),registry(),registry(),registry(),registry(),registry(),registry()
local modern={Button=T.Button,Title=T.Title,Skin=T.Skin,Section=T.Section,Background=T.Background,Color=T.Color}
local palettes={
    modern={text={.92,.91,.87},heading={.96,.94,.88},muted={.72,.70,.66},good={.45,.90,.48},missing={1,.66,.28},blueprint={.82,.62,1}},
    classic={text={.90,.88,.83},heading={1,.82,.22},muted={.72,.69,.63},good={.45,.90,.48},missing={1,.66,.28},blueprint={.82,.62,1}},
    neon={text={.92,.96,1.0},heading={.0,.90,1.0},muted={.48,.62,.78},good={.0,.95,.62},missing={1.0,.45,.20},blueprint={.65,.50,1.0}}
}
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
    if not saved.atlas and saved.coords and region.SetTexCoord then region:SetTexCoord(unpack(saved.coords)) end
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
    local style=T.Style()
    local classic=style=='classic'
    local neon=style=='neon'
    button.flatFill:SetShown(not classic); button.flatEdge:SetShown(not classic)
    for region,saved in pairs(record.parts) do region:SetShown(classic and saved or false) end
    for region,saved in pairs(record.textures) do
        if classic then restore(region,saved)
        elseif button.GetHighlightTexture and region==button:GetHighlightTexture() then
            if neon then
                region:SetColorTexture(.20,.65,1.0,.30)
            else
                region:SetColorTexture(.35,.31,.24,.45)
            end
            region:ClearAllPoints(); region:SetAllPoints()
        else region:SetAlpha(0) end
    end
    if neon then
        button.flatFill:SetColorTexture(0.040, 0.065, 0.105, 1)
        button.flatEdge:SetColorTexture(0.120, 0.180, 0.260, 0.95)
    elseif not classic then
        button.flatFill:SetColorTexture(.18,.165,.14,1)
        button.flatEdge:SetColorTexture(.38,.32,.23,1)
    end
    for _,state in ipairs({'Normal','Highlight','Disabled'}) do
        local font=button['Get'..state..'FontObject'](button)
        local color=state=='Disabled' and T.colors.muted or classic and state=='Normal' and T.colors.heading or (neon and state=='Highlight' and {.40,.80,1.0}) or T.colors.text
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
        local setText=button.SetText
        button.SetText=function(self,value)
            setText(self,value)
            if self:GetWidth()>0 then T.FitButton(self,self:GetWidth()) end
        end
    end
    applyButton(button,record)
end
local function skin(frame,inset,section)
    local style=T.Style()
    if style=='classic' then
        frame:SetBackdrop({bgFile='Interface\\ChatFrame\\ChatFrameBackground',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
            tile=false,edgeSize=section and 10 or 16,insets={left=4,right=4,top=4,bottom=4}})
        frame:SetBackdropColor(section and .15 or inset and .09 or .105,section and .09 or inset and .075 or .087,section and .035 or inset and .06 or .070,1)
        frame:SetBackdropBorderColor(.50,.35,.14,1)
        return
    end
    if style=='neon' then
        frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',
            tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
        if section then
            frame:SetBackdropColor(0.047, 0.070, 0.114, 0.98)
            frame:SetBackdropBorderColor(0.106, 0.153, 0.220, 0.85)
        elseif inset then
            frame:SetBackdropColor(0.035, 0.055, 0.090, 0.98)
            frame:SetBackdropBorderColor(0.082, 0.125, 0.180, 0.80)
        else
            frame:SetBackdropColor(0.043, 0.065, 0.105, 0.98)
            frame:SetBackdropBorderColor(0.094, 0.145, 0.210, 0.85)
        end
        if frame.neonStripe then frame.neonStripe:Hide() end
        return
    end
    if frame.neonStripe then frame.neonStripe:Hide() end
    if style=='classic' and frame.neonStripe then frame.neonStripe:Hide() end
    modern.Skin(frame,inset)
    if section then frame:SetBackdropBorderColor(.22,.20,.17,1) end
end
function T.Skin(frame,inset) T.skins[frame]={inset=inset}; T.sections[frame]=nil; skin(frame,inset) end
function T.Section(frame) T.sections[frame]=true; T.skins[frame]=nil; skin(frame,true,true) end
local function applyWindow(frame,record)
    local style=T.Style()
    local classic=style=='classic'
    local neon=style=='neon'
    if classic then
        frame.flatChrome:Hide(); frame.flatBase:Hide(); frame.brandIcon:Hide()
        for region,shown in pairs(record.parts) do region:SetShown(shown) end
        for region,saved in pairs(record.close) do restore(region,saved) end
        if frame.CloseButton.flatText then frame.CloseButton.flatText:Hide() end
        if frame.headerDivider then frame.headerDivider:Hide() end
        if frame.neonGlowBeam then frame.neonGlowBeam:Hide() end
        if frame.neonGlowSpread then frame.neonGlowSpread:Hide() end
        local U = F.UI
        if U and frame == U.frame and U.footerBar then
            U.footerBar:Hide()
            if U.commands then U.commands:ClearAllPoints(); U.commands:SetPoint('TOPLEFT', frame, 'TOPLEFT', 490, -535) end
            if U.help then U.help:ClearAllPoints(); U.help:SetPoint('TOPLEFT', frame, 'TOPLEFT', 614, -535) end
            if U.footer then U.footer:ClearAllPoints(); U.footer:SetPoint('TOPLEFT', frame, 'TOPLEFT', 24, -535) end
        end
        local title=frame:GetTitleText()
        if not restorePoints(title,record.points) then title:ClearAllPoints(); title:SetPoint('CENTER',frame.TitleContainer,'CENTER') end
        title:SetWidth(record.width and record.width>0 and record.width or frame:GetWidth()-100); title:SetJustifyH('CENTER'); T.Color(title,'heading')
        return
    end
    modern.Title(frame)
    for region in pairs(record.parts) do region:Hide() end
    for region in pairs(record.close) do region:SetAlpha(0) end
    local U = F.UI
    local isMainNeon = neon and ((U and frame == U.frame) or (frame.GetName and frame:GetName() == 'ForeverNetWindow'))
    frame.flatChrome:Show(); frame.flatBase:Show()
    if isMainNeon then
        frame.brandIcon:Hide()
    else
        frame.brandIcon:Show()
    end
    if frame.CloseButton.flatText then frame.CloseButton.flatText:Show() end
    local title=frame:GetTitleText()
    if isMainNeon then
        title:Hide()
    else
        title:Show()
        title:ClearAllPoints(); title:SetPoint('TOPLEFT',frame,'TOPLEFT',46,-13); title:SetJustifyH('LEFT')
        title:SetWidth(frame:GetWidth()-92)
    end
    if neon then
        frame.flatChrome:SetBackdropColor(0,0,0,0)
        frame.flatChrome:SetBackdropBorderColor(0.082, 0.125, 0.180, 0.95)
        frame.flatBase:SetColorTexture(0.024, 0.035, 0.055, 1)
        if frame.CloseButton.flatText then frame.CloseButton.flatText:SetTextColor(0.0, 0.95, 1.0, 1) end
        if frame.CloseButton then
            frame.CloseButton:ClearAllPoints()
            frame.CloseButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -12, -12)
            frame.CloseButton:SetSize(22, 22)
        end
        T.Color(title,'heading')

        if not frame.neonGlowBeam then
            local beam = frame:CreateTexture(nil,'BORDER',nil,2)
            beam:SetHeight(1)
            frame.neonGlowBeam = beam
        end
        frame.neonGlowBeam:SetHeight(1)
        frame.neonGlowBeam:SetColorTexture(0.0, 0.80, 1.0, 0.75)
        frame.neonGlowBeam:ClearAllPoints()
        if isMainNeon then
            frame.neonGlowBeam:SetPoint('TOPLEFT', 205, -50)
            frame.neonGlowBeam:SetPoint('TOPRIGHT', -12, -50)
        else
            frame.neonGlowBeam:SetPoint('TOPLEFT', 10, -38)
            frame.neonGlowBeam:SetPoint('TOPRIGHT', -10, -38)
        end
        frame.neonGlowBeam:Show()

        if frame.neonGlowSpread then frame.neonGlowSpread:Hide() end
        if frame.headerDivider then frame.headerDivider:Hide() end

        -- EllesmereUI Docked Bottom Footer on main window
        if U and frame == U.frame then
            if not U.footerBar then
                local fb = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
                fb:SetPoint('BOTTOMLEFT', 0, 0); fb:SetPoint('BOTTOMRIGHT', 0, 0); fb:SetHeight(36)
                fb:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8', edgeFile='Interface\\Buttons\\WHITE8X8', tile=false, edgeSize=1, insets={left=0,right=0,top=1,bottom=0}})
                local topLine = fb:CreateTexture(nil, 'OVERLAY')
                topLine:SetPoint('TOPLEFT', 0, 0); topLine:SetPoint('TOPRIGHT', 0, 0); topLine:SetHeight(1)
                topLine:SetColorTexture(0.082, 0.125, 0.180, 0.9)
                fb.topLine = topLine
                U.footerBar = fb
            end
            if U.footerBar.topLine then U.footerBar.topLine:SetColorTexture(0.082, 0.125, 0.180, 0.9) end
            U.footerBar:SetBackdropColor(0.024, 0.035, 0.055, 1)
            U.footerBar:SetBackdropBorderColor(0.082, 0.125, 0.180, 0.9)
            U.footerBar:Show()
            if U.commands then
                U.commands:ClearAllPoints(); U.commands:SetPoint('BOTTOMRIGHT', U.footerBar, 'BOTTOMRIGHT', -130, 6)
            end
            if U.help then
                U.help:ClearAllPoints(); U.help:SetPoint('BOTTOMRIGHT', U.footerBar, 'BOTTOMRIGHT', -16, 6)
            end
            if U.footer then
                U.footer:ClearAllPoints(); U.footer:SetPoint('BOTTOMLEFT', U.footerBar, 'BOTTOMLEFT', 205, 10)
            end
        end
    else
        if frame.neonGlowBeam then frame.neonGlowBeam:Hide() end
        if frame.neonGlowSpread then frame.neonGlowSpread:Hide() end
        if frame.headerDivider then frame.headerDivider:Hide() end
        frame.flatChrome:SetBackdropColor(0,0,0,0)
        frame.flatChrome:SetBackdropBorderColor(.25,.225,.185,1)
        frame.flatBase:SetColorTexture(.07,.065,.055,1)
        if frame.CloseButton.flatText then frame.CloseButton.flatText:SetTextColor(1,1,1,1) end
        T.Color(title,'text')

        local U = F.UI
        if U and frame == U.frame and U.footerBar then
            U.footerBar:Hide()
            if U.commands then
                U.commands:ClearAllPoints(); U.commands:SetPoint('TOPLEFT', frame, 'TOPLEFT', 490, -535)
            end
            if U.help then
                U.help:ClearAllPoints(); U.help:SetPoint('TOPLEFT', frame, 'TOPLEFT', 614, -535)
            end
            if U.footer then
                U.footer:ClearAllPoints(); U.footer:SetPoint('TOPLEFT', frame, 'TOPLEFT', 24, -535)
            end
        end
    end
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
    local style=T.Style()
    if style=='classic' then
        texture:SetAlpha(.1); base:SetColorTexture(.12,.10,.08,1)
    elseif style=='neon' then
        texture:SetAlpha(0); base:SetColorTexture(0.016, 0.026, 0.048, 1)
    end
    return texture,base
end
function T.Color(region,tone) T.tones[region]=tone or 'text'; modern.Color(region,tone) end
function T.SideTab(nav)
    local record=T.tabs[nav]
    if not record then
        local icon = nav.iconPath or (nav.Icon and nav.Icon:GetTexture())
        record={width=nav:GetWidth(),height=nav:GetHeight(),icon=icon,regions={}}
        for _,name in ipairs({'Background','SelectedTexture','HighlightTexture','TabGlow'}) do
            if nav[name] then record.regions[nav[name]]=snapshot(nav[name]) end
        end
        T.tabs[nav]=record
    end
    local style=T.Style()
    if style=='classic' then
        nav:SetSize(record.width or 60,record.height or 48)
        for region,saved in pairs(record.regions) do restore(region,saved) end
        if nav.flatTabBorder then nav.flatTabBorder:Hide() end
        if nav.Icon and nav.Mask and nav.Icon.AddMaskTexture then pcall(nav.Icon.AddMaskTexture,nav.Icon,nav.Mask) end
        if nav.Icon then
            if record.icon then nav.Icon:SetTexture(record.icon) end
            nav.Icon:ClearAllPoints(); nav.Icon:SetPoint('CENTER',-3,0)
            nav.Icon:SetSize(40,40); nav.Icon:SetTexCoord(0.03125,0.96875,0.03125,0.96875)
            nav.Icon:SetAlpha(1); nav.Icon:Show()
        end
    else
        nav:SetSize(44,44)
        if nav.Icon and nav.Mask and nav.Icon.RemoveMaskTexture then pcall(nav.Icon.RemoveMaskTexture,nav.Icon,nav.Mask) end
        if nav.Icon then
            if record.icon then nav.Icon:SetTexture(record.icon) end
            nav.Icon:ClearAllPoints(); nav.Icon:SetPoint('CENTER',0,0)
            nav.Icon:SetSize(32,32); nav.Icon:SetTexCoord(0.03125,0.96875,0.03125,0.96875)
            nav.Icon:SetAlpha(1); nav.Icon:Show()
        end
        if style=='neon' then
            if nav.Background then nav.Background:SetColorTexture(0.018, 0.030, 0.055, 1); nav.Background:ClearAllPoints(); nav.Background:SetAllPoints() end
            if nav.SelectedTexture then
                nav.SelectedTexture:SetColorTexture(0.0, 0.90, 1.0, 1)
                nav.SelectedTexture:ClearAllPoints(); nav.SelectedTexture:SetPoint('TOPLEFT'); nav.SelectedTexture:SetSize(4,44)
            end
            if nav.HighlightTexture then nav.HighlightTexture:SetColorTexture(0.0, 0.85, 1.0, 0.25); nav.HighlightTexture:ClearAllPoints(); nav.HighlightTexture:SetAllPoints() end
            if nav.TabGlow then nav.TabGlow:SetTexture(nil) end
            if not nav.flatTabBorder then
                local b = CreateFrame('Frame',nil,nav,'BackdropTemplate')
                b:SetAllPoints(); b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
                b:SetBackdropColor(0,0,0,0)
                nav.flatTabBorder = b
            end
            nav.flatTabBorder:Show()
            nav.flatTabBorder:SetBackdropBorderColor(0.06, 0.45, 0.75, 1)

            if not nav.neonActiveGlow then
                local glow = nav:CreateTexture(nil, 'BORDER', nil, 3)
                glow:SetPoint('TOPLEFT', 4, 0); glow:SetPoint('BOTTOMLEFT', 16, 0); glow:SetWidth(12)
                glow:SetColorTexture(0.0, 0.85, 1.0, 0.16)
                nav.neonActiveGlow = glow
            end
            nav.neonActiveGlow:Show()
        else
            if nav.neonActiveGlow then nav.neonActiveGlow:Hide() end
            if nav.flatTabBorder then nav.flatTabBorder:Hide() end
            if nav.Background then nav.Background:SetColorTexture(.13,.12,.10,1); nav.Background:ClearAllPoints(); nav.Background:SetAllPoints() end
            if nav.SelectedTexture then
                nav.SelectedTexture:SetColorTexture(.78,.60,.30,1)
                nav.SelectedTexture:ClearAllPoints(); nav.SelectedTexture:SetPoint('TOPLEFT'); nav.SelectedTexture:SetSize(2,44)
            end
            if nav.HighlightTexture then nav.HighlightTexture:SetColorTexture(.24,.21,.16,.6); nav.HighlightTexture:ClearAllPoints(); nav.HighlightTexture:SetAllPoints() end
            if nav.TabGlow then nav.TabGlow:SetTexture(nil) end
        end
    end
end
function T.ApplyStyles()
    local style=T.Style()
    local palette=palettes[style] or palettes.modern
    for key,color in pairs(palette) do T.colors[key]=color end
    T.fontLocale=nil; T.RefreshFonts()
    for region,tone in pairs(T.tones) do modern.Color(region,tone) end
    for frame,record in pairs(T.skins) do skin(frame,record.inset) end
    for frame in pairs(T.sections) do skin(frame,true,true) end
    for button,record in pairs(T.buttons) do applyButton(button,record) end
    for frame,record in pairs(T.windows) do applyWindow(frame,record) end
    for texture,base in pairs(T.backgrounds) do
        if style=='classic' then
            texture:SetAlpha(.1); base:SetColorTexture(.12,.10,.08,1)
        elseif style=='neon' then
            texture:SetAlpha(0); base:SetColorTexture(.06,.08,.13,1)
        else
            texture:SetAlpha(0); base:SetColorTexture(.07,.065,.055,1)
        end
    end
    for nav in pairs(T.tabs) do T.SideTab(nav) end
    if F.Settings and F.Settings.checks then for _,check in ipairs(F.Settings.checks) do if check.UpdateVisual then check:UpdateVisual() end end end
end
function T.SetStyle(style)
    if style~='classic' and style~='modern' and style~='neon' then return false end
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
    if F.LootAdvisor and F.LootAdvisor.frame and F.LootAdvisor.frame:IsShown() then F.LootAdvisor.Render() end
    if F.Settings.RefreshBlizzPanels then F.Settings.RefreshBlizzPanels() end
    return true
end
