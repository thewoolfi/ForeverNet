# ForeverNet — База знаний и таблица ошибок (Troubleshooting & Memory)

Документ создан для быстрой навигации по известным проблемам, их первопричинам и применённым решениям без необходимости перечитывать весь исходный код. Обновляется после решения каждой задачи.

---

## Быстрая сводная таблица ошибок и исправлений

| # | Симптом / Проблема | Где проявлялось | Первопричина (Root Cause) | Решение / Исправление | Затронутые файлы |
|---|---------------------|-----------------|---------------------------|-----------------------|------------------|
| 1 | **Значки выходят за пределы окна аддона при скроллинге** | Список рецептов (слева), вкладка «Сеть» (справа) | Значки крепились к `U.BadgeLayer` (`UIParent`), который не обрезается границами `ScrollFrame`. | Функция `U.GetScrollParent(region)`. Если виджет внутри `ScrollFrame`, значок цепляется к строке (`icon:GetParent()`), активируя аппаратный clipping WoW. | `Graphics.lua` |
| 2 | **Материалы других профессий не отмечаются молоточком** (напр. Камень теней `item:1210`) | Сумки, банк | `C.IsCraftMaterial` требовал либо изученного рецепта в сети, либо наличия в узком списке `KNOWN_MATERIALS`. Семейство `Trade Goods` (7) и `Reagents` (5) проверялось только как вторичный признак. | Проверка `C.IsReagentFamily(id)` вынесена на первое место — все хозтовары и реагенты игры подсвечиваются для всех профессий. Камень теней и классические камни внесены в `KNOWN_MATERIALS` для мгновенного отклика. | `Catalog.lua` |
| 3 | **Значки не отображаются в личном банке** | Окно личного банка (`BankFrame` / `BankPanel`) | В современном UI WoW клиент использует динамический пул `BankPanel:EnumerateValidItems()` / `itemButtonPool`. Кнопки не имеют `GetBagID()`/`GetID()`, а используют `GetBankTabID()` и `GetContainerSlotID()`. Переключение вкладок не отслеживалось. | Полная поддержка `BankPanel`: опрос `EnumerateValidItems()`, извлечение через `GetBankTabID`/`GetContainerSlotID`/`GetItemLocation`. Добавлены хуки `hooksecurefunc` на смену вкладок (`SelectTab`, `SetBankType`) и таймеры задержки 0.15s и 0.4s после открытия. | `Graphics.lua`, `Bank.lua` |
| 4 | **Значки банка не исчезают после закрытия банка (висят в воздухе)** | Экран игры после закрытия окна банка | 1) Значки банка на `UIParent` должны были гаситься тикером `OnUpdate` по скрытию иконки, но из-за опечатки `badge.parent == U.BadgeLayer` (в WoW API у текстур нет поля `.parent`, только метод `:GetParent()`) они не попадали в `activeBadges`.<br>2) В `BANKFRAME_CLOSED` проверка `bankShown` шла до сброса `B.open = false`. | 1) Добавлена функция `U.HideBankBadges()`, принудительно гасящая все значки банка при закрытии.<br>2) `BANKFRAME_CLOSED` теперь первым делом сбрасывает `B.open = false` и вызывает `HideBankBadges()`.<br>3) На `OnHide` окна банка повешен хук `HideBankBadges()`.<br>4) Исправлена регистрация в `activeBadges`. | `Graphics.lua`, `Bank.lua` |
| 5 | **Отсутствовала настройка отключения значков** | Интерфейс настроек, команды чата | Не было флага в базе данных и элементов UI для включения/выключения молоточков. | Добавлен параметр `F.db.settings.materialBadges`, чекбокс в `Settings.lua`, слэш-команда `/fn badges on|off` в `Bootstrap.lua`, локализация на 12 языков. | `Settings.lua`, `Bootstrap.lua`, `Locale.lua`, `FeatureLocales.lua` |
| 6 | **Визуальный стиль окантовки значков** | Все значки-молоточки | Значок был без окантовки, затем требовалась мягкая закруглённая рамка достаточной ширины. | Создана маска `TempPortraitAlphaMask`, мягкий золотисто-жёлтый цвет `(0.92, 0.78, 0.20, 0.92)`, толщина/отступ 2px (`U.BADGE_BORDER_OFFSET = 2`). | `Graphics.lua` |
| 7 | **В банке есть значки — в сумках пропали** | Сумки игрока (`ContainerFrameCombinedBags`, `ContainerFrame1..14`) | 1) `EnumerateValidItems()` возвращает 3 аргумента `(iter, state, init)`. При вызове в `for a,b in iter do` без `state, init` внутри Blizzard-итератора происходила фатальная ошибка `index = index + 1` на `nil`, прерывавшая выполнение `BagBadges`.<br>2) В Classic сумки не имеют таблицы `.Items` или метода `EnumerateValidItems`, а `BagContainers()` отсеивал фреймы без них.<br>3) В Classic кнопки не имеют метода `:GetBagID()`, номер сумки берется только через `:GetParent():GetID()` или от контейнера.<br>4) Открытие сумок клавишей 'B' (`ToggleAllBags`/`OpenAllBags`) не генерирует `BAG_UPDATE_DELAYED`. | 1) Итератор `EnumerateValidItems` и `pool` вызываются безопасно со всеми аргументами `for a,b in iter,state,init do` внутри `pcall`.<br>2) В `collectContainerButtons` добавлены 5 стратегий поиска кнопок (`.Items`, `EnumerateValidItems`, `itemButtonPool`, `ContainerFrameXItemY` и `GetChildren`).<br>3) В `processBagButton` добавлен фолбэк получения `bagID` из `button:GetParent():GetID()` / `container:GetID()`, а текстуры — из `_G[name..'IconTexture']` и регионов.<br>4) Добавлены хуки на `OpenAllBags`, `ToggleAllBags`, `OpenBag`, `ToggleBag` и регистрация `BAG_OPEN`, `BAG_CLOSED`, `BAG_UPDATE`. | `Graphics.lua`, `Bank.lua`, `Bootstrap.lua` |
| 8 | **Реализовав значки в банке, сломались значки в сумках (в банке есть — в сумках пропали)** | Сумки игрока (`ContainerFrameCombinedBags`, `ContainerFrame1..14`) | 1) `U.BagContainers()` включал родительский фрейм `ContainerFrameContainer` и `BankFrame`. При общем сборе кнопок скрытые контейнеры перезаписывали видимые кнопки и вызывали `U.MaterialBadge(texture, nil)`, стирая значки.<br>2) В `Bank.lua` на `BANKFRAME_OPENED` задержки 0.15s и 0.4s вызывали только `BankBadges()`, пропуская открывающиеся сумки.<br>3) На `BANKFRAME_CLOSED` ошибочно вызывался `BankBadges()` до физического скрытия окна банка.<br>4) `U.BagBadges()` не вызывал `U.BankBadges()`. | 1) Контейнеры сумок очищены: `ContainerFrameContainer` и `BankFrame` удалены из списка сумок. Обход контейнеров изолирован (для Combined Bags опрашивается `Items[1..N]`).<br>2) На открытие банка таймеры запускают И `BagBadges()`, И `BankBadges()`.<br>3) На закрытие банка вызываются `HideBankBadges()` и `BagBadges()`, стирая значки банка и сохраняя значки открытых сумок.<br>4) В конце `U.BagBadges()` добавлен вызов `U.BankBadges()`. | `Graphics.lua`, `Bank.lua` |

---

## Детальный разбор архитектурных грабель и правил для WoW API

### 1. Текстуры и виджеты WoW: `.parent` vs `:GetParent()`
> [!WARNING]
> В WoW Lua API пользовательские текстуры и фреймы являются объектами C++ userdata. Свойство `widget.parent` **не существует** по умолчанию (равно `nil`), если его явно не присвоить в коде Lua. Для получения родителя **всегда** вызывайте `widget:GetParent()`.

### 2. Защищённые фреймы сумок (Protected Container Frames) vs ScrollFrame
- **Контейнеры сумок** (`ContainerFrameCombinedBags`, `ContainerFrame1..14`) — защищённые кнопки Blizzard. Добавление дочерних фреймов может вызывать `ADDON_ACTION_FORBIDDEN` при вызове `UseContainerItem`. Поэтому значки сумок создаются на общем слое `U.BadgeLayer` (`UIParent`).
- **Скроллируемые списки аддона** (`ScrollFrame`, `U.listScroll`, `U.details`) — наши собственные фреймы. Если повесить оверлей на `UIParent`, движок WoW не будет аппаратно обрезать его по границам скролла. Для них значок обязан создаваться на `icon:GetParent()`.

### 3. Эволюция интерфейса Банка (Classic vs Dragonflight / The War Within)
- **Classic Era / WotLK / TBC / Vanilla**: банк состоит из 24 или 28 статичных кнопок `BankFrameItem1` .. `BankFrameItem28` (сумка `BANK_CONTAINER = -1`), а сумки банка открываются как `ContainerFrame5..11`.
- **Modern / Unified Bank (`BankPanel`)**:
  - Кнопки генерируются динамически через объектный пул `bankPanel.itemButtonPool`.
  - Обход активных слотов выполняется через `bankPanel:EnumerateValidItems()` или `itemButtonPool:EnumerateActive()`.
  - Методы на кнопке: `btn:GetBankTabID()` (номер вкладки) и `btn:GetContainerSlotID()` (номер ячейки во вкладке).
  - Смена вкладок не переоткрывает окно, а вызывает `bankPanel:SelectTab()` / `bankPanel:SetBankType()`, что требует отслеживания через `hooksecurefunc`.
  - Генерация слотов происходит асинхронно, поэтому открытие окна банка требует коротких задержек (0.15s и 0.4s) для повторного сканирования кнопок.

### 4. Определение предметов и семейств ремёсел
- Проверка `classID == 7` (`Trade Goods`) и `classID == 5` (`Reagents`) покрывает все материалы ремёсел в игре (ткань, руда, слитки, травы, кожа, драгоценные камни, чары, стихии, части инженерии, ингредиенты кулинарии).
- `C_Item.GetItemInfoInstant` возвращает `classID` синхронно из базы клиента, но для низкоуровневых предметов сразу после старта игры надежнее иметь список `C.KNOWN_MATERIALS` как мгновенный кэш до первого отклика сервера.

### 5. Конфликт открытых и закрытых контейнеров сумок и видимость текстур
- В WoW клиент поддерживает два режима сумок: единая объединенная сумка (`ContainerFrameCombinedBags`) и раздельные сумки (`ContainerFrame1..14`). В памяти клиента ВСЕГДА существуют оба набора фреймов. Тот набор, который выключен в интерфейсе пользователя, имеет `IsShown() == false`.
- Если обходить контейнеры в один проход, закрытый контейнер может быть проверен раньше открытого. При этом кнопки предметов помечаются как `seen = true` со статусом `containerShown = false`, что приводило к принудительному скрытию значков на открытом экране.
- **Решение**: строго двухпроходный обход (Two-pass sweep):
  1. **Pass 1**: сбор и отрисовка кнопок только тех контейнеров, у которых `containerShown == true`. Пометка `seen[btn] = true`.
  2. **Pass 2**: закрытие/очистка значков для контейнеров `containerShown == false`, но **исключая** те кнопки, которые были помечены в Pass 1.
- Для текстур (`Texture:IsVisible()`) в Blizzard UI: текстура не всегда корректно сообщает `IsVisible()`. Всегда используйте безопасную цепочку:
  ```lua
  local visible = target:IsVisible()
  if visible == nil or visible == false then
      local parent = target.GetParent and target:GetParent()
      visible = target:IsShown() and (not parent or (parent.IsVisible and parent:IsVisible()) or (parent.IsShown and parent:IsShown()))
  end
  ```

### 6. Итераторы Blizzard EnumerateValidItems и кнопки в Classic
- Метод `container:EnumerateValidItems()` в коде Blizzard возвращает 3 значения: функцию-итератор, состояние (`self`) и начальный индекс (`0`).
  Если сохранить только первое значение `local ok, iter = pcall(container.EnumerateValidItems, container)` и запустить цикл `for a,b in iter do`, Lua вызывает итератор с аргументом `nil`. Внутри итератора строка `index = index + 1` выдаёт ошибку `attempt to perform arithmetic on a nil value`.
  **Правильный вызов**: `local ok, iter, state, init = pcall(...)` и `for a,b in iter, state, init do` строго внутри `pcall`.
- В Classic контейнерах кнопки не имеют метода `btn:GetBagID()`. Номер сумки необходимо определять через `btn:GetParent():GetID()` или ID контейнера. Иконка кнопки в Classic называется `_G[btn:GetName() .. "IconTexture"]`.

### 7. Изоляция `BagContainers()` от `ContainerFrameContainer` и `BankFrame`
- `ContainerFrameContainer` — это служебный фрейм компоновки в Modern WoW. Он не содержит ячеек с предметами, но при `IsShown() == false` может ложно пометить кнопки как закрытые.
- `BankFrame` и `BankPanel` обрабатываются отдельным сканером `U.BankBadges()`, так как используют совершенно другие API (`BankPanelItemButton`, `GetBankTabID`, асинхронные пулы). Смешивание их в одном списке приводило к взаимным затираниям.
- При закрытии банка (`BANKFRAME_CLOSED`) вызывается `U.HideBankBadges()`, которая очищает исключительно кнопки банка из таблицы `U.bankBadges`, гарантируя, что бейджи на открытых сумках остаются нетронутыми.


