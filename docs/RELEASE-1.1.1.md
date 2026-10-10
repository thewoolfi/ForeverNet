# ForeverNet 1.1.1

## English — changes since 1.1.0

- Added native WoW item tooltips: armor, stats, effects and requirements now appear when hovering an item. Planning quantities, bank counts and price hints remain below the description.
- Tooltips cover recipes, network cards, sidebar items, selected items, production chains and reagents, queue materials/crafts, market, tracker and auction results. Uncached items show a loading message and refresh when data arrives; reused and hidden cards clear stale tooltips.
- Restored recipe chat-link buttons beside recipe names in the native profession window. Click to insert the recipe link into a chat draft, then press Enter to send. With ForeverLink enabled, its existing button is used without a duplicate.
- Auction results now use compact rows with item icons and individual hover targets. Both Modern and Classic appearances and all 12 interface languages are supported.
- Expanded diagnostics for intermittent bag item-use blocks: bank scan stages, open windows, combat state and available native security attribution are recorded. `/fn taint status` shows the current logging level; detailed bank tracing runs only after enabling diagnostics.

**Known issue:** the intermittent block when using an item from a bag remains under investigation. This update improves diagnostics; a fix is not confirmed.

Descriptions use base item IDs from the catalog, without a particular inventory copy's enchantments or random variants. Saved recipes, bank snapshots, favorites and queue data are retained.

## Русский — изменения после 1.1.0

- Добавлены штатные подсказки предметов WoW: при наведении видны броня, характеристики, эффекты и требования. Количества для плана, запасы банка и подсказки о цене остаются ниже описания.
- Подсказки работают в рецептах, карточках сети, списках слева, выбранном предмете, цепочках и реагентах, материалах и крафтах очереди, рынке, трекере и результатах аукциона. Для незагруженных предметов показывается сообщение о загрузке с последующим обновлением; скрытые и повторно используемые карточки очищают старую подсказку.
- Возвращены кнопки ссылки на рецепт рядом с названиями в штатном окне профессии. Нажмите кнопку для вставки ссылки в черновик чата, затем Enter для отправки. При включённом ForeverLink используется его кнопка без дубля.
- Результаты аукциона представлены компактными строками с иконками и отдельной областью наведения. Поддерживаются обе темы и все 12 языков интерфейса.
- Расширена диагностика редкой блокировки предметов из сумки: сохраняются этапы сканирования банка, открытые окна, состояние боя и доступные сведения об источнике taint. `/fn taint status` показывает текущий уровень журнала; подробная запись этапов банка работает после включения диагностики.

**Известная проблема:** редкая блокировка использования предметов из сумки ещё исследуется. Улучшена диагностика; исправление не подтверждено.

Описание относится к базовому ID из каталога; чары и случайные варианты конкретного экземпляра из сумки не отображаются. Сохранённые рецепты, снимки банка, избранное и очередь сохраняются.
