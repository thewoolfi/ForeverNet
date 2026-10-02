# Localization / Локализация

## English

Supported locale codes: `enUS`, `enGB`, `ruRU`, `deDE`, `frFR`, `esES`, `esMX`, `itIT`, `ptBR`, `koKR`, `zhCN`, `zhTW`. Auto follows `GetLocale()`; unsupported codes fall back to English. Choose a language in settings or use `/fn language LOCALE`.

`Locale.lua` contains English and Russian, the registry, and native language names. `Locales/*.lua` contains nine additional dictionaries loaded by the TOC. enGB shares the enUS dictionary. New dictionaries cover every English key. They are machine-assisted translations with reviewed core game terms and formatting, and remain open to native-speaker corrections.

Save files as UTF-8. Keep key names, command names, URLs, identifiers and format placeholders unchanged. Preserve the order of `%s`/`%d` substitutions and paragraph breaks. Item names and textures come from the game client when available; choosing an interface language does not translate the game database or another player's recipe text.

Run `python tests/run.py` after editing. Tests check dictionary coverage, format substitutions, UTF-8 search and settings/update window construction. Verify line wrapping, font coverage and terminology in game as well.

## Русский

Поддерживаются коды `enUS`, `enGB`, `ruRU`, `deDE`, `frFR`, `esES`, `esMX`, `itIT`, `ptBR`, `koKR`, `zhCN`, `zhTW`. Автовыбор использует `GetLocale()`, неизвестные коды — английский. Язык можно выбрать в настройках или командой `/fn language LOCALE`.

В `Locale.lua` находятся русский и английский словари, реестр и названия языков. В `Locales/*.lua` — девять дополнительных словарей из TOC. enGB использует enUS. Новые словари содержат все английские ключи. Они подготовлены с помощью машинного перевода с проверкой основных игровых терминов и форматирования; исправления носителей приветствуются.

Сохраняйте UTF-8, имена ключей, команд, URL, идентификаторы и порядок `%s`/`%d`. Сохраняйте абзацы. Названия предметов и текстуры поступают из клиента; смена языка аддона не переводит игровую базу и текст рецептов другого игрока.

После правок выполните `python tests/run.py`, затем проверьте переносы, шрифты и термины в игре.
