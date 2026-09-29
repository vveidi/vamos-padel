# The schema is edited in v1 until the first release

The match database is versioned by migrations from its very first version, and that is not provision for the future: the rally journal will certainly change once players appear (ADR-0003).

There is exactly one version so far, `v1`, and no new one appears before the first release. The app has not a single user, so a column is added by editing `v1` rather than by appending a second migration to a database nobody has. On the developer's own device a second `v1` is a matter of deleting the app.

The rule inverts the day the app reaches somebody else. From that moment a released migration is untouchable and a new version is appended after it: a rewritten migration is applied afresh to a database where it has already run, and that crashes the opening. The database on the watch exists in a single copy and, until the transfer to the phone, is the only copy of the match (ADR-0002) — rewriting the migration history then means losing what it holds.

## Consequences

- **"Add a column" means editing `v1`, not appending beside it** — for now, and the tests say so out loud. `MigrationTests` asserts the list of versions literally, so a second one cannot appear out of habit, and the assertion carries the rule in its failure message.
- **The first release is what flips it.** Nothing in the code can detect that moment, so the inversion is a decision taken here and applied by hand: from the first upload onwards, this ADR is what says the migrations are frozen.
- **`eraseDatabaseOnSchemaChange` stays `false`**, and `MatchDatabase` says why at the line that sets it.
