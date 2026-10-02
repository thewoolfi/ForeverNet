local _,F=...
F.Settings={}
local S=F.Settings
S.githubURL='https://github.com/thewoolfi/ForeverNet'
S.supportURL='https://boosty.to/andrewwoolfi'
local function label(parent,y,text)
    local l=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    l:SetPoint('TOPLEFT',28,y); l:SetWidth(470); l:SetJustifyH('LEFT'); l:SetText(text); return l
end
function S.Refresh()
    if not S.frame then return end
    S.frame:SetTitle('ForeverNet - '..F.L('SETTINGS'))
    for _,check in ipairs(S.checks) do
        check:SetChecked(F.db.settings[check.key]~=false)
        if check.key=='sharing' then check:SetChecked(not not F.db.settings.sharing) end
        check.label:SetText(F.L(check.locale))
    end
    S.languageLabel:SetText(F.L('LANGUAGE'))
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
    S.about:SetText(F.L('ABOUT')..'\nForeverNet '..F.version..'\n'..F.L('AUTHOR')..'Andrew Woolfi\n\n'..F.L('ABOUT_TEXT'))
end
function S.Open()
    if not S.frame then
        local frame=CreateFrame('Frame','ForeverNetSettings',UIParent,'PortraitFrameTemplate')
        frame:SetSize(530,730); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN_DIALOG')
        frame:SetPortraitToAsset('Interface\\Icons\\Trade_Engineering')
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
        -- Keep the entire settings window above every child of the main window.
        -- The native portrait template supplies borders, but not an opaque body.
        local background=frame:CreateTexture(nil,'BACKGROUND',nil,1)
        background:SetPoint('TOPLEFT',6,-30); background:SetPoint('BOTTOMRIGHT',-6,6)
        background:SetColorTexture(.075,.055,.035,1)
        S.background=background
        S.frame=frame; S.checks={}
        local choices={{'sharing','SETTING_SHARE'},{'autoBank','SETTING_AUTOBANK'},{'useBank','SETTING_USEBANK'},{'showMinimap','SETTING_MINIMAP'},{'autoSync','SETTING_AUTOSYNC'}}
        for i,choice in ipairs(choices) do
            local check=CreateFrame('CheckButton',nil,frame,'UICheckButtonTemplate')
            check:SetSize(28,28); check:SetPoint('TOPLEFT',24,-55-(i-1)*34)
            check.key,check.locale=choice[1],choice[2]
            check.label=check:CreateFontString(nil,'OVERLAY','GameFontHighlight'); check.label:SetPoint('LEFT',check,'RIGHT',4,0)
            check.label:SetWidth(435); check.label:SetJustifyH('LEFT')
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
        S.intervalLabel=label(frame,-239,''); S.intervalLabel:SetWidth(180)
        S.intervals={}
        for i,seconds in ipairs({60,120,300}) do
            local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
            b:SetSize(85,24); b:SetPoint('TOPLEFT',221+(i-1)*94,-235)
            b:SetScript('OnClick',function() F.db.settings.syncInterval=seconds; F.Net.autoElapsed=0; S.Refresh() end)
            S.intervals[seconds]=b
        end
        S.languageLabel=label(frame,-278,'')
        S.languages={}
        for i,locale in ipairs({'auto','ruRU','enUS'}) do
            local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
            S.languages[locale]=b
            b:SetSize(145,24); b:SetPoint('TOPLEFT',28+(i-1)*157,-303)
            b:SetText(locale=='auto' and 'Auto' or locale=='ruRU' and 'Русский' or 'English')
            b:SetScript('OnClick',function() F.db.settings.locale=locale~='auto' and locale or nil; S.Refresh(); F.UI.DataChanged() end)
        end
        S.bank=label(frame,-348,''); S.bank:SetHeight(36)
        S.about=label(frame,-396,''); S.about:SetHeight(140)
        S.githubLabel=label(frame,-552,'')
        S.supportLabel=label(frame,-612,'')
        local function linkField(url,y)
            local field=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
            field:SetSize(464,24); field:SetPoint('TOPLEFT',33,y)
            field:SetAutoFocus(false); field:SetFontObject('GameFontHighlightSmall'); field:SetText(url)
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
        S.linkHint=label(frame,-672,''); S.linkHint:SetHeight(36)
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetSettings'
    end
    S.Refresh(); S.frame:Show()
end
