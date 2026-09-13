# 01: The storage seam splits away from GRDB

**What to build:** `PadelStorage` becomes two targets along the line its folders
already draw — `Seam/` and `SQLite/` — so that the watch can name a
`SavedMatch` on the wire without linking a database it no longer has.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Packages/PadelStorage/Package.swift` declares two library products:
      `PadelStorage` (sources `Sources/PadelStorage/Seam`) and
      `PadelStorageSQLite` (sources `Sources/PadelStorage/SQLite`), the second
      depending on the first and on GRDB
- [ ] Not one source file moves; the split is a manifest change and a `path:`
      per target
- [ ] `PadelStorage` builds with no GRDB in its graph — verified by
      `swift build --target PadelStorage` and by the absence of GRDB from its
      dependency list
- [ ] The test target keeps its one name and its folder-for-folder mirror,
      depending on both products
- [ ] The phone app links both products; the watch app links `PadelStorage`
      alone
- [ ] `CLAUDE.md`'s "Where things live in the packages" names the two targets
- [ ] `swift test` is green in the package, and both app targets build

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
