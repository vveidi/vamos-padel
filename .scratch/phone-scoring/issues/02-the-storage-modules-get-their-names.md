# 02: The storage modules get their names

**What to build:** the rename ticket 01 earned and did not do. The boundary
between the protocols and the database is called an **interface**, the
implementation is called a **database**, and the word SQLite appears nowhere an
app can see it.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Sources/PadelStorage/Seam/` is `Sources/PadelStorage/Interface/`, and
      `Sources/PadelStorage/SQLite/` is `Sources/PadelStorage/Database/`; the
      test target's two folders mirror them
- [ ] `SQLiteMatchStore` is `DatabaseMatchStore`, in a file of that name, and it
      is the only shipping file in the repo that imports GRDB
- [ ] The product and target `PadelStorageSQLite` is `PadelStorageDatabase`;
      `PadelStorage` keeps its name and is still the one with no database in its
      graph
- [ ] Both `path:` lines in `PadelStorage/Package.swift` follow the folders, and
      the comment above them says what the targets are rather than arguing for
      them
- [ ] Both app targets and both test targets name the new product; the Xcode
      project's frameworks phases are updated on both sides
- [ ] `CLAUDE.md`'s "Where things live in the packages" map reads `Interface/`
      and `Database/`, and the paragraph about the two targets uses the new
      names throughout
- [ ] `ADR-0002` is `0002-local-only-storage-behind-an-interface.md`, with its
      title and body saying interface; nothing links an ADR by filename, only by
      number, so no other file changes for this
- [ ] `ADR-0006`'s two architectural uses of "seam" say interface
- [ ] `PadelDelivery`'s `Package.swift` comment, `MatchTransport.swift` and
      `WatchConnectivityTransport.swift` say interface where they say seam
- [ ] `swift test` is green in every package, both app targets build, and
      `PadelTests` still passes

## What is deliberately left alone

**`PadelDesign`'s seams are the ball's**, and the net's — the white arcs on the
felt and the `seam` palette token. A different word that happens to be spelled
the same. Nothing in `PadelDesign` changes.

**`ADR-0011`'s "a seam of its own: `courtSurface`, `courtLine`…"** means a point
of variation where a theme could later be threaded, not an interface. Rewriting
it to say interface would make the sentence less true.

**`ADR-0003` keeps its title**, "SQLite via GRDB, not SwiftData". That is the
decision to use SQLite, and the decision record is exactly where the technology
should be named.

**Ticket 01 keeps its title and its filename.** It is closed, and it records
work done under the word that was current at the time.

## Notes

**The imports at the composition roots stay, and stay visible.**
`PadelApp.swift` and `PadelWatchApp.swift` each import the implementation and
name it once. Hiding that behind a factory or an `@_exported import` was
considered and refused: the file whose whole job is to decide which provider is
built should say so out loud. Everywhere else in the repo already speaks
`any MatchStore` and imports `PadelStorage`.

**Why "Database" and not "Local".** ADR-0002 uses "local" for the whole
arrangement — storage is local only, no cloud — so naming one implementation
`Local` would use the word that describes all of them. `Database` says what
distinguishes this one without saying which database, and a second provider
pairs with it: `PadelStorageCloud`, `CloudMatchStore`.

**This is a mechanical change with one trap.** The Xcode project references the
package *products* by name in both targets' frameworks phases, and both app
targets are `PBXFileSystemSynchronizedRootGroup`s that will not notice a
renamed product on their own. Build both apps, not just the packages.
