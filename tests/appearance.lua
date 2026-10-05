local F,U=ForeverNet,ForeverNet.UI
U.Status(); F.Settings.Open(); F.Updates.Open()
assert(U.paper.texture==F.Theme.background and U.paperBase.color[4]==1)
assert(F.Settings.backgroundBase.color[4]==1 and F.Updates.backgroundBase.color[4]==1)
for _,base in ipairs({U.paperBase,F.Settings.backgroundBase,F.Updates.backgroundBase}) do
    assert(base.color[1]<.2 and base.color[2]<.2 and base.color[3]<.2)
end
assert(U.paper.alpha<=.10 and F.Settings.background.alpha<=.10 and F.Updates.background.alpha<=.10)
for _,text in ipairs({U.bodyText,U.sharing,U.searchLabel,U.item,F.Settings.about,F.Settings.checks[1].label,F.Updates.installed}) do
    assert(text.fontSize>=12 and text.fontFlags=='' and text.shadow[1]==0 and text.shadow[2]==0)
end
assert(U.bodyText.fontSize>=14 and F.Settings.about.fontSize>=14)
local localized=U.body:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
localized.fontFile='Fonts\\localized-CJK.ttf'; F.Theme.Text(localized)
assert(localized.fontFile=='Fonts\\localized-CJK.ttf')
assert(U.bodyText.color[1]>.8 and F.Settings.about.color[1]>.8 and F.Updates.installed.color[1]>.8)
local net=U.navigation.network
assert(net.template=='LargeSideTabButtonTemplate' and net.fillToInterior)
assert(net.Icon.texture:find('INV_Misc_GroupLooking',1,true))
local page=U.page
net.scripts.OnMouseUp(net,'RightButton',true); assert(U.page==page)
net.scripts.OnMouseUp(net,'LeftButton',false); assert(U.page==page)
net.scripts.OnMouseUp(net,'LeftButton',true); assert(U.page=='network')
assert(net.SelectedTexture:IsShown() and not U.navigation.recipes.SelectedTexture:IsShown())
F.Settings.frame:Hide()
local settings=U.navigation.settings
settings.scripts.OnMouseUp(settings,'LeftButton',true); assert(F.Settings.frame:IsShown())
assert(F.Updates.frame:GetFrameLevel()>F.Settings.frame.TitleContainer:GetFrameLevel())
F.db.settings.locale='ruRU'; U.Status(); assert(net.tooltipText=='Сеть')
local p=F.localProfile
p.recipes.test={name='Potion',output='item:123',quantity=1,profession='skill:171',blueprint=false,reagents={},stations={}}
U.Navigate('recipes')
assert(U.recipeHeaders[1].icon==nil) -- A section strip cannot look like an item card.
assert(U.recipeHeaders[1].label:GetText():find('(1)',1,true))
assert(U.recipeHeaders[1]:GetHeight()<U.rows[1]:GetHeight())
assert(U.recipeHeaders[1].label.color[1]>.8 and U.rows[1].label.color[1]>.8)
assert(U.rows[1].backdropColor[1]<.2 and U.rows[1].backdropColor[4]==1)
p.recipes.test.name=string.rep('Длинный рецепт ',12)
U.Status()
assert(U.rows[1]:GetHeight()>=U.rows[1].label:GetStringHeight()+14)
U.Show(''); local offset=U.ShowCards({{item='item:123',title=string.rep('Материал ',16),text=string.rep('Количество ',16)}})
local card=U.cards[1]
assert(card:GetHeight()>=card.title:GetStringHeight()+card.detail:GetStringHeight()+20)
assert(offset>=card:GetHeight()+6)
U.Show('Ready',nil,nil,'good'); assert(U.summary.color[2]>.8)
U.Show('Missing',nil,nil,'missing'); assert(U.summary.color[1]>.9 and U.summary.color[2]>.5)
-- Readable body, headings, muted metadata and state colors on every dark panel.
local function luminance(color)
    local function linear(c) return c<=.04045 and c/12.92 or ((c+.055)/1.055)^2.4 end
    return .2126*linear(color[1])+.7152*linear(color[2])+.0722*linear(color[3])
end
for _,color in pairs(F.Theme.colors) do
    for _,background in ipairs({U.paperBase.color,U.rows[1].backdropColor,card.backdropColor}) do
        assert((luminance(color)+.05)/(luminance(background)+.05)>=4.5)
    end
end
