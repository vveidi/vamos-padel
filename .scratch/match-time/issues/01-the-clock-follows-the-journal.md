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

**Status:** ready-for-agent

- [ ] `SavedMatch.undo(at:)` exists and moves `lastRallyAt` to the moment of the undo
- [ ] Undoing the last remaining rally returns the match to zero duration, so a journal with nothing in it never reports time
- [ ] An undo the engine refuses — an abandoned match, an empty journal — leaves the saved match exactly as it was, both moments included
- [ ] `SavedMatch.abandon()` exists and moves neither moment
- [ ] `SavedMatch.match` is `private(set)`, and nothing outside the type mutates the match
- [ ] The three call sites are converted: `MatchView.swift` undo and abandon, and `MatchFixtures.swift` abandon
- [ ] `CONTEXT.md`'s **Match duration** entry says what a taken-back rally does to the end of a match
- [ ] The five cases below are in `SavedMatchTests`, and the package suite is green

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
