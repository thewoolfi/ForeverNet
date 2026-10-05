local F,U,S,V,T=ForeverNet,ForeverNet.UI,ForeverNet.Settings,ForeverNet.Updates,ForeverNet.Tracker
local function top(region) return -region.point[#region.point] end
local function textBottom(region) return top(region)+region:GetStringHeight() end
local function fits(button) assert(button:GetHeight()>=button.measure:GetStringHeight()+8) end
U.Status(); S.Open(); V.Open(); T.Toggle(true)
assert(S.frame:GetHeight()==600 and S.scroll.ScrollBar.template=='MinimalScrollBar')
assert(U.frame.clamped and S.frame.clamped and V.frame.clamped)
local normal=GameFontNormal:GetFont()
local measurements={}
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Status(); S.Refresh(); V.Refresh(); T.Render()
    local prior=0
    for _,check in ipairs(S.checks) do
        assert(top(check)>=prior)
        prior=top(check)+5+check.label:GetStringHeight()
    end
    assert(top(S.intervalLabel)>=prior)
    assert(S.intervals[60].point[2]>=S.intervalLabel.point[2]+S.intervalLabel:GetWidth()+12)
    assert(S.languageButton.point[2]>=S.languageLabel.point[2]+S.languageLabel:GetWidth()+12)
    assert(top(S.languageButton)>=textBottom(S.intervalLabel))
    assert(textBottom(S.about)<=top(S.githubLabel))
    assert(textBottom(S.githubLabel)<=top(S.githubLink))
    assert(top(S.githubLink)+24<=top(S.supportLabel))
    assert(textBottom(S.supportLabel)<=top(S.supportLink))
    assert(textBottom(S.linkHint)<=S.body:GetHeight())
    fits(S.languageButton); fits(S.updates)
    local before=top(S.bank)
    S.languageButton.scripts.OnClick(); assert(S.languageMenu:IsShown())
    assert(top(S.bank)==before+S.languageMenu:GetHeight()+8)
    S.languageButton.scripts.OnClick(); assert(top(S.bank)==before)
    assert(textBottom(V.status)<=top(V.notify))
    assert(top(V.notify)+5+V.notify.label:GetStringHeight()<=top(V.check))
    assert(top(V.check)+V.check:GetHeight()<=top(V.downloadLabel))
    assert(textBottom(V.instructions)<=V.frame:GetHeight()-18)
    fits(V.check)
    assert(-T.scroll.points.TOPLEFT[3]>=50+T.summary:GetStringHeight())
    U.Navigate('recipes'); U.OpenFilters()
    assert(U.filterMenu:GetHeight()<400)
    for _,control in ipairs(U.filterControls) do
        if control:IsShown() then
            fits(control)
            assert(control:GetNormalFontObject():GetFont()==U.bodyText:GetFont())
        end
    end
    U.filterMenu:Hide()
    U.Show('content',string.rep(F.L('SEARCH_LABEL')..' ',12),string.rep(F.L('CRAFTER'),12))
    local detailTop=-U.details.points.TOPLEFT[3]
    assert(detailTop>=textBottom(U.summary)+6)
    assert(U.detailTitle:GetHeight()==0 and U.summary:GetHeight()==0)
    U.crafter:SetText(string.rep(F.L('FINDER_BUTTON')..' ',5)); U.crafter:Show(); U.LayoutDetails()
    fits(U.crafter)
    assert(U.crafter.point[1]=='BOTTOMLEFT' and U.crafter.point[2]==12)
    assert(U.details.points.BOTTOMRIGHT[3]>=U.crafter:GetHeight()+20)
    U.Show('')
    local y=U.ShowSourceRows({{item='item:10',title='Material',text='Have: 1 / Need: 2'}})
    measurements[locale]=y
    assert(y<=76) -- Previously 102 px for the same one-line material card.
    assert(U.sourceRows[1].detail.point[2]>=42)
    local shortHeight=U.sourceRows[1]:GetHeight()
    local clicked=0
    U.ShowSourceRows({{item='item:10',title=string.rep('Long recipe ',16),text=string.rep('Reagent data ',15),
        actions={{text=string.rep('Long action ',14),hint='Explain',run=function() clicked=clicked+1 end},
            {text='Short',run=function() clicked=clicked+1 end}},
        extraAction={text=string.rep('Extra action ',14),run=function() clicked=clicked+1 end}},
        {section=true,title='Section',text='Info'}})
    local row=U.sourceRows[1]
    assert(row:GetHeight()>shortHeight and top(row.detail)>=textBottom(row.title))
    assert(top(row.buttons[1])>=textBottom(row.detail))
    assert(top(row.extraButton)>=top(row.buttons[1])+row.buttons[1]:GetHeight())
    assert(row:GetHeight()>=top(row.extraButton)+row.extraButton:GetHeight())
    fits(row.buttons[1]); fits(row.extraButton)
    row.buttons[1].scripts.OnEnter(row.buttons[1]); assert(F.Theme.tooltip:IsShown())
    row.buttons[1].scripts.OnLeave(); assert(not F.Theme.tooltip:IsShown())
    row.buttons[1].scripts.OnClick(row.buttons[1]); assert(clicked==1)
    U.ShowSourceRows({{title='Reused'}})
    assert(not row.buttons[1]:IsShown() and not row.extraButton:IsShown())
    assert(row.buttons[1].action==nil and row.buttons[1].hint==nil and row.extraButton.action==nil)
    assert(not U.sourceRows[2]:IsShown()) -- Old trailing rows must disappear even without U.Show.
end
assert(GameFontNormal:GetFont()==normal) -- No global font mutation.
F.db.settings.locale='enUS'; U.Navigate('network'); U.details:SetHeight(180)
local render=U.RenderSelection
U.RenderSelection=function() U.Show(''); U.body:SetHeight(500) end
U.details:SetVerticalScroll(280); U.dirty=true; U.Tick(.5)
assert(U.details:GetVerticalScroll()==280) -- Actual range 320; old hard-coded 240 clamps to 260.
U.details:SetVerticalScroll(290); U.qty:SetText('3'); assert(U.details:GetVerticalScroll()==290)
U.RenderSelection=function() U.Show(''); U.body:SetHeight(200) end
U.dirty=true; U.Tick(.5); assert(U.details:GetVerticalScroll()==20)
U.RenderSelection=render
S.languageButton.scripts.OnClick(); S.frame.scripts.OnHide(); assert(not S.languageMenu:IsShown())
