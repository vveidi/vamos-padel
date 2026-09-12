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

**Status:** done

- [x] `Match.record(rallyWonBy:)` is `@discardableResult` and reports whether the rally was recorded
- [x] `SavedMatch.record(rallyWonBy:at:)` reads that result instead of diffing journals, and copies nothing
- [x] Callers that ignore the result keep compiling without a warning
- [x] The scoring and storage suites are green, unchanged in what they assert

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

## Comments

**Done.** `Bool` it is, on both methods: the notes' argument against handing
back a `Rally` the caller already built holds, and `undo()` returning the
removed rally would have made the two signatures disagree for no gain.

- **Both guards went at once**, as the notes said they should now that ticket
  01 is in. `Match.undo()` reports `journal.removeLast() != nil`, and
  `SavedMatch.undo(at:)` is two lines: `guard match.undo() else { return }`
  and the moment.
- **`record`'s "was this the first rally" is now a `Bool`, not a journal.**
  The old code reused `journalBefore` for two jobs — was anything appended,
  and was the journal empty before. The first is the engine's answer now; the
  second is `match.journal.isEmpty` read before the call, which copies
  nothing.
- **Ticket 01's "same four lines twice" is gone with it.** The two methods no
  longer share a shape to extract: `record` is a guard plus two writes, `undo`
  a guard plus one.
- **Two tests added, none changed.** `Match` gains "Recording reports whether
  the rally was taken" and "Undoing the last point" gains "Undo reports
  whether it took a rally back" — the new contract on both refusal reasons,
  the match already over and the match abandoned. Every existing assertion in
  the scoring and storage suites reads exactly as it did; all three package
  suites and both app targets build clean, with no warning at the call sites
  that discard the result.
- **A mutating call cannot live inside `#expect`.** `#expect(match.undo())`
  fails to compile — the macro captures its operand immutably — so both tests
  bind each result to a `let` first and assert afterwards. Worth knowing
  before writing the next one of these.

**Driven on the watch.** Series 11 (46mm), Russian: a rally recorded, the
6:0 that ends the match, and undo from the outcome screen bringing it back to
40, 5 games — then a new match from zero, three rallies in. The clock page
itself I could not reach: the match screen exposes no swipe target to the
simulator's automation, so the clock's behavior rests on the storage suite,
whose assertions are unchanged and cover every branch of both methods.

**Left for the owner.** One judgment call from the review: "Recording reports
whether the rally was taken" sets up two matches in one test — one finished by
score, one abandoned — where two `@Test`s would name the failure more
precisely. It follows `finishedMatchRecordsNothing`'s existing style in that
file, so it was left as written.
