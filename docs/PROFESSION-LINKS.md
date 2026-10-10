# Recipe links in the native profession list — local 1.1.1

Restored on 2026-10-10 at the user's request. `ProfessionLinks.lua` adds a 20×20 chat-link button on the right of a native recipe row. `Bootstrap` starts it after successful addon initialization; the module is included in the runtime TOC and package. It uses the main addon's saved language and private tooltip fonts, with translations in all 12 languages.

The link is the recipe hyperlink from `C_TradeSkillUI.GetRecipeLink`, including enchant/spell formats returned by that API. It is inserted into the active chat draft, or opens a draft when chat is closed. The player presses Enter to send. A failed insertion into an active draft does not overwrite it by opening another chat box. No `SendChatMessage`, craft action or network synchronization is called by the link button.

The native ScrollBox initializes and reuses rows. `ScrollUtil.AddInitializedFrameCallback` attaches after native row initialization; existing rows are visited separately with `ForEachFrame` because callback signatures differ. Clicks resolve the current `GetElementData()` and highest learned recipe again. Category rows get no button. Missing links disable the button and are retried after recipe/item-data events. Native row selection, modified clicks, menus and other row scripts are retained.

Layout captures the native label width per initialization in a weak row map. Refresh does not progressively shrink it. The button reserves space alongside the craftable count, skill-up marker and locked icon; locked rows anchor the link immediately left of the lock. Art comes from the native chat-link and tertiary-square atlases, not a Unicode glyph or added image.

When the separate ForeverLink is loaded, ForeverNet yields this feature to it. If ForeverLink is loaded after Net already attached rows, Net hides its own buttons, restores the recorded native width and corrects the independent module's captured baseline before its normal refresh. Future initialization callbacks leave those rows to ForeverLink. Both addon load orders and subsequent row reuse were tested against the actual private ForeverLink core. Its runtime files, settings and ZIP were not changed or published.

## Native sources and lookup

Previously downloaded reference files from [Gethe/wow-ui-source, Forever commit e3ecc27b64d30fdc735a3f6579b866858f9f9df1](https://github.com/Gethe/wow-ui-source/tree/e3ecc27b64d30fdc735a3f6579b866858f9f9df1) were reused. Search terms were `GetRecipeLink`, `GetHighestLearnedRecipe`, `AddInitializedFrameCallback`, `LockedIcon`, `Count`, `SkillUps`, `common-icon-chatlink`, `OpenChat`, `GetActiveWindow` and `InsertLink`. The earlier recursive-tree lookup and retained source copies are described in PROJECT.md's original recipe-link task; no new assets were fetched.

- `work/reference/ProfessionsRecipeList.lua`: near 45–60, native modified-click recipe links; near 235–274, locked icons; near 335–350, craftable-count and measured label-width layout. Follow `ProfessionsRecipeList.xml` for row children and anchors.
- `work/reference/ProfessionsCrafting.lua`: near 35–45, `ProfessionsLinkButtonMixin` uses `common-icon-chatlink`/disabled and tertiary-square normal/hover/disabled atlases.
- `work/reference/ScrollUtil.lua`: 17–29 documents the post-initialization callback and optional existing-frame iteration. Preserve the separate owner/frame/node and row/node callback signatures.
- `work/reference/ChatFrameUtil.lua`: near 433, draft opening; near 496, active edit box lookup; later native link paths use `InsertLink`. `ChatFrameEditBox.lua` supplies the surrounding edit-box behavior. `TradeSkillUIDocumentation.lua` documents recipe-link lookup and recipe-list events.

For reuse in another addon, attach only owned children to native rows, resolve current row data at click time, retain native click scripts and avoid sending a message automatically. Capture widths after native initialization, not after your previous adjustment.

## Checks

54 main Lua 5.1 groups pass, including new link coverage for draft behavior, unavailable links/API fallbacks, recycled/category/missing-label rows, highest learned variants, counts/locks, repeated attachment, translated tooltips and late handoff. Two additional actual-module tests verify both ForeverLink/Net load orders, one visible button, stable native widths after repeated initialization and working draft links. Logs: `outputs/restored-profession-links-tests.txt` and `outputs/recipe-links-coinstall-tests.txt`.

These checks use mocks. The button's placement and chat behavior still require an in-game check after `/reload`; the earlier protected item-use popup is not claimed fixed.
