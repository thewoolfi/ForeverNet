local _, F = ...
F.Minimap = {}
local M = F.Minimap
function M.Position()
    if not M.button or not Minimap then return end
    local angle = math.rad(tonumber(F.db.settings.minimapAngle) or 225)
    local x = math.cos(angle) * (Minimap:GetWidth()/2 + 8)
    local y = math.sin(angle) * (Minimap:GetHeight()/2 + 8)
    M.button:ClearAllPoints(); M.button:SetPoint('CENTER',Minimap,'CENTER',x,y)
end
function M.Drag()
    local cx,cy = Minimap:GetCenter()
    if not cx or not cy then return end
    local x,y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    F.db.settings.minimapAngle = math.deg(math.atan2(y/scale-cy,x/scale-cx)) % 360
    M.Position()
end
function M.Init()
    if M.button or not Minimap then return end
    local b=CreateFrame('Button','ForeverNetMinimapButton',Minimap)
    b:SetSize(31,31); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    b:RegisterForClicks('LeftButtonUp','RightButtonUp'); b:RegisterForDrag('LeftButton')
    local background=b:CreateTexture(nil,'BACKGROUND')
    background:SetTexture('Interface\\Minimap\\UI-Minimap-Background'); background:SetSize(24,24); background:SetPoint('TOPLEFT',2,-2)
    local icon=b:CreateTexture(nil,'ARTWORK')
    icon:SetTexture('Interface\\Icons\\Trade_Engineering'); icon:SetSize(20,20); icon:SetPoint('TOPLEFT',7,-5)
    icon:SetTexCoord(.08,.92,.08,.92)
    local border=b:CreateTexture(nil,'OVERLAY')
    border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder'); border:SetSize(53,53); border:SetPoint('TOPLEFT')
    b:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
    b:SetScript('OnClick',function(_,mouse)
        if M.suppressUntil and GetTime() < M.suppressUntil then return end
        if mouse == 'RightButton' then F.UI.Help() else F.UI.Toggle() end
    end)
    b:SetScript('OnDragStart',function(self)
        if GameTooltip then GameTooltip:Hide() end
        self:SetScript('OnUpdate',function() M.Drag() end)
    end)
    b:SetScript('OnDragStop',function(self)
        self:SetScript('OnUpdate',nil); M.Drag(); M.suppressUntil=GetTime()+.15
    end)
    b:SetScript('OnHide',function(self) self:SetScript('OnUpdate',nil) end)
    b:SetScript('OnEnter',function(self)
        M.Position()
        if GameTooltip then
            GameTooltip:SetOwner(self,'ANCHOR_LEFT'); GameTooltip:SetText('ForeverNet')
            GameTooltip:AddLine(F.L('MINIMAP_HINT'),1,1,1,true); GameTooltip:Show()
        end
    end)
    b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    M.button=b; M.Position(); M.ApplyVisibility()
end

function M.ApplyVisibility()
    if M.button then M.button:SetShown(F.db.settings.showMinimap~=false) end
end
