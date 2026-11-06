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


# ForeverNet 1.2.1

## English — changes since 1.2.0

- Fixed crafting-material badge false positives on grey junk / vendor trash items (quality 0 / poor, such as Broken Fang, Chipped Claw, Bent Copper Tube, etc.).
- Cleaned up `KNOWN_MATERIALS` catalog: removed raw numeric ID ranges that erroneously included grey monster drops and crafted equipment.
- Immediate quality filtering: items with quality 0 (`Enum.ItemQuality.Poor`) are unconditionally rejected from material checks and badge rendering across all bags and bank frames.

Descriptions use base item IDs from the catalog. Saved recipes, bank snapshots, favorites and queue data are retained.

## Русский — изменения после 1.2.0

- Исправлено ошибочное появление значков-молоточков на сером мусоре (предметы низкого качества / Poor quality 0, например «Сломанный клык», «Надломанный коготь», «Гнутая медная трубка» и др.).
- Очищен справочник `KNOWN_MATERIALS`: удалены сырые диапазоны ID, содержавшие серую добычу с мобов и готовую экипировку.
- Мгновенная фильтрация по качеству: предметы с качеством 0 (`Enum.ItemQuality.Poor`) гарантированно исключаются из проверки материалов и никогда не помечаются значками в сумках и банке.

Описание относится к базовому ID из каталога. Сохранённые рецепты, снимки банка, избранное и очередь сохраняются.


# ForeverNet 1.2.0

## English — changes since 1.1.1

- Added golden crafting-material hammer badges to items in bags and personal bank.
- Reagents and Trade Goods across all professions (herbs, ore, bars, cloth, leather, gems like Shadowgem, enchanting elements, parts and cooking ingredients) are marked automatically without requiring scanned recipes.
- Material badges use a soft circular golden border with hardware-accelerated clipping inside addon scroll frames.
- Added a toggle for material badges in the Settings window and via chat command `/fn badges on|off`.
- Added an expandable "Bank materials" overview card on the Home tab listing stored crafting reagents from the bank snapshot.
- Robust container sweeping: full compatibility with Modern combined bags (`ContainerFrameCombinedBags`), classic numbered bags (`ContainerFrame1..14`), classic bank slots, and modern unified `BankPanel`.
- Fixed badge visibility lifecycle: bank badges cleanly disappear when the bank closes without hiding bag badges.

Descriptions use base item IDs from the catalog. Saved recipes, bank snapshots, favorites and queue data are retained.

## Русский — изменения после 1.1.1

- Добавлены золотые значки-молоточки для ремесленных материалов в сумках и личном банке.
- Реагенты и хозяйственные товары всех профессий (трава, руда, слитки, ткань, кожа, камни вроде Камня теней, части инженерии, ингредиенты кулинарии) отмечаются автоматически для всех профессий без необходимости иметь изученный рецепт.
- Значки используют мягкую закруглённую золотистую рамку и аппаратное отсечение границами списков аддона.
- Добавлена настройка включения и отключения значков в окне настроек и через команду `/fn badges on|off`.
- На вкладке «Главная» добавлена карточка «Материалы в банке» с раскрывающимся списком реагентов из сохранённого снимка банка.
- Надёжный обход сумок и банка: полная поддержка объединённых сумок (`ContainerFrameCombinedBags`), классических раздельных сумок (`ContainerFrame1..14`), слотов классического банка и современного `BankPanel`.
- Исправлено отображение значков при закрытии банка: значки банка исчезают сразу при закрытии, не затрагивая значки на открытых сумках.

Описание относится к базовому ID из каталога. Сохранённые рецепты, снимки банка, избранное и очередь сохраняются.


# ForeverNet 1.1.1

## English — changes since 1.1.0

- Hold Shift while hovering equipment to compare it with currently equipped items, including native stat differences and paired-slot comparisons. Pressing or releasing Shift updates the comparison without moving the mouse.
- Restored Requests as a permanent sidebar tab for direct access from every page.
- Added native WoW item tooltips: armor, stats, effects and requirements now appear when hovering an item. Planning quantities, bank counts and price hints remain below the description.
- Tooltips cover recipes, network cards, sidebar items, selected items, production chains and reagents, queue materials/crafts, market, tracker and auction results. Uncached items show a loading message and refresh when data arrives; reused and hidden cards clear stale tooltips.
- Restored recipe chat-link buttons beside recipe names in the native profession window. Click to insert the recipe link into a chat draft, then press Enter to send. With ForeverLink enabled, its existing button is used without a duplicate.
- Auction results now use compact rows with item icons and individual hover targets. Both Modern and Classic appearances and all 12 interface languages are supported.
- Expanded diagnostics for intermittent bag item-use blocks: bank scan stages, open windows, combat state and available native security attribution are recorded. `/fn taint status` shows the current logging level; detailed bank tracing runs only after enabling diagnostics.

**Known issue:** the intermittent block when using an item from a bag remains under investigation. This update improves diagnostics; a fix is not confirmed.

Descriptions use base item IDs from the catalog, without a particular inventory copy's enchantments or random variants. Saved recipes, bank snapshots, favorites and queue data are retained.

## Русский — изменения после 1.1.0

- Удерживайте Shift при наведении на экипировку для сравнения с надетыми вещами: штатная разница характеристик и сравнение парных слотов. Нажатие и отпускание Shift обновляют подсказки без движения мыши.
- Вкладка «Запросы» снова постоянно отображается в боковой панели и открывается напрямую с любой страницы.
- Добавлены штатные подсказки предметов WoW: при наведении видны броня, характеристики, эффекты и требования. Количества для плана, запасы банка и подсказки о цене остаются ниже описания.
- Подсказки работают в рецептах, карточках сети, списках слева, выбранном предмете, цепочках и реагентах, материалах и крафтах очереди, рынке, трекере и результатах аукциона. Для незагруженных предметов показывается сообщение о загрузке с последующим обновлением; скрытые и повторно используемые карточки очищают старую подсказку.
- Возвращены кнопки ссылки на рецепт рядом с названиями в штатном окне профессии. Нажмите кнопку для вставки ссылки в черновик чата, затем Enter для отправки. При включённом ForeverLink используется его кнопка без дубля.
- Результаты аукциона представлены компактными строками с иконками и отдельной областью наведения. Поддерживаются обе темы и все 12 языков интерфейса.
- Расширена диагностика редкой блокировки предметов из сумки: сохраняются этапы сканирования банка, открытые окна, состояние боя и доступные сведения об источнике taint. `/fn taint status` показывает текущий уровень журнала; подробная запись этапов банка работает после включения диагностики.

**Известная проблема:** редкая блокировка использования предметов из сумки ещё исследуется. Улучшена диагностика; исправление не подтверждено.

Описание относится к базовому ID из каталога; чары и случайные варианты конкретного экземпляра из сумки не отображаются. Сохранённые рецепты, снимки банка, избранное и очередь сохраняются.


# ForeverNet 1.0.0 Release

## English

This release brings the saved crafting queue, personal stock planning and auction-price tools together with the profession network. It includes all changes since 0.4.0 Beta:

- Character overview, up to 50 queue goals, 10 goal sets, maintained stock and a movable tracker.
- Native profession actions and exact-item crafter search, including supported unlearned recipes.
- Auction tab, targeted scans, purchase estimates and observed daily history; whole-plan material-source comparisons.
- Compact dark UI, profession grouping, filters, favorites, locale-aware CJK text and fixes for filter initialization, tab anchoring and overlapping recipe blocks.
- Improved message recovery: brief pauses retain progress; identical snapshots are coalesced; codes 3/8 retain the queue and adapt pacing; code 11 uses bounded backoff without repeated chat notices.
- Removed the recipe-chat-link integration and its unused translations from ForeverNet. The separate ForeverLink addon was prepared privately and is not included or published here.

Manual crafting/buying remain required. Price history is based on observed scans, equipment variants are not priced and client messaging restrictions may still pause exchange. The reported protected item-use popup after visiting a bank remains under investigation; native auction/layout verification continues.

Install by replacing the ForeverNet folder in Interface/AddOns, then /reload; retain SavedVariables. After first installing the bundled CJK fonts, restart the client. Both players should update for matching UI/transport behavior.

## Русский

Релиз объединяет сохраняемую очередь изготовления, учёт личных запасов и аукционные цены с сетью профессий. Включены накопленные изменения после 0.4.0 Beta:

- Обзор персонажа, до 50 целей очереди, 10 наборов, поддержание запаса и подвижный трекер.
- Действия в штатной профессии и поиск мастеров по предмету, включая распознаваемые неизученные рецепты.
- Вкладка аукциона, целевое сканирование, оценка покупок, наблюдавшаяся история цен и сравнение источников всего плана.
- Компактный тёмный UI, группировка, фильтры, избранное, CJK и исправления фильтра, привязки вкладки/наложения блоков.
- Надёжнее очередь сообщений: прогресс коротких пауз сохраняется, дубли объединяются, 3/8 не удаляют очередь, скорость адаптируется, 11 ждёт без спама.
- Модуль ссылок рецептов и неиспользуемые переводы удалены из ForeverNet. ForeverLink подготовлен отдельно локально, в этом выпуске не распространяется и не публикуется.

Крафт/покупка ручные. История состоит из наблюдений, варианты экипировки не оцениваются, клиентские ограничения могут задерживать обмен. Причина блокировки еды после банка ещё исследуется; проверка штатного интерфейса/аукциона продолжается.

Замените папку ForeverNet в Interface/AddOns и выполните /reload, сохранив SavedVariables. После первой установки CJK перезапустите клиент. Обновление обоих игроков обеспечивает одинаковое поведение интерфейса/транспорта.


# Local network rate-limit handling — 2026-10-04

The supplied /fn netstatus screenshot shows SendAddonMessage result=3, paused=false, no code-11 results, 29 queued fragments and an accepted fragment one second earlier. The currently observed restriction is a send-rate limit (AddonMessageThrottle), with intermittent progress; the screenshot alone does not show queue loss or the cause of the earlier lockdown.

A separate reproducible bug was found: codes 3/8 discarded the entire queue after 20 retries of a fragment. Rate limits now retain the queue for automatic retry, with silent 1/2/4/8/15-second backoff capped at 15 seconds. The regular interval adapts from 0.25 to 0.5 to 1 second after refusals, and reduces one step only after at least 60 stable seconds and 32 accepted fragments. Learned pacing is session-local. Accepted messages clear the rate-limit status. Code 11 retains its separate lockdown state/backoff; switching between 11 and 3 reports the actual current state. /fn netstatus adds Throttled, Send interval and rejection counts; the Network panel shows NET_THROTTLE in all 12 locales. No rate-limit notices spam chat. Permanent failures retain their existing explicit error path. The user's one-minute automatic sync setting is preserved, and disabling sharing clears transient pacing.

Validation: the new test failed on prior code with "Rate limits discard the entire queue after 20 retries"; all 46 Lua 5.1 groups pass after repair. Cases cover both 3 and 8 beyond 20 refusals, five blocked minutes of one-minute automatic sync with bounded attempts/no queue growth/no chat notices, complete profile decoding after recovery, actual pacing intervals and slow speed recovery, 11-to-3 transition, diagnostics without sending, 12 locales/CJK glyph coverage, share-off reset and permanent error 5. These mock tests do not establish the live client's rate budget or delivery to a real peer. Installed locally, with source/install/ZIP equality and CRC; public ZIP unchanged. No Git commit/push/release/CurseForge update. The earlier protected item-use report after bank remains unresolved.

Новый скриншот /fn netstatus: result=3, paused=false, отказов 11 нет, очередь 29 фрагментов, последний принятый фрагмент секунду назад. Сейчас наблюдается лимит частоты AddonMessageThrottle с частичным прогрессом. Сам скриншот не доказывает потерю очереди и не объясняет прежний code11.

В коде найден отдельный воспроизводимый дефект: после 20 отказов 3/8 очередь полностью удалялась. Теперь она сохраняется, повторная отправка автоматическая. При последовательных отказах ожидание 1/2/4/8/15 секунд, максимум 15. Обычный интервал передачи адаптируется 0.25/0.5/1 секунды; ускорение на один шаг допускается лишь после 60 стабильных секунд и 32 принятых фрагментов. Параметры скорости только в памяти текущей сессии. Успех снимает статус лимита. Code11 сохраняет отдельную паузу/ожидание; переход 11→3 отражает текущее состояние. В /fn netstatus добавлены Throttled/Send interval/счётчики, в «Сети» локализованный NET_THROTTLE на 12 языках. При лимите чат не спамит; постоянные ошибки по-прежнему сообщаются явно. Интервал автообновления 1 минута сохранён; выключение обмена очищает временную скорость/ожидание.

Новая проверка сначала упала на прежнем коде: Rate limits discard the entire queue after 20 retries. После исправления прошли 46 групп Lua 5.1: оба кода более 20 отказов, 5 минут паузы при авто 1 минута, ограничение попыток/роста очереди/чата, полная сборка профиля после восстановления, интервалы передачи/медленное ускорение, переход 11→3, чтение диагностики без отправки, 12 языков/CJK глифы, выключение обмена и постоянная ошибка 5. Mock не доказывает лимиты реального клиента или доставку живому участнику. Установлено локально, исходники/игра/ZIP совпадают, CRC проверен, публичный ZIP сохранён. Commit/push/публикаций нет. Причина прежней блокировки еды после банка всё ещё неизвестна.

# Local network recovery — 2026-10-04

The new screenshot shows NET_LOCKDOWN, the notice emitted only when SendAddonMessage returns AddOnMessageLockdown (11). It does not identify why the client restricts sending. This is a separate symptom from the protected item-use popup reported earlier; that root cause remains unresolved.

The recovery path had a reproducible defect: each rejection restarted all logical transfers with new tokens on the next attempt. Intermittent acceptance/rejection could repeatedly send fragment 1 and never finish a profile. Short interruptions now preserve tokens and progress. Only a partial transfer idle for at least 120 seconds or alive for at least 840 seconds is restarted, allowing margin before receiver limits of 150/900 seconds. Unsent transfers are not retokenized. Transfer timing and counts are session-local transport metadata and are not encoded into the wire payload.

Consecutive code-11 rejections back off 2/4/8/16/30 seconds, capped at 30; an accepted fragment resets the delay. A held-queue episode gets at most one chat notice, with at least 120 seconds between notices for separate episodes. The Network panel and /fn netstatus still expose the pause. Identical pending HELLO and REQUEST payloads on the same channel are coalesced; changed requests and other channels remain separate. Existing PROFILE revision/follow-up behavior remains. Disabling sharing clears the pending state. No combat/chat-flag pre-gate, alternate channel bypass or restriction-setting changes were added. Refresh settings, including one minute, are retained.

Diagnostics now show pause/retry wait, rejection/restart counts and the age of the last accepted fragment, alongside original result/queue/chat flags. Calling diagnostics sends nothing. The client may continue returning 11: this patch repairs local recovery, not the underlying client policy or its unknown trigger.

Validation: the new intermittent-rejection assertion failed on previous code; after fixing it all 45 Lua 5.1 groups passed. Covered complete profile reconstruction with one token, bounded attempts/notices over five blocked minutes with one-minute auto refresh, duplicate manual sync/request snapshots versus changed status, idle and total-lifetime restart, diagnostic reads, disabled sharing, plus existing enum/chat-flag/TTL and UI regressions. These are mock API tests, not a live WoW reproduction or proof of peer delivery. Installed locally; no commit/push/release/CurseForge publication. Public ZIP unchanged.

Новый скриншот показывает NET_LOCKDOWN: это сообщение выводится при фактическом AddOnMessageLockdown (11) от SendAddonMessage. Причину клиентского ограничения он не раскрывает. Это другой симптом, чем блокировка еды после банка; причина той блокировки всё ещё не установлена.

Подтверждён дефект повторной отправки: каждый отказ приводил к перезапуску всех логических сообщений с новыми токенами на следующей попытке. Если успех и отказ чередовались, отправлялся первый фрагмент, затем всё начиналось заново и профиль не собирался. При короткой паузе теперь сохраняются токен и прогресс. Перезапускается только частичная передача без успешного фрагмента 120 секунд или общей жизни 840 секунд — с запасом до лимитов приёмника 150/900. Ещё не начатые сообщения не перезапускаются. Время передачи и счётчики существуют только в памяти транспорта, не входят в payload.

При последовательных отказах 11 ожидание растёт 2/4/8/16/30 секунд, максимум 30; успех сбрасывает задержку. Одно уведомление на эпизод удерживаемой очереди и не чаще одного в 120 секунд между эпизодами; статус остаётся в «Сети» и /fn netstatus. Одинаковые ожидающие HELLO/REQUEST одного канала объединяются; изменённые запросы/другие каналы сохраняются отдельно. PROFILE по-прежнему учитывает ревизию и отложенную новую версию. Выключение обмена очищает ожидание. Общие chat-флаги и бой не используются как предварительный запрет, обходов ограничения/подмены канала нет. Пользовательский интервал 1 минута сохранён.

/fn netstatus дополнен состоянием паузы, ожиданием попытки, количеством отказов/перезапусков и временем последнего принятого API фрагмента. Чтение диагностики ничего не отправляет. Если клиент продолжит возвращать 11, сам запрет останется: исправлено поведение очереди, а не неизвестная причина ограничения.

Регрессия чередования успех/отказ сначала упала на прежнем коде. После исправления прошли 45 групп Lua 5.1: полная сборка профиля с одним токеном, ограничение попыток/сообщений за пять минут паузы с авто 1 минута, одинаковые ручные sync/снимки запросов и изменение статуса, idle/total TTL, чтение диагностики, выключение обмена, прежние интерфейсные/сетевые проверки. Mock не воспроизводит настоящий клиентский запрет и не доказывает доставку живому игроку. Установлено локально, публичный ZIP сохранён, commit/push/публикаций не было.

# Local recipe-panel overlap fix — 2026-10-04

The user's screenshot confirmed that material cards overlapped the recipe calculation. UI.ShowBlocks measured the last block position but did not return it, so RenderSelection passed nil to ShowCards and cards started at offset zero. Returning the measured end position preserves the compact design and places materials below the calculation, with crafters following the material rows.

Regression: the new overview/material separation assertion failed on the previous code with "Material cards overlap the recipe calculation". After the fix all 44 Lua 5.1 groups pass. Additional cases cover all 12 locales, multiline overview at a nonzero offset, material/master separation, empty material lists and final scroll-body extent. These tests use mock font metrics; native rendering remains to check after /reload. No new native APIs, fonts, textures or reference sources were required: this was a local composition return-value error. Installed locally, public ZIP unchanged, no commit/push/publication. The unrelated protected-action report after visiting the bank remains unresolved; existing diagnostics are retained.

Скриншот подтвердил наложение материалов на расчёт рецепта. UI.ShowBlocks вычислял конечную вертикальную позицию, но не возвращал её; RenderSelection передавал nil в ShowCards, карточки начинались с нулевого отступа. Добавлен возврат измеренной позиции. Материалы располагаются после расчёта, список мастеров — после материалов; компактный дизайн сохранён.

Новая проверка разделения расчёта и материалов сначала воспроизвела ошибку на прежнем коде: Material cards overlap the recipe calculation. После исправления прошли все 44 группы Lua 5.1. Дополнительно проверены 12 языков, многострочный расчёт с ненулевым начальным отступом, граница материалов/мастеров, пустой список материалов и высота прокручиваемой области. Метрики в mock приближённые, новый вид в клиенте ещё проверить после /reload. Штатных API/текстур/шрифтов и новых источников не потребовалось: причина в возврате значения собственной функции. Установлено локально, публичный ZIP сохранён; commit/push/GitHub/CurseForge не выполнялись. Блокировка еды после банка остаётся нерешённой, диагностика сохранена.

# Local right panel and protected-action diagnostics — 2026-10-04

Right-panel contents now prioritize useful data: recipe counts before materials, materials in two measured columns, and crafter names without repeating the item name. A single crafter is identified in the header without a duplicate block. Covered materials omit irrelevant missing-price messages. Passive stock/material entries use compact list rows; rows containing actions retain cards and their controls. Queue goals precede set management, and supplied stock is collapsed until requested. Headers, spacing and reused widgets were reviewed; primary body text remains readable and secondary list data uses the existing small font. Long translations expand measured heights.

The user reported a protected-action popup when eating food from a bag outside combat after opening the bank. No root cause has been established. Bank.lua reads stock through C_Bank/C_Container and does not modify native bank/item buttons or invoke item use. No taint log was available. Bootstrap now records the latest five ADDON_ACTION_BLOCKED/ADDON_ACTION_FORBIDDEN events attributed to ForeverNet, their function, bounded diagnostic stack and bank/auction state in private SavedVariables. Notifications are limited to one per 30 seconds. This observes a block; it does not prevent, suppress or repair it.

Use /reload to load this build, then /fn taint on, repeat bank open/close and eating from a bag, and inspect /fn taint status. /fn taint on explicitly enables native taintLog=2; /fn taint off restores the previous setting. Logs/taint.log may need a reload/logout to flush. Do not edit live SavedVariables. Diagnostics, bank snapshots and queues are not shared with peers.

Validation: 44 Lua 5.1 groups passed, including all 12 locales, card reuse/long text/two-column geometry, goal-first queue and expandable stock, read-only bank scan, unchanged native item-use functions in mocks, bounded event capture and CVar restoration. Mocks cannot reproduce the client's secure execution or establish the origin of taint. Native rendering and the protected-action repro remain pending. This build is installed locally; no Git commit/push, release or CurseForge publication occurred.

Правая панель уплотнена: сначала расчёт рецепта, затем материалы в двух колонках. У мастеров убраны повторения названия вещи; единственный мастер указан в заголовке без дублирующего блока. Для покрытых запасом реагентов не выводятся сообщения о неизвестной цене дефицита. Обычные материалы/запасы показаны короткими строками, карточки с действиями сохраняют кнопки. Цели очереди выше управления наборами, имеющиеся запасы раскрываются по кнопке. Уменьшены отступы и заголовки; основной текст сохранён, вторичные данные списка используют существующий малый шрифт. Длинные переводы увеличивают измеряемую высоту.

Пользователь уточнил: еда из сумки, вне боя, перед этим открывал банк. Причина блокировки защищённого действия НЕ установлена и НЕ исправлена. В Bank.lua найдены только чтение API и сохранение запасов; записи в штатные кнопки банка/сумок и вызовы использования предметов не найдены. Файла taint.log не было. Добавлена диагностика: последние 5 собственных ADDON_ACTION_BLOCKED/FORBIDDEN, точная функция, ограниченный стек и состояние банка/аукциона в private db.diagnostics; уведомление не чаще раза в 30 секунд. Нативная блокировка не подавляется.

После /reload: /fn taint on, открыть/закрыть банк и повторить еду из сумки. /fn taint status показывает события. /fn taint off восстанавливает прежний taintLog; журнал Logs/taint.log может сброситься на диск после /reload или выхода. Живые SavedVariables не редактировались. Диагностика не рассылается участникам сети.

44 группы Lua 5.1 прошли; лог outputs/right-panel-tests.txt. Проверены 12 языков, две колонки/длинный текст/переиспользование, очередь и раскрытие запасов, чтение банка без изменения нативных функций, ограничение записей/уведомлений и восстановление CVar. Мок не воспроизводит защищённую среду WoW: реальная отрисовка и источник блокировки остаются к проверке в игре. Установлено локально, без commit/push/GitHub/CurseForge; публичный ZIP сохранён.

# Local horizontal toolbar correction — 2026-10-04

The screenshot showed a real layout miss in the previous ui-compact build: profession actions were still below quantity while the right-hand side was empty. The panel now measures the quantity label, reserves a compact left metadata column, and places all three actions to its right in the same band when space permits. Button widths follow their actual natural text widths plus shared spare space; the former 640-unit width cap and the redundant visible ForeverNet heading are removed. Narrow panels fall back to two action rows; errors appear below the toolbar only when needed. No labels are shortened and no font sizes are reduced.

Скриншот подтвердил недостаток предыдущей ui-compact: кнопки оставались под количеством, а справа была пустая область. Теперь слева компактные поля количества/выхода, справа в той же полосе три действия. Ширины кнопок учитывают естественную ширину текста и доступное место. Убраны ограничение ширины панели 640 и отдельный видимый заголовок ForeverNet; название/инструкция доступны в подсказке панели. Узкая панель использует перенос, ошибки добавляют строку только при наличии. Тексты не сокращены, шрифты не уменьшены.

# Local compact interface — 2026-10-04

- Scrolling 600-unit Settings; measured headers/buttons/filter rows, locale-aware CJK filter fonts, compact source cards and profession actions, queue hints, responsive auction/update/tracker layout. Fixed actual-range scroll preservation and stale recycled rows/actions. 41 Lua 5.1 groups; installed locally, native visual check still required.
- Настройки с прокруткой высотой 600, измеряемые заголовки/кнопки/строки фильтров и CJK-шрифты, компактные карточки и панель профессии, подсказки очереди, адаптивное размещение аукциона/обновлений/трекера. Исправлены сохранение прокрутки и старые строки/действия. 41 группа Lua 5.1; установлено локально, внешний вид в игре ещё проверить.

# Local crafter finder — 2026-10-04

- Native Find a crafter action for learned/unlearned recipes with supported item outputs; exact-item matches, other players only, profile favorites, profession/skill/age, matching recipe groups and pinned-crafter plans. Click-time guards for changed profiles/schematics; read-only lookup with no sync/message or own-recipe capture. All 12 locales, 40 Lua 5.1 test groups; local installation only.
- «Найти мастера» в штатной профессии для изученных/неизученных рецептов с предметом-результатом; точный ID, исключение себя, избранное, профессия/навык/возраст, группы подходящих рецептов и планы с выбранным мастером. Проверка изменившихся профилей/схем при нажатии; поиск без обновления сети, сообщений или добавления собственного рецепта. Все 12 языков, 40 групп Lua 5.1; установлено локально, не опубликовано.

# Local maintained stock — 2026-10-04

- Persistent queue stock targets, refill after use, shared bags/enabled bank, bank-retained finished stock versus actual withdrawal inputs, private saved-set modes and duplicate-rule guards. Measured mode controls, wrapped dialog errors and one native count per unique inventory item. All 12 locales, 39 Lua 5.1 test groups; local installation only.
- Постоянный запас в очереди, новый дефицит после расходования, общие сумки/включённый банк, сохранение готового запаса в банке с переносом только нужных реагентов, режимы в личных наборах и запрет дублей правил. Измеряемые кнопки/ошибки и один запрос счётчика на уникальный предмет. Все 12 языков, 39 групп Lua 5.1; установлено локально, не опубликовано.

# Local queue sets — 2026-10-04

- Up to 10 private goal sets per character: preview, replace/append, pinned recipes, source conflicts, atomic bounds, live inventory and one-step queue undo. Bag-only cleanup distinguishes owned finished goods from ready materials/planned batches; repeated item targets clear only when all are covered. All 12 locales, 38 Lua 5.1 test groups. Local installation only.
- До 10 личных наборов целей на персонажа, просмотр перед заменой/добавлением, закреплённые рецепты, сохранение текущих спорных источников, пересчёт по живым запасам и отмена последней загрузки/очистки. Очистка только по готовым вещам на руках; одинаковые предметы — при покрытии всего объёма целей. Все 12 языков, 38 групп Lua 5.1. Установлено локально, не опубликовано.

# Локальная правка после 0.4.0 Beta — 2026-10-03

- Главный экран персонажа, очередь до 50 целей с едиными запасами/излишками, выбранными источниками, порядком и количеством; сохранение на персонажа без передачи личных данных.
- Вкладка ForeverNet на аукционе, целевое сканирование дефицита/избранного, кэш цен, стоимость покупки по доступному количеству или целым лотам, 30/90-дневная история реальных дневных наблюдений. Экипировка пока исключена; работа аукциона требует проверки в игре.
- Код отправки 11 больше не удаляет очередь: одно уведомление и повтор после паузы с новой полной передачей. Общие outgoing-chat флаги не блокируют служебные сообщения; добавлена /fn netstatus. Медленные профили используют таймаут бездействия 150 сек. с общим пределом 900 сек. Интервал 1 минута сохраняется. 33 группы проверок; пользователь подтвердил результат отправки 0. Локальная сборка market-queue, не опубликована.

- Кнопка ссылки на рецепт в чат справа в штатном списке профессии. Учитывает повторное использование строк, вариант изученного рецепта, количество крафтов и значок блокировки; открывает/дополняет черновик без отправки. Подсказки на всех 12 локалях. Локальная сборка, не опубликована.

- Ожидаемые отказы синхронизации и команд запросов (нет канала, обмен выключен, API недоступен и т. п.) выводятся обычными локализованными сообщениями, без assert/пути к Lua-файлу. Установлено локально; не опубликовано.

# 0.4.0 Beta — 2026-10-03

- Выпущены накопленные улучшения после публичной 0.3.3: оформление, группировка и фильтры, избранное, варианты реагентов, упрощённые цепочки и шрифты CJK.
- Установочный пакет включает три статических TTF, их лицензию OFL и данные происхождения. Код остаётся MIT.
- Подробное описание EN/RU: outputs/Release-0.4.0.md.

# 0.3.3 — 2026-10-03

- Встроены статические TTF на основе Noto Sans CJK для koKR/zhCN/zhTW с азиатскими символами, латиницей и кириллицей. Шрифт обновляется вместе с языком для текста, кнопок во всех состояниях, заголовков, ввода и собственных подсказок. Азиатские пункты выбора языка читаются на русском клиенте; глобальные игровые GameFont* не меняются. Шрифты, лицензия OFL и происхождение включены в ZIP.

- Упрощена цепочка: два списка «Что нужно получить» и «Что потом изготовить»; шаги с мастерами, иконками и полным расходом. Получение готового реагента / изготовление переключаются одной кнопкой с количеством в самой карточке. Другие рецепты раскрываются тут же, запасы свёрнуты по умолчанию. Убран отдельный экран источников и технический выбор автоматического режима. Выбор компонента для запроса больше не скрывает полную цепочку; «Пересчитать цепочку» сохраняет конечную вещь.

- Источники промежуточных реагентов: получить отдельно, закрепить известный рецепт/мастера или оставить автоматический выбор. Варианты показывают выход и расход за одно изготовление. Запасы списываются первыми, выбор пересчитывает исходную цепочку; получение отдельно оставляет дефицит самого реагента и убирает его изготовление. Исчезнувший выбранный рецепт не подменяется автоматически. Интерфейс переведён на все языки; выбор действует только в текущем плане.

- Звёздочки избранного: до 5 профилей и 5 рецептов, отдельные лимиты. Профили избранного показаны первыми и не удаляются по TTL; рецепты-избранное вынесены над профессиями. Обычные профили очищаются через 30 минут, старые избранные помечены как сохранённые данные. Личные рецепты, отметки и банк сохраняются в SavedVariables. Устаревшие лагерные возможности не считаются подтверждённо доступными.
- Декоративные рисунки профессий убраны из всех вкладок, настроек и обновлений; оставлен простой тёмный фон.
- Локализованы названия каналов обмена: группа/рейд/гильдия. Добавлены фильтры рецептов по профессии, типу (обычные/Blueprint), мастерам (свои/сеть) и сброс; одинаковые предметы объединяются после отбора подходящих мастеров. Поиск компактнее, полосы прокрутки заменены на штатные MinimalScrollBar. Новые элементы переведены на все языки.
- Оформление приведено к окну профессий Forever: тёмный коричневый фон, светлый текст и золотые заголовки; цвета материалов, Blueprint и уведомлений адаптированы к тёмным панелям. Увеличенные шрифты и измеряемая высота карточек сохранены.
- Исправлена читаемость: светлые однотонные панели/карточки, едва заметная текстура фона, текст без теней и обводки, шрифт не меньше 12 px (основной — 14 px). Высота строк и карточек материалов учитывает переносы текста.
- Светлая пергаментная тема с тёплыми рамками и тёмным текстом в главном окне, настройках и обновлениях; боковое меню использует штатный LargeSideTabButtonTemplate Forever.
- Заголовки профессий переделаны в узкие тёмные полоски с золотым названием, числом рецептов и плюсом/минусом, чтобы отличаться от карточек предметов.
- Профили участников «Сети»: сворачиваемые разделы профессий с иконками, навыком и количеством рецептов; карточки в две колонки, выделение Blueprint и переход к рецепту с закреплённым мастером.
- Основной каталог рецептов также сгруппирован по профессиям. Поиск учитывает название профессии и раскрывает подходящие разделы; сворачивание сохраняет выбранный рецепт и мастера.
- Окно обновлений поднимается выше всех элементов настроек, включая стандартную рамку, портрет, заголовок, крестик и список языков; уровни собственной рамки пересчитываются при каждом открытии.
- Иконка раздела рецептов заменена на свиток, чтобы отличаться от настроек.
- Основная иконка аддона — свиток рецепта: список модификаций, миникарта и портреты главного окна, настроек и обновлений.
- Исправлены дубли собственного профиля из-за имени/фамилии Forever; сохранённые рецепты и последний снимок банка объединяются автоматически.
- Сопоставление имён работает в группе и гильдии без party unit; мастера одного предмета отображаются по одному разу.
- Полные словари для всех 12 кодов языков WoW и список выбора языка. Новые переводы требуют проверки носителями.
- Окно обновлений: версия у участников, отключаемые уведомления и ссылка с инструкцией по ручному скачиванию.
- В настройках добавлены вкл./выкл. автообновления сети и интервалы 1/2/5 минут; по умолчанию 2 минуты.
- Изменённые рецепты публикуются автоматически; ручное обновление работает независимо от автоматического режима.
- Очередь объединяет одинаковые профили и досылает новую ревизию после текущей.

- В «Сети» отображаются только другие игроки; локальный профиль сохраняется для расчётов.
- Одинаковые предметы объединены в одну строку каталога с выбором мастера и варианта рецепта.
- Исправлен выбор канала обычной группы при отсутствии legacy-констант.
- Автопоиск участников при входе, включении обмена и изменении группы/гильдии.
- Новые участники получают существующие запросы исходного канала; заявки имеют приоритет перед профилями.
- Проверка enum-кодов отправки, повтор при throttling и сообщения об ошибках канала.
- Интеграционные тесты обмена через очередь и CHAT_MSG_ADDON между тремя виртуальными клиентами.

# 0.3.2 — 2026-10-01

- Справка разбита на отдельные шаги с золотыми заголовками и отступами; добавлена иконка книги.
- В цепочке убраны дубли материалов под карточками. Этапы, банк и дальнейшие действия отображаются отдельными блоками.
- Высота блоков рассчитывается по перенесённому тексту; увеличены межстрочные и межблочные интервалы.

# 0.3.1 — 2026-10-01

- Окно настроек поднято на отдельный слой поверх главного окна и его дочерних элементов.
- Добавлен непрозрачный тёмный фон внутри штатной рамки; главное окно больше не просвечивает сквозь настройки.
- Добавлена проверка слоя и непрозрачности при обновлении главного окна.

# 0.3.0 — 2026-10-01

- Отдельное окно настроек и информации об аддоне, автор Andrew Woolfi; команда /fn settings.
- Автосканирование вкладок личного банка при посещении и изменении содержимого; сохранение отдельно для каждого персонажа.
- Настраиваемый учёт банка в расчёте и карточки с количеством материалов в сумках/банке.
- Цветные карточки с крупными иконками, новая иконка цепочек и иконка ForeverNet в списке модификаций.
- Переключатели обмена, банка, кнопки миникарты и языка; русский и английский интерфейс.
- Тесты загрузки вкладок, переносов, пустого банка, изоляции персонажей и настроек. Отображение и реальный банк требуют проверки в игре.

# 0.2.0 — 2026-10-01

- Кнопка миникарты: окно по левому клику, справка по правому, перетаскивание и сохранение положения.
- Выбор предмета из списка рецептов, поиск, количество и понятные подсказки вместо обязательного ввода ID.
- Расчёт показывает материалы из сумок, недостающие компоненты и исполнителей. Выбранный мастер сохраняется при повторном расчёте.
- Запрос помощи по выбранному недостающему компоненту; обновление статуса входящих заявок и ожидание ответа на предложение.
- Учебный пример не публикуется. Русские и английские подписи, исправлен поиск без повреждения UTF-8.
- Добавлены проверки полного сценария выбора, расчёта, заявки и кнопки миникарты.

# 0.1.3 — 2026-10-01

- Убрана Unicode-стрелка между шагами цепочки: игровой шрифт отображал её пустым квадратом. Шаги разделены пустой строкой и сохраняют нумерацию.

# 0.1.2 — 2026-10-01

- Внешняя рамка, заголовок, круглый портрет и кнопка закрытия используют штатный `PortraitFrameTemplate` клиента Forever. Удалена ручная комбинация иконки с кольцом миникарты, которую перекрывал заголовок.
- Название раздела сдвинуто вправо от портрета, чтобы они не перекрывались.

# 0.1.1 — 2026-10-01

- Исправлено падение `UI.lua:94` при открытии/переключении разделов. Вместо несуществующего `EditBox:GetTextHeight` используется `FontString:GetStringHeight`, текст размещён внутри прокручиваемого Frame.
- Исправлена высота области для длинного текста и возврат прокрутки к началу при смене записи.
- Добавлен адаптер `C_TradeSkillUI` по исходникам Forever 1.60.1 (70124); сканер работает без legacy-глобалов, читает только свои изученные рецепты, сохраняет ручные метки и не меняет фильтры.
- Добавлены сообщения о недогруженных данных, пустом списке и пропущенных неподдерживаемых рецептах на русском и английском.
- Поиск локального названия предмета поддерживает `C_Item.GetItemInfo`.
- Номер Interface изменён на 16001, версия — 0.1.1.
- Тестовые виджеты больше не разрешают произвольные несуществующие методы. Добавлены регрессии всех разделов, длинного текста и современного сканера; 12 групп проверок Lua 5.1 проходят.

Повторная проверка UI и сканирования в игре ожидается после `/reload`.

### Local continuation: material tracking and auction search

- Independent movable queue tracker: allocated bags, saved bank withdrawals, external shortages, first planned craft and budget. Refreshes after bag/queue/bank changes; saved per-character visibility, `/fn track` toggle.
- Native auction name search from queue, Market and tracker. Checks open/readiness/item loading, stops the scanner, clears category and retains native filters. Manual buying.
- All 12 interface languages; 35 Lua 5.1 check groups including fresh-runtime tracker reload. Client visual/search verification remains pending. Local package only; no publication.

### Local fix: first profession selection

- Fix a nil filterMenu error when choosing a profession from the Character dashboard before opening Filter for the first time.
- Replace unsupported middle-dot/approximation separators in dashboard and market text with ASCII alternatives.
- Regression covers first-use profession row clicks, filtering/reset and the later menu. 35 Lua 5.1 groups passed. Local installation only.

Исправлен первый выбор профессии до открытия меню фильтров; заменены разделители, отображавшиеся квадратиками. Проверено 35 групп Lua 5.1, новая локальная сборка установлена.

### Local continuation 2026-10-04: native profession actions

- Attach a ForeverNet panel below the native crafting page: finished-item target, Add to queue and Materials. Reads the current schematic at action time and preserves native filters/craft count.
- Read-only single-recipe previews; explicit atomic capture with own-mode/loading/unsupported-output guards, profession identity validation, retained manual Blueprint/station metadata and unrelated recipes.
- All 12 locales, measured text layout and 36 Lua 5.1 groups. Local package/install only; native rendering still needs a client check.

Панель под штатной профессией: количество готовых вещей, очередь и материалы. Просмотр не меняет профиль; выбор считывается заново при нажатии. 36 групп проверок; публикации нет.

### Local continuation 2026-10-04: material-source costs and auction tab fix

- Expanded material options compare additional auction purchases for the entire queue/plan with shared stock, real batch inputs and reused surplus. Choose ready-made, a recipe or automatic selection; no automatic cost optimization.
- Unknown crafting fees/prices, insufficient auction volume, old/partial observations and unavailable dependencies are explicit and excluded from lowest fully priced estimate. Bounded/cached previews.
- Fix Auction.Attach inserting its tab twice: the native template inherits parentArray="Tabs". Preserve existing addon tabs and use the actual registered index.
- 37 Lua 5.1 groups, strict native tab-registration/self-anchor regression, all 12 languages. Local build only.

Сравнение покупки общего дефицита при разных источниках реагента. Исправлена двойная вставка вкладки аукциона/ошибка привязки к самой себе. Проверки пройдены; публикации нет.


## 2026-10-07 — local graphical UI and automation

Profession/material cards, counters, progress bars and reagent icons replace repeated prose; details and queue tools unfold on demand. Six primary pages with contextual plans/requests. Own-profession auto scan and bounded eligible-cost auto routes default on with independent switches; explicit choices/pins remain. Live single-plan stock/quantity refresh. 47 mock test groups; local install/42-file ZIP verified, no publication.


## 2026-10-07 — local modern-board revision

Flat owned window/button/navigation skin, private Sans typography, neutral colors. QueueBoard replaces duplicate right-side goals and accordions with shared material/craft tabs and one sets menu; inline goal controls and quantity autosave preserve input focus. 48 mock groups, 43-file local package installed, no publication.


## Local development — 2026-10-07: appearance and sidebar

- Modern/Classic appearance setting, saved and applied live; translated button wrapping and adaptive header/menu/modal spacing.
- Professions shown once in the home sidebar with skill progress; independent five-item market favorites above the regular market list, retained without price history and included in empty-deficit auction scans.
- Commands replaces Example; demo removed completely from runtime; startup chat shows only the version.
- Переключение современного/классического стиля, перенос русских надписей с измерением отступов. Профессии только слева; отдельное избранное рынка до пяти вещей сверху. Вместо «Пример» — «Команды», демо удалено, при загрузке только версия.
- Local changes only; no new GitHub/CurseForge release. Native rendering remains to be verified in game.


## Local development — 2026-10-07: release helper and auction wallet

- Optional Windows pre-launch helper checks latest stable GitHub release and provides one localized startup message; failed/stale checks are explicit. Existing participant reports now persist and remind on login as unconfirmed information. No updater/service or CurseForge keys.
- Auction tab reserves the native bottom wallet strip in both styles; balances remain visible outside the addon content.
- Помощник перед лаунчером проверяет стабильный релиз GitHub и передаёт результат в чат игры. Версии участников сохраняются как неподтверждённые сведения. Вкладка аукциона отделена от штатной полосы денег в обеих темах.
- Local install only, no publication. 52 Lua groups plus Windows helper checks; native visual confirmation remains pending.


# ForeverNet 1.1.0

## English — changes since 1.0.0

### Interface
- New Modern appearance and a selectable Classic appearance, saved in Settings and applied immediately. Both use the compact layout and support Korean/Chinese fonts.
- More visual recipe and production plans: item cards, owned/needed/craft counters, reagent icons, progress, price tooltips and expandable details.
- Queue goals appear once on the left. The right pane switches between shared materials and crafting order, highlights the next available local craft and offers compact goal controls. Valid quantity edits save immediately; sets, cleanup and undo are in one scrolling menu.
- Professions on the character page are shown only in the left sidebar, with rank/max skill, recipe counts, progress and scan-age tooltips. The right side shows queue, network and saved-bank state.
- Translated button labels wrap with measured height; headers, filters, language-menu rows and queue-set dialogs adapt their spacing.
- Commands replaces Example. The demo command, synthetic sample profiles and special sample inventory have been removed. Help retains the short walkthrough.

### Automation and market
- Automatically scan your own learned recipes when opening/updating a profession. Reads current native filters and merges without deleting previously saved recipes; can be disabled in Settings.
- Automatically compare known ways to obtain intermediate materials and choose a lower known purchase cost. Only fresh, complete, sufficiently stocked and otherwise eligible estimates drive selection; explicit choices and pinned crafters remain in control. The bounded comparison is not a global economic optimizer.
- Open production plans recalculate after inventory, bank, profile, price or valid target-quantity changes while retaining manual choices and scroll position.
- Independent market favorites: up to five watched items in a top sidebar group, retained even without price history. Empty-deficit auction scans include recipe bookmarks and market watch items.
- The ForeverNet auction tab reserves the native bottom balance strip in both themes so content does not cover the money display.

### Version notifications
- Built-in version announcements through guild/group addon messages, with short delayed replies, coalescing and bounded retries. Sends only the installed version and works independently of profession-profile sharing.
- A higher version reported by another player is saved and reminded on the next login, once per session. Normal startup prints the installed version; notices can be muted in the updates window.
- Uses player reports, not a live GitHub/CurseForge query. No external helper, special launch shortcut or background service is required.

### Validation and compatibility
- 52 Lua 5.1 test groups: transport, stock/plans, automation, 12 locales, both themes, larger translated buttons, version announcements/cache/retries and auction wallet spacing.
- Five refreshed Modern UI images with the game’s screenshot-saved overlay removed. Captures were supplied from the development build before the version-number bump; Settings therefore retains its captured 1.0.0 label.
- Target: Forever 1.60.1 (70124), Interface 16001. Crafting, buying and trading remain manual. The previously reported protected-action popup after a bank visit remains under investigation.

## Русский — изменения после 1.0.0

### Интерфейс
- Современный и классический стили: переключение в настройках, сохранение выбора и применение сразу. Оба сохраняют компактную компоновку и поддержку корейских/китайских шрифтов.
- Более наглядные рецепты и цепочки: карточки вещей, счётчики наличия/потребности/крафтов, иконки реагентов, прогресс, цены в подсказках и раскрываемые подробности.
- Цели очереди показаны один раз слева. Справа — общие материалы или порядок изготовления, следующий доступный локальный крафт и компактные действия цели. Валидное количество сохраняется при вводе; наборы, очистка и отмена собраны в одно меню.
- Профессии на главной только слева: ранг/максимум, количество рецептов, прогресс и возраст сканирования. Справа — очередь, сеть и сохранённый банк.
- Переведённые надписи переносятся с измерением высоты кнопок; адаптированы шапка, фильтр, список языков и диалоги наборов.
- Вместо «Пример» — «Команды». Демо, искусственные профили и отдельные демонстрационные запасы удалены. «Справка» сохраняет короткое руководство.

### Автоматизация и рынок
- Автосканирование изученных рецептов при открытии/обновлении своей профессии. Учитывает текущие штатные фильтры, дополняет сохранённое без удаления старых рецептов и отключается в настройках.
- Автоматическое сравнение способов получения промежуточных материалов по известным дополнительным покупкам. Выбор учитывает свежесть/полноту цены, доступный объём и остальные условия; ручные решения и закреплённые мастера приоритетны. Расчёт ограниченный, не глобальная экономическая оптимизация.
- Открытая цепочка пересчитывается после изменения сумок, банка, профилей, цен и валидного количества, сохраняя ручные способы получения и прокрутку.
- Отдельное избранное рынка до пяти вещей: группа сверху слева, сохранение даже без истории цен. При пустом дефиците сканирование аукциона включает избранные рецепты и вещи рынка.
- На вкладке аукциона оставлена штатная нижняя полоса денег в обеих темах: содержимое её не перекрывает.

### Сообщения о версии
- Встроенный обмен номерами версий в гильдии/группе: короткие отложенные ответы, объединение повторов и ограниченные повторы отправки. Передаётся только номер версии, независимо от обмена профессиями.
- Более новая версия от другого игрока сохраняется и напоминается при следующем входе один раз за сеанс. При обычной загрузке выводится установленная версия; уведомления отключаются в окне обновлений.
- Сведения от игроков, без прямого запроса GitHub/CurseForge. Внешняя программа, специальный ярлык и фоновая служба не нужны.

### Проверки и совместимость
- 52 группы Lua 5.1: сеть, запасы/планы, автоматизация, 12 локалей, обе темы, увеличенные переведённые кнопки, версии/сохранение/повторы и отступ денег аукциона.
- Пять обновлённых изображений современного интерфейса без надписи «Скриншот сохранён». Снимки предоставлены из разработки до смены номера версии; в настройках оставлен снятый номер 1.0.0.
- Forever 1.60.1 (70124), Interface 16001. Изготовление, покупки и передача вещей остаются ручными. Ранее сообщённая блокировка использования вещи после посещения банка ещё расследуется.


