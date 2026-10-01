# 03: The icon's ADR

**What to build:** the decision behind the new app icon written down where it
outlives `.scratch/` — what was chosen, what was rejected, and what the choice
cost.

**Blocked by:** 02

**Status:** done

- [x] A new ADR at `docs/adr/0015-<slug>.md`. **0015 and not 0010** — that number
      is retired rather than free: `0010-the-mirrored-workout-keeps-the-phone-alive.md`
      was deleted in `31a110b` when the pair was parked, and reusing it would make
      two decisions share a name in the history. *Landed as 0016: `any-window`
      01 took 0015 after this was written, and the rule is the next free number*
- [x] It records the decision — the icon is the ball on the court — and the one
      thing that decided it: what survives at 29 points, the size a Settings row
      gives an icon
- [x] It records the rejected alternative **by name**: the court from a high
      corner, with its near glass, its posts, the net and the white lines. It was
      the better picture at 1024, and the only one of the two that says *padel*
- [x] It records the cost that came with the winner: a yellow ball on a blue
      court is every racket sport, and the glass back wall is the one thing in
      padel no other racket sport has. An ADR listing only the winner's virtues
      is the assertion this repo keeps studies to avoid
- [x] The second argument against the loser is recorded as what it was — an
      argument, not the reason: a perspective court is a second drawing of what
      `PadelDesign` already owns and no test keeps it honest, and a picture good
      enough at 29pt would have been worth that maintenance
- [x] It cites `docs/design/AppIcon.html` as where the alternative can be **seen**,
      the way ADR-0011 cites `RallyMark.html`. The ADR says what was decided and
      what it cost; the study is where it can be looked at
- [x] It does not restate the study. The projection, the hexes, the 24-unit box
      and the weave period stay on the page
- [x] `docs/design/README.md`'s studies entry names the ADR by number, so its two
      lines match: `RallyMark.html` already cites ADR-0011 and `AppIcon.html`
      currently cites nothing

## Notes

**Why this is a ticket and not a line in the last one.** The icon shipped with
its argument in two places, and one of them is temporary. The closing note under
`.scratch/court-surface/issues/02-the-icon.md` holds the reasoning, and
`docs/agents/issue-tracker.md` is explicit that the tracker holds work in flight
and is emptied as features close. When `court-surface` closes, the argument goes
with it.

**What survives without this, and why it is not enough.** `docs/design/AppIcon.html`
is in `docs/` precisely so it outlives the ticket, and it keeps candidate B drawn
under a verdict. But `docs/design/README.md` says a study "answers one question
that several screens will be built against" and is kept because "the
alternatives are the thing worth keeping" — it is where a decision can be *seen*,
not where it is *stated*. ADR-0011 and `RallyMark.html` are the pair that shows
the intended shape: the ADR carries the prose, the study carries the pictures.
This feature built the second half and not the first.

**The question it has to answer.** Not "why is the icon a ball" — anyone can see
that. It is "why isn't the icon the court, when the court is what the whole app
draws and the glass is the only thing that says padel". That question has a good
answer, it was settled by looking at a 29-point tile, and right now the answer
lives in a file that is scheduled for deletion.

## Comments

Built and closed. All eight criteria met.

**What shipped.** `docs/adr/0016-the-icon-is-the-ball-on-the-court.md`, and
the studies entry in `docs/design/README.md` now names ADR-0016 the way
`RallyMark.html`'s names ADR-0011. The ADR answers "why not the court": B was
the better picture and the only one that says *padel*, and it failed at 29pt.
It records the winner's two costs — it says every racket sport, and its PNG
is still exported by hand from values copied out of the palette.

**One departure.** The ADR is 0016, not 0015 — see the first criterion.

**What `code-review` found.** Three claims the sources did not support: the
lozenge's edge rather than the tile's, a superlative about the App Store, and
"draws nothing the app does not" when the weave is coarser by design. All
three were corrected. A sentence that was the ticket's wording pasted into
the ADR was cut.
