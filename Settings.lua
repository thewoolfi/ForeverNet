local _,F=...
F.Settings={}
local S=F.Settings
S.githubURL='https://github.com/thewoolfi/ForeverNet'
S.supportURL='https://boosty.to/andrewwoolfi'
local function label(parent,y,text,size,tone)
    local l=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    l:SetPoint('TOPLEFT',8,y); l:SetWidth(454); l:SetJustifyH('LEFT'); l:SetWordWrap(true); l:SetText(text)
    F.Theme.Text(l,false,size or 14)
    if tone then F.Theme.Color(l,tone) end
    return l
end
local function skinCheck(check)
    if check.toggleTrack then return end
    local track=check:CreateTexture(nil,'BACKGROUND',nil,1)
    track:SetSize(36,18); track:SetPoint('LEFT',2,0)
    check.toggleTrack=track

    local trackBorder=check:CreateTexture(nil,'BORDER',nil,1)
    trackBorder:SetSize(38,20); trackBorder:SetPoint('CENTER',track,'CENTER',0,0)
    check.toggleTrackBorder=trackBorder

    local thumb=check:CreateTexture(nil,'ARTWORK',nil,2)
    thumb:SetSize(14,14)
    check.toggleThumb=thumb

    local function updateVisual()
        local style=F.Theme.Style()
        if style~='neon' then
            track:Hide(); trackBorder:Hide(); thumb:Hide()
            if check.GetNormalTexture and check:GetNormalTexture() then check:GetNormalTexture():SetAlpha(1) end
            if check.GetCheckedTexture and check:GetCheckedTexture() then check:GetCheckedTexture():SetAlpha(1) end
            if check.label then
                check.label:ClearAllPoints(); check.label:SetPoint('TOPLEFT',check,'TOPRIGHT',4,-5)
                check.label:SetWidth(426)
            end
            return
        end

        track:Show(); trackBorder:Show(); thumb:Show()
        if check.GetNormalTexture and check:GetNormalTexture() then check:GetNormalTexture():SetAlpha(0) end
        if check.GetCheckedTexture and check:GetCheckedTexture() then check:GetCheckedTexture():SetAlpha(0) end
        if check.GetHighlightTexture and check:GetHighlightTexture() then check:GetHighlightTexture():SetAlpha(0) end
        if check.label then
            check.label:ClearAllPoints(); check.label:SetPoint('TOPLEFT',check,'TOPLEFT',46,-2)
            check.label:SetWidth(400)
        end

        local checked=check:GetChecked()
        if checked then
            trackBorder:SetColorTexture(0.20,0.75,1.0,0.9)
            track:SetColorTexture(0.08,0.45,0.75,1)
            thumb:SetColorTexture(1,1,1,1)
            thumb:ClearAllPoints(); thumb:SetPoint('RIGHT',track,'RIGHT',-2,0)
        else
            trackBorder:SetColorTexture(0.20,0.28,0.40,0.8)
            track:SetColorTexture(0.08,0.11,0.17,1)
            thumb:SetColorTexture(0.45,0.55,0.68,1)
            thumb:ClearAllPoints(); thumb:SetPoint('LEFT',track,'LEFT',2,0)
        end
    end
    check.UpdateVisual=updateVisual
    check:HookScript('OnClick',updateVisual)
    updateVisual()
end
function S.Layout()
    local y=8
    S.scroll:ClearAllPoints(); S.scroll:SetPoint('TOPLEFT',20,F.Theme.IsClassic() and -58 or -48); S.scroll:SetPoint('BOTTOMRIGHT',-34,44)
    local function place(region,x,gap)
        region:ClearAllPoints(); region:SetPoint('TOPLEFT',x,-y)
        region:SetHeight(0); y=y+region:GetStringHeight()+(gap or 8)
    end

    local styleTop=y
    if S.sectionStyle then place(S.sectionStyle,8,3) end
    if S.subStyle then place(S.subStyle,8,8) end
    local styleLabelWidth=math.min(130,math.max(90,math.ceil(S.styleLabel:GetUnboundedStringWidth())))
    S.styleLabel:SetWidth(styleLabelWidth); S.styleLabel:SetHeight(0)
    S.styleLabel:ClearAllPoints(); S.styleLabel:SetPoint('TOPLEFT',8,-(y+4))
    local bWidth=(446-styleLabelWidth-20)/3
    local styleHeight=S.styleLabel:GetStringHeight()
    for i,style in ipairs({'modern','classic','neon'}) do
        local b=S.styles[style]
        if b then
            b:ClearAllPoints(); b:SetPoint('TOPLEFT',16+styleLabelWidth+(i-1)*(bWidth+6),-y)
            styleHeight=math.max(styleHeight,F.Theme.FitButton(b,bWidth))
        end
    end
    y=y+math.max(styleHeight,S.styleLabel:GetStringHeight()+4)+12
    local styleBottom=y
    if S.cardStyle then
        S.cardStyle:ClearAllPoints(); S.cardStyle:SetPoint('TOPLEFT',4,-styleTop+4); S.cardStyle:SetPoint('BOTTOMRIGHT',S.body,'TOPRIGHT',-4,-styleBottom)
    end
    y=y+14

    local syncTop=y
    if S.sectionSync then place(S.sectionSync,8,3) end
    if S.subSync then place(S.subSync,8,8) end
    for i=1,8 do
        local check=S.checks[i]
        if check then
            check:ClearAllPoints(); check:SetPoint('TOPLEFT',4,-y)
            check.label:SetHeight(0)
            y=y+math.max(28,check.label:GetStringHeight()+4)+2
        end
    end
    local syncBottom=y
    if S.cardSync then
        S.cardSync:ClearAllPoints(); S.cardSync:SetPoint('TOPLEFT',4,-syncTop+4); S.cardSync:SetPoint('BOTTOMRIGHT',S.body,'TOPRIGHT',-4,-syncBottom)
    end
    y=y+14

    local lootTop=y
    if S.sectionLoot then place(S.sectionLoot,8,3) end
    if S.subLoot then place(S.subLoot,8,8) end
    for i=9,#S.checks do
        local check=S.checks[i]
        if check then
            check:ClearAllPoints(); check:SetPoint('TOPLEFT',4,-y)
            check.label:SetHeight(0)
            y=y+math.max(28,check.label:GetStringHeight()+4)+2
        end
    end

    if S.lootQualityLabel then
        S.lootQualityLabel:ClearAllPoints(); S.lootQualityLabel:SetPoint('TOPLEFT',8,-(y+4))
        S.lootQualityLabel:SetWidth(446); S.lootQualityLabel:SetHeight(0)
        y=y+S.lootQualityLabel:GetStringHeight()+8
        local qWidth=(446-3*8)/4
        local qHeight=0
        for i,q in ipairs({0,1,2,3}) do
            local b=S.lootQualities[q]
            if b then
                b:ClearAllPoints(); b:SetPoint('TOPLEFT',8+(i-1)*(qWidth+8),-y)
                qHeight=math.max(qHeight,F.Theme.FitButton(b,qWidth))
            end
        end
        y=y+math.max(qHeight,24)+10
    end
    if S.lootSortLabel and S.lootSortModes then
        S.lootSortLabel:ClearAllPoints(); S.lootSortLabel:SetPoint('TOPLEFT',8,-(y+4))
        S.lootSortLabel:SetWidth(446); S.lootSortLabel:SetHeight(0)
        y=y+S.lootSortLabel:GetStringHeight()+8
        local sortWidth=(446-8)/2
        local sortHeight=0
        for i,mode in ipairs({'price','quality'}) do
            local b=S.lootSortModes[mode]
            if b then
                b:ClearAllPoints(); b:SetPoint('TOPLEFT',8+(i-1)*(sortWidth+8),-y)
                sortHeight=math.max(sortHeight,F.Theme.FitButton(b,sortWidth))
            end
        end
        y=y+math.max(sortHeight,24)+10
    end
    if S.lootBlacklistLabel and S.lootBlacklistClear then
        place(S.lootBlacklistLabel,8,4)
        S.lootBlacklistClear:ClearAllPoints(); S.lootBlacklistClear:SetPoint('TOPLEFT',8,-y)
        y=y+F.Theme.FitButton(S.lootBlacklistClear,220)+12
    end
    local lootBottom=y
    if S.cardLoot then
        S.cardLoot:ClearAllPoints(); S.cardLoot:SetPoint('TOPLEFT',4,-lootTop+4); S.cardLoot:SetPoint('BOTTOMRIGHT',S.body,'TOPRIGHT',-4,-lootBottom)
    end
    y=y+14

    local langTop=y
    local intervalWidth=math.min(172,math.max(110,math.ceil(S.intervalLabel:GetUnboundedStringWidth())))
    S.intervalLabel:SetWidth(intervalWidth); S.intervalLabel:SetHeight(0)
    S.intervalLabel:ClearAllPoints(); S.intervalLabel:SetPoint('TOPLEFT',8,-(y+4))
    local buttonWidth=(446-intervalWidth-28)/3
    local height=0
    for i,seconds in ipairs({60,120,300}) do
        local b=S.intervals[seconds]; b:ClearAllPoints(); b:SetPoint('TOPLEFT',20+intervalWidth+(i-1)*(buttonWidth+8),-y)
        height=math.max(height,F.Theme.FitButton(b,buttonWidth))
    end
    y=y+math.max(height,S.intervalLabel:GetStringHeight()+4)+12

    if S.sectionLang then place(S.sectionLang,8,3) end
    if S.subLang then place(S.subLang,8,8) end
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
    y=y+F.Theme.FitButton(S.updates,446)+12
    local langBottom=y
    if S.cardLang then
        S.cardLang:ClearAllPoints(); S.cardLang:SetPoint('TOPLEFT',4,-langTop+4); S.cardLang:SetPoint('BOTTOMRIGHT',S.body,'TOPRIGHT',-4,-langBottom)
    end
    y=y+14

    local aboutTop=y
    if S.sectionAbout then place(S.sectionAbout,8,3) end
    if S.subAbout then place(S.subAbout,8,8) end
    place(S.about,8,12)
    place(S.githubLabel,8,5)
    S.githubLink:ClearAllPoints(); S.githubLink:SetPoint('TOPLEFT',13,-y); y=y+30
    place(S.supportLabel,8,5)
    S.supportLink:ClearAllPoints(); S.supportLink:SetPoint('TOPLEFT',13,-y); y=y+30
    place(S.linkHint,8,12)
    local aboutBottom=y
    if S.cardAbout then
        S.cardAbout:ClearAllPoints(); S.cardAbout:SetPoint('TOPLEFT',4,-aboutTop+4); S.cardAbout:SetPoint('BOTTOMRIGHT',S.body,'TOPRIGHT',-4,-aboutBottom)
    end
    S.body:SetHeight(y+8)
end
function S.Refresh()
    if not S.frame then return end
    F.Theme.RefreshFonts()
    S.frame:SetTitle('ForeverNet - '..F.L('SETTINGS'))
    if S.sectionStyle then S.sectionStyle:SetText(F.L('SETTING_SEC_STYLE')); F.Theme.Text(S.sectionStyle,true,14); F.Theme.Color(S.sectionStyle,'heading') end
    if S.subStyle then S.subStyle:SetText(F.L('SETTING_SUB_STYLE')); F.Theme.Text(S.subStyle,false,11); F.Theme.Color(S.subStyle,'muted') end
    if S.sectionSync then S.sectionSync:SetText(F.L('SETTING_SEC_SYNC')); F.Theme.Text(S.sectionSync,true,14); F.Theme.Color(S.sectionSync,'heading') end
    if S.subSync then S.subSync:SetText(F.L('SETTING_SUB_SYNC')); F.Theme.Text(S.subSync,false,11); F.Theme.Color(S.subSync,'muted') end
    if S.sectionLoot then S.sectionLoot:SetText(F.L('SETTING_SEC_LOOT')); F.Theme.Text(S.sectionLoot,true,14); F.Theme.Color(S.sectionLoot,'heading') end
    if S.subLoot then S.subLoot:SetText(F.L('SETTING_SUB_LOOT')); F.Theme.Text(S.subLoot,false,11); F.Theme.Color(S.subLoot,'muted') end
    if S.sectionLang then S.sectionLang:SetText(F.L('SETTING_SEC_LANG')); F.Theme.Text(S.sectionLang,true,14); F.Theme.Color(S.sectionLang,'heading') end
    if S.subLang then S.subLang:SetText(F.L('SETTING_SUB_LANG')); F.Theme.Text(S.subLang,false,11); F.Theme.Color(S.subLang,'muted') end
    if S.sectionAbout then S.sectionAbout:SetText(F.L('SETTING_SEC_ABOUT')); F.Theme.Text(S.sectionAbout,true,14); F.Theme.Color(S.sectionAbout,'heading') end
    if S.subAbout then S.subAbout:SetText(F.L('SETTING_SUB_ABOUT')); F.Theme.Text(S.subAbout,false,11); F.Theme.Color(S.subAbout,'muted') end
    S.styleLabel:SetText(F.L('SETTING_STYLE'))
    local styleLocales={modern='STYLE_MODERN',classic='STYLE_CLASSIC',neon='STYLE_NEON'}
    for style,b in pairs(S.styles) do
        b:SetText(F.L(styleLocales[style] or 'STYLE_MODERN'))
        b:SetEnabled(style~=F.db.settings.uiStyle)
    end
    for _,check in ipairs(S.checks) do
        check:SetChecked(F.db.settings[check.key]~=false)
        if check.key=='sharing' then check:SetChecked(not not F.db.settings.sharing) end
        check.label:SetText(F.L(check.locale))
        if check.UpdateVisual then check:UpdateVisual() end
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
    if S.lootQualityLabel then
        S.lootQualityLabel:SetText(F.L('SETTING_LOOT_MAX_QUALITY'))
        local currentQ=F.db and F.db.settings and F.db.settings.lootMaxQuality or 0
        local qLocales={[0]='QUALITY_POOR',[1]='QUALITY_COMMON',[2]='QUALITY_UNCOMMON',[3]='QUALITY_RARE'}
        for q,b in pairs(S.lootQualities or {}) do
            b:SetText(F.L(qLocales[q]))
            b:SetEnabled(currentQ~=q)
        end
    end
    if S.lootSortLabel then
        S.lootSortLabel:SetText(F.L('SETTING_LOOT_SORT_LABEL'))
        local currentSort=F.db and F.db.settings and F.db.settings.lootSortMode or 'price'
        if S.lootSortModes then
            if S.lootSortModes.price then
                S.lootSortModes.price:SetText(F.L('SETTING_LOOT_SORT_PRICE'))
                S.lootSortModes.price:SetEnabled(currentSort~='price')
            end
            if S.lootSortModes.quality then
                S.lootSortModes.quality:SetText(F.L('SETTING_LOOT_SORT_QUALITY'))
                S.lootSortModes.quality:SetEnabled(currentSort~='quality')
            end
        end
    end
    if S.lootBlacklistLabel then
        local count=0
        for _ in pairs(F.db and F.db.settings and F.db.settings.lootBlacklist or {}) do count=count+1 end
        S.lootBlacklistLabel:SetText(string.format(F.L('SETTING_LOOT_BLACKLIST'),count))
        S.lootBlacklistClear:SetText(F.L('SETTING_LOOT_BLACKLIST_CLEAR'))
        S.lootBlacklistClear:SetEnabled(count>0)
    end
    if S.reloadBtn then S.reloadBtn:SetText(F.L('RELOAD_UI')) end
    if S.closeBtn then S.closeBtn:SetText(F.L('CLOSE')) end
    if S.footerHint then S.footerHint:SetText(F.L('FOOTER_HINT')) end

    local isBoot = F.Theme.Style() == 'neon'
    local isMod = F.Theme.Style() == 'modern'
    for _,card in ipairs(S.cards or {}) do
        if isBoot then
            card:Show()
            card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
            card:SetBackdropColor(0.06,0.09,0.15,0.92)
            card:SetBackdropBorderColor(0.18,0.28,0.42,0.95)
        elseif isMod then
            card:Show()
            card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
            card:SetBackdropColor(0.10,0.09,0.075,0.85)
            card:SetBackdropBorderColor(0.25,0.22,0.18,1)
        else
            card:Hide()
        end
    end
    if S.footerBg then
        if isBoot then
            S.footerBg:Show()
            S.footerBg:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',tile=false,edgeSize=1,insets={left=0,right=0,top=1,bottom=0}})
            S.footerBg:SetBackdropColor(0.04,0.06,0.10,1)
            S.footerBg:SetBackdropBorderColor(0.18,0.28,0.42,1)
        elseif isMod then
            S.footerBg:Show()
            S.footerBg:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',tile=false,edgeSize=1,insets={left=0,right=0,top=1,bottom=0}})
            S.footerBg:SetBackdropColor(0.07,0.065,0.055,1)
            S.footerBg:SetBackdropBorderColor(0.25,0.22,0.18,1)
        else
            S.footerBg:Hide()
        end
    end
    S.Layout()

    if S.RefreshBlizzPanels then S.RefreshBlizzPanels() end

end
function S.Ensure()

    if not S.frame then
        local frame=CreateFrame('Frame','ForeverNetSettings',UIParent,'PortraitFrameTemplate')
        frame:SetSize(530,600); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN_DIALOG'); frame:SetClampedToScreen(true)
        frame:SetPortraitToAsset(F.icon)
        F.Theme.Title(frame)
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
        S.background,S.backgroundBase=F.Theme.Background(frame)
        S.frame=frame; S.checks={}
        S.scroll=F.Theme.ScrollFrame(frame)
        S.scroll:SetPoint('TOPLEFT',20,-48); S.scroll:SetPoint('BOTTOMRIGHT',-34,44)
        S.body=CreateFrame('Frame',nil,S.scroll); S.body:SetSize(470,540); S.scroll:SetScrollChild(S.body)
        local content=S.body

        local function makeCard()
            local c=CreateFrame('Frame',nil,content,'BackdropTemplate')
            c:SetFrameLevel(math.max(1,content:GetFrameLevel()-1))
            return c
        end
        S.cardStyle=makeCard()
        S.cardSync=makeCard()
        S.cardLoot=makeCard()
        S.cardLang=makeCard()
        S.cardAbout=makeCard()
        S.cards={S.cardStyle,S.cardSync,S.cardLoot,S.cardLang,S.cardAbout}

        S.sectionStyle=label(content,0,'')
        S.subStyle=label(content,0,'')
        S.styleLabel=label(content,0,''); S.styles={}
        for _,style in ipairs({'modern','classic','neon'}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate'); b:SetSize(146,24); F.Theme.Button(b)
            b:SetScript('OnClick',function() F.Theme.SetStyle(style) end); S.styles[style]=b
        end
        S.sectionSync=label(content,0,'')
        S.subSync=label(content,0,'')
        local choices={{'sharing','SETTING_SHARE'},{'autoBank','SETTING_AUTOBANK'},{'useBank','SETTING_USEBANK'},{'showMinimap','SETTING_MINIMAP'},{'autoSync','SETTING_AUTOSYNC'},{'autoScan','SETTING_AUTOSCAN'},{'autoSources','SETTING_AUTOSOURCES'},{'materialBadges','SETTING_MATERIAL_BADGES'},{'lootAdvisor','SETTING_LOOT_ADVISOR'},{'lootInCombat','SETTING_LOOT_IN_COMBAT'},{'lootProtectReagents','SETTING_LOOT_PROTECT_REAGENTS'},{'lootProtectGear','SETTING_LOOT_PROTECT_GEAR'}}
        for i,choice in ipairs(choices) do
            local check=CreateFrame('CheckButton',nil,content,'UICheckButtonTemplate')
            check:SetSize(28,28); check:SetPoint('TOPLEFT',24,-55-(i-1)*34)
            check.key,check.locale=choice[1],choice[2]
            check.label=check:CreateFontString(nil,'OVERLAY','GameFontHighlight'); check.label:SetPoint('TOPLEFT',check,'TOPRIGHT',4,-5)
            check.label:SetWidth(426); check.label:SetJustifyH('LEFT'); check.label:SetWordWrap(true)
            F.Theme.Text(check.label,false,14)
            skinCheck(check)
            if check.key=='autoSources' or check.key=='autoScan' or check.key=='materialBadges' or check.key=='lootAdvisor' then
                check:SetScript('OnEnter',function(self)
                    local help=self.key=='autoSources' and 'SOURCE_COST_HELP' or (self.key=='autoScan' and 'SCAN_HINT' or (self.key=='materialBadges' and 'MATERIAL_BADGES_HINT' or (self.key=='lootInCombat' and 'SETTING_LOOT_IN_COMBAT_HINT' or 'SETTING_LOOT_ADVISOR_HINT')))
                    F.Theme.ShowTooltip(self,F.L(self.locale),F.L(help))
                end)
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
                if self.key=='materialBadges' then
                    if F.UI and F.UI.UpdateBadges then F.UI.UpdateBadges() end
                end
                F.UI.DataChanged(); S.Refresh()
            end)
            S.checks[i]=check
        end
        S.sectionLoot=label(content,0,'')
        S.subLoot=label(content,0,'')
        S.lootQualityLabel=label(content,0,'')
        S.lootQualities={}
        for _,q in ipairs({0,1,2,3}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate'); b:SetSize(100,24); F.Theme.Button(b)
            b:SetScript('OnClick',function() F.db.settings.lootMaxQuality=q; S.Refresh() end)
            S.lootQualities[q]=b
        end
        S.lootSortLabel=label(content,0,'')
        S.lootSortModes={}
        for _,mode in ipairs({'price','quality'}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate'); b:SetSize(218,24); F.Theme.Button(b)
            b:SetScript('OnClick',function()
                F.db.settings.lootSortMode=mode
                S.Refresh()
                if F.LootAdvisor and F.LootAdvisor.frame and F.LootAdvisor.frame:IsShown() then
                    F.LootAdvisor.Render(F.LootAdvisor.ScanCandidates())
                end
            end)
            S.lootSortModes[mode]=b
        end
        S.lootBlacklistLabel=label(content,0,'')
        S.lootBlacklistClear=CreateFrame('Button',nil,content,'UIPanelButtonTemplate'); S.lootBlacklistClear:SetSize(220,24); F.Theme.Button(S.lootBlacklistClear)
        S.lootBlacklistClear:SetScript('OnClick',function() F.db.settings.lootBlacklist={}; S.Refresh() end)
        S.intervalLabel=label(content,-239,'')
        S.intervals={}
        for i,seconds in ipairs({60,120,300}) do
            local b=CreateFrame('Button',nil,content,'UIPanelButtonTemplate')
            b:SetSize(85,24); b:SetPoint('TOPLEFT',221+(i-1)*94,-235)
            F.Theme.Button(b)
            b:SetScript('OnClick',function() F.db.settings.syncInterval=seconds; F.Net.autoElapsed=0; S.Refresh() end)
            S.intervals[seconds]=b
        end
        S.sectionLang=label(content,0,'')
        S.subLang=label(content,0,'')
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
        S.sectionAbout=label(content,0,'')
        S.subAbout=label(content,0,'')
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

        local footerBg=CreateFrame('Frame',nil,frame,'BackdropTemplate')
        footerBg:SetPoint('BOTTOMLEFT',0,0); footerBg:SetPoint('BOTTOMRIGHT',0,0); footerBg:SetHeight(42)
        S.footerBg=footerBg

        local reloadBtn=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        reloadBtn:SetSize(130,24); reloadBtn:SetPoint('BOTTOMRIGHT',-110,9)
        F.Theme.Button(reloadBtn)
        reloadBtn:SetScript('OnClick',function() ReloadUI() end)
        S.reloadBtn=reloadBtn

        local closeBtn=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        closeBtn:SetSize(90,24); closeBtn:SetPoint('BOTTOMRIGHT',-14,9)
        F.Theme.Button(closeBtn)
        closeBtn:SetScript('OnClick',function() frame:Hide() end)
        S.closeBtn=closeBtn

        local footerHint=frame:CreateFontString(nil,'OVERLAY','GameFontDisableSmall')
        footerHint:SetPoint('BOTTOMLEFT',18,15)
        F.Theme.Text(footerHint,false,11); F.Theme.Color(footerHint,'muted')
        S.footerHint=footerHint

        frame:SetScript('OnHide',function() S.languageMenu:Hide(); F.Theme.HideTooltip() end)
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetSettings'
    end
    return S.frame
end

---------------------------------------------------------------------------
-- Blizzard Interface Options (AddOns Category & Submenus)
---------------------------------------------------------------------------
S.blizzPanels = {}
S.blizzControls = {}

local function makeBlizzPanel(name, subOf)
    local p = CreateFrame('Frame', nil, UIParent)
    p.name = name
    if subOf then p.parent = subOf end
    local scroll = F.Theme.ScrollFrame(p)
    scroll:SetPoint('TOPLEFT', 10, -10)
    scroll:SetPoint('BOTTOMRIGHT', -26, 10)
    local body = CreateFrame('Frame', nil, scroll)
    body:SetSize(600, 560)
    scroll:SetScrollChild(body)
    p.scroll = scroll
    p.body = body
    return p, body
end

local function blizzTitle(parent, text, subText)
    local t = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    t:SetPoint('TOPLEFT', 12, -10)
    F.Theme.Text(t, true, 18); F.Theme.Color(t, 'heading')
    t:SetText(text)

    local sub = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    sub:SetPoint('TOPLEFT', 12, -32); sub:SetWidth(560); sub:SetJustifyH('LEFT')
    F.Theme.Text(sub, false, 11); F.Theme.Color(sub, 'muted')
    sub:SetText(subText or '')

    local div = parent:CreateTexture(nil, 'ARTWORK')
    div:SetPoint('TOPLEFT', 10, -50); div:SetPoint('TOPRIGHT', -10, -50); div:SetHeight(1)
    div:SetColorTexture(0.20, 0.25, 0.35, 0.6)

    return t, sub
end

local function makeBlizzCheck(parent, x, y, key, localeKey, hintKey)
    local check = CreateFrame('CheckButton', nil, parent, 'InterfaceOptionsCheckButtonTemplate')
    if not check then
        check = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
    end
    check:SetPoint('TOPLEFT', x, -y)
    local label = check:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    label:SetPoint('LEFT', check, 'RIGHT', 4, 1)
    check.label = label
    label:SetText(F.L(localeKey))
    F.Theme.Text(label, false, 13)

    check:SetChecked(not not F.db.settings[key])
    check:SetScript('OnClick', function(self)
        F.db.settings[key] = not not self:GetChecked()
        if key == 'sharing' and not self:GetChecked() then F.Net.queue, F.Net.buffers = {}, {} end
        if key == 'showMinimap' then F.Minimap.ApplyVisibility() end
        if key == 'autoBank' and self:GetChecked() and F.Bank.open then F.Bank.Event('BANKFRAME_OPENED') end
        if key == 'autoSync' then
            F.Net.pendingSync, F.Net.pendingPublish, F.Net.autoElapsed = nil, nil, 0
            if self:GetChecked() then F.Net.ScheduleSync() end
        end
        if key == 'materialBadges' and F.UI and F.UI.UpdateBadges then F.UI.UpdateBadges() end
        F.UI.DataChanged()
        S.Refresh()
    end)
    if hintKey then
        check:SetScript('OnEnter', function(self)
            F.Theme.ShowTooltip(self, F.L(localeKey), F.L(hintKey))
        end)
        check:SetScript('OnLeave', F.Theme.HideTooltip)
    end
    return check
end

function S.InitBlizzardPanels()
    if S.blizzPanels.overview then return end

    -- 1. Main Overview
    local pOver, bOver = makeBlizzPanel('ForeverNet')
    S.blizzPanels.overview = pOver
    pOver:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bOver, 'ForeverNet ' .. F.version, F.L('NOTES'))

    local card = CreateFrame('Frame', nil, bOver, 'BackdropTemplate')
    card:SetPoint('TOPLEFT', 10, -60); card:SetSize(580, 105)
    F.Theme.Skin(card, true)

    local statusRows = {}
    local statusDefs = {
        {'statusSharing', 'P2P сеть: ', function() return F.db.settings.sharing and '|cff38bdf8Включена|r' or '|cff94a3b8Отключена|r' end},
        {'statusSync', 'Синхронизация: ', function() return F.db.settings.autoSync and ('|cff38bdf8Автоматическая (' .. math.floor((F.db.settings.syncInterval or 60)/60) .. ' мин)|r') or '|cff94a3b8Вручную|r' end},
        {'statusLoot', 'Помощник сумок: ', function() return F.db.settings.lootAdvisor and '|cff38bdf8Активен|r' or '|cff94a3b8Отключен|r' end},
        {'statusStyle', 'Текущий стиль: ', function() return '|cffffffff' .. (F.db.settings.uiStyle or 'modern'):upper() .. '|r' end},
    }
    for i, def in ipairs(statusDefs) do
        local fs = card:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        fs:SetPoint('TOPLEFT', 16, -12 - (i - 1) * 22)
        F.Theme.Text(fs, false, 13)
        statusRows[def[1]] = {label = fs, prefix = def[2], getVal = def[3]}
    end
    S.blizzControls.statusRows = statusRows

    local btnUI = CreateFrame('Button', nil, bOver, 'UIPanelButtonTemplate')
    btnUI:SetSize(180, 26); btnUI:SetPoint('TOPLEFT', 10, -178)
    F.Theme.Button(btnUI); btnUI:SetText('Открыть ForeverNet')
    btnUI:SetScript('OnClick', function() F.UI.Toggle() end)

    local btnUpdates = CreateFrame('Button', nil, bOver, 'UIPanelButtonTemplate')
    btnUpdates:SetSize(180, 26); btnUpdates:SetPoint('TOPLEFT', 200, -178)
    F.Theme.Button(btnUpdates); btnUpdates:SetText(F.L('ADDON_UPDATES'))
    btnUpdates:SetScript('OnClick', function() F.Updates.Open() end)

    local btnReload = CreateFrame('Button', nil, bOver, 'UIPanelButtonTemplate')
    btnReload:SetSize(140, 26); btnReload:SetPoint('TOPLEFT', 390, -178)
    F.Theme.Button(btnReload); btnReload:SetText(F.L('RELOAD_UI'))
    btnReload:SetScript('OnClick', function() ReloadUI() end)

    local hintCard = CreateFrame('Frame', nil, bOver, 'BackdropTemplate')
    hintCard:SetPoint('TOPLEFT', 10, -216); hintCard:SetSize(580, 160)
    F.Theme.Skin(hintCard, true)

    local hintTitle = hintCard:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    hintTitle:SetPoint('TOPLEFT', 16, -12)
    F.Theme.Text(hintTitle, true, 13); F.Theme.Color(hintTitle, 'heading')
    hintTitle:SetText('Разделы настроек аддона:')

    local guideLines = {
        '• Стиль оформления — выбор внешнего вида окон (Modern, Classic, Neon).',
        '• Синхронизация и профессии — настройки P2P обмена, сканирования сумок и банка.',
        '• Помощник сумок — автоматический выброс мусора при переполнении сумок.',
        '• Язык интерфейса — переключение между 12 языками локализации и шрифтами.',
        '• Об аддоне — сведения о версии, авторе и ссылки на проект.',
    }
    for i, line in ipairs(guideLines) do
        local fs = hintCard:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        fs:SetPoint('TOPLEFT', 16, -34 - (i - 1) * 22); fs:SetWidth(548); fs:SetJustifyH('LEFT')
        F.Theme.Text(fs, false, 12); F.Theme.Color(fs, 'text')
        fs:SetText(line)
    end
    local function makeLinkBox(parent, name, x, y, width, labelText, url)
        local lbl = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        lbl:SetPoint('TOPLEFT', x, -y)
        F.Theme.Text(lbl, false, 11); F.Theme.Color(lbl, 'muted')
        lbl:SetText(labelText)

        local box = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
        box:SetSize(width, 24); box:SetPoint('TOPLEFT', x, -y - 16)
        box:SetBackdrop({
            bgFile = 'Interface\\Buttons\\WHITE8X8',
            edgeFile = 'Interface\\Buttons\\WHITE8X8',
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        box:SetBackdropColor(0.02, 0.03, 0.06, 0.95)
        box:SetBackdropBorderColor(0.18, 0.30, 0.45, 0.8)

        local eb = CreateFrame('EditBox', name, box)
        eb:SetPoint('TOPLEFT', 8, 0); eb:SetPoint('BOTTOMRIGHT', -8, 0)
        eb:SetAutoFocus(false)
        if eb.SetMaxLetters then eb:SetMaxLetters(256) end
        local fo = _G['GameFontHighlightSmall'] or GameFontHighlightSmall
        if fo and type(fo) ~= 'string' then pcall(eb.SetFontObject, eb, fo) end
        F.Theme.Font(eb, 12)
        if eb.SetTextColor then eb:SetTextColor(0.92, 0.96, 1.0, 1) end

        eb.url = url
        local function applyText()
            if not url then return end
            eb._settingText = true
            eb:SetText(url)
            eb._settingText = nil
            if eb.SetCursorPosition then eb:SetCursorPosition(0) end
        end
        applyText()

        eb:SetScript('OnShow', applyText)
        eb:SetScript('OnMouseUp', function(self) self:SetFocus(); self:HighlightText() end)
        eb:SetScript('OnEditFocusGained', function(self)
            box:SetBackdropBorderColor(0.0, 0.85, 1.0, 1.0)
            self:HighlightText()
        end)
        eb:SetScript('OnEditFocusLost', function(self)
            box:SetBackdropBorderColor(0.18, 0.30, 0.45, 0.8)
            applyText()
        end)
        eb:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
        eb:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)
        eb:SetScript('OnTextChanged', function(self)
            if self._settingText then return end
            if url and self:GetText() ~= url then
                self._settingText = true
                self:SetText(url)
                self._settingText = nil
            end
        end)

        S.blizzControls.linkBoxes = S.blizzControls.linkBoxes or {}
        table.insert(S.blizzControls.linkBoxes, eb)
        return eb
    end

    local function makeLinkCard(parent, prefix, x, y, width)
        local card = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
        card:SetPoint('TOPLEFT', x, -y); card:SetSize(width, 136)
        F.Theme.Skin(card, true)

        local title = card:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        title:SetPoint('TOPLEFT', 16, -10)
        F.Theme.Text(title, true, 13); F.Theme.Color(title, 'heading')
        title:SetText('Полезные ссылки:')

        makeLinkBox(card, prefix .. 'GhLink', 16, 28, width - 32, F.L('PROJECT_GITHUB'), S.githubURL)
        makeLinkBox(card, prefix .. 'BstLink', 16, 70, width - 32, F.L('SUPPORT_BOOSTY'), S.supportURL)

        local hint = card:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
        hint:SetPoint('TOPLEFT', 16, -114)
        F.Theme.Text(hint, false, 10); F.Theme.Color(hint, 'muted')
        hint:SetText(F.L('COPY_LINK_HINT'))
        return card
    end

    makeLinkCard(bOver, 'ForeverNetMain', 10, 386, 580)

    -- 2. Style Subpanel
    local styleName = (F.L('SETTING_SEC_STYLE') or 'Appearance'):gsub('^|%s*', '')
    local pStyle, bStyle = makeBlizzPanel(styleName, 'ForeverNet')
    S.blizzPanels.style = pStyle
    pStyle:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bStyle, styleName, F.L('SETTING_SUB_STYLE'))

    local styleButtons = {}
    local styles = {'modern', 'classic', 'neon'}
    local styleWidth = (580 - 16) / 3
    for i, st in ipairs(styles) do
        local btn = CreateFrame('Button', nil, bStyle, 'UIPanelButtonTemplate')
        btn:SetSize(styleWidth, 28); btn:SetPoint('TOPLEFT', 10 + (i - 1) * (styleWidth + 8), -65)
        F.Theme.Button(btn); btn:SetText(st:upper())
        btn:SetScript('OnClick', function()
            F.Theme.SetStyle(st)
            S.Refresh()
        end)
        styleButtons[st] = btn
    end
    S.blizzControls.styleButtons = styleButtons

    local descCard = CreateFrame('Frame', nil, bStyle, 'BackdropTemplate')
    descCard:SetPoint('TOPLEFT', 10, -110); descCard:SetSize(580, 160)
    F.Theme.Skin(descCard, true)

    local descText = descCard:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    descText:SetPoint('TOPLEFT', 16, -16); descText:SetWidth(548); descText:SetJustifyH('LEFT')
    F.Theme.Text(descText, false, 13)
    S.blizzControls.styleDesc = descText

    -- 3. Sync Subpanel
    local syncName = (F.L('SETTING_SEC_SYNC') or 'Network & Professions'):gsub('^|%s*', '')
    local pSync, bSync = makeBlizzPanel(syncName, 'ForeverNet')
    S.blizzPanels.sync = pSync
    pSync:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bSync, syncName, F.L('SETTING_SUB_SYNC'))

    local syncChecks = {}
    local syncDefs = {
        {'sharing', 'SETTING_SHARE', 'SHARE_HINT'},
        {'autoSync', 'SETTING_AUTOSYNC', nil},
        {'autoScan', 'SETTING_AUTOSCAN', 'SCAN_HINT'},
        {'autoSources', 'SETTING_AUTOSOURCES', 'SOURCE_COST_HELP'},
        {'autoBank', 'SETTING_AUTOBANK', nil},
        {'useBank', 'SETTING_USEBANK', nil},
        {'materialBadges', 'SETTING_MATERIAL_BADGES', 'MATERIAL_BADGES_HINT'},
        {'showMinimap', 'SETTING_MINIMAP', nil},
    }
    for i, def in ipairs(syncDefs) do
        local chk = makeBlizzCheck(bSync, 16, 60 + (i - 1) * 32, def[1], def[2], def[3])
        syncChecks[def[1]] = chk
    end
    S.blizzControls.syncChecks = syncChecks

    local intY = 60 + #syncDefs * 32 + 10
    local intLabel = bSync:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    intLabel:SetPoint('TOPLEFT', 18, -intY)
    F.Theme.Text(intLabel, true, 13)
    intLabel:SetText(F.L('SYNC_INTERVAL'))

    local intButtons = {}
    for i, sec in ipairs({60, 120, 300}) do
        local btn = CreateFrame('Button', nil, bSync, 'UIPanelButtonTemplate')
        btn:SetSize(100, 24); btn:SetPoint('TOPLEFT', 18 + (i - 1) * 110, -intY - 24)
        F.Theme.Button(btn); btn:SetText(string.format(F.L('SYNC_MINUTES'), sec/60))
        btn:SetScript('OnClick', function()
            F.db.settings.syncInterval = sec
            F.Net.autoElapsed = 0
            S.Refresh()
        end)
        intButtons[sec] = btn
    end
    S.blizzControls.intButtons = intButtons

    -- 4. Loot Advisor Subpanel
    local lootName = (F.L('SETTING_SEC_LOOT') or 'Loot Advisor'):gsub('^|%s*', '')
    local pLoot, bLoot = makeBlizzPanel(lootName, 'ForeverNet')
    S.blizzPanels.loot = pLoot
    pLoot:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bLoot, lootName, F.L('SETTING_SUB_LOOT'))

    local lootChecks = {}
    local lootDefs = {
        {'lootAdvisor', 'SETTING_LOOT_ADVISOR', 'SETTING_LOOT_ADVISOR_HINT'},
        {'lootInCombat', 'SETTING_LOOT_IN_COMBAT', 'SETTING_LOOT_IN_COMBAT_HINT'},
        {'lootProtectReagents', 'SETTING_LOOT_PROTECT_REAGENTS', nil},
        {'lootProtectGear', 'SETTING_LOOT_PROTECT_GEAR', nil},
    }
    for i, def in ipairs(lootDefs) do
        local chk = makeBlizzCheck(bLoot, 16, 60 + (i - 1) * 30, def[1], def[2], def[3])
        lootChecks[def[1]] = chk
    end
    S.blizzControls.lootChecks = lootChecks

    local qLabel = bLoot:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    qLabel:SetPoint('TOPLEFT', 18, -188)
    F.Theme.Text(qLabel, true, 13)
    qLabel:SetText(F.L('SETTING_LOOT_MAX_QUALITY'))

    local qButtons = {}
    local qLocales = {[0]='QUALITY_POOR',[1]='QUALITY_COMMON',[2]='QUALITY_UNCOMMON',[3]='QUALITY_RARE'}
    for i, q in ipairs({0, 1, 2, 3}) do
        local btn = CreateFrame('Button', nil, bLoot, 'UIPanelButtonTemplate')
        btn:SetSize(100, 24); btn:SetPoint('TOPLEFT', 18 + (i - 1) * 110, -212)
        F.Theme.Button(btn); btn:SetText(F.L(qLocales[q]))
        btn:SetScript('OnClick', function()
            F.db.settings.lootMaxQuality = q
            S.Refresh()
        end)
        qButtons[q] = btn
    end
    S.blizzControls.qButtons = qButtons

    local sortLabel = bLoot:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    sortLabel:SetPoint('TOPLEFT', 18, -248)
    F.Theme.Text(sortLabel, true, 13)
    sortLabel:SetText(F.L('SETTING_LOOT_SORT_LABEL'))

    local sortButtons = {}
    local smDefs = {{'price', 'SETTING_LOOT_SORT_PRICE'}, {'quality', 'SETTING_LOOT_SORT_QUALITY'}}
    for i, sm in ipairs(smDefs) do
        local btn = CreateFrame('Button', nil, bLoot, 'UIPanelButtonTemplate')
        btn:SetSize(180, 24); btn:SetPoint('TOPLEFT', 18 + (i - 1) * 190, -272)
        F.Theme.Button(btn); btn:SetText(F.L(sm[2]))
        btn:SetScript('OnClick', function()
            F.db.settings.lootSortMode = sm[1]
            S.Refresh()
            if F.LootAdvisor and F.LootAdvisor.frame and F.LootAdvisor.frame:IsShown() then
                F.LootAdvisor.Render(F.LootAdvisor.ScanCandidates())
            end
        end)
        sortButtons[sm[1]] = btn
    end
    S.blizzControls.sortButtons = sortButtons

    local blLabel = bLoot:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    blLabel:SetPoint('TOPLEFT', 18, -310)
    F.Theme.Text(blLabel, true, 13)
    S.blizzControls.blLabel = blLabel

    local blClear = CreateFrame('Button', nil, bLoot, 'UIPanelButtonTemplate')
    blClear:SetSize(200, 24); blClear:SetPoint('TOPLEFT', 18, -334)
    F.Theme.Button(blClear); blClear:SetText(F.L('SETTING_LOOT_BLACKLIST_CLEAR'))
    blClear:SetScript('OnClick', function()
        F.db.settings.lootBlacklist = {}
        S.Refresh()
    end)
    S.blizzControls.blClear = blClear

    -- 5. Language Subpanel
    local langName = (F.L('SETTING_SEC_LANG') or 'Interface Language'):gsub('^|%s*', '')
    local pLang, bLang = makeBlizzPanel(langName, 'ForeverNet')
    S.blizzPanels.lang = pLang
    pLang:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bLang, langName, F.L('SETTING_SUB_LANG'))

    local langButtons = {}
    local locales = {'auto'}
    for _, loc in ipairs(F.LocaleOrder) do locales[#locales + 1] = loc end
    local langWidth = (580 - 16) / 3
    for i, loc in ipairs(locales) do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local btn = CreateFrame('Button', nil, bLang, 'UIPanelButtonTemplate')
        btn:SetSize(langWidth, 26); btn:SetPoint('TOPLEFT', 10 + col * (langWidth + 8), -65 - row * 32)
        F.Theme.Button(btn, F.Theme.fontFiles[loc] and loc or nil)
        btn:SetText(loc == 'auto' and F.L('LANG_AUTO') or F.LocaleNames[loc])
        btn:SetScript('OnClick', function()
            F.db.settings.locale = loc ~= 'auto' and loc or nil
            S.Refresh()
            F.Updates.Refresh()
            if F.UI.frame and F.UI.frame:IsShown() then F.UI.Status() else F.UI.DataChanged() end
        end)
        langButtons[loc] = btn
    end
    S.blizzControls.langButtons = langButtons

    -- 6. About Subpanel
    local aboutName = (F.L('SETTING_SEC_ABOUT') or 'Об аддоне'):gsub('^|%s*', '')
    local pAbout, bAbout = makeBlizzPanel(aboutName, 'ForeverNet')
    S.blizzPanels.about = pAbout
    pAbout:SetScript('OnShow', function() S.RefreshBlizzPanels() end)

    blizzTitle(bAbout, aboutName, F.L('SETTING_SUB_ABOUT'))

    local cardAbout = CreateFrame('Frame', nil, bAbout, 'BackdropTemplate')
    cardAbout:SetPoint('TOPLEFT', 10, -60); cardAbout:SetSize(580, 100)
    F.Theme.Skin(cardAbout, true)

    local info = cardAbout:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    info:SetPoint('TOPLEFT', 16, -14); info:SetWidth(548); info:SetJustifyH('LEFT')
    F.Theme.Text(info, true, 14)
    info:SetText('ForeverNet ' .. F.version .. '   |cff94a3b8by Andrew Woolfi|r')

    local authorNote = cardAbout:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    authorNote:SetPoint('TOPLEFT', 16, -40); authorNote:SetWidth(548); authorNote:SetJustifyH('LEFT')
    F.Theme.Text(authorNote, false, 12); F.Theme.Color(authorNote, 'muted')
    authorNote:SetText('Аддон для World of Warcraft: единая сеть ремесел, общий инвентарь сумок и банка, асинхронный P2P обмен и умный менеджер добычи.')

    authorNote:SetText('Аддон для World of Warcraft: обмен рецептами профессий, планирование крафта, банк и P2P сеть.')

    makeLinkCard(bAbout, 'ForeverNetAbout', 10, 175, 580)
end

function S.RefreshBlizzPanels()
    if not S.blizzPanels.overview then return end
    local c = S.blizzControls
    if c.linkBoxes then
        for _, eb in ipairs(c.linkBoxes) do
            if eb.url then
                eb._settingText = true
                eb:SetText(eb.url)
                eb._settingText = nil
                if eb.SetCursorPosition then eb:SetCursorPosition(0) end
            end
        end
    end


    -- Overview Status
    if c.statusRows then
        for _, def in pairs(c.statusRows) do
            def.label:SetText(def.prefix .. def.getVal())
        end
    end

    -- Style buttons & desc
    if c.styleButtons then
        local currentStyle = F.Theme.Style()
        for st, btn in pairs(c.styleButtons) do
            btn:SetEnabled(currentStyle ~= st)
        end
        if c.styleDesc then
            if currentStyle == 'neon' then
                c.styleDesc:SetText('Neon — яркий киберпанк дизайн с неоновой бирюзово-фиолетовой подсветкой, светящимися рамками и акцентными карточками.\n\n• Тёмный фон #060910 и неоновые рамки\n• Стильные неоновые переключатели и индикаторы\n• Подсветка активных вкладок и заголовков')
            elseif currentStyle == 'classic' then
                c.styleDesc:SetText('Classic — классический стиль интерфейса World of Warcraft с аутентичными золотыми рамками и текстурами Blizzard.\n\n• Традиционный вид окон и кнопок WoW\n• Ретро-шрифты и стандартные текстуры')
            else
                c.styleDesc:SetText('Modern — строгий минималистичный тёмный дизайн с плоскими кнопками и чистыми шрифтами Sans.\n\n• Оптимизирован для удобства чтения\n• Компактные плоские элементы')
            end
        end
    end

    -- Sync checks & intervals
    if c.syncChecks then
        for key, chk in pairs(c.syncChecks) do
            chk:SetChecked(not not F.db.settings[key])
        end
    end
    if c.intButtons then
        local curInt = F.db.settings.syncInterval or 60
        local autoOn = F.Net.AutoEnabled()
        for sec, btn in pairs(c.intButtons) do
            btn:SetEnabled(autoOn and curInt ~= sec)
        end
    end

    -- Loot checks, qualities, sort modes, blacklist
    if c.lootChecks then
        for key, chk in pairs(c.lootChecks) do
            chk:SetChecked(not not F.db.settings[key])
        end
    end
    if c.qButtons then
        local curQ = F.db.settings.lootMaxQuality or 0
        for q, btn in pairs(c.qButtons) do
            btn:SetEnabled(curQ ~= q)
        end
    end
    if c.sortButtons then
        local curSort = F.db.settings.lootSortMode or 'price'
        for sm, btn in pairs(c.sortButtons) do
            btn:SetEnabled(curSort ~= sm)
        end
    end
    if c.blLabel and c.blClear then
        local count = 0
        for _ in pairs(F.db.settings.lootBlacklist or {}) do count = count + 1 end
        c.blLabel:SetText(string.format(F.L('SETTING_LOOT_BLACKLIST'), count))
        c.blClear:SetEnabled(count > 0)
    end

    -- Language buttons
    if c.langButtons then
        local curLoc = F.db.settings.locale or 'auto'
        for loc, btn in pairs(c.langButtons) do
            btn:SetEnabled(curLoc ~= loc)
        end
    end
end

function S.RegisterBlizzardOptions()
    if S.blizzardOptionsRegistered then return end
    S.blizzardOptionsRegistered = true

    S.InitBlizzardPanels()

    local main = S.blizzPanels.overview
    local style = S.blizzPanels.style
    local sync = S.blizzPanels.sync
    local loot = S.blizzPanels.loot
    local lang = S.blizzPanels.lang
    local about = S.blizzPanels.about

    local mainName = 'ForeverNet'
    main.name = mainName
    style.name = (F.L('SETTING_SEC_STYLE') or 'Appearance'):gsub('^|%s*', '')
    style.parent = mainName
    sync.name = (F.L('SETTING_SEC_SYNC') or 'Network & Professions'):gsub('^|%s*', '')
    sync.parent = mainName
    loot.name = (F.L('SETTING_SEC_LOOT') or 'Loot Advisor'):gsub('^|%s*', '')
    loot.parent = mainName
    lang.name = (F.L('SETTING_SEC_LANG') or 'Interface Language'):gsub('^|%s*', '')
    lang.parent = mainName
    about.name = (F.L('SETTING_SEC_ABOUT') or 'Об аддоне'):gsub('^|%s*', '')
    about.parent = mainName

    local registered = false
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local ok = pcall(function()
            local cat = Settings.RegisterCanvasLayoutCategory(main, mainName)
            S.blizzardCategory = cat
            Settings.RegisterAddOnCategory(cat)

            local subPanels = {
                {style, 'style'},
                {sync, 'sync'},
                {loot, 'loot'},
                {lang, 'lang'},
                {about, 'about'},
            }
            S.blizzardSubcategories = {}
            for _, pair in ipairs(subPanels) do
                local sub = pair[1]
                local key = pair[2]
                local subCat = Settings.RegisterCanvasLayoutSubcategory(cat, sub, sub.name)
                S.blizzardSubcategories[key] = subCat
                S.blizzardSubcategories[sub.name] = subCat
            end
        end)
        if ok and S.blizzardCategory then
            registered = true
        end
    end

    if not registered and InterfaceOptions_AddCategory then
        pcall(function()
            InterfaceOptions_AddCategory(main)
            InterfaceOptions_AddCategory(style)
            InterfaceOptions_AddCategory(sync)
            InterfaceOptions_AddCategory(loot)
            InterfaceOptions_AddCategory(lang)
            InterfaceOptions_AddCategory(about)
        end)
    end
end

function S.Open(subCategory)
    S.Ensure()
    S.RegisterBlizzardOptions()

    local opened = false
    if Settings and Settings.OpenToCategory and S.blizzardCategory then
        pcall(function()
            local targetCat = S.blizzardCategory
            if subCategory and S.blizzardSubcategories and S.blizzardSubcategories[subCategory] then
                targetCat = S.blizzardSubcategories[subCategory]
            end
            if targetCat and targetCat.GetID then
                Settings.OpenToCategory(targetCat:GetID())
                opened = true
            elseif targetCat then
                Settings.OpenToCategory(targetCat)
                opened = true
            end
        end)
    end
    if not opened and InterfaceOptionsFrame_OpenToCategory then
        pcall(function()
            local targetPanel = S.blizzPanels and S.blizzPanels.overview
            if subCategory and S.blizzPanels and S.blizzPanels[subCategory] then
                targetPanel = S.blizzPanels[subCategory]
            end
            if targetPanel then
                InterfaceOptionsFrame_OpenToCategory(targetPanel)
                InterfaceOptionsFrame_OpenToCategory(targetPanel)
                opened = true
            end
        end)
    end

    if not opened then
        S.languageMenu:Hide(); S.Refresh(); S.scroll:SetVerticalScroll(0); S.frame:Show()
    end
end

