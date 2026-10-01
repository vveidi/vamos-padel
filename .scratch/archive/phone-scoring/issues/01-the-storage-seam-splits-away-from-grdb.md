# 01: The storage seam splits away from GRDB

**What to build:** `PadelStorage` becomes two targets along the line its folders
already draw — `Seam/` and `SQLite/` — so that the watch can name a
`SavedMatch` on the wire without linking a database it no longer has.

**Blocked by:** None

**Status:** done

- [x] `Packages/PadelStorage/Package.swift` declares two library products:
      `PadelStorage` (sources `Sources/PadelStorage/Seam`) and
      `PadelStorageSQLite` (sources `Sources/PadelStorage/SQLite`), the second
      depending on the first and on GRDB
- [x] Not one source file moves; the split is a manifest change and a `path:`
      per target
- [x] `PadelStorage` builds with no GRDB in its graph — verified by
      `swift build --target PadelStorage` and by the absence of GRDB from its
      dependency list
- [x] The test target keeps its one name and its folder-for-folder mirror,
      depending on both products
- [x] ~~The phone app links both products; the watch app links `PadelStorage`
      alone~~ Both apps link both products. The watch drops to the seam in
      ticket 10, which owns the line — see the closing note
- [x] `CLAUDE.md`'s "Where things live in the packages" names the two targets
- [x] `swift test` is green in the package, and both app targets build

## Why now and not later

Ticket 02 puts `SavedMatch` on the wire in both directions, and ticket 09 leaves
the watch with no store at all. Between them the watch would be linking SQLite
to render a score. Doing it first also keeps 09 from carrying a package
refactor inside a screen ticket.

## Notes

**`NoMatchStore` goes with the seam.** It is the stand-in a preview and a failed
database both fall back to, and it knows nothing about SQLite.

**The products, not the targets, are what the Xcode project names.** Both app
targets reference the package products in their frameworks phase; the watch's
entry changes from the umbrella to the seam.

## Comments

**Done.** The manifest split went in as written and no source file moved. One
criterion could not be met as written, and one package outside `PadelStorage`
had to be told about the change.

- **The watch cannot link the seam alone yet, and criterion five is amended
  rather than ticked on reasoning.** As written it contradicts the last
  criterion, "both app targets build": `PadelWatchApp.swift` opens
  `SQLiteMatchStore.inApplicationSupport()`, `RootView` asks that store what is
  in progress, `MatchView` writes to it, and `MatchDelivery` drains it as a
  queue. Cutting it here would be a silent behaviour regression — a watch that
  plays a match and records nothing — several tickets before anything replaces
  it. Ticket 10 already owns the exact line ("the watch links no store and no
  GRDB"), so the watch links both products for now, with a `TODO:` at the call
  site pointing there. What ticket 01 actually bought is the *ability* to link
  the seam alone: `swift package describe` reports target `PadelStorage` at
  `Sources/PadelStorage/Seam` with `PadelScoring` and nothing else, and
  `swift build --target PadelStorage` compiles three files with no GRDB step.

- **`PadelDelivery`'s tests needed the second product.** Its sources only ever
  named the seam, but `MatchDeliveryTests` and `MatchReceptionTests` build a
  real `SQLiteMatchStore` twenty-odd times, so the test target gained
  `PadelStorageSQLite`. The shipping target still depends on the seam alone,
  which is the half that matters: GRDB has left `PadelDelivery`'s product
  graph.

- **Four import lines, and they are the whole source diff.**
  `SQLiteMatchStore.swift` now imports `PadelStorage` because the seam is a
  different module to it; the two app entry points and the four test files that
  name `SQLiteMatchStore` import `PadelStorageSQLite`. Nothing else in either
  app names a SQLite symbol — one file on the watch, one on the phone.

- **No guard test was added, and none is needed.** `PadelScoring` and
  `PadelDesign` carry `PackageIsolationTests` because SwiftUI compiles
  everywhere and the compiler would never object. Here the compiler is the
  guard: an `import GRDB` in `Seam/` fails to build, because the target has no
  GRDB dependency to satisfy it.

- **Driven, not just built.** Both apps were installed and launched on
  simulators. The watch drew its start screen and the phone its empty history —
  both of which are answers from the store, so the database opened on each
  side; nothing reached the `storage` logger.

- **From the review.** Two standards findings were confirmed and fixed before
  the commit: `CLAUDE.md` claimed the watch does not link GRDB, which the same
  diff contradicted, and the manifest comment argued the design instead of
  saying what the code does. A third — that the `AA`-prefixed runs in the
  pbxproj should stay sorted — was already fixed. The spec review found no
  defect and agreed with the reading of criterion five above.

- **The watch's half of the payoff is deferred, not lost.** This ticket was
  written when the watch was about to lose its database. The feature was since
  cut so that each device scores a match of its own, and the watch keeps its
  store. What the split still buys today is `PadelDelivery`'s product graph,
  which has no GRDB in it; the watch drops to the interface in
  `paired-scoring` 06.

- **The word "seam" in the title is the word that was current when this closed.**
  Ticket 02 renames the folders, the targets and the type to interface and
  database. A closed ticket is left standing as the record of what was done.
