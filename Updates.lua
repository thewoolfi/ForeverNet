local _,F=...
F.Updates={releasesURL='https://github.com/thewoolfi/ForeverNet/releases'}
local V=F.Updates
local function identifiers(text,numericRules)
    if text=='' or text:find('[^A-Za-z0-9%.%-]') or text:find('..',1,true) or text:sub(1,1)=='.' or text:sub(-1)=='.' then return end
    local values={}
    for value in text:gmatch('[^.]+') do
        if numericRules and value:match('^%d+$') and #value>1 and value:sub(1,1)=='0' then return end
        values[#values+1]=value
    end
    return values
end
function V.Parse(version)
    if type(version)~='string' or #version>64 then return end
    local base,build=version:match('^([^+]+)%+(.+)$')
    if base then if not identifiers(build,false) then return end else base=version end
    local major,minor,patch,suffix=base:match('^(%d+)%.(%d+)%.(%d+)(.*)$')
    if not major then return end
    local parts={major,minor,patch}
    for i,part in ipairs(parts) do
        if #part>5 or (#part>1 and part:sub(1,1)=='0') then return end
        parts[i]=tonumber(part)
    end
    if suffix~='' then
        if suffix:sub(1,1)~='-' then return end
        parts.pre=identifiers(suffix:sub(2),true); if not parts.pre then return end
    end
    return parts
end
function V.Newer(candidate,current)
    local a,b=V.Parse(candidate),V.Parse(current)
    if not a or not b then return false end
    for i=1,3 do if a[i]~=b[i] then return a[i]>b[i] end end
    if not a.pre or not b.pre then return not a.pre and b.pre~=nil end
    for i=1,math.max(#a.pre,#b.pre) do
        local x,y=a.pre[i],b.pre[i]
        if not x or not y then return x~=nil end
        if x~=y then
            local xn,yn=x:match('^%d+$')~=nil,y:match('^%d+$')~=nil
            if xn~=yn then return not xn end
            if xn and #x~=#y then return #x>#y end
            return x>y
        end
    end
    return false
end
function V.Startup()
    F.Print(F.version)
    local known=F.db.newerAddonVersion
    if type(known)=='table' and F.Text(known.source) and V.Newer(known.version,F.version) then
        V.latest,V.source,V.cached=known.version,known.source,true
    else F.db.newerAddonVersion=nil end
end
function V.Login()
    if V.loginChecked then return end
    V.loginChecked=true
    if V.cached and V.latest and F.db.settings.updateNotifications~=false and not V.notified then
        V.notified=true
        F.Print(string.format(F.L('UPDATE_PEER_CACHED'),V.source,V.latest,F.version))
    end
    V.ScheduleAll(8)
end
function V.Observe(version,sender)
    if not F.Text(sender) or sender=='' or F.IsSelf(sender) or not V.Newer(version,F.version) then return end
    if V.latest and not V.Newer(version,V.latest) then return end
    V.latest,V.source,V.cached=version,sender,nil
    F.db.newerAddonVersion={version=version,source=sender,seen=F.Now()}
    if F.db.settings.updateNotifications~=false and not V.notified then
        V.notified=true; F.Print(string.format(F.L('UPDATE_NOTIFICATION'),sender,version,F.version))
    end
    V.Refresh()
end
function V.Refresh()
    if not V.frame then return end
    F.Theme.RefreshFonts()
    V.frame:SetTitle('ForeverNet - '..F.L('ADDON_UPDATES'))
    V.installed:SetText(string.format(F.L('UPDATE_INSTALLED'),F.version))
    local newer=V.latest and V.Newer(V.latest,F.version)
    local status=newer and string.format(F.L('UPDATE_FOUND'),V.latest,V.source) or F.L('UPDATE_NOT_FOUND')
    V.status:SetText(status)
    F.Theme.Color(V.status,newer and 'missing' or 'text')
    V.notify.label:SetText(F.L('UPDATE_NOTIFY_SETTING'))
    V.notify:SetChecked(F.db.settings.updateNotifications~=false)
    V.check:SetText(F.L('UPDATE_CHECK_PEERS'))
    V.downloadLabel:SetText(F.L('UPDATE_DOWNLOAD'))
    V.copyHint:SetText(F.L('COPY_LINK_HINT'))
    V.instructions:SetText(F.L('UPDATE_INSTRUCTIONS'))
    local y=54
    local function place(region,gap)
        region:ClearAllPoints(); region:SetPoint('TOPLEFT',28,-y); region:SetHeight(0)
        y=y+region:GetStringHeight()+(gap or 12)
    end
    place(V.installed); place(V.status)
    V.notify:ClearAllPoints(); V.notify:SetPoint('TOPLEFT',24,-y)
    V.notify.label:SetHeight(0); y=y+math.max(28,V.notify.label:GetStringHeight()+5)+8
    V.check:ClearAllPoints(); V.check:SetPoint('TOPLEFT',28,-y)
    y=y+F.Theme.FitButton(V.check,500)+16
    place(V.downloadLabel,6)
    V.link:ClearAllPoints(); V.link:SetPoint('TOPLEFT',33,-y); y=y+32
    place(V.copyHint); place(V.instructions,18)
    V.frame:SetHeight(math.max(360,y))
end
function V.Open()
    if not V.frame then
        local frame=CreateFrame('Frame','ForeverNetUpdates',UIParent,'PortraitFrameTemplate')
        frame:SetSize(560,550); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN_DIALOG'); frame:SetClampedToScreen(true)
        frame:SetTitle('ForeverNet'); frame:SetPortraitToAsset(F.icon)
        F.Theme.Title(frame)
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
        V.background,V.backgroundBase=F.Theme.Background(frame)
        local function label(y,font)
            local l=frame:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight')
            l:SetPoint('TOPLEFT',28,y); l:SetWidth(500); l:SetJustifyH('LEFT'); l:SetWordWrap(true); l:SetSpacing(4)
            F.Theme.Text(l,font and font:find('Normal',1,true))
            return l
        end
        V.frame=frame; V.installed=label(-57,'GameFontNormalLarge')
        V.status=label(-98); V.status:SetHeight(72)
        V.notify=CreateFrame('CheckButton',nil,frame,'UICheckButtonTemplate')
        V.notify:SetSize(28,28); V.notify:SetPoint('TOPLEFT',24,-184)
        V.notify.label=V.notify:CreateFontString(nil,'OVERLAY','GameFontHighlight')
        V.notify.label:SetPoint('TOPLEFT',V.notify,'TOPRIGHT',4,-5); V.notify.label:SetWidth(467); V.notify.label:SetJustifyH('LEFT'); V.notify.label:SetWordWrap(true)
        F.Theme.Text(V.notify.label)
        V.notify:SetScript('OnClick',function(self) F.db.settings.updateNotifications=not not self:GetChecked() end)
        V.check=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        V.check:SetSize(320,26); V.check:SetPoint('TOPLEFT',28,-224)
        F.Theme.Button(V.check)
        V.check:SetScript('OnClick',function()
            local _,why=V.CheckNow()
            F.Print(why)
        end)
        V.downloadLabel=label(-274,'GameFontNormal')
        V.link=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
        V.link:SetSize(490,24); V.link:SetPoint('TOPLEFT',33,-300); V.link:SetAutoFocus(false)
        V.link:SetFontObject('GameFontHighlightSmall'); V.link:SetText(V.releasesURL)
        F.Theme.Font(V.link,12)
        V.link:SetScript('OnMouseUp',function(self) self:SetFocus(); self:HighlightText() end)
        V.link:SetScript('OnEditFocusGained',function(self) self:HighlightText() end)
        V.link:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        V.link:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
        V.link:SetScript('OnTextChanged',function(self) if self:GetText()~=V.releasesURL then self:SetText(V.releasesURL) end end)
        V.copyHint=label(-333,'GameFontHighlightSmall')
        V.instructions=label(-378,'GameFontHighlightSmall')
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetUpdates'
    end
    -- PortraitFrameTemplate puts its border/title/close button hundreds of
    -- levels above the body. Clear the entire settings frame, not just its base.
    local settings=F.Settings.frame
    local level=settings and settings:GetFrameLevel() or 0
    if settings then
        for _,key in ipairs({'NineSlice','PortraitContainer','TitleContainer','CloseButton'}) do
            local part=settings[key]
            if part then level=math.max(level,part:GetFrameLevel()) end
        end
    end
    if F.Settings.languageMenu then level=math.max(level,F.Settings.languageMenu:GetFrameLevel()) end
    V.frame:SetFrameLevel(level+10)
    if V.frame.SetFrameLevelsFromBaseLevel then V.frame:SetFrameLevelsFromBaseLevel(level+10) end
    V.Refresh(); V.frame:Show()
end
