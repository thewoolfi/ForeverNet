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
function V.Observe(version,sender)
    if sender==F.me or not V.Newer(version,F.version) then return end
    if V.latest and not V.Newer(version,V.latest) then return end
    V.latest,V.source=version,sender
    if F.db.settings.updateNotifications~=false then
        F.Print(string.format(F.L('UPDATE_NOTIFICATION'),sender,version,F.version))
    end
    V.Refresh()
end
function V.Refresh()
    if not V.frame then return end
    V.frame:SetTitle('ForeverNet - '..F.L('ADDON_UPDATES'))
    V.installed:SetText(string.format(F.L('UPDATE_INSTALLED'),F.version))
    local newer=V.latest and V.Newer(V.latest,F.version)
    V.status:SetText(newer and string.format(F.L('UPDATE_FOUND'),V.latest,V.source) or F.L('UPDATE_NOT_FOUND'))
    V.status:SetTextColor(newer and 1 or .85,newer and .8 or .85,newer and .25 or .85)
    V.notify.label:SetText(F.L('UPDATE_NOTIFY_SETTING'))
    V.notify:SetChecked(F.db.settings.updateNotifications~=false)
    V.check:SetText(F.L('UPDATE_CHECK_PEERS'))
    V.downloadLabel:SetText(F.L('UPDATE_DOWNLOAD'))
    V.copyHint:SetText(F.L('COPY_LINK_HINT'))
    V.instructions:SetText(F.L('UPDATE_INSTRUCTIONS'))
end
function V.Open()
    if not V.frame then
        local frame=CreateFrame('Frame','ForeverNetUpdates',UIParent,'PortraitFrameTemplate')
        frame:SetSize(560,550); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN_DIALOG')
        frame:SetTitle('ForeverNet'); frame:SetPortraitToAsset('Interface\\Icons\\INV_Misc_Book_09')
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
        local bg=frame:CreateTexture(nil,'BACKGROUND',nil,1)
        bg:SetPoint('TOPLEFT',6,-30); bg:SetPoint('BOTTOMRIGHT',-6,6); bg:SetColorTexture(.075,.055,.035,1)
        local function label(y,font)
            local l=frame:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight')
            l:SetPoint('TOPLEFT',28,y); l:SetWidth(500); l:SetJustifyH('LEFT'); l:SetWordWrap(true); l:SetSpacing(4)
            return l
        end
        V.frame=frame; V.installed=label(-57,'GameFontNormalLarge')
        V.status=label(-98); V.status:SetHeight(72)
        V.notify=CreateFrame('CheckButton',nil,frame,'UICheckButtonTemplate')
        V.notify:SetSize(28,28); V.notify:SetPoint('TOPLEFT',24,-184)
        V.notify.label=V.notify:CreateFontString(nil,'OVERLAY','GameFontHighlight')
        V.notify.label:SetPoint('LEFT',V.notify,'RIGHT',4,0); V.notify.label:SetWidth(467); V.notify.label:SetJustifyH('LEFT')
        V.notify:SetScript('OnClick',function(self) F.db.settings.updateNotifications=not not self:GetChecked() end)
        V.check=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
        V.check:SetSize(320,26); V.check:SetPoint('TOPLEFT',28,-224)
        V.check:SetScript('OnClick',function()
            local ok,why=F.Net.Sync()
            F.Print(ok and F.L('UPDATE_CHECK_QUEUED') or why)
        end)
        V.downloadLabel=label(-274,'GameFontNormal')
        V.link=CreateFrame('EditBox',nil,frame,'InputBoxTemplate')
        V.link:SetSize(490,24); V.link:SetPoint('TOPLEFT',33,-300); V.link:SetAutoFocus(false)
        V.link:SetFontObject('GameFontHighlightSmall'); V.link:SetText(V.releasesURL)
        V.link:SetScript('OnMouseUp',function(self) self:SetFocus(); self:HighlightText() end)
        V.link:SetScript('OnEditFocusGained',function(self) self:HighlightText() end)
        V.link:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        V.link:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
        V.link:SetScript('OnTextChanged',function(self) if self:GetText()~=V.releasesURL then self:SetText(V.releasesURL) end end)
        V.copyHint=label(-333,'GameFontHighlightSmall')
        V.instructions=label(-378,'GameFontHighlightSmall')
        UISpecialFrames[#UISpecialFrames+1]='ForeverNetUpdates'
    end
    V.Refresh(); V.frame:Show()
end
