local _,F=...
F.Settings={}
local S=F.Settings
S.githubURL='https://github.com/thewoolfi/ForeverNet'
S.supportURL='https://boosty.to/andrewwoolfi'
local function label(parent,y,text)
    local l=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    l:SetPoint('TOPLEFT',8,y); l:SetWidth(454); l:SetJustifyH('LEFT'); l:SetWordWrap(true); l:SetText(text); F.Theme.Text(l,false,14); return l
end
function S.Layout()
    local y=4
    S.scroll:ClearAllPoints(); S.scroll:SetPoint('TOPLEFT',20,F.Theme.IsClassic() and -58 or -48); S.scroll:SetPoint('BOTTOMRIGHT',-34,18)
    local function place(region,x,gap)
        region:ClearAllPoints(); region:SetPoint('TOPLEFT',x,-y)
        region:SetHeight(0); y=y+region:GetStringHeight()+(gap or 8)
    end
    S.styleLabel:ClearAllPoints(); S.styleLabel:SetPoint('TOPLEFT',8,-y); S.styleLabel:SetWidth(140); S.styleLabel:SetHeight(0)
    local styleHeight=S.styleLabel:GetStringHeight()
    for i,style in ipairs({'modern','classic'}) do
        local b=S.styles[style]; b:ClearAllPoints(); b:SetPoint('TOPLEFT',160+(i-1)*154,-y)
        styleHeight=math.max(styleHeight,F.Theme.FitButton(b,146))
    end
    y=y+styleHeight+14
    for _,check in ipairs(S.checks) do
        check:ClearAllPoints(); check:SetPoint('TOPLEFT',4,-y)
        check.label:SetHeight(0)
        y=y+math.max(28,check.label:GetStringHeight()+4)+2
    end
    local intervalWidth=math.min(172,math.max(110,math.ceil(S.intervalLabel:GetUnboundedStringWidth())))
    S.intervalLabel:SetWidth(intervalWidth); S.intervalLabel:SetHeight(0)
    S.intervalLabel:ClearAllPoints(); S.intervalLabel:SetPoint('TOPLEFT',8,-(y+4))
    local buttonWidth=(454-intervalWidth-28)/3
    local height=0
    for i,seconds in ipairs({60,120,300}) do
        local b=S.intervals[seconds]; b:ClearAllPoints(); b:SetPoint('TOPLEFT',20+intervalWidth+(i-1)*(buttonWidth+8),-y)
        height=math.max(height,F.Theme.FitButton(b,buttonWidth))
    end
    y=y+math.max(height,S.intervalLabel:GetStringHeight()+4)+10
    local languageWidth=math.min(160,math.max(92,math.ceil(S.languageLabel:GetUnboundedStringWidth())))
    S.languageLabel:SetWidth(languageWidth); S.languageLabel:SetHeight(0)
    S.languageLabel:ClearAllPoints(); S.languageLabel:SetPoint('TOPLEFT',8,-(y+4))
    S.languageButton:ClearAllPoints(); S.languageButton:SetPoint('TOPLEFT',20+languageWidth,-y)
    height=F.Theme.FitButton(S.languageButton,442-languageWidth)
    y=y+math.max(height,S.languageLabel:GetStringHeight()+4)+8
    local menuY=9; local order={'auto'}
    for _,locale in ipairs(F.LocaleOrder) do order[#order+1]=locale end
    for first=1,#order,3 do
        local rowHeight=0
        for i=first,math.min(first+2,#order) do
            local b=S.languages[order[i]]; b:ClearAllPoints(); b:SetPoint('TOPLEFT',6+(i-first)*150,-menuY)
            rowHeight=math.max(rowHeight,F.Theme.FitButton(b,142))
        end
        menuY=menuY+rowHeight+4
    end
    S.languageMenu:SetHeight(menuY+5)
    S.languageMenu:ClearAllPoints(); S.languageMenu:SetPoint('TOPLEFT',8,-y)
    if S.languageMenu:IsShown() then y=y+S.languageMenu:GetHeight()+8 end
    place(S.bank,8,10)
    S.updates:ClearAllPoints(); S.updates:SetPoint('TOPLEFT',8,-y)
    y=y+F.Theme.FitButton(S.updates,454)+12
    place(S.about,8,12)
    place(S.githubLabel,8,5)
    S.githubLink:ClearAllPoints(); S.githubLink:SetPoint('TOPLEFT',13,-y); y=y+30
    place(S.supportLabel,8,5)
    S.supportLink:ClearAllPoints(); S.supportLink:SetPoint('TOPLEFT',13,-y); y=y+30
    place(S.linkHint,8,12); S.body:SetHeight(y)
end
function S.Refresh()
    if not S.frame then return end
    F.Theme.RefreshFonts()
    S.frame:SetTitle('ForeverNet - '..F.L('SETTINGS'))
    S.styleLabel:SetText(F.L('SETTING_STYLE'))
    for style,b in pairs(S.styles) do
        b:SetText(F.L(style=='modern' and 'STYLE_MODERN' or 'STYLE_CLASSIC'))
        b:SetEnabled(style~=F.db.settings.uiStyle)
    end
    for _,check in ipairs(S.checks) do
        check:SetChecked(F.db.settings[check.key]~=false)
        if check.key=='sharing' then check:SetChecked(not not F.db.settings.sharing) end
        check.label:SetText(F.L(check.locale))
    end
    S.languageLabel:SetText(F.L('LANGUAGE'))
    S.languageButton:SetText(F.db.settings.locale and F.LocaleNames[F.db.settings.locale] or F.L('LANG_AUTO'))
    S.intervalLabel:SetText(F.L('SYNC_INTERVAL'))
    for seconds,b in pairs(S.intervals) do
        b:SetText(string.format(F.L('SYNC_MINUTES'),seconds/60))
        b:SetEnabled(F.Net.AutoEnabled() and seconds~=F.Net.Interval())
    end
    for locale,b in pairs(S.languages or {}) do b:SetEnabled(locale~=(F.db.settings.locale or 'auto')) end
    S.bank:SetText(F.Bank.Status())
    S.githubLabel:SetText(F.L('PROJECT_GITHUB'))
    S.supportLabel:SetText(F.L('SUPPORT_BOOSTY'))
    S.linkHint:SetText(F.L('COPY_LINK_HINT'))
    S.about:SetText('ForeverNet '..F.version..'  /  Andrew Woolfi')
    S.updates:SetText(F.L('ADDON_UPDATES'))
    S.languages.auto:SetText(F.L('LANG_AUTO'))
    S.Layout()
end
function S.Open()
    if not S.frame then
        local frame=CreateFrame('Frame','ForeverNetSettings',UIParent,'PortraitFrameTemplate')
        frame:SetSize(530,600); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN_DIALOG'); frame:SetClampedToScreen(true)
        frame:SetPortraitToAsset(F.icon)
        F.Theme.Title(frame)
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
        -- Keep the entire settings window above every child of the main window.
        -- The native portrait template supplies borders, but not an opaque body.
        S.background,S.backgroundBase=F.Theme.Background(frame)
        S.frame=frame; S.checks={}
        S.scroll=F.Theme.ScrollFrame(frame)
        S.scroll:SetPoint('TOPLEFT',20,-48); S.scroll:SetPoint('BOTTOMRIGHT',-34,18)
        S.body=CreateFrame('Frame',nil,S.scroll); S.body:SetSize(470,540); S.scroll:SetScrollChild(S.body)
        -- Controls live in a measured scrolling body, separate from the native border.
        local content=S.body
        S.styleLabel=label(content,0,''); S.styles={}
        for _,style in ipairs({'modern','classic'}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate'); b:SetSize(146,24); F.Theme.Button(b)
            b:SetScript('OnClick',function() F.Theme.SetStyle(style) end); S.styles[style]=b
        end
        local choices={{'sharing','SETTING_SHARE'},{'autoBank','SETTING_AUTOBANK'},{'useBank','SETTING_USEBANK'},{'showMinimap','SETTING_MINIMAP'},{'autoSync','SETTING_AUTOSYNC'},{'autoScan','SETTING_AUTOSCAN'},{'autoSources','SETTING_AUTOSOURCES'}}
        for i,choice in ipairs(choices) do
            local check=CreateFrame('CheckButton',nil,content,'UICheckButtonTemplate')
            check:SetSize(28,28); check:SetPoint('TOPLEFT',24,-55-(i-1)*34)
            check.key,check.locale=choice[1],choice[2]
            check.label=check:CreateFontString(nil,'OVERLAY','GameFontHighlight'); check.label:SetPoint('TOPLEFT',check,'TOPRIGHT',4,-5)
            check.label:SetWidth(426); check.label:SetJustifyH('LEFT'); check.label:SetWordWrap(true)
            F.Theme.Text(check.label,false,14)
            if check.key=='autoSources' or check.key=='autoScan' then
                check:SetScript('OnEnter',function(self) F.Theme.ShowTooltip(self,F.L(self.locale),F.L(self.key=='autoSources' and 'SOURCE_COST_HELP' or 'SCAN_HINT')) end)
                check:SetScript('OnLeave',F.Theme.HideTooltip)
            end
            check:SetScript('OnClick',function(self)
                F.db.settings[self.key]=not not self:GetChecked()
                if self.key=='sharing' and not self:GetChecked() then F.Net.queue,F.Net.buffers={},{} end
                if self.key=='showMinimap' then F.Minimap.ApplyVisibility() end
                if self.key=='autoBank' and self:GetChecked() and F.Bank.open then F.Bank.Event('BANKFRAME_OPENED') end
                if self.key=='autoSync' then
                    F.Net.pendingSync,F.Net.pendingPublish,F.Net.autoElapsed=nil,nil,0
                    if self:GetChecked() then F.Net.ScheduleSync() end
                end
                F.UI.DataChanged(); S.Refresh()
            end)
            S.checks[i]=check
        end
        S.intervalLabel=label(content,-239,'')
        S.intervals={}
        for i,seconds in ipairs({60,120,300}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate')
            b:SetSize(85,24); b:SetPoint('TOPLEFT',221+(i-1)*94,-235)
            F.Theme.Button(b)
            b:SetScript('OnClick',function() F.db.settings.syncInterval=seconds; F.Net.autoElapsed=0; S.Refresh() end)
            S.intervals[seconds]=b
        end
        S.languageLabel=label(content,-278,'')
        S.languageButton=CreateFrame('Button',nil,content,'UIPanelButtonTemplate')
        S.languageButton:SetSize(470,24); S.languageButton:SetPoint('TOPLEFT',28,-303)
        F.Theme.Button(S.languageButton)
        S.languageMenu=CreateFrame('Frame',nil,content,'BackdropTemplate')
        S.languageMenu:SetPoint('TOPLEFT',8,-331); S.languageMenu:SetSize(454,154)
        S.languageMenu:SetFrameLevel(frame:GetFrameLevel()+20)
        F.Theme.Skin(S.languageMenu)
        S.languageMenu:Hide()
        S.languageButton:SetScript('OnClick',function() S.languageMenu:SetShown(not S.languageMenu:IsShown()); S.Layout() end)
        S.languages={}; local locales={'auto'}
        for _,locale in ipairs(F.LocaleOrder) do locales[#locales+1]=locale end
        for i,locale in ipairs(locales) do
            local b=CreateFrame('Button',nil,S.languageMenu,'UIPanelButtonTemplate')
            S.languages[locale]=b
            b:SetSize(142,24); b:SetPoint('TOPLEFT',6+((i-1)%3)*150,-9-math.floor((i-1)/3)*28)
            b:SetText(locale=='auto' and 'Auto' or F.LocaleNames[locale])
            F.Theme.Button(b,F.Theme.fontFiles[locale] and locale or nil)
            b:SetScript('OnClick',function()
                F.db.settings.locale=locale~='auto' and locale or nil
                S.languageMenu:Hide(); S.Refresh(); F.Updates.Refresh()
                if F.UI.frame and F.UI.frame:IsShown() then F.UI.Status() else F.UI.DataChanged() end
            end)
        end
        S.bank=label(content,-348,'')
        S.about=label(content,-396,'')
        S.updates=CreateFrame('Button',nil,content,'UIPanelButtonTemplate')
        S.updates:SetSize(195,26); S.updates:SetPoint('TOPLEFT',307,-395)
        F.Theme.Button(S.updates)
        S.updates:SetScript('OnClick',function() F.Updates.Open() end)
        S.githubLabel=label(content,-552,'')
        S.supportLabel=label(content,-612,'')
        local function linkField(url,y)
            local field=CreateFrame('EditBox',nil,content,'InputBoxTemplate')
            field:SetSize(444,24); field:SetPoint('TOPLEFT',13,y)
            field:SetAutoFocus(false); field:SetFontObject('GameFontHighlightSmall'); field:SetText(url)
            F.Theme.Font(field,12)
            field:SetScript('OnEditFocusGained',function(self) self:HighlightText() end)
            field:SetScript('OnMouseUp',function(self) self:SetFocus(); self:HighlightText() end)
            field:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
            field:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
            field:SetScript('OnTextChanged',function(self)
                if self:GetText()~=url then self:SetText(url); self:HighlightText() end
            end)
            return field
        end
        S.githubLink=linkField(S.githubURL,-574)
        S.supportLink=linkField(S.supportURL,-634)
        S.linkHint=label(content,-672,'')
        frame:SetScript('OnHide',function() S.languageMenu:Hide(); F.Theme.HideTooltip() end)
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetSettings'
    end
    S.languageMenu:Hide(); S.Refresh(); S.scroll:SetVerticalScroll(0); S.frame:Show()
end
