# Архитектура ForeverNet

## Загрузка и модули

Одна приватная таблица namespace передаётся файлам WoW-загрузчиком. `ForeverNet` экспортирует API для отладки. Порядок задаёт TOC.

| Модуль | Ответственность |
|---|---|
| Locale, Locales/* | 12 кодов языков WoW, автоподбор и английский резервный язык |
| Theme, Fonts/* | Собственные CJK TTF, реестр шрифтов текста/кнопок/ввода/заголовков, смена языка без изменения игровых GameFont* |
| Core | идентичность персонажа, алиасы имени/фамилии, SavedVariables и миграция дублей |
| Queue | приватная очередь до 50 целей на персонажа, общие запасы и выбранные источники, сохранение без P2P |
| SourceCosts | приватные сравнения источника реагента: пересчёт всей цели/очереди, партии/общий запас, покупка дефицита и неизвестные услуги |
| Market | приватный кэш цен по рынку, глубина товара/целые лоты, неизвестная часть бюджета, 90 дневных наблюдений |
| Auction | четвёртая штатная вкладка, последовательные целевые запросы/пагинация, readiness/таймауты, прекращение при чужом поиске |
| FeatureLocales | новые экранные подписи и форматы всех 12 локалей, включая денежные единицы |
| Updates | сравнение версий участников, уведомления, окно ручного скачивания |
| Model | схемы, проверки входных данных, истечение кэша, Skill Graph |
| Catalog | имена и иконки предметов, список рецептов, поиск без изменения UTF-8 |
| Codec | ограниченная сериализация без исполнения кода |
| Planner | материалы, исполнители, лагерь, последовательность шагов |
| ProfessionActions | панель в штатной профессии: выбранный рецепт, цель в готовых вещах, очередь и материалы |
| Adapters | изоляция WoW API; C_TradeSkillUI и legacy-сканер, локальные сумки, демо |
| Bank | локальные снимки купленных вкладок личного банка; события посещения и изменения |
| Settings | отдельное окно параметров, информация, автор и версия |
| Network | каналы WoW, очередь, разбивка, сборка, HELLO/PROFILE |
| Requests | заявки и единственный автор состояния |
| UI | разделы сети, рецептов, заявок и цепочки |
| Theme | тёмная тема окна профессий, светлый текст, золотые заголовки, фоны/рамки и полоски разделов |
| Minimap | кнопка запуска, перетаскивание, settings.minimapAngle |
| Bootstrap | события, команды, запуск и обновление транспорта |

## Профиль

В Forever `UnitNameUnmodified` возвращает имя и фамилию. Канонический ключ — `First-Surname`; компактное имя чата, пробелы и суффикс текущего сервера сопоставляются по собственному персонажу и составу группы. Для legacy API сохраняется `Name-Realm`, включая различение одноимённых персонажей разных серверов. Собственные сообщения не становятся профилем другого участника. При загрузке и очистке кэша собственные алиасы объединяются с локальным профилем: отсутствующие рецепты сохраняются, выбирается новейший снимок банка, owner/assignee собственных заявок нормализуются. ID старых заявок сохраняется; его автор проверяется через те же алиасы относительно отправителя игрового события.

```lua
{
  rev = 3, seen = 1800000000,
  professions = { ['skill:202'] = 300 },
  recipes = {
    ['spell:123'] = {
      name = 'Название из клиента', output = 'item:456', quantity = 1,
      profession = 'skill:202', blueprint = true,
      reagents = { ['item:789'] = 2 }, stations = { ['camp:example'] = true }
    }
  },
  camps = { ['camp:example'] = 1800000000 }
}
```

Числа в примере условные. `seen` устанавливается принимающим узлом, удалённое время свежести не используется. Ревизия увеличивается при изменении локального профиля. Удаления передаются полным снимком; нижняя ревизия не заменяет более новую, равная обновляет время присутствия. При сбросе SavedVariables другим игрокам может потребоваться дождаться истечения старого кэша.

Локализованный текст — только отображение. ID `spell:*` и `item:*` обеспечивают совместимость языков. Ручные ID должны совпадать у участников. Адаптер Forever использует `skill:<professionID>` из `C_TradeSkillUI.GetBaseProfessionInfo()`, ID изученных рецептов из `GetFilteredRecipeIDs()` и результат/реагенты из `GetRecipeSchematic(id, false)`. Это те же функции, которыми пользуется окно профессий Blizzard сборки 70124. Фильтры пользователя не изменяются. Для legacy-профессий без skillLineID по-прежнему используется namespace языка и hex-имя; поиск изготовителей идёт по выходному item ID.

Сканирование сначала собирает кандидат профиля, проверяет схему и только затем заменяет локальные данные. Недогруженные данные не сохраняются частично. Неподдерживаемые рецепты (альтернативные/валютные/переменные обязательные реагенты, неизвестный предметный результат) пропускаются с отчётом, а ранее известные записи сохраняются. Ручные Blueprint и требования лагеря сохраняются при повторном сканировании.

Текстовая область UI — `FontString` фиксированной ширины внутри прокручиваемого `Frame`. После установки текста `GetStringHeight()` определяет высоту дочернего Frame; при смене записи прокрутка возвращается к началу. Заглушки тестов различают типы виджетов и возвращают nil для неизвестных методов.

Каталог и профили участников группируют рецепты по профессиям. Сворачивание не удаляет рецепт из выбора или расчётов; поисковые результаты автоматически раскрываются. Профиль показывает измеряемые карточки в две колонки; нажатие закрепляет конкретный рецепт/мастера в каталоге. Заголовки — узкие тёмные полоски, отличные от светлых карточек. В случае нескольких вариантов профессия предмета в каталоге определяется текущим выбранным вариантом, предмет остаётся одной строкой.

Боковое меню использует `LargeSideTabButtonTemplate` и `SetCustomOnMouseUpHandler` из клиента 70124; размеры, маска, рамка и подсветка задаются штатным атласом Forever. `Theme.lua` задаёт тёмные коричневые панели, светлый текст и золотые заголовки; сплошной нижний слой не допускает просвечивания мира, штатный UI-Background-Rock даёт слабую фактуру только на фоне окна. Семантические цвета материалов/Blueprint/обновлений заданы общей палитрой для тёмного фона. Рамка обновлений поднимается выше NineSlice/PortraitContainer/TitleContainer/CloseButton настроек, учитывая штатные смещения +400/+500/+510.

`Theme.ScrollFrame` связывает обычный ScrollFrame со штатным EventFrame/MinimalScrollBar через `ScrollUtil.InitScrollFrameWithScrollBar`. Эта функция клиента синхронизирует ползунок, диапазон и колесо мыши. Панели используют простой тёмный фон; декоративные рисунки профессий удалены по просьбе пользователя.

Параметры фильтра `UI.recipeFilters` (profession/kind/scope) локальны текущему UI и не рассылаются. `Catalog.Recipes` сначала отбирает варианты по этим параметрам, затем объединяет предметы и выбирает мастера из оставшихся вариантов. Открытие рецепта из профиля сети сбрасывает фильтр, чтобы выбранный мастер не оказался скрыт. Видимые названия CHANNEL_PARTY/RAID/GUILD локализуются; внутренние коды транспорта сохраняются.

Избранное сохраняется в `ForeverNetDB.favorites`: profiles — ключи мастеров, recipes — item ID. Лимиты независимые, по 5 записей. Звёздочки используют штатные атласы auctionhouse-icon-favorite/favorite-off. Профили избранного сортируются первыми и не удаляются по PEER_TTL; остальные удаляются через 30 минут. Старые избранные показываются как сохранённые данные; их лагерные объекты не считаются доступными до свежего сообщения. Избранные рецепты показаны отдельной группой над профессиями. Закладка рецепта не удерживает чужой профиль — для этого нужно отметить сам профиль. Личные рецепты и банк уже входят в SavedVariables и сохраняются при обычном выходе/перезагрузке.

## P2P v1

`ProfessionLinks.lua` adds recipe chat-link buttons to the native `ProfessionsFrame.CraftingPage.RecipeList.ScrollBox` through `ScrollUtil.AddInitializedFrameCallback`. It handles load-on-demand initialization and recycled rows, reserves space beside the name/craftable count, and reads the current recipe (including the highest learned variant) on each click. `C_TradeSkillUI.GetRecipeLink` supplies the recipe hyperlink. `ChatFrameUtil.InsertLink/OpenChat` only edits the chat draft; no chat message is sent. Tooltip text covers all 12 locales; button art uses native `common-icon-chatlink` and tertiary-square atlases.

Префикс `ForeverNet1`. Канал по умолчанию: RAID → PARTY → GUILD. Instance group не используется. Приём разрешён в этих трёх каналах только при включённом обмене; имя отправителя берётся из игрового события, а не из полезной нагрузки.

```text
1|<epoch.serial>|<part>|<total>|<payload fragment>
```

Содержимое: `{kind = 'PROFILE'|'HELLO'|'REQUEST'|'OFFER', data = {...}}`. Кодек: строки с длиной в байтах, целые числа, boolean, таблицы со строковыми ключами. Ключи сортируются. Никаких `loadstring`/десериализации Lua-кода. `loadstring` используется исключительно в тестовом загрузчике локальных исходников.

- Фрагменты по 200 байт, входные сообщения до 250 байт.
- Полезная нагрузка до 96 KB / 480 частей; профиль до 1000 рецептов, фактический размер может ограничить его раньше.
- Очередь до 1000 сообщений, отправка до 4 фрагментов/сек.
- До 16 незавершённых сборок; таймаут 150 секунд.
- Лимит 300 входных фрагментов от отправителя за 30 секунд, до 100 отправителей в таблице лимитов.
- Глубина декодирования 12, до 30000 значений, размер одной таблицы до 2000 записей.
- До 100 профилей и 100 активных заявок в кэше.

Автообновление управляется settings.autoSync (nil/true — включено) и settings.syncInterval (60/120/300 секунд, по умолчанию 120). При включённом автоматическом режиме вход, включение обмена и изменение состава группы/гильдии запускают HELLO и публикацию снимка. Таймер запускает повторную синхронизацию только после окончания текущей очереди; ручной Sync перезапускает отсчёт. F.Touch ставит публикацию изменённого профиля с задержкой 0,5 секунды. При выключенном автоматическом режиме фоновых инициатив нет, но ручной Sync, приём и ответы на HELLO остаются доступны при включённом обмене. Повторная публикация одного профиля в том же канале объединяется; более новая ревизия отправляется после завершения текущей даже в ручном режиме. При HELLO участники отвечают своим профилем и собственными неистёкшими заявками исходного канала с задержкой 0–3 секунды, не чаще раза за 30 секунд одному отправителю. HELLO, REQUEST и OFFER получают приоритет перед фрагментами профилей. Регистрация префикса и отправка проверяют enum-результаты клиента 70124; при кодах 3/8 очередь сохраняется, используется backoff до 15 секунд и адаптация интервала; код 11 имеет отдельную паузу до 30 секунд. Остальные ошибки и потеря канала показываются игроку. Нет gossip/relay, ACK, сжатия, delta sync и гарантии доставки. Потерянный снимок можно запросить через Sync.

## Skill Graph и производство

HELLO содержит `version`, PROFILE — дополнительные поля `addonVersion` и `characterName`. Последнее помогает восстановить границу имени/фамилии гильдейского участника без party unit; оно учитывается только после сопоставления с отправителем игрового события. Неподходящие заявления не создают алиасы. Старые сообщения без этих полей принимаются. Сборка фрагментов использует исходное имя отправителя, чтобы появление алиаса во время передачи не теряло начало профиля. Updates сравнивает строгие версии major.minor.patch с prerelease и build metadata, игнорирует собственные сообщения, уведомляет лишь о повышении максимальной увиденной версии. Это сведения участников, а не проверка опубликованного релиза. Аддон не выполняет HTTP-запросы и не заменяет свои файлы. Ссылка скачивания фиксирована в коде и не принимается от других игроков.

Узлы: `player`, `profession`, `recipe:<owner>:<id>`, `item`, `camp`. Рёбра: `practices`, `knows`/`blueprint`, `produces`, `requires`, `provides`, `needs`. Все рецепты принадлежат отдельным игрокам. Каталог группирует их по выходному item ID в одну строку, сохраняя все варианты изготовления. По умолчанию выбирается локальный мастер; кнопка смены мастера/рецепта позволяет закрепить другой вариант для конечного предмета. Раздел «Сеть» скрывает локального персонажа, не удаляя его профиль из расчёта.

Планировщик рекурсивно раскрывает зависимости до 20 уровней / 2000 посещений. Использует копию вашего запаса; сначала списывает доступное, затем округляет число изготовлений вверх и сохраняет излишек для общих зависимостей. Исполнители и рецепты обходятся в стабильном порядке. Шаги записываются после зависимостей, поэтому вывод соответствует порядку изготовления. Зависимость от лагеря включает поставщика; объект с временем готовности в будущем пока делает рецепт недоступным. При цикле или отсутствии изготовителя появляется дефицит. Шаги при дефиците остаются предварительным планом, а не разрешением на выполнение.

Источники промежуточных реагентов выбираются через `options.sources[item]`: nil — первый доступный рецепт, `'external'` — получить отдельно без раскрытия зависимостей, `{owner,recipeID}` — закреплённый рецепт. Запас списывается первым при любом режиме. При исчезновении выбранного рецепта или недоступности станции автоматической подмены нет. `Planner.Sources` возвращает известные варианты с расходом/выходом и доступностью станции. Индекс вариантов строится один раз на расчёт. `plan.materials` хранит суммарную потребность, расход исходного запаса, дефицит до изготовления и выбранный вариант; `plan.sources` — независимую копию решений. Излишки производства переиспользуются, а не учитываются как исходный запас. Выбор в UI всегда пересчитывает исходную цель и количество, даже если перед этим был выбран компонент. Решения локальны текущему плану, не сохраняются в SavedVariables и не передаются по сети.

UI плана — два последовательных списка получения и изготовления; `steps[].reagents` хранит полный расход этого шага, а не на одно изготовление. Карточки промежуточных шагов переключают на получение готового одной кнопкой; карточки дефицита предлагают изготовление известным мастером. Альтернативы раскрываются внутри списка (`expandedSource`), показывают полный расход/выход и излишки, без отдельной страницы источников. Исходные запасы свёрнуты (`showPlanStock`). Кнопки меняют план, не исполняют крафт. Выбор компонента слева служит запросу помощи, полная цепочка справа остаётся видна; пересчёт возвращается к конечной цели.

Будущая итерация: автоматическое сравнение альтернатив по цене/дистанции/сроку, cooldown рецептов и объектов, резервирование инвентаря, визуальная графовая раскладка и отдельные задания каждому участнику цепочки.

## Заявки

ID `<owner>:<server time>:<saved counter>`. Поля: item, quantity, expires, rev, status, assignee; owner и исходный channel устанавливает получатель по событию. Только автор публикует канонический REQUEST. Исполнитель отправляет OFFER с ID. Автор принимает первый отклик, назначает исполнителя и повышает ревизию; последующие отклики игнорируются. Завершение подтверждает автор. Полные снимки заявок дают вновь подключившимся игрокам увидеть уже принятую заявку.

Это координация намерений, без криптографической аутентификации, репутации и подтверждения фактической сделки. Игровой транспорт идентифицирует отправителя, заявленные профессии/рецепты остаются самоотчётом.

## Развитие

1. Проверить исправление окна и новый сканер в клиенте Forever 1.60.1 (70124); Interface 16001 уже указан.
2. Добавить автоматическое обнаружение Blueprint/Camping, сохранив ручной override.
3. Проверить новые переводы носителями языков и проверить шрифты/разметку на соответствующих клиентах. Все 12 кодов уже поддержаны; enGB использует английский словарь. Названия предметов локализует сам клиент.
4. ACK и повторная доставка потерянных сообщений, delta-профили и сжатие для больших каталогов.
5. Отдельные подзадачи цепочки и автоматическое сравнение маршрутов с альтернативными рецептами.

## Источники и референсы

- [NameUtil Forever, клиент 70124](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua) — имя/фамилия, UnitNameUnmodified и форматирование полного имени.

- [Blizzard: Forever Deep Dive](https://worldofwarcraft.blizzard.com/en-us/news/24303313) — описание систем; не спецификация Lua API.
- [ChatInfo для клиента 70124](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua) и [enum-результаты](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatConstantsDocumentation.lua).
- [TradeSkillUI для Forever 1.60.1 (70124)](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua) и [структуры результата/реагентов](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUITypesDocumentation.lua).
- [Список рецептов Blizzard](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_Professions.lua) — GetFilteredRecipeIDs и проверки чужой профессии; [Camelot override](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_ProfessionsTemplates/Camelot/Blizzard_Professions.lua) — GetBaseProfessionInfo.
- [FontString API этой сборки](https://github.com/Gethe/wow-ui-source/blob/966519cf0ad2c10301ea011a88c14b25697c9687/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua) — GetStringHeight.
- Пять скриншотов пользователя: персонаж, навыки, таланты, обзор профессий, рецепт кожевничества. Они являются главным визуальным референсом этой версии. Изображения в проект не копируются.

## Material tracker and native auction lookup (local build)

`Tracker.lua` rebuilds the same `Queue.Build()` plan instead of adding independent deficits. `supplied - bagSupplied` is allocated saved-bank stock to withdraw. Missing quantities are external shortages; planned crafting surplus never becomes bag stock. The next planned step is informational, not an automatic craft or a claim that every ingredient is carried. Actual crafting/item receipt triggers `BAG_UPDATE_DELAYED`; bank snapshots and queue/source edits also mark the tracker dirty. Visible updates are debounced to 0.5 seconds, with a 10-second refresh for market/bank age. Hidden trackers do no polling. Visibility is private `queues[character].tracker`, restored after login; goals remain until removed by the player. Dragging changes the session position; position is not saved yet.

`Auction.Search(item)` checks the open native frame, search readiness and the item name from client item data. It cancels our scanner, opens the native Buy mode, clears the category, fills `SearchBar:SetSearchText` and calls `SearchBar:StartSearch`. Native level/other filters remain active. Blizzard owns browse result lifecycle, item selection and purchase confirmation; we do not fabricate browse records, preselect a buy quantity, send purchase messages or queue delayed purchases. Native search is by name, not exact variant ID; equipment variants still have no price estimate. Loading/closed/not-ready cases return a localized explanation without changing the scanner or search. Entry points: queue shortage cards, Market item card and the independent tracker.

Native reference: Gethe/wow-ui-source Forever SHA `e3ecc27b64d30fdc735a3f6579b866858f9f9df1`, `Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseSearchBar.lua` (SetSearchText, StartSearch), `Blizzard_AuctionHouseFrame.lua` (Buy display mode, category access, SendBrowseQuery), `Blizzard_AuctionHouseBrowseResultsFrame.lua` (browse lifecycle). Downloads retained under `work/reference/`; inspected with rg and focused line ranges. `SimpleFrameAPIDocumentation.lua` confirms SetClampedToScreen for movable trackers. Client rendering/native integration remains unverified.

### First-use filter lifecycle

The Character page can apply a profession filter before the lazy Filter menu exists. SetRecipeFilter guards the optional menu and scroll frame, then calls Status to ensure/update UI. Regression tests click the actual profession row before opening the menu, then verify filtering, reset and normal menu operation. Dashboard/market punctuation uses ASCII / and ~ because the user’s RU client showed missing glyphs for middle dot and approximation sign. CJK fonts remain unchanged.

## Native profession context actions (local 04.10 build)

`ProfessionActions.lua` attaches an independent measured dark panel below `ProfessionsFrame.CraftingPage` (parented to the native page). It follows native visibility/size, attaches once, uses secure post-hooks for SelectRecipe and ordinary HookScript for show/hide/size, and resolves `SchematicForm:GetRecipeInfo()` at action time. There is no replacement of Blizzard methods or change to the native craft spinner. The extra numeric input is a target of finished items, 1–10000. A new selected ID resets it to 1. Read-only preview updates are debounced to 0.25 seconds when visible/dirty; no per-frame API scanning.

`Adapter.ReadRecipe(id)` shares the modern schematic parser with full scans but inspects just that ID. It does not enumerate/change native filters, alter profiles, queue goals or revisions. Local-crafting checks reject linked/guild/NPC/remote modes. When available, GetProfessionInfoByRecipeID + parentProfessionID must match the opened base profession; stale cross-profession schematics remain unavailable. Unsupported required alternatives/currencies/variable costs/non-item output and unlearned/gathering/salvage/recraft/dummy recipes are rejected. The selected-action preview additionally rejects a variable quantityMax; existing whole scans still retain their previous conservative minimum-output behavior. Optional reagents are excluded and this is stated in the panel. API loading exceptions do not erase old recipes.

Only explicit Add to queue or Materials captures the chosen recipe through an atomic profile merge, preserving Blueprint/station metadata and unrelated recipes. Add validates the 50-goal limit before mutation, pins the local owner/spell ID and keeps the native window open. Materials does not create a queue goal; it builds a pinned single-item plan with live bags/saved bank and opens the Chain page. Profile changes follow the existing debounced sharing path; a single capture records a partial profession scan timestamp, not proof of a complete fresh profession catalog. Automatic crafting, purchase and native reagent allocations are untouched.

Native references were already retained under work/reference at Gethe Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1: ProfessionsCrafting.lua (SelectRecipe, SchematicForm:GetRecipeInfo and native quantity controls), ProfessionsCrafting.xml (CraftingPage layout/parenting), TradeSkillUIDocumentation.lua (recipe/profession getters and data-source event), TradeSkillUITypesDocumentation.lua (ProfessionInfo.parentProfessionID and schematic quantities). Found with rg for those names and read focused ranges with Select-Object. No third-party addon code was copied. Rendered fit below the native profession frame, screen edges and overlap with other addons still require a game check.

## Source-cost previews and auction-tab registration (local continuation 04.10)

SourceCosts.Compare rebuilds the entire goal list from the same original inventory for each intermediate source choice. Root owner/recipe pins remain intact. The preview changes exactly one global material-source preference; all other preferences remain. Plans therefore reuse shared bag/bank allocations and generated batch surplus across goals. Displayed cost is additional auction purchase of shortage, not economic value of stock, vendor cost, gathering time or service charges. Reagent cards report actual summed batches/input/output from the resulting plan; displayed generated surplus subtracts unused original stock and does not become bags.

Automatic, external and up to 8 recipe options are previewed. A pinned source beyond that limit remains included. Each comparison has a private quote cache and 1,000,000 estimated operations for market quote work; expensive whole-lot optimization consumes the budget, and exceeded quotes become visibly unknown/limited, not zero-priced. Planner retains its own cycle/depth/visit limits. No cache outlives the comparison and no preview applies preferences or mutates profiles. Queue choices are saved; single-chain choices remain local to that chain.

A lowest purchase estimate is marked only among fully priced, fresh, complete-volume, non-approximate options without unavailable dependencies or stale providers. Any other-player craft makes fees unknown and excludes that option from ranking. Missing/stale/partial/insufficient-volume prices remain visible, so a cheap partial known sum cannot win. Savings deltas are shown only when both the candidate and recomputed current selection meet those same conditions. This is a bounded one-material comparison, not a global optimizer; automatic selection still follows the existing deterministic recipe preference.

The 18:15 client stack revealed duplicate auction tab insertion. AuctionHouseFrameDisplayModeTabTemplate → AuctionHouseFrameTabTemplate → PanelTabButtonTemplate inherits parentArray="Tabs", so CreateFrame already appends the tab. Auction.Attach now looks up its registered index and adds it only when registration is absent. It uses the actual index for SetID/display-mode mapping, preserving existing third-party tabs. Strict mocks now model native parentArray and reject self-anchors; tests reproduce PanelTemplates_AnchorTabs and an existing fourth addon tab.

Native evidence: work/reference/AuctionHouseTab.xml, freshly saved from pinned Interface/AddOns/Blizzard_AuctionHouseUI/Mainline/Blizzard_AuctionHouseTab.xml; SharedUIPanelTemplates.xml (PanelTabButtonTemplate, line 932, parentArray), SharedUIPanelTemplates.lua (PanelTemplates_SetNumTabs/AnchorTabs), AuctionHouseFrame.lua (tab/display mode indexing). Gethe Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1. Found using rg for inherits/parentArray/Tabs, then focused ranges. The initial mock missed template registration; it has now been corrected.


## Queue goal sets (local 0.4.0 development)

Queue.data.sets stores up to 10 named snapshots in db.queues[F.me], separate from public profession profiles. A set contains only bounded goals and intermediate source choices: no stock, market data or generated plan. Save uses an exact trimmed name (1–80 UTF-8 bytes); existing names overwrite that set even at the cap. Init validates goals atomically, rejects malformed sets and sanitizes choices. Root owner/recipe pins survive loading, including unavailable peers; loading always rebuilds against current inventory/profiles.

LoadSet replaces or appends atomically within 50 goals and 200 source choices. Append keeps existing conflicting routes and reports the conflict count. Load/RemoveOwned create one session-only undo snapshot of queue goals/sources; subsequent manual goal/order/quantity/source changes invalidate it. Saving/deleting a set does not alter the queue or tracker preference. Sets persist per character and never enter the network protocol.

Planner.goalStates.stock records only original inventory allocated at root depth. It excludes generated surplus, material allocations and the ready-to-craft flag. RemoveOwned rebuilds with carried counts only, excluding saved bank snapshots regardless of planning preferences. It removes an item group only if every queued root goal for that item is fully covered. This keeps partially fulfilled duplicate goals intact across repeated clicks. No partial quantities are silently reduced, and no crafting/buying/chat occurs.

The queue offers named-set management through measured cards and a preview dialog with native PortraitFrameTemplate, InputBoxTemplate and Theme.ScrollFrame/MinimalScrollBar. Existing UI label/button helpers supply dark styling and CJK fonts. All 12 locales are covered. Goal preview scrolls rather than hiding targets; failures leave the dialog open without changing the queue.

Native references were reused, not copied from another addon: work/reference/SharedUIPanelTemplates.xml and PortraitFrame.lua (portrait), MinimalScrollBar.xml/lua and ScrollUtil.lua (scroll binding), existing UI.Ensure input widgets and Adapter.ItemCount wrapping GetItemCount(id,false). Discovery is recorded in PROJECT.md: rg for PortraitFrameTemplate/frameLevel/MinimalScrollBar and the existing native-source revision table. No new native auction API or dependency was introduced in this task.

Наборы личные, до 10 на персонажа; очередь до 50 целей. Загрузка сохраняет закреплённые конечные рецепты, добавление не меняет текущие спорные источники. Очистка учитывает только исходные готовые вещи на руках, выделенные конечным целям; повторные цели одного предмета удаляются только целиком. Запасы/цены/банк не сохраняются в наборах и не передаются. Отмена загрузки/очистки действует до следующей правки очереди и только в текущем сеансе.


## Maintained stock targets (local 0.4.0 development)

Queue goals optionally carry mode='stock'; nil retains the previous one-time behavior. Quantity is the desired total allocated finished stock, not the amount to craft on each refresh. The existing shared-stock planner consumes available stock and crafts only the deficit, with normal batch rounding, pins, source preferences and dependency checks. Maintained goals stay after RemoveOwned and become actionable again through BAG_UPDATE_DELAYED. No inventory is fabricated and no automated craft or purchase occurs.

One maintained goal per item is allowed. Mode/Add reject duplicate rules; LoadSet rejects a conflicting append atomically before altering queue/undo. Init drops invalid/duplicate active rules and rejects entire malformed saved sets. Save/load preserve the mode and root pins. One-time goals may coexist and allocate inventory separately; repeated item cleanup still waits for the entire item group to be covered while always retaining its maintained goal. Mode edits invalidate queue undo.

Adapter.Inventory optionally returns carried counts alongside combined stock and reads each unique item only once per survey. Queue.Build passes these counts as Planner options.bags. The planner tracks remaining original carried counts separately from generated surplus. goalStates.bankStock records original bank allocation at root depth; retainedBank records only maintained roots. Maintained roots allocate available saved bank stock before carried copies, so those bank copies can remain stored and bags stay available for other goals. This preference does not change total shortage/crafting cost.

Tracker withdrawal = supplied - bagSupplied - retainedBank. Bank inputs used for other goals/crafts remain withdrawal requirements. A bank-only met target therefore does not request a transfer merely to maintain it. Disabling useBank zeroes the bank contribution; dated snapshot status is shown on any rule that relies on bank allocation. Stock-only fulfilled queues use the maintained status. Goal counters describe allocations, not all unreserved player inventory; planned surplus never counts as currently owned stock.

UI goal cards add one measured second-row mode action using the same native button/fonts as existing cards. The Stock field edits target quantity; set previews include modes. All 12 locales are translated. Long duplicate-load errors are measured and shrink the preview region above fixed bottom buttons, avoiding overlap. Native inputs, stock APIs, bag event routing and scroll templates are reused from existing code, with no new dependency/protocol/native API.

Постоянная цель сохраняется после очистки и снова показывает дефицит после расходования. Учёт сумок/банка общий для всей очереди; банк участвует только по настройке, его снимок датирован. Банковская часть готового постоянного запаса остаётся в банке, банковские реагенты для изготовления показываются к переносу. Режим и количество сохраняются в наборах и при перезапуске, другим игрокам не передаются. Правило одно на предмет, конфликтующая загрузка атомарно отклоняется. Отрисовка новых элементов в реальном клиенте ещё требует проверки.


## Native crafter lookup (local 0.4.0 development)

ProfessionActions adds a third, measured full-width Find a crafter button below the existing queue/material actions. It resolves the actual selected SchematicForm recipe again on each click and carries the desired finished-item quantity into the finder. Queue capacity does not limit lookup. Adapter.RecipeOutput is a read-only base-output reader: learned=false is allowed, but linked/guild/NPC/non-local views, wrong profession membership, invalid/mismatched recipe IDs, recraft/dummy/gather/salvage flags and loading/missing output data are guarded. When present, schematic.recipeID must match the requested recipe. No CaptureRecipe/commit/Touch occurs during lookup; unsupported costs/variable output are not promoted to a known own recipe.

Catalog.Crafters matches recipe.output exactly, excludes F.IsSelf, groups multiple variants by owner and sorts favorites first, then fresh profiles, then names. Localized names are search metadata, never matching keys. Profession names are deduplicated for search and query strings are assembled linearly. Existing prune/alias/favorite rules remain; stale favorites can be inspected but are marked saved. Unknown timestamps and skills are explicit, including unknown age in the full Network profile.

UI.FindCrafters opens a transient crafters page under the Network navigation highlight. Search applies to player, matching recipe names and profession. Overview cards are capped at 20 while all matches remain in the left list. A selected player preview shows up to 20 matching variants grouped by profession; the full profile retains every recipe. Only reported skills and known recipes are shown; no online-presence assertion is made. Matching covers base item IDs, not optional crafting choices, quality/equipment variants or service fees.

PreviewCrafter re-reads current profiles and validates the selected owner/recipe/output and quantity. It then builds a plan pinned to that exact owner/recipe using current carried/enabled bank stock, or opens the provider's recipe card. Missing/changed data produces a local message; another provider is never substituted by this action. Facility constraints remain the planner's responsibility. These actions do not modify the queue, own recipe profile, bank snapshot or send messages. Generic request/build actions stay disabled in the finder; explicit per-recipe actions provide the provider pin. The existing background sharing schedule is unchanged, and lookup does not initiate sync.

Native evidence is reused from pinned Gethe Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1 in work/reference: TradeSkillUIDocumentation.lua (GetProfessionInfoByRecipeID line 473; GetRecipeInfo 639; GetRecipeSchematic 753, isRecraft=false); TradeSkillUITypesDocumentation.lua (CraftingRecipeSchematic, recipeID and nullable outputItemID around lines 281–295); ProfessionsCrafting.lua (SelectRecipe, SchematicForm:GetRecipeInfo around 459/499/720). Discovery: rg for those method/field names, then focused ranges. The addon uses its existing native panel hooks/templates/fonts and scroll helper; no new dependency, texture or protocol field is added.

Кнопка работает по текущему результату штатного рецепта, в том числе неизученного, без добавления собственного умения. Только другие игроки, точный item ID, несколько вариантов не увеличивают число мастеров. Свежесть и навык — сведения профиля, не подтверждение онлайна/платы/варианта вещи. План закреплён за выбранным игроком и рецептом, проверяет лагерные требования; изменившиеся данные не заменяются другим мастером. Все 12 локалей; реальная отрисовка кнопки под профессией и страницы результатов ещё требует проверки.


## Local compact UI audit (2026-10-04)

Settings uses a fixed 530×600 portrait frame with a native MinimalScrollBar/ScrollUtil scroll body. Its layout measures text and expands the language selector inline. Theme.FitButton measures the button's private normal-state font, preserves font size, wraps the native Button:GetFontString and adjusts height. Source cards place description text beside icons below their title, use tighter spacing and clear recycled actions/hints. Queue management explanations are retained as localized hover tooltips. The profession panel avoids duplicating the selected recipe title and uses three actions per row at widths ≥540 (two rows below).

UI.LayoutDetails measures the title/subtitle and reserves the actual visible bottom action heights. Background and quantity refreshes restore the prior detail scroll position clamped by GetVerticalScrollRange, rather than assuming a 240-unit viewport. Filter grid buttons use Theme.Button locale fonts and variable row heights. Updates, tracker summaries and auction content measure height; the auction panel derives content widths from its own width. Existing native APIs/protocols/stock logic are preserved.

Native evidence reused from pinned Gethe Forever e3ecc27b64d30fdc735a3f6579b866858f9f9df1: work/reference/SimpleButtonAPIDocumentation.lua (GetFontString, ~112), SimpleFontStringAPIDocumentation.lua (GetStringHeight/SetWordWrap, ~325/~720), SimpleFrameAPIDocumentation.lua (SetClampedToScreen, ~1206), SharedUIPanelTemplates.xml (UIPanelButton templates, ~279–315). Discovery used rg on these names followed by focused reads. The API files originate in Interface/AddOns/Blizzard_APIDocumentationGenerated/; templates in Blizzard_SharedXML/Mainline/. ScrollUtil/MinimalScrollBar remain the existing Theme.ScrollFrame implementation. No new dependency or native asset was added.

Все 12 языков и 41 группа Lua 5.1 проверены в симуляторе. Он проверяет логику, anchor points и приблизительные размеры текста, но не заменяет визуальную проверку в игре. Содержимое настроек прокручивается, шрифты не уменьшены, декоративных рисунков нет. Требуются /reload и проверка реальных глифов/масштаба/клиппинга/штатных текстур.


## Screenshot-driven horizontal layout correction (2026-10-04)

The screenshot showed a real layout miss in the previous ui-compact build: profession actions were still below quantity while the right-hand side was empty. The panel now measures the quantity label, reserves a compact left metadata column, and places all three actions to its right in the same band when space permits. Button widths follow their actual natural text widths plus shared spare space; the former 640-unit width cap and the redundant visible ForeverNet heading are removed. Narrow panels fall back to two action rows; errors appear below the toolbar only when needed. No labels are shortened and no font sizes are reduced.

The audit also moved refresh intervals and the language selector to the right of their Settings labels, packs title/actions into one row for textless queue tool sections when measured widths fit, and packs Remove/Move/Maintain into one action row when all three labels fit. Long labels safely retain the multi-row layout. Character and Network pages hide the unrelated crafting-footer controls and expand both content panes from 357 to 433 units; quantity controls remain on recipes, queue, market, requests and crafter finder. Helpers retain state, callbacks, explanations and native font isolation.

Validation: 42 Lua 5.1 groups passed. New toolbar_layout covers 12 locales and native widths 350/620/640/800/1000, proves actions occupy the right side of the metadata band, checks boundaries/gaps, no width cap, natural-width allocation, error expansion, inline queue actions and long-label fallback, browsing-pane transitions and read-only/no-network refresh. Existing 41 groups also pass. Approximate widget tests are not a native screenshot. The supplied screenshot verifies the previous defect only; the new build still needs /reload and a visual check in the running game. No publishing.

Скриншот подтвердил недостаток предыдущей ui-compact: кнопки оставались под количеством, а справа была пустая область. Теперь слева компактные поля количества/выхода, справа в той же полосе три действия. Ширины кнопок учитывают естественную ширину текста и доступное место. Убраны ограничение ширины панели 640 и отдельный видимый заголовок ForeverNet; название/инструкция доступны в подсказке панели. Узкая панель использует перенос, ошибки добавляют строку только при наличии. Тексты не сокращены, шрифты не уменьшены.

Настройки: интервалы и язык справа от подписи вместо отдельного ряда. Управление наборами: заголовок и кнопки одной строкой, если помещаются. Карточки целей: удаление/перемещение/режим запаса одной строкой, когда измеренные подписи позволяют; длинные переводы сохраняют безопасный перенос. «Персонаж»/«Сеть»: ненужный блок изготовления скрыт, списки и профили выше на 76 (433 вместо 357). На рецептах/очереди/рынке/запросах/поиске мастеров количество сохранено.

42 группы Lua 5.1 прошли, включая 12 языков, 5 ширин (350/620/640/800/1000), размещение действий справа от полей, отсутствие пересечений, естественные ширины, ошибки, длинные переводы, переходы между страницами, прежние действия и отсутствие отправки сообщений при layout-refresh. Это проверка логики/геометрии с приближёнными метриками, а не изображение нового UI из игры. Новый вид после /reload нужно проверить в клиенте. Публичная версия не менялась.

Native discovery: rg GetUnboundedStringWidth/GetStringWidth in pinned work/reference/SimpleFontStringAPIDocumentation.lua and focused read around 398 (uiUnit return). Same Gethe Forever e3ecc27b64d30fdc735a3f6579b866858f9f9df1; original path Interface/AddOns/Blizzard_APIDocumentationGenerated/. No new download. Theme.ButtonWidth uses the existing hidden measurement FontString/private state font. Earlier ui-compact profession layout details are superseded by this correction.


## Dense right panel and unresolved protected-action report (2026-10-04)

Right-panel contents now prioritize useful data: recipe counts before materials, materials in two measured columns, and crafter names without repeating the item name. A single crafter is identified in the header without a duplicate block. Covered materials omit irrelevant missing-price messages. Passive stock/material entries use compact list rows; rows containing actions retain cards and their controls. Queue goals precede set management, and supplied stock is collapsed until requested. Headers, spacing and reused widgets were reviewed; primary body text remains readable and secondary list data uses the existing small font. Long translations expand measured heights.

The user reported a protected-action popup when eating food from a bag outside combat after opening the bank. No root cause has been established. Bank.lua reads stock through C_Bank/C_Container and does not modify native bank/item buttons or invoke item use. No taint log was available. Bootstrap now records the latest five ADDON_ACTION_BLOCKED/ADDON_ACTION_FORBIDDEN events attributed to ForeverNet, their function, bounded diagnostic stack and bank/auction state in private SavedVariables. Notifications are limited to one per 30 seconds. This observes a block; it does not prevent, suppress or repair it.

Use /reload to load this build, then /fn taint on, repeat bank open/close and eating from a bag, and inspect /fn taint status. /fn taint on explicitly enables native taintLog=2; /fn taint off restores the previous setting. Logs/taint.log may need a reload/logout to flush. Do not edit live SavedVariables. Diagnostics, bank snapshots and queues are not shared with peers.

Validation: 44 Lua 5.1 groups passed, including all 12 locales, card reuse/long text/two-column geometry, goal-first queue and expandable stock, read-only bank scan, unchanged native item-use functions in mocks, bounded event capture and CVar restoration. Mocks cannot reproduce the client's secure execution or establish the origin of taint. Native rendering and the protected-action repro remain pending. This build is installed locally; no Git commit/push, release or CurseForge publication occurred.

Native discovery: work/fetch_bank_reference.py queries the recursive Gethe/wow-ui-source tree at Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1, selects BankFrame/ContainerFrame/UIParent/PanelManager paths, and downloads exact files into work/reference/bank-taint/ with manifest.json. Reviewed with rg for UseContainerItem, bagID, bank types and item-click handlers, followed by focused line reads. Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua around 1603 invokes native C_Container.UseContainerItem with BankFrame:GetActiveBankType(); Vanilla/BankFrame.lua around 438 returns the active character bank type only when shown. Camelot and Vanilla bank/container implementations are retained as references; their presence does not prove which exact path the running client uses. No native source was modified or shipped. The native comments about bagID/taint are investigation leads, not proof of this bug. Header measurement reuses the prior pinned SimpleFontString API reference and GetUnboundedStringWidth; no new fonts/assets/libraries.

Где/как искать штатные вещи: скрипт work/fetch_bank_reference.py, recursive GitHub tree закреплённого Forever SHA; поиск suffix BankFrame/ContainerFrame/UIParent/PanelManager, затем rg UseContainerItem/bagID/GetActiveBankType и точечные диапазоны. Пути/ревизия в work/reference/bank-taint/manifest.json. Исходники Mainline/Camelot/Vanilla не считаются автоматически совпадающими с исполняемым клиентом. Ссылка для продолжения: https://github.com/Gethe/wow-ui-source/tree/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_UIPanels_Game. Не приписывать найденному комментарию о taint причинность без журнала.


## Recipe-panel composition offset regression (2026-10-04)

The user's screenshot confirmed that material cards overlapped the recipe calculation. UI.ShowBlocks measured the last block position but did not return it, so RenderSelection passed nil to ShowCards and cards started at offset zero. Returning the measured end position preserves the compact design and places materials below the calculation, with crafters following the material rows.

Regression: the new overview/material separation assertion failed on the previous code with "Material cards overlap the recipe calculation". After the fix all 44 Lua 5.1 groups pass. Additional cases cover all 12 locales, multiline overview at a nonzero offset, material/master separation, empty material lists and final scroll-body extent. These tests use mock font metrics; native rendering remains to check after /reload. No new native APIs, fonts, textures or reference sources were required: this was a local composition return-value error. Installed locally, public ZIP unchanged, no commit/push/publication. The unrelated protected-action report after visiting the bank remains unresolved; existing diagnostics are retained.


## Network recovery under repeated client rejection (2026-10-04)

The new screenshot shows NET_LOCKDOWN, the notice emitted only when SendAddonMessage returns AddOnMessageLockdown (11). It does not identify why the client restricts sending. This is a separate symptom from the protected item-use popup reported earlier; that root cause remains unresolved.

The recovery path had a reproducible defect: each rejection restarted all logical transfers with new tokens on the next attempt. Intermittent acceptance/rejection could repeatedly send fragment 1 and never finish a profile. Short interruptions now preserve tokens and progress. Only a partial transfer idle for at least 120 seconds or alive for at least 840 seconds is restarted, allowing margin before receiver limits of 150/900 seconds. Unsent transfers are not retokenized. Transfer timing and counts are session-local transport metadata and are not encoded into the wire payload.

Consecutive code-11 rejections back off 2/4/8/16/30 seconds, capped at 30; an accepted fragment resets the delay. A held-queue episode gets at most one chat notice, with at least 120 seconds between notices for separate episodes. The Network panel and /fn netstatus still expose the pause. Identical pending HELLO and REQUEST payloads on the same channel are coalesced; changed requests and other channels remain separate. Existing PROFILE revision/follow-up behavior remains. Disabling sharing clears the pending state. No combat/chat-flag pre-gate, alternate channel bypass or restriction-setting changes were added. Refresh settings, including one minute, are retained.

Diagnostics now show pause/retry wait, rejection/restart counts and the age of the last accepted fragment, alongside original result/queue/chat flags. Calling diagnostics sends nothing. The client may continue returning 11: this patch repairs local recovery, not the underlying client policy or its unknown trigger.

Validation: the new intermittent-rejection assertion failed on previous code; after fixing it all 45 Lua 5.1 groups passed. Covered complete profile reconstruction with one token, bounded attempts/notices over five blocked minutes with one-minute auto refresh, duplicate manual sync/request snapshots versus changed status, idle and total-lifetime restart, diagnostic reads, disabled sharing, plus existing enum/chat-flag/TTL and UI regressions. These are mock API tests, not a live WoW reproduction or proof of peer delivery. Installed locally; no commit/push/release/CurseForge publication. Public ZIP unchanged.

Native references were reused, not redownloaded: work/reference/ChatConstantsDocumentation.lua around 144-163 defines SendAddonMessageResult (Success=0, AddOnMessageLockdown=11); ChatInfoDocumentation.lua around 516-532 documents SendAddonMessage's result. The descriptions at 11-18 and 293-301 distinguish the outgoing-chat restriction flags; prior live reports showed those flags do not reliably gate addon communication. Located by rg for exact enum/function names and focused reads. Original paths: Interface/AddOns/Blizzard_APIDocumentationGenerated/, pinned Gethe/wow-ui-source Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1. No native source, CVar, fonts or other addons were modified. The documentation establishes enum meaning, not the trigger of this particular restriction.

Где/как: переиспользованы сохранённые ChatConstantsDocumentation.lua:144-163 и ChatInfoDocumentation.lua:516-532 из Blizzard_APIDocumentationGenerated на закреплённом Forever SHA; rg по SendAddonMessageResult/SendAddonMessage, затем точечные диапазоны. Описания chat-флагов около 11/293 прочитаны отдельно. Значение кода подтверждено, причина ограничения этим не доказывается.


## Retaining messages under rate limits (2026-10-04)

The supplied /fn netstatus screenshot shows SendAddonMessage result=3, paused=false, no code-11 results, 29 queued fragments and an accepted fragment one second earlier. The currently observed restriction is a send-rate limit (AddonMessageThrottle), with intermittent progress; the screenshot alone does not show queue loss or the cause of the earlier lockdown.

A separate reproducible bug was found: codes 3/8 discarded the entire queue after 20 retries of a fragment. Rate limits now retain the queue for automatic retry, with silent 1/2/4/8/15-second backoff capped at 15 seconds. The regular interval adapts from 0.25 to 0.5 to 1 second after refusals, and reduces one step only after at least 60 stable seconds and 32 accepted fragments. Learned pacing is session-local. Accepted messages clear the rate-limit status. Code 11 retains its separate lockdown state/backoff; switching between 11 and 3 reports the actual current state. /fn netstatus adds Throttled, Send interval and rejection counts; the Network panel shows NET_THROTTLE in all 12 locales. No rate-limit notices spam chat. Permanent failures retain their existing explicit error path. The user's one-minute automatic sync setting is preserved, and disabling sharing clears transient pacing.

Validation: the new test failed on prior code with "Rate limits discard the entire queue after 20 retries"; all 46 Lua 5.1 groups pass after repair. Cases cover both 3 and 8 beyond 20 refusals, five blocked minutes of one-minute automatic sync with bounded attempts/no queue growth/no chat notices, complete profile decoding after recovery, actual pacing intervals and slow speed recovery, 11-to-3 transition, diagnostics without sending, 12 locales/CJK glyph coverage, share-off reset and permanent error 5. These mock tests do not establish the live client's rate budget or delivery to a real peer. Installed locally, with source/install/ZIP equality and CRC; public ZIP unchanged. No Git commit/push/release/CurseForge update. The earlier protected item-use report after bank remains unresolved.

Native discovery reuses work/reference/ChatConstantsDocumentation.lua around 144-163: AddonMessageThrottle=3, ChannelThrottle=8, AddOnMessageLockdown=11. Read with rg by exact SendAddonMessageResult name and a focused range. work/reference/ChatInfoDocumentation.lua around 516-532 documents SendAddonMessage's result. Original source: Interface/AddOns/Blizzard_APIDocumentationGenerated/ at pinned Gethe/wow-ui-source Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1. No new fetch, native hooks, fonts/assets or CVar changes. The enum names confirm categories, not numerical rate budgets; retry/pacing bounds are our implementation choices.

Где/как: уже сохранённые ChatConstantsDocumentation.lua:144-163 и ChatInfoDocumentation.lua:516-532, поиск rg точного имени enum/функции и чтение диапазона. Штатные имена разделяют 3/8/11, но не сообщают квоты клиента. Выбранные задержки/интервалы — наша стратегия; не приписывать их Blizzard. Новых штатных ресурсов не потребовалось.


## Release 1.0.0 and standalone extraction — 2026-10-05

ProfessionLinks.lua, its bootstrap/TOC entries and unused RECIPE_CHAT_LINK translations have been extracted from ForeverNet. The link module belongs to a local independent ForeverLink addon; it is excluded from this Git repository and release. ProfessionActions, auction, queue, tracker, bank and network remain. Earlier notes about ProfessionLinks describe historical implementation, not a current dependency. Developer tests/documentation stay in Git, runtime archives use an explicit TOC/font/license whitelist. Private PROJECT/CHANGELOG/work/outputs and branding drafts are ignored. Core and TOC version: 1.0.0; Release stage, not a prerelease.

Native recipe-link sources reused for extraction: Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsRecipeList.lua/.xml and Blizzard_ProfessionsCrafting.lua/.xml; Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua; Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua, pinned Gethe/wow-ui-source Forever SHA e3ecc27b64d30fdc735a3f6579b866858f9f9df1. Located previously with rg GetRecipeLink/GetHighestLearnedRecipe/AddInitializedFrameCallback/common-icon-chatlink and focused reads, retained under work/reference. The standalone tooltip uses its own GameTooltipTemplate and native locale fonts, without Theme or GameFont mutations. No new native API/hook is introduced by extraction. The exact local path and development memory remain private.


## Graphical UI and automation (local development after 1.0.0)

Graphics.lua loads after UI and supplies graphical home/recipe/plan rendering, reusable stats/tiles, measured reagent icon strips, progress bars, tooltips and row disclosure state. The profession-style dark background is retained without decorative profession art. Queue controls, sets and sources are available through explicit disclosure; warnings about blocked dependencies and unknown costs remain accessible. Native bag/item-use methods are not replaced.

Automation.lua loads after SourceCosts and before UI. settings.autoScan and settings.autoSources default to enabled (nil/true); false disables each separately. Profession SHOW/LIST_UPDATE/DATA_SOURCE_CHANGED debounce 0.7s, use the existing read-only scanner, and retry loading at most three times; CLOSE, hidden frame and linked/guild/NPC/remote modes cancel. Current native filters are respected and scanning merges without deleting old recipes. No new crafting/purchase/chat-send API is called.

Queue.Build and single-item UI plans pass through Automation.Build. It considers at most six intermediate items with a total 200,000 price-evaluation-work allowance; SourceCosts.Compare exposes workUsed and accepts a smaller maxWork context. Only fully eligible fresh complete volume-covered price estimates with known local crafting fees can drive a change; ties keep the current route. Explicit sources and final goal pins win. Auto routes are transient autoSources, explicit routes are manualSources, and stored queue.sources remains unchanged. This bounded greedy cash comparison is not global optimization and excludes stock opportunity cost, gathering time and unknown service fees. Source choices may differ as valid price observations change.

Visible single-item plans recalculate on dirty data while preserving root item/quantity/pins/manual choices and scroll state; valid final quantity edits also rebuild. NextCraft highlights the first local step whose full reagent quantities are currently carried; it does not claim physical station proximity or trigger crafting. Saved bank materials must still be withdrawn. Tests include all locales, long text/count geometry, reused widgets/tooltips, cost guards, source priority, live refresh, scan cancellation and fresh-runtime preference persistence.


## Flat theme and QueueBoard (local development, 2026-10-07)

QueueBoard.lua replaces the former RenderQueue accordion. Goals are not repeated on the right. Materials and crafting order share two measured tabs, with one price total, a next-step hint and selected-goal controls. Sets/cleanup/undo use a scrolling menu; material tiles open the existing whole-queue SourceCosts comparison. Unknown final outputs are included as shortages. The generic craft footer is hidden, and its private quantity/label controls are reparented into the selected-goal toolbar. Valid edits save immediately; while typing, the edit box and its parent must not hide/reparent (native keyboard focus). Leaving queue restores the original parent/anchors. No native profession/bag/auction controls are reparented.

Theme uses 1px WHITE8X8 backdrops, flat owned-button fills, centered measured labels, white headings and subdued accents. Native portrait template chrome is hidden only on owned addon windows; title/close behavior and frame levels remain. The six owned side tabs retain native mouse handling while replacing decorative atlas art with simple surfaces/selection rails. Source Sans Latin/Cyrillic from the existing Noto Sans CJK SC file becomes the standard-font fallback; regional CJK and explicit custom fonts remain intact. Shared GameFont objects and native windows are untouched. Extra fonts/assets/dependencies are not added.


## Saved appearance, sidebar and commands (local development, 2026-10-07)

ThemeStyles.lua registers only ForeverNet-owned widgets in weak registries. Settings.uiStyle is sanitized to modern/classic (default modern). Original native button textures, title anchors, window chrome visibility and side-tab atlases/anchors/sizes are captured before hiding/replacing them; Classic restores these and native font files. Modern restores flat owned surfaces, Sans fallback and selection rails. CJK locale/client fallback and language-menu regional font overrides remain active in both styles. Private button-state Font objects are reused; shared GameFont objects and native bag/auction/profession methods are never modified. The owned button instance SetText wrapper invokes FitButton, while main header/footer, language rows and modal preview/error insets measure the resulting height. Flat window child chrome must retain transparent fill on every style switch or it covers parent text. Scroll position is clamped to the real range after repaint. Existing compact content layout is retained in both styles.

Home professions now appear only in left rows, with rank/max skill, recipe count, progress and scan-age tooltip; clicking a row opens the existing profession filter without creating its menu. The right side retains queue/network/bank state. Market favorite item IDs are stored in db.favorites.market, independently sanitized/capped at five; recipe/profile bookmarks are unchanged. Market list unions price snapshots, queue shortages, recipe bookmarks and market bookmarks, filters them once, then renders a top favorite-market group and regular market-items group without duplicates. Removing history cannot remove a watch item. Star clicks update only this independent set. With no shortages, targeted auction scanning uses the union of recipe and market bookmarks. Neither favorite data nor appearance is sent in a profile.

The bottom Commands button replaces Example. /fn help and /fn commands open a stable commands view; the Help button/minimap right click retains the short walkthrough. This view survives inventory refresh and hides crafting footer controls. Demo command, synthetic profile provider, special inventory/routes and translations have been removed from runtime entirely. Synthetic planner graph fixtures now live only in tests/planner_fixture.lua, excluded by runtime packaging. Startup prints the addon name prefix and F.version only.

### Native sources and repeatable lookup for other addons

No new remote source was needed: the pinned Forever source checkout previously saved under work/reference was reused (Gethe/wow-ui-source, forever commit e3ecc27b64d30fdc735a3f6579b866858f9f9df1). Search the original paths below with rg for a template/API name, then follow inherits, parentKey and mixin into XML/Lua before implementing integration. Local reference copies are evidence files and are excluded from the addon package.

- Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml: rg UIPanelButtonTemplate/NormalFont/DisabledFont found the template near lines 304–324, its private Left/Middle/Right art and inherited mouse/enable-state scripts. Preserve these native scripts when restoring Classic; only own art visibility changes. rg PortraitFrameTemplate/TitleContainer found native chrome/title hierarchy near 562–660, including title/close frame levels; snapshot that original state before Modern hides it.
- The same XML: rg LargeSideTabButtonTemplate near 1008 found Background, Icon, Mask, SelectedTexture, TabGlow and HighlightTexture atlas children. Follow SidePanelTabButtonMixin in SharedUIPanelTemplates.lua for fill/checked/click behavior. Capture native atlas geometry after SetFillToInterior and before flat-art edits; a hardcoded guessed native size would lose Forever's wider Camelot tabs.
- Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua: rg UIPanelButtonHeightScaledMixin near 238–246 confirms button art can be height-scaled independently; title positioning near 105–107 belongs to native border setup. Restore captured anchors rather than assuming the modern title location is the native one.
- Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleButtonAPIDocumentation.lua (local same basename): rg GetFontString/GetNormalFontObject/GetDisabledFontObject confirms access to the displayed label and normal/disabled font state. SimpleFontAPIDocumentation.lua and SimpleFontStringAPIDocumentation.lua provide GetFont/SetFont and text measurement. Existing Theme.FitButton measures a private normal font, enables wrapping and sizes both owned button and centered label without shrinking translations or mutating shared fonts.

Checks cover both styles across all 12 locales, native texture/atlas restoration, warm repeated switching without Font growth, fresh-runtime persistence, sidebar separation/search/collapse, removed demo and version-only startup. A second client mock starts with 18px native button fonts to catch spacing/wrapping assumptions. These are Lua/geometry checks; actual native rendering and the previously reported protected item-use popup still require client validation.


## Built-in version channel and native auction wallet strip (2026-10-08)

VersionChannel.lua registers the private ForeverNetVer prefix. Startup prints the installed version; login restores a saved higher participant version and schedules one small announcement after eight seconds. Guild/group/world membership changes also schedule announcements. Version checking is independent of profession-profile sharing: only a protocol marker and validated SemVer are sent, never recipes, inventory or bank data. Guild, home party/raid and instance scopes are checked separately. Older clients can still advertise through the existing PROFILE/HELLO path when profile sharing is enabled.

Current/newer replies cancel pending older-peer responses; replies are short and delayed, coalesced by channel, with a ten-second send cooldown. Failed sends get at most five bounded attempts, no chat spam; leaving a channel discards its pending entry. The updates button schedules this metadata check rather than a full profile sync. Updates.Observe stores the highest private newerAddonVersion and emits at most one update notice per session; later logins remind while the installed version remains lower. No peer report certifies publication on GitHub/CurseForge. No external launch helper or shortcut is used; the previously prepared optional scripts and receipt were removed and archived locally at the user's request.

For other addons, the behavior was verified by listing installed AddOns and using rg VersionCheck/SendAddonMessage/newestSeenVersion in ForeverDungeonJournal/Systems/VersionCheck.lua. Lines 7–11 explain player announcements, 69–97 implement broadcasts and 138–159 persist/remind on login. Its code was not copied. Existing pinned Gethe Forever reference ChatInfoDocumentation.lua and ChatConstantsDocumentation.lua supply RegisterAddonMessagePrefix/SendAddonMessage and success/prefix-registration enums; PartyConstantsDocumentation.lua/PartyInfoDocumentation.lua supply home/instance categories. Read these namespaces and actual return values rather than interpreting the general outgoing-chat restriction flag as a block on addon messages. The full pinned API tree has no documented arbitrary HTTP fetch; URLDocumentation/ExternalEventURLDocumentation launch a URL instead of returning JSON responses. Links and updater apps remain outside in-game checking.

For the wallet overlap, rg MoneyFrame/Inset in work/reference/AuctionHouseFrame.xml found MoneyFrameInset at 11–15 (bottom=3/top=27), MoneyFrameBorder at 17–21 (height=19/bottom=6), and native sell/auction panels above that border at 122/168. A.LayoutPanel reserves at least 36 units and increases it with the actual native strip heights, on attach and render in both themes. Native money widgets are never hidden, reparented or modified. Reference checkout: Gethe/wow-ui-source forever e3ecc27b64d30fdc735a3f6579b866858f9f9df1, local evidence copies in work/reference excluded from the package.

Validation covers the metadata-only channel with profile sharing disabled, all membership scopes, malformed/self guards, delayed/coalesced/cancelled replies, five failed-send attempts, once-per-session notices, muted notices, upgraded-version cleanup and fresh-runtime reminders. Wallet reserve is checked in both themes with normal/increased native heights. Screenshots are user-supplied captures, cleaned with the built-in image_gen tool; they were enlarged by that tool, with labels/layout checked, and retain the captured version number. No claim of reproducing native taint or continuous web monitoring is made.
