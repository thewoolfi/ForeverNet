-- This client starts with 18px native button fonts, rather than the mock's 12px default.
local F,U,S,T=ForeverNet,ForeverNet.UI,ForeverNet.Settings,ForeverNet.Theme
F.db.settings.locale='ruRU'
U.Navigate('recipes'); S.Open()
for _,style in ipairs({'classic','modern'}) do
    T.SetStyle(style)
    for _,page in ipairs({'home','recipes','queue','market','network'}) do
        U.Navigate(page)
        local header=0
        for _,b in ipairs({U.scan,U.share,U.sync,U.plan,U.request,U.commands,U.help,U.filterButton}) do
            assert(b:GetHeight()>=b.measure:GetStringHeight()+8)
            assert(b:GetFontString():GetWidth()==b:GetWidth()-20)
            if b==U.scan or b==U.share or b==U.sync then header=math.max(header,b:GetHeight()) end
        end
        assert(U.paneTop>=48+header+12 and U.right:GetHeight()>320)
        assert(-U.listScroll.points.TOPLEFT[3]>=29+U.filterButton:GetHeight()+10 or not U.filterButton:IsShown())
    end
    S.languageMenu:Show(); S.Refresh()
    local rows={}
    for _,b in pairs(S.languages) do
        local y=-b.point[3]; rows[y]=math.max(rows[y] or 0,b:GetHeight())
        assert(y+b:GetHeight()+5<=S.languageMenu:GetHeight())
    end
    local ys=F.Keys(rows)
    for i=2,#ys do assert(ys[i]>=ys[i-1]+rows[ys[i-1]]+4) end
    U.QueueSetDialog('save')
    local d=U.setDialog
    assert(d.first.point[1]=='BOTTOMLEFT' and d.scroll.points.BOTTOMRIGHT[3]>=d.first:GetHeight()+54)
    d.name:SetText(''); d.first.scripts.OnClick(d.first)
    assert(d.error.point[3]>=14+d.first:GetHeight()+8)
    d:Hide()
end
