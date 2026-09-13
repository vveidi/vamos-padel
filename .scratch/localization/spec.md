# Two languages: Russian and English (v1)

Status: ready-for-agent

## Problem Statement

The app speaks Russian and nothing else, and every sentence it says is a Russian
literal sitting in a SwiftUI view. That was a decision, not an oversight — the
glossary said so in as many words — and it held for as long as the app was going
to no store.

It is going to one now, and a Russian-only app is invisible to everyone outside
a single market. There is a second cost already paid before the store: a phone
set to English shows Russian screens with `1 hr, 35 min` in the middle of a
Russian row, because `MatchWording` pins `ru_RU` to keep the two from mixing.
The pin is a workaround for having no second language.

## Solution

The app speaks Russian and English, and the reader's phone chooses. English is
the source language: the literal in the code is the English sentence and the key
its Russian translation is found by (ADR-0005). One String Catalog,
`Shared/Localizable.xcstrings`, is a member of both targets; the watch's Health
prompts get a catalog of their own, because Info.plist localization cannot be
shared.

Along the way three things that were bent around the single language get
straightened: the hand-written Russian plural table gives way to the catalog's
plural variations, the pinned `ru_RU` disappears, and eight strings that are
built by gluing words together get rewritten as whole clauses.

## Implementation Decisions

### The catalog

`Shared/Localizable.xcstrings`, member of `Padel` and `Padel Watch App` both.
Neither target owns it, so it lives in neither target's folder. `knownRegions`
gains `ru`; `developmentRegion` is already `en`.

The folder is new and will invite company — `ourSideColor` is defined twice
today under a comment that says "two targets with no shared home for a color".
That is not this work. Nothing but the catalog goes in `Shared/` here.

### English is written, not translated

The strings are read by someone for whom English is the only language, so they
are written as an English app's strings: `"Can't load your history"`, not
`"The history is unreadable"`. The register is the one the screens already have
in Russian — short, plain, no exclamation marks — not the register of this
repo's prose.

The English is **American**, in spelling and in usage — and so is the prose
around it, which used to be British and was converted with the decision
(ticket 01). Little of the app's own vocabulary can go either way, the padel
words being the same on both sides of the Atlantic, but one is on a screen
already: a **tiebreak** is one word, the way the USTA spells it, not "tie-break"
the way Wimbledon does. The source language stays `en` rather than `en-US`
(ADR-0005).

### The smallest translatable unit is a clause

A key may be interpolated into another string only when the outer string is a
mechanical separator (`", "`, `" · "`, `": "`) and every piece reads on its own.
A bare noun is never dropped into a sentence frame — the frame becomes two keys
instead. `"…, выиграли \(winner == .us ? "мы" : "соперники")"` is the case that
makes the rule: English puts the word before the verb, and the frame does not
survive the move.

Eight places compose strings today. They are fixed inside the tickets that
rewrite their files, not in a ticket of their own, because those files are being
rewritten anyway.

### Plurals

Russian has four categories and English two. The catalog carries both sets per
key, which also absorbs the case the hand-written table needed a second function
for: after "до" the noun takes the genitive and stops agreeing with the numeral
the ordinary way — "до 21 очка", but "до 22 очков". In a catalog that is not a
rule, it is what the key says for that category.

`Ruleset.plural`, `Ruleset.points`, `Ruleset.sets`, `Ruleset.rallies` and
`StartView.sets` all go.

### Dates and durations

`MatchWording` stops pinning `Locale(identifier: "ru_RU")`. With two
localizations `Locale.current` resolves to the app's language and the reader's
own region, which is what the pin was faking: a Russian speaker in Spain gets
Russian words and the local order of the day and the month.

### The packages stay mute

`PadelScoring`, `PadelStorage` and `PadelDelivery` contain no user-facing string
today and gain none. No `Bundle.module`, no catalog in a package. `"40"` and
`"AD"` stay as they are in both languages — padel's notation, not English.

### The language is the system's to choose

Two declared localizations give a per-app language switch in Settings for free.
No picker of our own, on either device. The watch takes its language from the
paired phone.

## Testing Decisions

The project has no test target at all today: tests live only in the SPM
packages, and the wording layer is covered by nothing. Once the plural forms
move into the catalog there is no logic left to test — there is *data*, and data
rots quietly. Nobody notices "до 22 очка" until they see it on a screen.

So: one test target on the phone, resolving every plural-bearing key across
every number the rules screen actually offers, in both languages. Because the
catalog is shared, that target reaches the watch's keys too — a consequence of
one catalog rather than two, and the reason the watch needs no target of its
own.

### What the tests do not cover

- **Layout.** English and Russian differ in length and the watch has no room to
  spare — `StartView` already leans on `lineLimit(1)` and
  `minimumScaleFactor(0.7)` in Russian alone. This is checked by eye, on the
  smallest watch and at the largest Dynamic Type, and it is an acceptance
  criterion of the watch's ticket.
- **The Health permission sheet**, which needs a fresh install.
- **Whether the English reads well.** No test has an opinion about copy.

## Out of Scope

- **The App Store listing** — name, subtitle, description, screenshots. It lives
  outside the repo and needs screenshots that do not exist yet. A release task
  of its own.
- **A third language.** The decision is built for two; a third would mostly work
  and would want a second look at the composed strings, where clause order is
  assumed to be shared between Russian and English.
- **An in-app language picker.** The system's is free and sufficient.
- **A shared home for anything but the catalog**, the duplicated color included.
- **The app's display name.** `Padel` is a word in both languages.

## Further Notes

`InfoPlist.xcstrings` is the one piece with no automation behind it: the two
Health usage descriptions live in build settings as `INFOPLIST_KEY_…`, and Xcode
does not extract those into a catalog. The English goes into the build settings
by hand and the Russian into the catalog by hand, and a fresh install is the
only way to see whether it worked.

The order is set by one dependency: the catalog has to exist before the watch
can put strings in it. Everything else is parallel.
