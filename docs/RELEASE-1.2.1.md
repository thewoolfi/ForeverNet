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
