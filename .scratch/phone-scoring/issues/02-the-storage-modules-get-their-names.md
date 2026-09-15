# 02: The storage modules get their names

**What to build:** the rename ticket 01 earned and did not do. The boundary
between the protocols and the database is called an **interface**, the
implementation is called a **database**, and the word SQLite appears nowhere an
app can see it.

**Blocked by:** None

**Status:** done

- [x] `Sources/PadelStorage/Seam/` is `Sources/PadelStorage/Interface/`, and
      `Sources/PadelStorage/SQLite/` is `Sources/PadelStorage/Database/`; the
      test target's two folders mirror them
- [x] `SQLiteMatchStore` is `DatabaseMatchStore`, in a file of that name, and
      ~~it is the only shipping file in the repo that imports GRDB~~ it is one
      of the two, both inside `Database/` — see the closing note
- [x] The product and target `PadelStorageSQLite` is `PadelStorageDatabase`;
      `PadelStorage` keeps its name and is still the one with no database in its
      graph
- [x] Both `path:` lines in `PadelStorage/Package.swift` follow the folders, and
      the comment above them says what the targets are rather than arguing for
      them
- [x] Both app targets and both test targets name the new product; the Xcode
      project's frameworks phases are updated on both sides
- [x] `CLAUDE.md`'s "Where things live in the packages" map reads `Interface/`
      and `Database/`, and the paragraph about the two targets uses the new
      names throughout
- [x] `ADR-0002` is `0002-local-only-storage-behind-an-interface.md`, with its
      title and body saying interface; nothing links an ADR by filename, only by
      number, so no other file changes for this
- [x] `ADR-0006`'s two architectural uses of "seam" say interface
- [x] `PadelDelivery`'s `Package.swift` comment, `MatchTransport.swift` and
      `WatchConnectivityTransport.swift` say interface where they say seam
- [x] `swift test` is green in every package, both app targets build, and
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

## Comments

**Done.** The rename went in as written: four folders moved, one type and one
product renamed, and the word interface replaced seam everywhere the ticket
named it. The trap held no surprises — the two frameworks phases and the two
`XCSwiftPackageProductDependency` entries in `project.pbxproj` were the only
project edits needed, and both apps build, launch and run on a simulator after
them.

- **Criterion two is amended rather than ticked on reasoning.** `Database/`
  holds two shipping files that import GRDB, not one: `DatabaseMatchStore.swift`
  and `MatchDatabase.swift`, the schema and its migrator. That was already true
  when ticket 01 drew the folder, and folding the migrator into the store to
  make the sentence literal would be a restructuring this ticket did not ask
  for — the two files are the store and the schema, and they are separate for a
  reason that has nothing to do with naming. What the criterion was guarding
  holds: both files sit inside `Database/`, and nothing outside that folder
  imports GRDB except `MigrationTests`, which opens a database before the store
  does and is named in `Package.swift` for it.

- **One architectural "seam" the criteria did not name was rewritten anyway.**
  `MatchStore.swift` called itself "precisely the seam that is later swapped for
  CloudKit", and it is the very boundary the ticket renames; leaving it would
  have defeated the change in the one file that defines it. Its "a protocol
  rather than SQLite outright" became "rather than a database outright" for the
  same reason — `Interface/` is what an app sees.

- **A dangling citation went with it.** `MatchStoreTests.swift` opened a test
  with "what the spec demands of Seam 2", quoting a spec section that no longer
  exists anywhere — a closed feature's folder is emptied. Both review axes
  flagged it. The quotation is now the sentence itself, with no pointer.

- **Left for the owner to arbitrate.** ADR-0002's body gained "— a protocol
  each" alongside the word interface, because the paragraph had no "seam" to
  swap and needed somewhere to put the word. And the new comment above the two
  `path:` lines names what each target holds, which the ticket asked for but
  which restates the `dependencies:` array below it; the reviewer called it
  taste, and it is left as written.
