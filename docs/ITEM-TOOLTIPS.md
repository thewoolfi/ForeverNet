# Native item descriptions — local 1.1.1, 2026-10-10

`ItemTooltip.lua` owns one `ForeverNetTooltip` using `GameTooltipTemplate`. It is loaded after the theme and before the UI. `Theme.ShowItemTooltip` validates a base `item:N` ID and delegates rendering to `SetItemByID`, or `SetHyperlink` when the former is unavailable. WoW supplies the name, quality colors, armor, stats, effects, requirements and other native item lines. The addon does not synthesize equipment statistics or change the global `GameTooltip`, native bag/item-use methods or shared font objects.

The planning footer is appended after native lines. Only the owned tooltip's primary info receives a `rebuildPostCall` callback to restore that footer after Blizzard rebuilds item data. This callback checks the current hover record and owner visibility. Private region fonts retain theme/CJK support without recoloring native item lines. Modern and Classic use the same native data path.

On a cache miss, the tooltip shows the fallback name, a localized loading message and planning hints. It requests the base ID once per active hover through `C_Item.RequestLoadItemDataByID` (older-client fallback: `GetItemInfo`). Bootstrap routes `GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT`; only the matching visible owner refreshes. A failed request displays a localized unavailable message. Leaving, hiding, changing appearance or reusing a widget clears the active state and handler info. Custom non-item entries keep their text tooltips and make no item-data requests.

Bindings cover sidebar item rows, recipe/profile cards, visual material tiles, legacy material cards, selected-item/footer frames, the current item's header icon, source/chain steps, reagent icons, queue crafts/next step and tracker rows. The plan header explicitly uses the root result instead of whichever shortage is selected. Help/Commands have no item binding. Auction results are separately measured, mouse-enabled rows with icons, keeping existing scan and balance-strip behavior. No new click actions are attached to those result rows.

The catalog records base IDs. Tooltips consequently describe a base item, not a particular inventory copy's enchantments, random suffix or other variant metadata. Persisted profile schema, private bank snapshots, transport and price matching remain unchanged.

## Sources and how they were found

The previously pinned Forever tree was searched for `TooltipDataHandler`, `GetItemByID`, `RequestLoadItemDataByID` and item-data events. Its GitHub recursive tree was used to find the original filenames, then the raw files were saved under `work/reference` and read with `rg` and numbered excerpts. These evidence copies and lookup records are excluded from addon packaging.

Pinned tree: Gethe/wow-ui-source, Forever commit `e3ecc27b64d30fdc735a3f6579b866858f9f9df1`.

- [TooltipDataHandler.lua](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua): lines 241–300 process native tooltip data; 366–395 rebuild and invoke the primary info's post-call callback; near 525 `SetItemByID` maps to `C_TooltipInfo.GetItemByID`, and near 590 `SetHyperlink` maps to `GetHyperlink`. `GetPrimaryTooltipInfo` returns the owned tooltip's first info record.
- [TooltipInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua): near 439, `GetItemByID` accepts an item ID and may return no data. This is why missing-cache fallback is required.
- [ItemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua): near 1710, `RequestLoadItemDataByID`; near 1813/1855, `GET_ITEM_INFO_RECEIVED`/`ITEM_DATA_LOAD_RESULT`, both reporting item ID and success. These events supply the cache completion path.

For another addon, follow the actual tooltip template/mixin and documented return behavior before binding hover callbacks. Keep native item rendering and addon-specific hints separate in ordering, validate stored IDs, and detach stale callbacks when reusing rows. Avoid global item-use hooks or custom copies of stat strings.

## Validation

53 Lua 5.1 test groups pass. New tests verify native delegation with armor/stat/effect/requirement fixtures, native colors, footer ordering and rebuilds, legacy method fallback, one cache request, matching/wrong/failed events, hidden/recycled owners, custom-ID fallback, actual item surfaces, help/commands cleanup, both themes and all 12 locales. Auction tests also check independent hover rows and narrow-width text bounds. Existing font coverage, saved data, transport and protected-action diagnostics still pass.

The test tooltip is a mock with supplied native rows; this establishes delegation and lifecycle behavior, not live-client rendering or server item-data completeness. In-game rendering still requires validation. The earlier protected item-use report after a bank visit is not claimed fixed by this change.
