# The store is SQLite through GRDB, not SwiftData

Both platforms (watchOS and iOS) keep matches in SQLite, accessed through GRDB. The obvious choice for a new SwiftUI app would have been SwiftData, so the decision is worth explaining: an SQLite file is the most portable local format there is, and Android reads it natively. When Android comes around (see ADR-0002), what will have to be ported is the code, not the data.

The second reason is migrations: the journal's schema will certainly change once players appear, and GRDB's schema versioning is explicit and checkable by tests.

## Consequences

- GRDB is a dependency through SPM.
- The `PadelScoring` package knows nothing about GRDB or SQLite: the rules engine works on plain Swift types, while the storage adapter lives outside it — in a separate `PadelStorage` package that depends on both GRDB and the engine. The constraint is enforced by the structure of the packages rather than by convention: a guard test fails the build if an external dependency appears in `PadelScoring`'s manifest.
- The adapter was moved into a package rather than into the app targets for two reasons: the round trip through SQLite has to run without a simulator, and both platforms need the store to be identical, so it must not exist in two copies.
