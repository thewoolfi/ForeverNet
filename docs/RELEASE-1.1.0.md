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
