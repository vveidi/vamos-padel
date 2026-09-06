# 02: The engine says whether it took the rally

**What to build:** `Match.record(rallyWonBy:)` reports whether the rally was
accepted, and the callers that need to know stop working it out for themselves.

The engine already computes the answer — `guard !state.outcome.isOver` — and
then throws it away. `SavedMatch.record(rallyWonBy:at:)` needs it, so it copies
the whole rally journal, calls through, and compares the two to recover a
boolean the engine had in its hand:

```swift
let journalBefore = match.journal

match.record(rallyWonBy: side)

guard match.journal != journalBefore else { return }
```

That is a copy of every rally played, on every rally played, to learn one bit.

`RallyJournal.removeLast()` is already `@discardableResult` and already returns
what it removed. This is the same convention, one level up.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Match.record(rallyWonBy:)` is `@discardableResult` and reports whether the rally was recorded
- [ ] `SavedMatch.record(rallyWonBy:at:)` reads that result instead of diffing journals, and copies nothing
- [ ] Callers that ignore the result keep compiling without a warning
- [ ] The scoring and storage suites are green, unchanged in what they assert

## Notes

**On the shape of the result.** `Bool` is the small answer and probably the
right one: the caller wants to know whether anything happened, not what. Worth
a moment's thought against returning the appended `Rally?`, which would mirror
`removeLast()` exactly — but a `Rally` the caller already built is a strange
thing to hand back, and nobody has a use for it.

**On `SavedMatch.undo(at:)`.** Ticket 01 gives it the same journal-diff guard,
for the same reason: `Match.undo()` also returns `Void`. If this ticket is built
after it, the same simplification applies there and both guards go at once.
`Match.undo()` would report whether it removed anything — which
`RallyJournal.removeLast()` already tells it.

**On scope.** This is a signature on the engine, so it lands in `PadelScoring`
and its tests do. It changes no behavior: every existing assertion in the
scoring suite must still read exactly as it does now, and that is the check
that the change is what it claims to be.
