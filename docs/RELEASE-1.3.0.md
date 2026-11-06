# ForeverNet 1.3.0

## English — changes since 1.2.1

- **Loot Discard Advisor**: Added an intelligent popup window when looting with full bags to quickly discard lowest-value junk and free space for loot.
  - Automatically sorts inventory items by unit vendor sell price, stack total price, and quality.
  - One-click discard with procedural vector trash icon.
  - One-click blacklist with procedural vector padlock icon (toggle protection for individual items).
  - Dynamic positioning: detects right screen edge and automatically flips to the left side of the WoW LootFrame to avoid overlapping.
  - Smart item protection: configurable toggles to protect crafting reagents and equipment from discard suggestions.
  - Configurable discard quality threshold (Poor, Common, Uncommon, Rare) and sort modes (By Price vs By Quality & Price).
  - Combat toggle: `Show advisor during combat` (enabled by default) with safe non-blocking cursor discard calls.
  - Chat commands: `/fn loot` to test-open advisor, `/fn loot on|off` to toggle the feature.
- **Blizzard Interface Options Integration**:
  - Full registration under `ESC -> Options -> AddOns -> ForeverNet` and `Loot Advisor` subpanel.
  - Clear section layout, interactive checkboxes, quality selection buttons, and blacklist management.
  - Standalone Settings dialog accessible via `/fn settings` or `/fn config`.
  - Added copyable GitHub and Boosty donation links in both Overview and "About Addon" panels.
- **Theme & Visual Enhancements**:
  - Added "Neon" UI style (cyan/azure modern flat theme with glow accents and dark backdrop).
  - Procedural vector controls: vector padlock (shackle, body, keyhole with locked/unlocked colors) and vector trash bin.
  - Cleaned up settings tabs, renaming "About" to "About Addon" and ensuring all 10 locales are updated.
- **Quality & Stability**:
  - Complete test coverage across 57 test suites under Lua 5.1.

Descriptions use base item IDs from the catalog. Saved recipes, bank snapshots, favorites and queue data are retained.

## Русский — изменения после 1.2.1

- **Помощник сумок (Loot Discard Advisor)**: Добавлено интеллектуальное окно при переполнении сумок во время сбора добычи, предлагающее быстро выбросить самый дешёвый мусор и освободить место для лута.
  - Автоматическая сортировка предметов по цене торговца за штуку, цене стопки и качеству.
  - Удаление в 1 клик компактной векторной кнопкой с корзиной.
  - Добавление в чёрный список в 1 клик векторной кнопкой-замком (вещь больше никогда не будет предлагаться к выбросу).
  - Умное позиционирование: определение правого края экрана и автоматический перенос окна сброса влево от окна добычи (`LootFrame`), чтобы не перекрывать его.
  - Защита ценных вещей: отключаемая защита ремесленных материалов и экипировки от предложения к выбросу.
  - Настраиваемый порог качества (Серый, Белый, Зелёный, Синий) и режимы сортировки (По цене / По качеству и цене).
  - Работа в бою: опция «Показывать помощник во время боя» (включена по умолчанию) с безопасным вызовом удаления без блокировки интерфейса.
  - Команды в чате: `/fn loot` для вызова окна, `/fn loot on|off` для включения/выключения.
- **Интеграция с параметрами интерфейса Blizzard**:
  - Полноценная регистрация категорий в меню `ESC -> Параметры -> Модификации -> ForeverNet` и подразделе `Помощник сумок`.
  - Интерактивные чекбоксы, переключатели качества и кнопка очистки чёрного списка.
  - Отдельное окно настроек аддона, открывающееся через `/fn settings` или `/fn config`.
  - Добавлены интерактивные поля для копирования ссылок на GitHub и Boosty в обзоре и разделе «Об аддоне».
- **Визуальные улучшения и темы**:
  - Добавлен стиль интерфейса «Неон» (современный неоновый дизайн с акцентными светящимися рамками).
  - Процедурные векторные иконки: замок (дужка, корпус, замочная скважина с переключением цвета сталь/золото) и мусорный бак.
  - Переименована вкладка «О программе» в «Об аддоне» и обновлена локализация на всех 10 языках.
- **Надёжность и тестирование**:
  - Полное покрытие тестами — все 57 тестовых наборов пройдены в среде Lua 5.1.

Описания используют базовые ID предметов из каталога. Сохранённые рецепты, снимки банка, избранное и очередь сохраняются.
