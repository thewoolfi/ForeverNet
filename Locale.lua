local _, F = ...
local en = {
    ['   Лагерь '] = '   Camp ',
    [', лагерных объектов '] = ', camp objects ',
    [', связей '] = ', edges ',
    [': рецептов '] = ': recipes ',
    ['API обмена недоступен.'] = 'Communication API unavailable.',
    ['DEMO: двигатель'] = 'DEMO: engine',
    ['DEMO: сумка'] = 'DEMO: bag',
    ['ForeverNet 0.1 — сеть профессий'] = 'ForeverNet 0.1 — profession network',
    ['ForeverNet — обмен: '] = 'ForeverNet — sharing: ',
    ['Skill Graph: узлов '] = 'Skill Graph: nodes ',
    ['\nhelp — команды; demo — безопасный пример цепочки; scan — считать открытую профессию'] = '\nhelp — commands; demo — example chain; scan — scan open profession',
    ['\nАвтор: '] = '\nOwner: ',
    ['\nЗапросы:'] = '\nRequests:',
    ['В этом клиенте нужен адаптер профессий; используйте ручной ввод.'] = 'This client needs a profession adapter; use manual entry.',
    ['Данные предметов ещё загружаются. Повторите сканирование.'] = 'Item data is still loading. Scan again.',
    ['Для обмена нужна гильдия или обычная группа.'] = 'Join a guild or a regular group to synchronize.',
    ['Дополнительно: команды без /fn. help — справка'] = 'Advanced: commands without /fn. help — command reference',
    ['Загружен. /fn demo — пример, /fn help — команды.'] = 'Loaded. /fn demo — example, /fn help — commands.',
    ['Запрос недоступен.'] = 'Request unavailable.',
    ['Запрос уже закрыт.'] = 'Request already closed.',
    ['Запросы'] = 'Requests',
    ['Запросы сети'] = 'Network requests',
    ['Изменять запрос может только автор.'] = 'Only the owner can change a request.',
    ['Исполнитель запроса: '] = 'Request assignee: ',
    ['Лимит: 100 запросов.'] = 'Limit: 100 requests.',
    ['Не удалось отправить сообщение. Повторите /fn sync.'] = 'Sending failed. Retry /fn sync.',
    ['Не хватает: '] = 'Missing: ',
    ['Неверный предмет или количество.'] = 'Invalid item or quantity.',
    ['Неизвестная версия базы; загрузка остановлена.'] = 'Unknown database version; loading stopped.',
    ['Некорректные поля или превышены лимиты профиля.'] = 'Invalid fields or profile limits exceeded.',
    ['Нет доступных предметных рецептов. Разверните категории или используйте ручной ввод.'] = 'No item recipes available. Expand categories or use manual entry.',
    ['Обмен'] = 'Sharing',
    ['Обмен выключен: /fn share on'] = 'Sharing disabled: /fn share on',
    ['Обновить'] = 'Sync',
    ['Откройте окно профессии.'] = 'Open a profession window.',
    ['Очередь заполнена; повторите позже.'] = 'Queue full; try again later.',
    ['Ошибка: '] = 'Error: ',
    ['План собран (исполнение вручную).'] = 'Plan ready (craft manually).',
    ['План требует ресурсов или возможностей.'] = 'Plan needs materials or capabilities.',
    ['Пока нет запросов. Укажите предмет и количество внизу окна.'] = 'No requests yet. Enter item and quantity below.',
    ['Предложить помощь: accept ID; завершить свой запрос: done ID; отменить: cancel ID'] = 'Offer help: accept ID; complete your request: done ID; cancel: cancel ID',
    ['Пример цепочки'] = 'Example chain',
    ['Профиль обновлён. /fn sync — отправить.'] = 'Profile updated. /fn sync — publish.',
    ['Сеть'] = 'Network',
    ['Синхронизация поставлена в очередь.'] = 'Synchronization queued.',
    ['Сканирование превышает лимиты профиля.'] = 'Scan exceeds profile limits.',
    ['Сканировать'] = 'Scan',
    ['Сначала нужен исполнитель.'] = 'An assignee is required first.',
    ['Собрать цепочку'] = 'Build chain',
    ['Создать запрос'] = 'Create request',
    ['Сообщение превышает ограничения.'] = 'Message exceeds limits.',
    ['Считано рецептов: '] = 'Recipes scanned: ',
    ['Цикл/лимит: '] = 'Cycle/limit: ',
    ['включён'] = 'enabled',
    ['выключен'] = 'disabled',
    HELP = [[ForeverNet — /fn commands:
show — profiles, network and requests
language auto|enUS|ruRU — display language
share on|off — enable/disable sharing
sync — publish and query profiles
scan — scan the open Classic profession
profession ID RANK — set a profession
recipe ID OUTPUT QTY PROFESSION REAGENTS — add recipe
  REAGENTS: item:123=2,item:456=4 or -
blueprint RECIPE on|off — Blueprint flag
station RECIPE STATION on|off — required camp object
camp STATION SECONDS — ready after N seconds
uncamp STATION — remove a camp object
forget RECIPE — delete a recipe
plan ITEM QTY — plan using your bags
request ITEM QTY — publish a 30-minute request
accept REQUEST_ID — offer to fulfill
done REQUEST_ID / cancel REQUEST_ID — close your request
graph — Skill Graph size
demo — isolated production-chain example]],
}
local helpRU = [[ForeverNet — команды /fn:
show — профиль, сеть и запросы
share on|off — разрешить/остановить обмен профилями
sync — отправить профиль и запросить профили сети
scan — считать открытую Classic-профессию
profession ID RANK — ручная профессия
recipe ID OUTPUT QTY PROFESSION REAGENTS — ручной рецепт
  REAGENTS: item:123=2,item:456=4 или -
  Пример: recipe custom:gear item:999 1 engineering item:123=2
blueprint RECIPE on|off — метка Blueprint
station RECIPE STATION on|off — требуемое сооружение
camp STATION SECONDS — сможете предоставить через N секунд
uncamp STATION — убрать объект
forget RECIPE — удалить рецепт
plan ITEM QTY — цепочка с учётом ваших сумок
request ITEM QTY — запрос на 30 минут
accept REQUEST_ID — предложить себя исполнителем
done REQUEST_ID / cancel REQUEST_ID — закрыть свой запрос
graph — размер Skill Graph
demo — демонстрационная цепочка без записи и публикации
language auto|enUS|ruRU — язык интерфейса]]
local ru = {
    SCAN_EMPTY = 'Нет доступных изученных предметных рецептов. Откройте свою профессию, очистите поиск и фильтры и повторите сканирование.',
    SCAN_LOADING = 'Данные профессии ещё загружаются. Подождите и повторите сканирование.',
    SCAN_SKIPPED = '. Пропущено неподдерживаемых рецептов: %d',
    SCAN_UNSUPPORTED = 'Не найден поддерживаемый API профессий. Откройте окно профессии и повторите сканирование.',
    OWN_PROFESSION_ONLY = 'Откройте свою профессию. Чужие рецепты не записываются в ваш профиль.',
    PAGE_network = 'Сеть', PAGE_recipes = 'Рецепты', PAGE_requests = 'Запросы', PAGE_chain = 'Цепочка',
    RECIPES_COUNT = 'рецептов', PROFESSIONS = 'Профессии', CAPABILITIES = 'Возможности', CAMP = 'Лагерь: ', SECONDS = ' сек.',
    RECIPE = 'Рецепт', REAGENTS = 'Реагенты', OWNER = 'Автор: ', ACCEPT = 'Предложить помощь', DONE = 'Завершить', CANCEL = 'Отменить',
    HELP_BUTTON = 'Справка', ITEM_FIELD = 'Предмет (item:ID)', QUANTITY_FIELD = 'Количество',
    CHAIN_HINT = 'Выберите рецепт или укажите предмет внизу. Затем нажмите «Собрать цепочку».\n\nДля примера введите demo в поле команд.',
    SELECT_HINT = 'Выберите запись слева.\n\nСканируйте открытую профессию, чтобы заполнить профиль. Включите обмен и нажмите «Обновить», чтобы найти игроков сети.',
    STATUS_open = 'Открыт', STATUS_accepted = 'Принят', STATUS_done = 'Завершён', STATUS_cancelled = 'Отменён',
}
local extra = {
    SCAN_EMPTY = 'No supported learned item recipes. Open your own profession, clear search and filters, then scan again.',
    SCAN_LOADING = 'Profession data is still loading. Wait and scan again.',
    SCAN_SKIPPED = '. Unsupported recipes skipped: %d',
    SCAN_UNSUPPORTED = 'No supported profession API found. Open a profession window and scan again.',
    OWN_PROFESSION_ONLY = 'Open your own profession. Other players’ recipes cannot be added to your profile.',
    PAGE_network = 'Network', PAGE_recipes = 'Recipes', PAGE_requests = 'Requests', PAGE_chain = 'Production chain',
    RECIPES_COUNT = 'recipes', PROFESSIONS = 'Professions', CAPABILITIES = 'Capabilities', CAMP = 'Camp: ', SECONDS = ' sec.',
    RECIPE = 'Recipe', REAGENTS = 'Reagents', OWNER = 'Owner: ', ACCEPT = 'Offer help', DONE = 'Complete', CANCEL = 'Cancel',
    HELP_BUTTON = 'Help', ITEM_FIELD = 'Item (item:ID)', QUANTITY_FIELD = 'Quantity',
    CHAIN_HINT = 'Select a recipe or enter an item below. Then click Build chain.\n\nFor an example, enter demo in the command field.',
    SELECT_HINT = 'Select an entry on the left.\n\nScan an open profession to fill your profile. Enable sharing and click Sync to find players.',
    STATUS_open = 'Open', STATUS_accepted = 'Accepted', STATUS_done = 'Done', STATUS_cancelled = 'Cancelled',
}
for k, v in pairs(extra) do en[k] = v end
ru["YOU"] = "Вы"
ru["MINIMAP_HINT"] = "Левая кнопка: открыть или закрыть. Правая: справка. Перетащите кнопку вдоль миникарты."
ru["SCAN_HINT"] = "Откройте свою профессию и сохраните изученные рецепты."
ru["SHARE_HINT"] = "Разрешить обмен профилем и запросами с гильдией или группой."
ru["SYNC_HINT"] = "Отправить профиль и найти игроков с ForeverNet."
ru["CHOOSE_RECIPE"] = "Выберите рецепт слева."
ru["QUANTITY_ERROR"] = "Введите целое количество от 1 до 10000."
ru["DEMO_ONLY"] = "Учебный пример: не отправляется игрокам."
ru["ENABLE_TO_REQUEST"] = "Для запросов включите обмен."
ru["JOIN_TO_REQUEST"] = "Для запросов нужна гильдия или группа."
ru["FOOTER_FLOW"] = "Выберите предмет, рассчитайте цепочку и запросите помощь."
ru["RECIPE_COUNT"] = "%d рецептов"
ru["MISSING_QUANTITY"] = "Не хватает: %d"
ru["SEARCH_EMPTY"] = "Ничего не найдено. Измените поиск."
ru["EMPTY_recipes"] = "Откройте профессию и нажмите «Сканировать»."
ru["EMPTY_network"] = "Игроков пока нет. Включите обмен и обновите сеть."
ru["EMPTY_requests"] = "Пока нет запросов."
ru["EMPTY_chain"] = "Выберите рецепт и соберите цепочку."
ru["WHAT_TO_MAKE"] = "Что хотите изготовить?"
ru["START_PICK"] = "Выберите рецепт слева, укажите количество и нажмите «Собрать цепочку». Аддон покажет материалы из ваших сумок, недостающие компоненты и возможных исполнителей."
ru["START_SCAN"] = "Откройте свою профессию и нажмите «Сканировать». Здесь появятся изученные рецепты. Затем выберите предмет для расчёта. Кнопка «Пример» показывает учебную цепочку."
ru["START_SUBTITLE"] = "От рецепта до списка действий"
ru["RECIPE_OVERVIEW"] = "Нужно всего: %d. В сумках: %d. За одно изготовление: %d. Изготовлений: %d."
ru["DIRECT_REAGENTS"] = "Материалы этого рецепта"
ru["HAVE_NEED"] = "В сумках: %d / нужно: %d / не хватает: %d"
ru["NO_REAGENTS"] = "Материалы не требуются."
ru["RECIPE_NEXT"] = "Нажмите «Собрать цепочку», чтобы учесть изготовление компонентов другими игроками."
ru["CRAFTER"] = "Исполнитель: "
ru["DATA_AGE"] = "Профиль обновлён %d мин. назад"
ru["NOT_ASSIGNED"] = "Ещё не выбран"
ru["REQUEST_EXPIRES"] = "Запрос истекает через %d мин."
ru["REQUEST_HELP"] = "Предложение помощи подтверждается автором аддона автоматически: первый отклик получает запрос. Передачу материалов и предметов согласуйте в игре. Автор отмечает завершение вручную."
ru["OFFER_PENDING"] = "Ожидаем ответ…"
ru["MISSING_REASON_camp"] = "Нет доступного объекта лагеря для изготовления."
ru["MISSING_REASON_unknown"] = "В сети нет доступного рецепта этого компонента."
ru["MISSING_REASON_cycle"] = "В рецептах обнаружена замкнутая зависимость."
ru["MISSING_REASON_limit"] = "Цепочка слишком сложная для полного расчёта."
ru["MISSING_HELP"] = "Компонент выбран внизу. Нажмите «Запросить помощь», чтобы опубликовать нужное количество."
ru["STEP_OUTPUT"] = "Изготовлений: %d. Будет получено: %d."
ru["MANUAL_CRAFT"] = "Это план, а не заказ исполнителю. Изготовление и передачу предметов выполняют игроки вручную."
ru["PLAN_MISSING"] = "Чего не хватает"
ru["NOTHING_MISSING"] = "Все материалы и возможности найдены."
ru["FROM_BAGS"] = "Из ваших сумок"
ru["NONE_USED"] = "Ничего не используется."
ru["PLAN_STEPS"] = "Порядок изготовления"
ru["ALREADY_OWNED"] = "Нужное количество уже есть в сумках."
ru["CRAFTS"] = "%d изготовл."
ru["PLAN_CYCLE_WARNING"] = "Часть цепочки не рассчитана: цикл или ограничение сложности."
ru["PLAN_READY"] = "Цепочка рассчитана, недостающих материалов нет."
ru["PLAN_NEEDS"] = "Сначала получите недостающие материалы."
ru["NETWORK_SUMMARY"] = "Рецептов: %d. Профилей: %d. Обмен: %s."
ru["SHARE_ON"] = "Обмен: вкл."
ru["SHARE_OFF"] = "Обмен: выкл."
ru["SEARCH_LABEL"] = "Поиск"
ru["CHOSEN_ITEM"] = "Выбранный предмет"
ru["ASK_HELP"] = "Запросить помощь"
ru["DEMO_BUTTON"] = "Пример"
ru["REQUEST_PUBLISHED"] = "Запрос опубликован в сети."
ru["OFFER_SENT"] = "Предложение отправлено. Ожидаем ответ автора."
ru["QUICK_HELP"] = "1. Откройте профессию и нажмите «Сканировать». 2. Выберите рецепт и количество. 3. Соберите цепочку. 4. Выберите недостающий компонент и запросите помощь. Для обмена нужна гильдия или группа и ForeverNet у других игроков. Кнопка миникарты открывает окно; правая кнопка показывает справку. Команды: /fn help."
en["YOU"] = "You"
en["MINIMAP_HINT"] = "Left click: toggle window. Right click: help. Drag around the minimap."
en["SCAN_HINT"] = "Open your profession and save learned recipes."
en["SHARE_HINT"] = "Share your profile and requests with your guild or group."
en["SYNC_HINT"] = "Send your profile and discover ForeverNet players."
en["CHOOSE_RECIPE"] = "Select a recipe on the left."
en["QUANTITY_ERROR"] = "Enter a whole quantity from 1 to 10000."
en["DEMO_ONLY"] = "Example only: never sent to players."
en["ENABLE_TO_REQUEST"] = "Enable sharing to send requests."
en["JOIN_TO_REQUEST"] = "Join a guild or group to send requests."
en["FOOTER_FLOW"] = "Choose an item, build a chain and ask for help."
en["RECIPE_COUNT"] = "%d recipes"
en["MISSING_QUANTITY"] = "Missing: %d"
en["SEARCH_EMPTY"] = "No matches. Change your search."
en["EMPTY_recipes"] = "Open a profession and click Scan."
en["EMPTY_network"] = "No players yet. Enable sharing and sync."
en["EMPTY_requests"] = "No requests yet."
en["EMPTY_chain"] = "Select a recipe and build a chain."
en["WHAT_TO_MAKE"] = "What would you like to craft?"
en["START_PICK"] = "Select a recipe, choose a quantity and click Build chain. See materials from your bags, missing components and possible crafters."
en["START_SCAN"] = "Open your profession and click Scan to list learned recipes. Then select an item to plan. Example shows a sample chain."
en["START_SUBTITLE"] = "From recipe to action list"
en["RECIPE_OVERVIEW"] = "Target: %d. In bags: %d. Per craft: %d. Crafts needed: %d."
en["DIRECT_REAGENTS"] = "Recipe materials"
en["HAVE_NEED"] = "In bags: %d / needed: %d / missing: %d"
en["NO_REAGENTS"] = "No materials required."
en["RECIPE_NEXT"] = "Click Build chain to include components crafted by other players."
en["CRAFTER"] = "Crafter: "
en["DATA_AGE"] = "Profile updated %d min ago"
en["NOT_ASSIGNED"] = "Not assigned yet"
en["REQUEST_EXPIRES"] = "Request expires in %d min."
en["REQUEST_HELP"] = "The request owner's addon accepts the first offer automatically. Arrange materials and delivery in game. The owner marks completion manually."
en["OFFER_PENDING"] = "Waiting for reply…"
en["MISSING_REASON_camp"] = "No required camp facility is available."
en["MISSING_REASON_unknown"] = "No available recipe for this component in the network."
en["MISSING_REASON_cycle"] = "A circular recipe dependency was found."
en["MISSING_REASON_limit"] = "This chain exceeds the planner limit."
en["MISSING_HELP"] = "This component is selected below. Click Ask for help to publish the required quantity."
en["STEP_OUTPUT"] = "Crafts: %d. Output: %d."
en["MANUAL_CRAFT"] = "This is a plan, not an assigned order. Players craft and trade items manually."
en["PLAN_MISSING"] = "Missing materials"
en["NOTHING_MISSING"] = "All materials and capabilities found."
en["FROM_BAGS"] = "From your bags"
en["NONE_USED"] = "None used."
en["PLAN_STEPS"] = "Crafting order"
en["ALREADY_OWNED"] = "You already have the requested quantity."
en["CRAFTS"] = "%d crafts"
en["PLAN_CYCLE_WARNING"] = "Part of the chain could not be resolved: cycle or complexity limit."
en["PLAN_READY"] = "Plan ready: no missing materials."
en["PLAN_NEEDS"] = "Obtain the missing materials first."
en["NETWORK_SUMMARY"] = "Recipes: %d. Profiles: %d. Sharing: %s."
en["SHARE_ON"] = "Sharing: on"
en["SHARE_OFF"] = "Sharing: off"
en["SEARCH_LABEL"] = "Search"
en["CHOSEN_ITEM"] = "Selected item"
en["ASK_HELP"] = "Ask for help"
en["DEMO_BUTTON"] = "Example"
en["REQUEST_PUBLISHED"] = "Request published to the network."
en["OFFER_SENT"] = "Offer sent. Waiting for the owner's reply."
en["QUICK_HELP"] = "1. Open your profession and click Scan. 2. Select a recipe and quantity. 3. Build the chain. 4. Select a missing component and ask for help. Sharing requires a guild or group and other ForeverNet users. Left click the minimap button to toggle; right click for help. Commands: /fn help."
ru["SETTINGS"]="Настройки"
en["SETTINGS"]="Settings"
ru["PAGE_settings"]="Настройки и об аддоне"
en["PAGE_settings"]="Settings and about"
ru["SETTING_SHARE"]="Обмен с гильдией и группой"
en["SETTING_SHARE"]="Share with guild and group"
ru["SETTING_AUTOBANK"]="Сканировать личный банк при посещении"
en["SETTING_AUTOBANK"]="Scan personal bank on every visit"
ru["SETTING_USEBANK"]="Учитывать сохранённый банк в расчёте"
en["SETTING_USEBANK"]="Include saved bank contents in planning"
ru["SETTING_MINIMAP"]="Показывать кнопку миникарты"
en["SETTING_MINIMAP"]="Show minimap button"
ru["LANGUAGE"]="Язык интерфейса"
en["LANGUAGE"]="Interface language"
ru["ABOUT"]="Об аддоне"
en["ABOUT"]="About"
ru["AUTHOR"]="Автор: "
en["AUTHOR"]="Author: "
ru["ABOUT_TEXT"]="Сеть профессий, рецептов и взаимопомощи. Планируйте изготовление вместе с гильдией или группой. Банк хранится отдельно для каждого персонажа и не передаётся другим игрокам."
en["ABOUT_TEXT"]="A network for professions, recipes and cooperation. Plan crafts with your guild or group. Bank snapshots are stored per character and never shared."
ru["BANK_UNSEEN"]="Банк ещё не сохранён. Посетите личный банк."
en["BANK_UNSEEN"]="Bank not scanned yet. Visit your personal bank."
ru["BANK_AGE"]="Банк: обновлён %d мин. назад, видов предметов: %d."
en["BANK_AGE"]="Bank updated %d min ago; distinct items: %d."
ru["BANK_REMINDER"]="Учтён сохранённый банк. Заберите материалы перед изготовлением. После изменения запасов пересчитайте цепочку."
en["BANK_REMINDER"]="Saved bank contents included. Withdraw materials before crafting. Rebuild the chain after stock changes."
ru["MATERIAL_CARD"]="Сумки: %d / банк: %d / нужно: %d"
en["MATERIAL_CARD"]="Bags: %d / bank: %d / needed: %d"
ru["STOCK_CARD"]="Взять из сумок: %d / забрать из банка: %d"
en["STOCK_CARD"]="Use from bags: %d / withdraw from bank: %d"
ru["FROM_STOCK"]="Из ваших запасов"
en["FROM_STOCK"]="From your stock"
ru["RECIPE_OVERVIEW"]="Нужно: %d. В запасах: %d. За одно изготовление: %d. Изготовлений: %d."
en["RECIPE_OVERVIEW"]="Target: %d. In stock: %d. Per craft: %d. Crafts needed: %d."
ru["HELP_TITLE_1"]="Сохраните рецепты"
en["HELP_TITLE_1"]="Save your recipes"
ru["HELP_TEXT_1"]="Откройте свою профессию и нажмите «Сканировать» в ForeverNet."
en["HELP_TEXT_1"]="Open your profession and click Scan in ForeverNet."
ru["HELP_TITLE_2"]="Выберите предмет"
en["HELP_TITLE_2"]="Choose an item"
ru["HELP_TEXT_2"]="Найдите рецепт в списке слева и укажите нужное количество."
en["HELP_TEXT_2"]="Find a recipe on the left and enter the quantity you need."
ru["HELP_TITLE_3"]="Рассчитайте материалы"
en["HELP_TITLE_3"]="Plan the materials"
ru["HELP_TEXT_3"]="Нажмите «Собрать цепочку». Карточки покажут ваши запасы и недостающие материалы. Ниже — порядок изготовления."
en["HELP_TEXT_3"]="Click Build chain. The cards show your stock and missing materials. Crafting steps appear below."
ru["HELP_TITLE_4"]="Запросите помощь"
en["HELP_TITLE_4"]="Ask for help"
ru["HELP_TEXT_4"]="Выберите недостающий компонент слева и нажмите «Запросить помощь»."
en["HELP_TEXT_4"]="Select a missing component on the left and click Ask for help."
ru["HELP_NETWORK"]="Игра с другими участниками"
en["HELP_NETWORK"]="Playing with others"
ru["HELP_NETWORK_TEXT"]="Для обмена нужна общая гильдия или обычная группа и ForeverNet у других игроков. Включите обмен у обоих: поиск участников запускается автоматически. «Обновить» повторяет синхронизацию."
en["HELP_NETWORK_TEXT"]="Sharing requires a common guild or home group and ForeverNet installed by other players. Enable sharing on both sides: discovery starts automatically. Sync refreshes the data."
ru["HELP_CONTROLS"]="Управление"
en["HELP_CONTROLS"]="Controls"
ru["BANK_SECTION"]="Материалы в банке"
en["BANK_SECTION"]="Bank materials"
ru["NEXT_SECTION"]="Что делать дальше"
en["NEXT_SECTION"]="What to do next"
ru["PROJECT_GITHUB"]="Проект на GitHub"
en["PROJECT_GITHUB"]="Project on GitHub"
ru["SUPPORT_BOOSTY"]="Поддержать автора на Boosty"
en["SUPPORT_BOOSTY"]="Support the author on Boosty"
ru["COPY_LINK_HINT"]="Нажмите на ссылку, затем Ctrl+C, чтобы скопировать."
en["COPY_LINK_HINT"]="Click a link, then press Ctrl+C to copy."
ru["NETWORK_PICK"]="Выберите игрока слева, чтобы посмотреть его профессии и рецепты."
en["NETWORK_PICK"]="Select a player on the left to view their professions and recipes."
ru["NETWORK_CHANNEL"]="Канал обмена: "
en["NETWORK_CHANNEL"]="Sharing channel: "
ru["NETWORK_NO_CHANNEL"]="Нет доступной гильдии или обычной группы"
en["NETWORK_NO_CHANNEL"]="No available guild or home group"
ru["NET_CHANNEL_LOST"]="Канал обмена недоступен после изменения группы или гильдии. Повторите обновление в общем канале."
en["NET_CHANNEL_LOST"]="The sharing channel is unavailable after a group or guild change. Sync again in a shared channel."
ru["NET_SEND_FAILED"]="Игра отклонила отправку. Проверьте группу и повторите обновление. Код ошибки"
en["NET_SEND_FAILED"]="The game rejected the message. Check your group and sync again. Error code"
ru["NETWORK_SUMMARY"]="Рецептов: %d. Игроков сети: %d. Обмен: %s."
en["NETWORK_SUMMARY"]="Recipes: %d. Network players: %d. Sharing: %s."
ru["CRAFTER_COUNT"]="Мастеров: %d"
en["CRAFTER_COUNT"]="Crafters: %d"
ru["CHANGE_CRAFTER"]="Сменить мастера / рецепт"
en["CHANGE_CRAFTER"]="Change crafter / recipe"
ru["AVAILABLE_CRAFTERS"]="Доступные мастера"
en["AVAILABLE_CRAFTERS"]="Available crafters"
ru["RECIPE_DETAILS"]="Расчёт рецепта"
en["RECIPE_DETAILS"]="Recipe calculation"
ru["SETTING_AUTOSYNC"]="Автообновление сети"
en["SETTING_AUTOSYNC"]="Automatically refresh the network"
ru["SYNC_INTERVAL"]="Интервал обновления"
en["SYNC_INTERVAL"]="Refresh interval"
ru["SYNC_MINUTES"]="%d мин."
en["SYNC_MINUTES"]="%d min"
ru["ADDON_UPDATES"]="Обновление аддона"
en["ADDON_UPDATES"]="Addon updates"
ru["UPDATE_INSTALLED"]="Установлена версия: %s"
en["UPDATE_INSTALLED"]="Installed version: %s"
ru["UPDATE_FOUND"]="У участника обнаружена версия %s (%s). Проверьте опубликованные файлы по ссылке ниже."
en["UPDATE_FOUND"]="A participant reported version %s (%s). Check the published files using the link below."
ru["UPDATE_NOT_FOUND"]="Более новая версия у участников пока не обнаружена. Проверить опубликованные версии можно по ссылке ниже."
en["UPDATE_NOT_FOUND"]="No newer version has been seen from participants yet. Check published versions using the link below."
ru["UPDATE_NOTIFICATION"]="У %s обнаружен ForeverNet %s. У вас %s. Подробнее: /fn updates."
en["UPDATE_NOTIFICATION"]="%s reported ForeverNet %s. You have %s. Details: /fn updates."
ru["UPDATE_NOTIFY_SETTING"]="Уведомлять о новых версиях у участников"
en["UPDATE_NOTIFY_SETTING"]="Notify when participants report newer versions"
ru["UPDATE_CHECK_PEERS"]="Проверить версии у участников"
en["UPDATE_CHECK_PEERS"]="Check participant versions"
ru["UPDATE_CHECK_QUEUED"]="Проверка версий у участников поставлена в очередь. Для неё нужен включённый обмен и общая группа или гильдия."
en["UPDATE_CHECK_QUEUED"]="Participant version check queued. It requires sharing enabled and a shared group or guild."
ru["UPDATE_DOWNLOAD"]="Скачать опубликованную версию — GitHub"
en["UPDATE_DOWNLOAD"]="Download a published version — GitHub"
ru["UPDATE_INSTRUCTIONS"]="Вручную: скачайте ZIP, замените папку ForeverNet в Interface/AddOns и выполните /reload.\n\nАвтоматически: в приложении CurseForge включите Auto Install Updates для нужной установки WoW. Версия должна быть опубликована на CurseForge."
en["UPDATE_INSTRUCTIONS"]="Manual: download the ZIP, replace the ForeverNet folder in Interface/AddOns, and use /reload.\n\nAutomatic: enable Auto Install Updates for your WoW installation in the CurseForge app. The version must be published on CurseForge."
en["LANG_AUTO"]="Automatic (client language)"
ru["LANG_AUTO"]="Авто (язык клиента)"
en.HELP=en.HELP:gsub('language auto|enUS|ruRU', 'language LOCALE'):gsub('scan the open Classic profession','scan your open profession')..'\nsettings — settings\nupdates — addon versions and downloads'
helpRU=helpRU:gsub('language auto|enUS|ruRU', 'language LOCALE'):gsub('Classic%-профессию','профессию')..'\nsettings — настройки\nupdates — версии аддона и скачивание'
ru.HELP=helpRU
F.Locales={enUS=en,enGB=en,ruRU=ru}
en.SKILL_RANK='Skill: %d'
ru.SKILL_RANK='Навык: %d'
en.PROFILE_RECIPE_HINT='Click a recipe to view its materials and build a production chain.'
ru.PROFILE_RECIPE_HINT='Нажмите на рецепт, чтобы посмотреть материалы и собрать цепочку.'
en.PROFILE_EMPTY='This player has not shared any learned recipes yet.'
ru.PROFILE_EMPTY='Игрок ещё не передал изученные рецепты.'
F.LocaleOrder={'enUS','enGB','ruRU','deDE','frFR','esES','esMX','itIT','ptBR','koKR','zhCN','zhTW'}
F.LocaleNames={enUS='English (US)',enGB='English (UK)',ruRU='Русский',deDE='Deutsch',frFR='Français',
    esES='Español (ES)',esMX='Español (AL)',itIT='Italiano',ptBR='Português (BR)',koKR='한국어',zhCN='简体中文',zhTW='繁體中文'}
function F.L(key)
    local locale = F.db and F.db.settings.locale or GetLocale()
    local dictionary=F.Locales[locale] or en
    if locale=='ruRU' then return dictionary[key] or key end
    return dictionary[key] or en[key] or key
end
F.LocaleEnglish = en

-- Recipe filters and display names; transport codes remain unchanged.
en.CHANNEL_PARTY="Party"
en.CHANNEL_RAID="Raid"
en.CHANNEL_GUILD="Guild"
en.FILTER_BUTTON="Filter"
en.FILTER_PROFESSION="Profession"
en.FILTER_ALL="All"
en.FILTER_TYPE="Recipe type"
en.FILTER_REGULAR="Regular"
en.FILTER_BLUEPRINT="Blueprints"
en.FILTER_CRAFTERS="Crafters"
en.FILTER_MINE="Mine"
en.FILTER_NETWORK="Network"
en.FILTER_RESET="Reset filters"

-- Recipe filters and display names; transport codes remain unchanged.
ru.CHANNEL_PARTY="Группа"
ru.CHANNEL_RAID="Рейд"
ru.CHANNEL_GUILD="Гильдия"
ru.FILTER_BUTTON="Фильтр"
ru.FILTER_PROFESSION="Профессия"
ru.FILTER_ALL="Все"
ru.FILTER_TYPE="Тип рецепта"
ru.FILTER_REGULAR="Обычные"
ru.FILTER_BLUEPRINT="Чертежи"
ru.FILTER_CRAFTERS="Мастера"
ru.FILTER_MINE="Мои"
ru.FILTER_NETWORK="Сети"
ru.FILTER_RESET="Сбросить фильтры"

-- Retained peer profiles are not a promise of current availability.
en.PROFILE_CACHED="Saved data"
en.PROFILE_CACHED_AGE="Saved data: %d min ago"

-- Retained peer profiles are not a promise of current availability.
ru.PROFILE_CACHED="Сохранённые данные"
ru.PROFILE_CACHED_AGE="Сохранённые данные: %d мин. назад"
en.FAVORITES="Favorites"
en.FAVORITE_LIMIT="You can favorite up to 5 profiles and 5 recipes."
en.FAVORITE_HINT="Add/remove favorite (up to 5 of each)."
ru.FAVORITES="Избранное"
ru.FAVORITE_LIMIT="Можно добавить не более 5 профилей и 5 рецептов в избранное."
ru.FAVORITE_HINT="Добавить/убрать из избранного (до 5 каждого типа)."

en.SOURCE_TITLE="Material sources"
en.SOURCE_CHOOSE="Choose source"
en.SOURCE_BACK="Back to full chain"
en.SOURCE_AUTO="Automatic recipe choice"
en.SOURCE_AUTO_HELP="Use stock first, then the first known available recipe, preferring you and fresh profiles. This does not compare costs."
en.SOURCE_EXTERNAL="Obtain separately"
en.SOURCE_EXTERNAL_HELP="Keep the missing reagent on the shopping/gathering list instead of crafting it. It remains missing until you actually have it."
en.SOURCE_CRAFT="Craft"
en.SOURCE_STOCK="Use existing stock"
en.SOURCE_COUNTS="Required in this plan: %d; used from stock: %d."
en.SOURCE_PER_CRAFT="Produces %d per craft. Ingredients per craft:"
en.SOURCE_USE="Use this option"
en.SOURCE_SELECTED="Selected"
en.SOURCE_REBUILD_HELP="Stock is used first with every option. A source choice rebuilds the original item and quantity, including all dependent steps. Choices apply to this plan only. Known recipes are shown; shop prices and gathering locations are not tracked."
en.MISSING_REASON_external="You chose to obtain this reagent separately. Gather, buy or request the missing quantity, then rebuild the plan."
en.MISSING_REASON_source="The selected crafter or recipe is no longer known. Choose another source; the plan will not silently substitute it."
ru.SOURCE_TITLE="Источники реагентов"
ru.SOURCE_CHOOSE="Выбрать источник"
ru.SOURCE_BACK="К полной цепочке"
ru.SOURCE_AUTO="Автоматический выбор рецепта"
ru.SOURCE_AUTO_HELP="Сначала используются запасы, затем первый известный доступный рецепт. Приоритет — вы и свежие профили. Стоимость вариантов не сравнивается."
ru.SOURCE_EXTERNAL="Получить отдельно"
ru.SOURCE_EXTERNAL_HELP="Оставить недостающий реагент в списке для получения, не изготавливая его. Он останется недостающим, пока вы его не получите."
ru.SOURCE_CRAFT="Изготовить"
ru.SOURCE_STOCK="Использовать запасы"
ru.SOURCE_COUNTS="Нужно в этой цепочке: %d; взято из запасов: %d."
ru.SOURCE_PER_CRAFT="Выход за изготовление: %d. Реагенты на одно изготовление:"
ru.SOURCE_USE="Выбрать этот вариант"
ru.SOURCE_SELECTED="Выбрано"
ru.SOURCE_REBUILD_HELP="При любом выборе сначала используются запасы. Выбор источника пересчитывает исходный предмет и количество со всеми зависимыми шагами. Выбор действует только в этой цепочке. Показаны известные рецепты; цены и места добычи не отслеживаются."
ru.MISSING_REASON_external="Вы выбрали получение этого реагента отдельно. Добудьте, купите или запросите недостающее количество и пересчитайте цепочку."
ru.MISSING_REASON_source="Выбранный мастер или рецепт больше не известен. Выберите другой источник; автоматической подмены не будет."

-- Plain-language, inline crafting plan.
en.CHAIN_GET="1. What to get"
en.CHAIN_GET_HELP="Get these materials, then follow the steps below."
en.CHAIN_MAKE="2. What to craft"
en.CHAIN_MAKE_WAIT="After getting the materials, craft in this order."
en.CHAIN_MAKE_HELP="Craft in this order using your materials."
en.CHAIN_GET_COUNT="Get %d more."
en.CHAIN_HAVE="From your stock: %d."
en.CHAIN_OR_MAKE="Or craft this material instead:"
en.CHAIN_FROM="You will need:\n%s"
en.CHAIN_SURPLUS="Extra produced: %d."
en.CHAIN_GET_BUTTON="Get %d ready-made"
en.CHAIN_MAKE_BUTTON="Craft %d"
en.CHAIN_MAKE_ITEM="Craft %s x%d"
en.CHAIN_OTHER_RECIPES="Other recipes"
en.CHAIN_HIDE_RECIPES="Hide recipes"
en.CHAIN_RECIPES="Ways to craft this material"
en.CHAIN_RECIPES_HELP="Choose a recipe for the quantity you need."
en.CHAIN_USE_RECIPE="Use this recipe"
en.CHAIN_STOCK="Stock used in this plan"
en.CHAIN_HIDE_STOCK="Hide stock"
en.CHAIN_SHOW_STOCK="Show stock"
en.CHAIN_REFRESH="Recalculate chain"

-- Plain-language, inline crafting plan.
ru.CHAIN_GET="1. Что нужно получить"
ru.CHAIN_GET_HELP="Получите эти материалы, затем переходите к изготовлению ниже."
ru.CHAIN_MAKE="2. Что потом изготовить"
ru.CHAIN_MAKE_WAIT="После получения материалов изготовьте по порядку."
ru.CHAIN_MAKE_HELP="Изготовьте по порядку из имеющихся материалов."
ru.CHAIN_GET_COUNT="Получите ещё %d шт."
ru.CHAIN_HAVE="Из ваших запасов: %d шт."
ru.CHAIN_OR_MAKE="Можно изготовить этот материал:"
ru.CHAIN_FROM="Понадобится:\n%s"
ru.CHAIN_SURPLUS="Получится лишних: %d шт."
ru.CHAIN_GET_BUTTON="Получить %d шт."
ru.CHAIN_MAKE_BUTTON="Изготовить %d шт."
ru.CHAIN_MAKE_ITEM="Изготовить %s x%d"
ru.CHAIN_OTHER_RECIPES="Другие рецепты"
ru.CHAIN_HIDE_RECIPES="Скрыть рецепты"
ru.CHAIN_RECIPES="Как изготовить этот материал"
ru.CHAIN_RECIPES_HELP="Выберите рецепт для нужного количества."
ru.CHAIN_USE_RECIPE="Использовать рецепт"
ru.CHAIN_STOCK="Используемые запасы"
ru.CHAIN_HIDE_STOCK="Скрыть запасы"
ru.CHAIN_SHOW_STOCK="Показать запасы"
ru.CHAIN_REFRESH="Пересчитать цепочку"

en.CHAIN_PLAN_ONLY="This is a plan. Craft in your profession window."

ru.CHAIN_PLAN_ONLY="Это план. Изготовление — в окне профессии."
