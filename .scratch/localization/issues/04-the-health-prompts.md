# 04: The Health prompts

**What to build:** The two Health permission descriptions in both languages.

They are the only user-facing strings that live outside Swift: `INFOPLIST_KEY_NSHealthShareUsageDescription` and `INFOPLIST_KEY_NSHealthUpdateUsageDescription`, in the watch target's build settings, in Russian. Xcode does not extract build settings into a String Catalog, so this one is done by hand at both ends.

They are also the first thing a new owner reads — the sheet stands between them and their first match — and they cannot be shared with `Shared/Localizable.xcstrings`: Info.plist localization is per target.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Both `INFOPLIST_KEY_NSHealth…UsageDescription` values are English
- [ ] `padel Watch App/InfoPlist.xcstrings` carries the Russian for both keys
- [ ] The permission sheet was seen in both languages on a fresh install, and neither one shows the raw key
- [ ] The iPhone target gains no Health strings — it asks for nothing from Health

## Notes

The English is American, and is not a translation of the Russian sentence but the same argument made in English: the app reads heart rate and calories to record the match as a workout, and needs to write the workout so the watch keeps the score screen lit for the whole game.
