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
