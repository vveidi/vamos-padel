# 01: The decision, written down

**What to build:** No code. The glossary currently forbids exactly what the other four tickets do — *"Do not translate the strings: Russian is the language of the app"* — and until that is retracted in writing, every one of them reads as a violation of a documented decision.

This ticket retracts it and records what replaces it: two languages, English as the source language and the key, Russian as a translation in a String Catalog.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] `docs/adr/0005-two-languages-with-english-as-the-source.md` records the decision, the alternatives that were weighed, and the consequences
- [x] The `Written language` section of `CONTEXT.md` no longer forbids translation and says where a sentence is written and in what language
- [x] The glossary gains no new term: language, catalogs and locales are layers of implementation, and `CONTEXT.md` is a glossary of padel
- [x] The English is American everywhere, prose included: the repo's own British spellings are converted, so that a doc comment is never a bad example for the string written under it

## Comments

**Done.** Both files are written.

- **ADR-0005** carries the decision, the two rejected alternatives (Russian literals as keys, symbolic keys) and seven consequences — among them the ones the later tickets act on: the plural forms belong to the catalog, the pinned `ru_RU` goes, the engine packages stay mute, and the escape hatch for one English sentence with two meanings is `String(localized:)` with an explicit `key:` and `defaultValue:`.
- **`CONTEXT.md`** now says that the app's strings stand in the source in English, that the English sentence is at once the key, and that the two languages are equal on screen and unequal in the source.
- **American English, repo-wide.** The strings are American, and the prose around them was British — `colour`, `behaviour`, `recognises`, `grey`, `centre`, `localisation`. A split was considered and rejected: the prose sits directly above the strings, and a comment reading "our side's colour" is what the next string gets written from. 60 lines across 34 files, all of it comments, ticket bodies and documents — plus one test *name* (`"Imports are recognized…"`) and the `grey` variable in `.scratch/status.sh`, renamed with its four uses. No identifier and no API name was touched: `cancellable` in `SQLiteMatchStore` is named after `AnyDatabaseCancellable` and stays. The 154 package tests are green and `status.sh` still runs. The feature directory moved to `.scratch/localization/` in the same breath.
- **No new term.** The candidate was "wording" — the layer where the domain becomes sentences. It was left out: it names a place in the code, not a thing on a padel court, and the glossary is for the latter.
