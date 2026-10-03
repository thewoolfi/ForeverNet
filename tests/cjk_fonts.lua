local F,T,U,S,V=ForeverNet,ForeverNet.Theme,ForeverNet.UI,ForeverNet.Settings,ForeverNet.Updates
clientLocale='ruRU'; F.db.settings.locale='ruRU'
U.Help(); S.Open(); V.Open()
Minimap=CreateFrame('Frame'); Minimap:SetSize(140,140); F.Minimap.Init()
local normal,normalSize=GameFontNormal:GetFont()
local body,bodySize=U.bodyText:GetFont()
local title=S.frame:GetTitleText():GetFont()
local search,searchSize=U.search:GetFont()
local originalButton=S.languageButton:GetNormalFontObject():GetFont()
-- Menu entries can be read before selecting an Asian locale on a Russian client.
for _,locale in ipairs({'koKR','zhCN','zhTW'}) do
    for _,state in ipairs({'Normal','Highlight','Disabled'}) do
        local font=S.languages[locale]['Get'..state..'FontObject'](S.languages[locale])
        assert(font:GetFont()==T.fontFiles[locale])
    end
end
assert(S.languages.ruRU:GetNormalFontObject():GetFont()==normal)
for _,locale in ipairs({'koKR','zhCN','zhTW'}) do
    S.languages[locale].scripts.OnClick()
    local path=T.fontFiles[locale]
    assert(U.bodyText:GetFont()==path and U.heading:GetFont()==path)
    assert(S.about:GetFont()==path and S.checks[1].label:GetFont()==path)
    assert(S.frame:GetTitleText():GetFont()==path and V.frame:GetTitleText():GetFont()==path)
    assert(U.search:GetFont()==path and U.qty:GetFont()==path)
    assert(V.link:GetFont()==path and S.supportLink:GetFont()==path)
    for _,b in ipairs({U.plan,U.help,U.filterButton,S.languageButton,V.check}) do
        for _,state in ipairs({'Normal','Highlight','Disabled'}) do
            local font=b['Get'..state..'FontObject'](b)
            assert(font~=GameFontNormal and font:GetFont()==path)
        end
    end
    U.scan.scripts.OnEnter(U.scan)
    assert(T.tooltip and T.tooltip:IsShown() and T.tooltip.title:GetFont()==path)
    U.scan.scripts.OnLeave(U.scan); assert(not T.tooltip:IsShown())
    U.navigation.recipes.scripts.OnEnter(U.navigation.recipes)
    assert(T.tooltip.title:GetFont()==path); U.navigation.recipes.scripts.OnLeave()
    F.Minimap.button.scripts.OnEnter(F.Minimap.button)
    assert(T.tooltip.line:GetFont()==path and T.tooltip.anchor=='ANCHOR_LEFT'); F.Minimap.button.scripts.OnLeave()
    -- New measured widgets also use the new language, rather than only old widgets.
    U.Show(''); U.ShowCards({{item='item:123',title=string.rep(F.L('SEARCH_LABEL'),25),text=F.L('BANK_REMINDER')}})
    local card=U.cards[1]
    assert(card.title:GetFont()==path and card.detail:GetFont()==path)
    assert(card:GetHeight()>=card.title:GetStringHeight()+card.detail:GetStringHeight()+20)
    assert(GameFontNormal:GetFont()==normal and GameFontHighlight:GetFont()==normal)
end
-- Restore original files and sizes when returning to Russian/English.
S.languages.ruRU.scripts.OnClick()
assert(U.bodyText:GetFont()==body and select(2,U.bodyText:GetFont())==bodySize)
assert(U.search:GetFont()==search and select(2,U.search:GetFont())==searchSize)
assert(S.frame:GetTitleText():GetFont()==title)
assert(S.languageButton:GetNormalFontObject():GetFont()==originalButton)
assert(GameFontNormal:GetFont()==normal and select(2,GameFontNormal:GetFont())==normalSize)
for _,locale in ipairs({'koKR','zhCN','zhTW'}) do assert(S.languages[locale]:GetNormalFontObject():GetFont()==T.fontFiles[locale]) end
-- Auto follows the client, and slash changes refresh all already-open windows.
clientLocale='koKR'; F.Command('language auto'); assert(U.bodyText:GetFont()==T.fontFiles.koKR)
F.Command('language ruRU'); assert(U.bodyText:GetFont()==T.fontFiles.koKR) -- bundled KR also contains Cyrillic
F.Command('language zhTW'); assert(S.about:GetFont()==T.fontFiles.zhTW and V.installed:GetFont()==T.fontFiles.zhTW)
clientLocale='ruRU'; F.Command('language auto'); assert(U.bodyText:GetFont()==body)
