# 07: The match store

**What to build:** The match stops living only in memory. The **rally journal** is written to the device after every rally, together with the **ruleset**, the moment of the start and the duration. If the app was unloaded or the watch restarted in the middle of a match, at the next launch the player carries on from the same place instead of starting over.

The ruleset is stored together with the journal: without it the journal cannot be interpreted, and the rules will change over time.

The store is SQLite through GRDB, with the schema versioned by migrations from its first version (ADR-0003). Access is hidden behind a protocol, so that the engine and the screens know nothing about the database.

**Blocked by:** 02

**Status:** done

- [x] The journal is written after every rally, not at the end of the match
- [x] A saved match reads back with the same journal and the same ruleset
- [x] An unfinished match is restored at the next launch of the app
- [x] The schema is versioned by migrations from its first version
- [x] The rules engine knows nothing about GRDB and SQLite
- [x] The tests run the round trip through an in-memory SQLite database, without the file system
- [x] A test checks that the migrations apply to a database of the previous version

## Comments

### What was built

The match stopped living only in memory. After every rally it lies in SQLite in full, and an
app unloaded in the middle of a set brings the player back to the same place at the next
launch rather than to 0:0.

**The store is a separate `PadelStorage` package.** This is a departure from the letter of
ADR-0003, where the storage adapter "lives in the app"; the ADR was amended. There are two
reasons. The first is the tests: the spec demands running the round trip through SQLite
without a simulator, and the app targets have no test target at all — creating one would mean
booting a simulator for a check that costs three milliseconds. The second is that both
platforms need the store to be identical (tickets 10–12), and there must not be two copies of
the adapter. The substance of ADR-0003 is intact meanwhile: `PadelScoring` still knows nothing
about GRDB or SQLite, and the same guard watches over it — an external dependency in its
manifest fails a test. It is also what pointed to the decision: folding the store in as a
second target of `PadelScoring` would not have worked without breaking it.

**A rally is a row in a table, not an element of an array in a column of the match.** The
journal is the single stored truth about a match (ADR-0001); storing it so that only our code
can read it would give away half of what SQLite was chosen for. For the same reason the
ruleset is spread across columns rather than folded into JSON, and for the same reason the
check "each case owns its half of the columns" is written into the schema and not only into
the code: code that is not ours will read this file too.

**Being unfinished is not stored in a column but computed by the engine.** The store asks for
the last match and hands it back only if the outcome is `.inProgress`. A "the match is still
running" column would be state beside the journal — exactly the kind that one day diverges
from it (ADR-0001). The last match is asked for specifically, not the first unfinished one
that turns up: if the last one was played out there is nothing to continue, and one dropped at
3:2 a month ago must not rise from the dead in the middle of a court.

**The duration is two moments, not a number.** The match's row holds the start and the time of
the last rally, and the duration is computed from them. A number somebody has to keep up to
date will one day be forgotten — that is exactly the argument by which the score is not
stored. The end of the match here is the last rally, not "now": a match cut short by a dead
battery lasted until its last point, not until the moment it was opened again. The start is
the first rally, not the app launching: between "opened it on court" and "served" there is a
warm-up. **Match duration** was added to the glossary.

**A write means cutting off what was undone and appending what is missing.** The journal
changes only at the tail: a rally is appended to the end, and an undo removes the last one
(ADR-0001). So the next point costs one insert rather than a rewrite of the whole journal, and
an undone rally disappears from the database rather than lying past the end of the journal
until the next point.

**Three lines were added to the screen.** `MatchView` saves the match after `record` and after
`undo`, and asks once when it appears whether there is anything to continue. A write failure
never reaches the match — for the same reason a workout failure does not: on court the score
matters more than everything it is being written down for. A database that did not open yields
a `NoMatchStore` and a line in the log; a match without a record is worse than a match with
one, but better than an app that did not launch.

### Decisions departing from the ticket

- **The schema has only one version so far, and a "previous" one does not exist in the strict
  sense.** The migration test is written honestly: the database is brought up to its earliest
  version, filled through bare SQL — that is how that version of the app would have written
  it, and not today's store — and only then opened by today's code. The check rests on the
  reading not depending on today's writing; once v2 appears the test will start doing exactly
  what its name promises without a line changing. Inventing a fictitious v2 for a pretty tick
  was not done. Today's matches are protected by the second test — the list of versions is
  spelled out literally, and a renamed or rewritten migration fails the build.
- **The match identifier is a UUID created by the app.** The ticket says nothing about it, but
  without one the store cannot tell "the same match" from "a new one", and the phone will not
  tell apart one delivered twice (ticket 10). It is stored as text rather than a blob: the
  file's portability is half of ADR-0003's argument.
- **An empty match does not reach the database.** A write happens because of a rally, so
  launching the app without a single point following leaves no row. Otherwise the database
  would collect a match for every opening on court.
- **`PadelStorage` is linked into the phone target too**, even though it will start being used
  there in ticket 11. That way the iPhone build checks that the store compiles under iOS
  today, not three tickets from now.
- **The write is synchronous, on the thread it was called from.** One rally is one short
  transaction; waiting for it costs the screen less than working out in which order two
  consecutive taps reached the database.

### What the agent checked

- 18 `PadelStorage` tests green, all through in-memory SQLite, without the file system: the
  round trip across four rulesets, the first server, the start and the duration, the write
  after every rally, undo (including down to an empty journal), a finished match not being
  offered for continuation, the latest match being continued, a new match not overwriting the
  previous one, reopening the database.
- 68 `PadelScoring` tests still green — the isolation guard among them: the engine knows
  nothing about GRDB or SQLite.
- Both targets build.
- On a 46 mm simulator the app creates `Library/Application Support/matches.sqlite` on first
  launch; the database holds both tables, the ruleset check and `grdb_migrations = v1`.
- **Restoration checked for real.** A match left at 30:0 with games at 2:1 was put into the
  simulator's database; after a relaunch the app showed exactly that score, with the serve on
  the opponents' side. The converse was checked separately: with a finished match in the
  database the app opens a new 0:0 rather than resurrecting the one played out.

### What is left to check by hand

The writing half is checked by tests through real SQLite, but not through real taps: synthetic
taps do not reach the app (the same wall as in tickets 04, 05 and 08). What stays unchecked is
the three lines of glue in `MatchView` and everything the simulator does not reproduce:

1. Play a few rallies, remove the app from memory, open it again — the score carries on from
   the same place.
2. The same after restarting the watch.
3. Undo a point, remove the app from memory, open it again — the undone rally has not come
   back.
4. **On a device:** an hour and a half of match — a tap awards a point without a delay, and
   the write per rally is not noticeable.
