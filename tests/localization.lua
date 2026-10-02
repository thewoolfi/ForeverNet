local F=ForeverNet
assert(#F.LocaleOrder==12)
local function formats(text)
    local result={}; for token in text:gmatch('%%[ds]') do result[#result+1]=token end
    return table.concat(result)
end
for _,locale in ipairs(F.LocaleOrder) do
    assert(F.Locales[locale],locale)
    F.Command('language '..locale); assert(F.db.settings.locale==locale)
    for key,source in pairs(F.LocaleEnglish) do
        if locale~='ruRU' then assert(F.Locales[locale][key],locale..' missing '..key) end
        local text=F.L(key)
        assert(type(text)=='string' and text~='',locale..' empty '..key)
        assert(formats(text)==formats(source),locale..' invalid format '..key)
        assert(not text:find('ZXV',1,true) and not text:find('ZXQ',1,true),locale..' marker '..key)
        local args={}; for token in source:gmatch('%%[ds]') do args[#args+1]=token=='%d' and 2 or 'Example' end
        assert(pcall(string.format,text,unpack(args)),locale..' invalid formatting '..key)
    end
    F.UI.Help(); F.Settings.Open(); F.Updates.Open()
    assert(F.Settings.languageLabel:GetText()==F.L('LANGUAGE'))
    assert(F.Updates.installed:GetText():find(F.version,1,true))
    F.Settings.languageButton.scripts.OnClick(); assert(F.Settings.languageMenu:IsShown())
    F.Settings.languages[locale].scripts.OnClick(); assert(not F.Settings.languageMenu:IsShown())
end
F.Command('language auto'); clientLocale='frFR'; assert(F.L('PAGE_recipes')==F.Locales.frFR.PAGE_recipes)
clientLocale='unknown'; assert(F.L('PAGE_recipes')==F.LocaleEnglish.PAGE_recipes)
assert(F.Catalog.Fold('ÉLIXIR')==F.Catalog.Fold('élixir'))
assert(F.Catalog.Fold('ÖL ÄTHER STRASSE')==F.Catalog.Fold('öl äther Straße'))
assert(F.Catalog.Fold('POÇÃO AÇÃO')==F.Catalog.Fold('poção ação'))
assert(F.Catalog.Fold('ŒUVRE')==F.Catalog.Fold('œuvre'))
assert(F.Catalog.Fold('КОЖАНАЯ')==F.Catalog.Fold('Кожаная'))
assert(F.Catalog.Fold('治疗药水')=='治疗药水' and F.Catalog.Fold('치유 물약')=='치유 물약')
