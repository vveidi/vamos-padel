# 04: The Health prompts

**What to build:** The two Health permission descriptions in both languages.

They are the only user-facing strings that live outside Swift: `INFOPLIST_KEY_NSHealthShareUsageDescription` and `INFOPLIST_KEY_NSHealthUpdateUsageDescription`, in the watch target's build settings, in Russian. Xcode does not extract build settings into a String Catalog, so this one is done by hand at both ends.

They are also the first thing a new owner reads — the sheet stands between them and their first match — and they cannot be shared with `Shared/Localizable.xcstrings`: Info.plist localization is per target.

**Blocked by:** 01

**Status:** ready-for-human

- [x] Both `INFOPLIST_KEY_NSHealth…UsageDescription` values are English
- [x] `padel Watch App/InfoPlist.xcstrings` carries the Russian for both keys
- [ ] The permission sheet was seen in both languages on a fresh install, and neither one shows the raw key
- [x] The iPhone target gains no Health strings — it asks for nothing from Health

## Notes

The English is American, and is not a translation of the Russian sentence but the same argument made in English: the app reads heart rate and calories to record the match as a workout, and needs to write the workout so the watch keeps the score screen lit for the whole game.

## Comments

**Written, not yet seen.** Three criteria of four are met; the fourth is the fresh install, which the owner is running.

- **The build settings speak English.** Both `INFOPLIST_KEY_NSHealth…UsageDescription` values, in the watch target's Debug and Release alike: *"Padel reads your heart rate and calories during a match to record it as a workout."* and *"Padel saves each match to Health as a workout. Without it the watch won't keep the score on screen for the whole game, and padel won't count toward your activity rings."*
- **`padel Watch App/InfoPlist.xcstrings` carries both languages,** keyed by the plist key rather than the sentence — an Info.plist catalog is keyed that way, so the English cannot be its own key here as it is in `Shared/Localizable.xcstrings`. Both entries are `"extractionState" : "manual"` with a comment saying where the value comes from. The `en` string is written out beside the `ru` one even though the build setting already supplies it: it costs nothing, and it keeps the pair readable side by side.
- **The ticket's premise is half wrong: Xcode does extract build settings into this catalog.** The first build after the file appeared added `CFBundleDisplayName` and `CFBundleName` to it, values and all, from `INFOPLIST_KEY_CFBundleDisplayName` and `PRODUCT_NAME`. It left the two Health keys alone because they were already there under `manual` — extraction only adds what is missing, so what the ticket says holds for the keys it is about, and only for them. Neither new key wants a translation: `CFBundleName` is never shown to anyone, and the display name is out of scope by the spec ("`Padel` is a word in both languages"). Deleting them would only invite the next build to add them back, so both are marked `"shouldTranslate" : false` — the catalog's own way of saying *deliberately untranslated*, which also stops Xcode counting them as unfinished work.
- **No project file surgery.** `padel Watch App/` is a `PBXFileSystemSynchronizedRootGroup`, so dropping the catalog in the folder makes it a member of the watch target. `Info.plist` is the folder's one membership exception; the catalog needs none.
- **The iPhone target gains nothing.** `INFOPLIST_KEY_NSHealth` appears in two build configurations, both the watch's.
- **Left to the owner:** delete the app from the watch, install, and answer the sheet in each language. The raw key showing instead of a sentence is what a broken catalog looks like here.
