# The comment diet: code that reads itself

Status: ready-for-agent

## Problem Statement

A third of this codebase is comments. Measured across the four packages and both
app targets: **13,779 Swift lines, of which 3,715 are doc comments and 764 are
inline — 32%.**

That is not thoroughness, it is a cost paid on every read. Every agent session
that opens a file pays for those lines in tokens, and pays again on every model
call for the rest of the session, because the whole conversation is resent. A
file that is a third prose is a third more expensive to look at, forever.

Worse, the prose is not where the value is. The doc comments break down like
this:

| block size | blocks | lines  |
| ---------- | -----: | -----: |
| 6+ lines   |    244 |  2,431 |
| 3–5 lines  |    231 |    874 |
| 1–2 lines  |    276 |   ~410 |

**Two thirds of every doc-comment line sits in a third of the blocks.** Those
244 essays are the feature's target. They are where the design arguments, the
rejected alternatives and the history of what the code used to be ended up —
none of which is what a comment is for, and all of which has a better home in
`docs/adr/`, in a ticket, or in the commit that made the change.

The old rule caused this. `CLAUDE.md` used to say a doc comment "is written even
when the name looks self-evident: it is what Quick Help shows". That mandates a
sentence per symbol whether or not there is anything to say, and a sentence with
nothing to say grows into a paragraph.

## What is in, and what is not

In:

- **The rule**, already rewritten in `CLAUDE.md`'s "Writing comments": the
  default is no comment, four lines is the ceiling, and nothing survives that
  the code could have said itself.
- **Every `.swift` file** under `Packages/` and both app targets, including the
  test targets, one area per ticket.
- **Deleting**, not rewording. A comment that has to be rewritten to fit the
  rule is a comment the rule says should not exist.
- **The rescue of anything genuinely load-bearing** found along the way — a
  measured number, a real argument — into `docs/adr/` or a ticket, rather than
  the bin.

Not in:

- **Renaming.** The rule says a name needing a comment wants renaming, and that
  is true, but a rename is an API change and this feature is not one. Where a
  deleted comment leaves a name looking thin, the ticket says so in its closing
  note and the rename is somebody else's.
- **New ADRs, except where a deletion would lose a real decision.** Most of
  these essays are not decisions, they are narration.
- **`.md`, `.html` or ticket prose.** The docs are meant to be prose. This is
  about `.swift` files.
- **The `// MARK:` lines.** They are navigation, they cost one line, and Xcode's
  jump bar reads them.

Out, along with the comments:

- **`TODO:` and `FIXME:`.** `CLAUDE.md` now forbids both — work that is not done
  is a ticket, never a comment, because the board cannot see a comment. The two
  that existed when this feature was written are already gone; any that turn up
  become tickets before they are deleted.

## The design, in words

**Delete first, ask second.** The question for each comment is not "is this
nice to have" — everything is nice to have, which is how the codebase got here.
It is: *if this line were gone, what would a reader get wrong?* If the answer is
"nothing", it goes. If the answer names a precondition, a unit, a threading
rule, a failure mode, a measured number or a workaround, it stays — cut to four
lines.

**The essays are the work; the one-liners are mostly free.** A ticket that
spends its session on the 6+ line blocks in its area does most of the good. The
one- and two-line blocks are `/// The court's surface.` over `static let court`
and go in the same pass with no thought, but they are not what pays.

**Nothing here changes behaviour.** Every ticket in this feature is a
comment-only diff. `swift test` and both schemes are the proof, and a ticket
whose diff touches a line of code has gone wrong — with one exception: deleting
a comment sometimes leaves a dangling blank line or an orphaned `- Parameter`,
and tidying that is part of the deletion.

## Solution

One ticket per area, sized by what it holds:

| # | area                  | lines | doc   | inline |
| - | --------------------- | ----: | ----: | -----: |
| 01| `PadelDesign`         | 4,886 | 1,426 |    279 |
| 02| `Padel Watch App`     | 2,220 |   688 |    211 |
| 03| `PadelScoring`        | 2,503 |   538 |     84 |
| 04| `Padel` (phone)       | 1,467 |   462 |     54 |
| 05| `PadelStorage`        | 1,526 |   356 |    102 |
| 06| `PadelDelivery`       | 1,177 |   245 |     34 |

Ordered by weight, heaviest first, so the expensive areas are cleared while the
rule is freshest. None blocks another: they touch disjoint files.

`PadelDesign` goes first for a second reason — it is the package the other five
read, and its doc comments are the ones an agent hits most often.

## Implementation Decisions

### No Quick Help exemption for `public`

Weighed and declined. The argument for keeping a one-liner on public API is that
Quick Help shows nothing without one. The answer is that Quick Help showing
nothing is correct when there is nothing to say: `public static let court` needs
no gloss, and `/// The court's surface.` above it is the name again in a
sentence. The package's two consumers are both in this repo and both read the
source.

### Deleted, not shortened

A rewrite pass would preserve the instinct that produced the essays. The rule is
a test each comment either passes or fails, and one that fails is deleted whole.
The only comments that get *shortened* are the ones that pass on substance and
fail on length — a real precondition buried in four paragraphs of argument.

### One area per session

Each ticket reads its area's files in full, which is the expensive part and
cannot be avoided: deciding whether a comment earns its line means reading the
code under it. `PadelDesign` alone is ~8,000 tokens of source. Six sessions of
one area each stay inside the context budget where one session of all six would
not.

### The measurement is the acceptance criterion

Every ticket states its area's line counts before and after. That makes the
result checkable without re-reading the diff, and it is the number this feature
exists to move.

## Consequences, stated plainly

- **`code-review`'s standards axis enforces this from now on.** It reads
  `CLAUDE.md`, so the new rule is live for every ticket in every feature, not
  only this one. Expect it to start flagging comment essays in unrelated work.
- **Some ticket specs ask for prose in doc comments and are now wrong.**
  `court-surface`'s spec chose doc comments over an ADR explicitly — "the
  reasoning lands as doc comments on the surface token and on `CourtHalf`". That
  feature has shipped; the comment it planted is in `01`'s scope like any other.
  A future spec that tries the same should be pushed back on.
- **The repo gets quieter to read and cheaper to work in.** The target is under
  10% comments, which on today's line count is roughly 1,400 lines kept out of
  4,479 — about 3,000 lines deleted.
- **Some of what goes was genuinely good writing.** It was the wrong container
  for it. Where a deletion would lose a real decision, it moves to an ADR rather
  than being lost, and that is a criterion on every ticket rather than a hope.

## The tickets

```
01  PadelDesign
02  the watch app
03  PadelScoring
04  the phone app
05  PadelStorage
06  PadelDelivery
```

None blocks another. Lowest number first is the recommended order, not a
requirement.
