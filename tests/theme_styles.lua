local F,T,U,S=ForeverNet,ForeverNet.Theme,ForeverNet.UI,ForeverNet.Settings
local native=GameFontNormal:GetFont()
U.Status(); S.Open(); F.Updates.Open(); F.Tracker.Toggle(true)
local sample=CreateFrame('Button',nil,UIParent,'UIPanelButtonTemplate')
sample:SetSize(110,24); sample:SetText('Native')
sample.Left=sample:CreateTexture(); sample.Left:SetTexture('native-left')
sample.Middle=sample:CreateTexture(); sample.Right=sample:CreateTexture()
sample.normal=sample:CreateTexture(); sample.normal:SetTexture('native-normal'); sample.normal:SetAlpha(.7)
sample.highlight=sample:CreateTexture(); sample.highlight:SetAtlas('native-highlight'); sample.highlight:SetPoint('CENTER')
function sample:GetNormalTexture() return self.normal end
function sample:GetHighlightTexture() return self.highlight end
T.Button(sample)
local section=CreateFrame('Frame',nil,UIParent,'BackdropTemplate'); T.Section(section)
local before=F.Codec.Encode(F.localProfile)
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale
    assert(T.SetStyle('classic'))
    assert(F.db.settings.uiStyle=='classic' and not S.styles.classic:IsEnabled())
    assert(sample.Left:IsShown() and not sample.flatFill:IsShown())
    assert(sample.normal:GetTexture()=='native-normal' and sample.normal:GetAlpha()==.7)
    assert(sample.highlight:GetAtlas()=='native-highlight' and sample.highlight.point[1]=='CENTER')
    for _,frame in ipairs({U.frame,S.frame,F.Updates.frame}) do
        assert(frame.NineSlice:IsShown() and frame.PortraitContainer:IsShown())
        assert(not frame.flatChrome:IsShown() and not frame.flatBase:IsShown())
        assert(frame:GetTitleText().point[1]=='CENTER')
    end
    assert(U.navigation.recipes:GetWidth()==60 and U.navigation.recipes:GetHeight()==48)
    assert(section.backdrop.edgeSize==10)
    for _,asian in ipairs({'koKR','zhCN','zhTW'}) do assert(S.languages[asian]:GetNormalFontObject():GetFont()==T.fontFiles[asian]) end
    assert(T.SetStyle('modern'))
    assert(sample.flatFill:IsShown() and not sample.Left:IsShown())
    assert(U.navigation.recipes:GetWidth()==44 and section.backdrop.edgeSize==1)
    assert(U.frame.flatChrome.backdropColor[4]==0 and U.frame.flatBase:IsShown())
    assert(F.Codec.Encode(F.localProfile)==before and GameFontNormal:GetFont()==native)
end
F.db.settings.locale='ruRU'; T.SetStyle('classic')
assert(U.heading:GetFont()==native and S.about:GetFont()==native)
T.SetStyle('modern'); assert(U.heading:GetFont()==T.defaultFont)
local count=T.fontCounter
for i=1,20 do T.SetStyle(i%2==0 and 'modern' or 'classic') end
assert(T.fontCounter==count and not T.SetStyle('invalid'))
T.SetStyle('classic')
-- Both style choices and favourites must survive a real fresh Lua runtime.
F.ToggleFavorite('market','item:777')
