# The clock a match is measured by (v1)

Status: ready-for-agent

## Problem Statement

A saved match carries two moments, `startedAt` and `lastRallyAt`, and its
duration is the distance between them. `SavedMatch.record(rallyWonBy:at:)`
keeps both true as the journal grows. Nothing keeps them true when it shrinks.

The watch takes a rally back by reaching straight through the wrapper —
`saved.match.undo()` — and the moment of the withdrawn rally stays behind as
`lastRallyAt`. The match is then measured to a rally that was taken back, and
the glossary is explicit that its duration runs "from the first rally to the
last". Stopping is the same story: `saved.match.abandon()` goes around the
wrapper too, though in its case there is nothing to keep in step.

The field is not only shown. It orders the delivery queue, it is the key by
which the store finds the match to resume on relaunch, and it crosses to the
phone in the payload. A wrong value there is not a cosmetic wrong value.

In the ordinary case the lie is small — an undo lands seconds after the rally
it withdraws, and a duration is read at minute granularity. In one case it is
not small: undo the only rally of a match and the journal is empty while both
moments survive, so a match with no rallies reports a duration, which is the
one thing the initializer promises it will never do.

## Solution

Every mutation of a saved match goes through `SavedMatch`, and `match` becomes
`private(set)` so that nothing else can. The wrapper gains `undo(at:)` and
`abandon()` beside the `record(rallyWonBy:at:)` it already has, and the rule
about the clock is stated once, in the type that owns it.

A taken-back rally ends the match at the undo rather than at the rally it
withdrew. That is not the exact answer — the exact answer is the moment of the
rally now last, and the journal does not remember it. Rallies carry no time and
must not start to: a match in the engine is a ruleset and a journal, nothing
more (ADR-0001), and time lives outside it precisely so that the engine stays
what it is.

## Implementation Decisions

### The clock moves on undo, not backward

Three ways were weighed:

- **Leave the moment alone.** Today's behavior; the defect.
- **Move it to the undo.** One line, nothing new stored, and wrong by the
  seconds between the rally and the undo.
- **Remember each rally's moment.** Exact, and it doubles what is stored for
  every match: rallies persist as a list of winner strings, in the database and
  in the payload alike, and both would have to carry dates.

The second is chosen. The third is the honest answer to a question nobody is
asking yet: no screen shows a duration to finer than a minute, so the
exactness buys nothing a reader can see. It becomes worth revisiting when
extended match statistics arrive and want to know when a rally happened —
break points, streaks, the pace of a set. At that point the moments belong
beside the journal in `SavedMatch`, not inside it.

### Stopping does not touch the clock

`abandon()` appends no rally, so it moves neither moment. A match cut short
lasted until its last point, not until the moment it was stopped — the same
rule that keeps a dead battery from lengthening a match. `abandon()` moves onto
`SavedMatch` because sealing the seam requires it, not because it has time to
keep.

### The wrapper is the only way in

`match` becomes `private(set)`. Without that the wrapper is a convention, and
the next mutation added to a view reintroduces exactly this defect with nothing
failing to compile. Three call sites reach through today and all three are
served by the new methods.

## Testing Decisions

The rule lives in `PadelStorage` and is tested there, through `SavedMatch`'s own
interface, where `SavedMatchTests` already covers the growing journal. Both
no-op branches get a test of their own: an undo that the engine refuses must
leave the match byte-for-byte as it was, and those are the branches that rot
first when someone later simplifies the guard away.

`private(set)` gets no test. The compiler is the assertion.

## Out of Scope

- **Per-rally moments.** Deferred, with the reasoning above.
- **A test target for the watch and phone apps.** The call sites change
  mechanically; the rule itself is tested where it lives. The missing target is
  its own problem, already written down as localization ticket 05.
- **The engine reporting a refused rally.** Split out as ticket 02: it is a
  separate signature, it touches `PadelScoring`, and this ticket does not need
  it.

## Further Notes

The glossary's **Match duration** entry has to gain a sentence in the same
change. It currently says the duration runs from the first rally to the last,
and after this ticket that stops being true the moment somebody undoes. An
entry that describes the old behavior turns the new code into the apparent bug.
