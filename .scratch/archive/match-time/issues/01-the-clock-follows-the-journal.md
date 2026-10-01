# 01: The clock follows the journal

**What to build:** Every mutation of a saved match goes through `SavedMatch`,
and the two moments it carries stay true when the journal shrinks as well as
when it grows.

`undo(at:)` and `abandon()` join the `record(rallyWonBy:at:)` that is already
there, `match` becomes `private(set)`, and the three call sites that reach
through the wrapper today start going around by the front.

A rally taken back ends the match at the undo. That is deliberate and it is not
exact: the moment of the rally now last would be exact, and the journal does not
remember it. See the spec for why rallies are not given dates.

**Blocked by:** None

**Status:** done

- [x] `SavedMatch.undo(at:)` exists and moves `lastRallyAt` to the moment of the undo
- [x] Undoing the last remaining rally returns the match to zero duration, so a journal with nothing in it never reports time
- [x] An undo the engine refuses — an abandoned match, an empty journal — leaves the saved match exactly as it was, both moments included
- [x] `SavedMatch.abandon()` exists and moves neither moment
- [x] `SavedMatch.match` is `private(set)`, and nothing outside the type mutates the match
- [x] The three call sites are converted: `MatchView.swift` undo and abandon, and `MatchFixtures.swift` abandon
- [x] `CONTEXT.md`'s **Match duration** entry says what a taken-back rally does to the end of a match
- [x] The five cases below are in `SavedMatchTests`, and the package suite is green

## The rule

```swift
public mutating func undo(at moment: Date) {
    let journalBefore = match.journal

    match.undo()

    guard match.journal != journalBefore else { return }

    lastRallyAt = match.journal.isEmpty ? startedAt : moment
}
```

The guard covers both no-ops in one stroke: `Match.undo()` does nothing on an
abandoned match, and `RallyJournal.removeLast()` returns `nil` on an empty one.
Neither must move the clock, and neither is worth a separate check.

`startedAt` is deliberately left alone when the journal empties. There is no
first rally to point at, and the next `record` on an empty journal overwrites it
anyway — the value heals itself the moment it means anything again.

## The tests

1. **An undo ends the match at the undo.** A rally at +75 min, an undo at
   +80 min: the duration is 80 minutes, not 75.
2. **Undoing the only rally returns the match to zero duration.** The case the
   ticket exists for.
3. **An undo on an abandoned match moves nothing.** Compare whole values, the
   way `aRejectedRallyDoesNotLengthenTheMatch` already does.
4. **An undo on an empty journal moves nothing.** The other half of the guard.
5. **Stopping a match does not move the clock.** Written down as a test rather
   than left in a comment.

`private(set)` is not tested. It either compiles or it does not.

## Notes

**On the existing suite.** `theDurationSpansTheRallies` stays as it is. It
exercises the growing journal, which this ticket does not touch, and its name is
still true of what it tests.

**On why the moment is passed in rather than taken.** `record` already takes its
moment from the caller instead of reading `.now`, which is what makes the
durations in `SavedMatchTests` and in `MatchFixtures.preview` assertable at all.
`undo(at:)` follows it for the same reason.

**On what is not here.** `Match.record(rallyWonBy:)` still returns `Void`, so
`SavedMatch.record` still copies the journal to learn whether the engine took
the rally. That is ticket 02 and this ticket does not wait for it.

## Comments

**Done.** The rule went in as written, and the seam closed harder than the
ticket's three call sites suggested.

- **`private(set)` costs more than three call sites.** The ticket counts the
  three in the apps, and those are the three that matter. But `private(set)`
  is not lifted by `@testable`, so ten more in `MatchStoreTests`,
  `MatchDeliveryTests`, `MatchReceptionTests` and `MatchPayloadTests` stopped
  compiling as well. All ten are mechanical — `saved.match.abandon()` becomes
  `saved.abandon()`, `saved.match.undo()` becomes `saved.undo(at:)` — and went
  through two `ast-grep` rules rather than by hand. The undos there are all
  followed by a replay to a later moment, so none of them asserts on a
  duration the new clock would change.
- **Driven on the watch, and read back out of the database.** A match played
  to three rallies, undone to two, to one, to none: the row came back with
  `startedAt == lastRallyAt` and no rallies — the zero-duration case the
  ticket exists for. A fourth undo on the empty journal changed nothing. Two
  fresh rallies, then stopping 38 seconds after the second: `lastRallyAt`
  stayed on the rally, not on the stop. And a set played out 6:0 and then
  undone from the outcome screen moved `lastRallyAt` 23 seconds forward, onto
  the undo, bringing the match back into play at 40, 5 games.
- **The doc comments above the field had to move with it.** `lastRallyAt` said
  "the moment of the last rally" and `duration` said the end of the match "is
  the last rally" — both false the moment an undo can write into that field.
  They now say "the last play", and `lastRallyAt` names the undo as the other
  thing it can hold. `CONTEXT.md` was already in the ticket; these two were
  the same sentence in a third place.

**Left for the owner.** Two judgment calls the review raised and this ticket
did not settle:

- **`lastRallyAt` is now a slightly wrong name** — after an undo it holds no
  rally's moment. Renaming it reaches the column in `match`, the payload and
  the store, so it is not a rename to slip into this ticket.
- **`record` and `undo(at:)` are the same four lines twice** — snapshot the
  journal, mutate, compare, move the clock. Ticket 02 changes `record`'s half
  of that shape, so any extraction is better judged after it.

**Found while driving, not fixed here.** `SQLiteMatchStore.save` treats
`startedAt` as immutable on update — "set on the first rally and immutable
after that". That is no longer true of a match whose journal is emptied and
then played again: `SavedMatch` moves `startedAt` to the new first rally, the
row keeps the old one, and the stored match reports a start earlier than its
first rally. The divergence predates this ticket and is not in its criteria.
