# The rally mark: the court answers, so a rally is seen and not only counted

Status: ready-for-agent

## Problem Statement

A rally is awarded and a digit changes. That is the whole of the feedback both
score screens give, and it asks the reader to have been looking at the right
number at the right moment.

On the wrist that is nearly free — you tapped, and `watch-tap-mode` 02 is giving
the wrist four haptics to answer with. On the bench it is not free at all. The
phone's scoreboard is read by four people at a distance, none of whom awarded
anything, and the rally that moved it was awarded on somebody's wrist. A 30
becoming a 40 across a court is a change nobody sees happen; it is a change
noticed afterwards, if at all.

The reference app answers this by flashing the field green. It can: its field is
black and carries no information. Ours is a court whose two halves already mean
something, and whose surfaces are about to become clay and grass.

This feature makes the court answer. The half that won the rally brightens in its
own color and falls back.

## What is in, and what is not

In:

- **The rally mark** as a primitive in `PadelDesign`, drawn in `courtLit` and
  spending no new color.
- **Two tiers**: a rally, and a rally that also took a game or a set.
- **The watch's score screen** and **the phone's scoreboard**, each marking the
  rallies it awarded.
- **One strength**, in the file that already owns what the court is painted in.

Not in:

- **A mark for an undo.** The obvious answer — the mark reversed, the half
  draining rather than blooming — was drawn and does not survive being looked at.
  ADR-0011 records why, and `docs/design/RallyMark.html` still has the button so
  the next person can check rather than re-derive.
- **A mark for the match ending.** The rally that ended it has already been
  marked, and the screen it would be marked on is replaced by the outcome in the
  same update. This is the same answer `watch-tap-mode` 02 gives about the
  haptics, for the same reason.
- **Anything for VoiceOver.** The watch's haptic already says a rally landed and
  which way; both halves already carry a label, a value and an undo action.
  Announcing every rally on the phone would be forty announcements a match to say
  what the value already says when focused. This is a decision to write no code.
- **A gate on Reduce Motion.** See the decision below; it is also a decision to
  write no code, and the comment exists so that nobody writes some.
- **A dimmed variant.** Unlike every other thing drawn on the court, this one has
  no Always-On case at all.
- **A theme.** There is one strength for one surface today. It becomes one per
  surface when there are several, and needs no seam built ahead of them.

## The design, in words

**The half that won brightens in the surface's own color and falls back.** The
court lifted in value with its hue kept — `courtLit`. Not white, not the
floodlight's warm light, not the ball's yellow.

That is the whole decision and it was made against four alternatives, all of them
drawn and fired side by side in `docs/design/RallyMark.html`. What settled it was
not this court but the next ones: every other candidate carries a hue, and a hue
has to be re-decided the day the court can be Roland Garros clay or Wimbledon
grass. A mark that *is* the surface has nothing to re-decide.

**The two tiers differ in time, never in strength.** A rally that also took a game
or a set holds at its peak before it falls. Strength is already the surface's — a
tier that moved it too would make every surface tune four numbers instead of two.

**A device marks the rallies it awarded, not the rallies it is told about.** The
watch marks a tap made on the watch. The phone marks every rally, whatever its
origin, because nobody is holding the phone and there is no "you know what you
did" to lean on.

**It fires from the journal, never from the tap.** The rule pairing will bring: the
watch draws nothing it has not been given. The haptic is the optimistic one; the
mark is the honest one, and where they disagree — an intent the phone refuses —
the wrist buzzes and nothing lights.

## Solution

### The primitive

`Court/RallyMark.swift` in `PadelDesign`, laid over a half as a modifier. It
takes a `Side`, a tier, and a trigger that changes when a rally lands. It knows
nothing about a match, a journal or a rally count — ADR-0006's seam, unchanged:
the package is asked for a marked half and nothing more.

Inside it splits in two, and the split is what makes it testable: **what it looks
like at a given strength** is a view of its own, renderable and therefore
raster-testable the way every other court primitive is; **when it plays** is the
wrapper around that, and is tested by nobody.

### The color

`Color.courtLit`, already in the palette: `court-surface` 01 added it as the
surface brightened against itself, and it means exactly what the mark means —
*this court is live*. There is nothing left for this feature to name.

That also settles the shape of the mark: it is a **fill animated 0 → 1 → 0**
over the half, not a blend mode over the surface. Same pixels, one concept
fewer to re-derive.

### Where the trigger comes from

The screens compute it from what they already hold. The journal grew, its last
rally was won by this side — that is the mark. The tier is the games or the sets
having moved with it, which both screens are already handed. No new
`PadelScoring` API, and nothing new stored (ADR-0001).

## Implementation Decisions

### The mark is the surface, and the surface's own hue

`courtLit` is the court lifted in value with its hue kept, so a marked half
reads as the court itself responding rather than as something laid over it. A
mark that washed toward white would be the floodlight, which is a different
primitive and the candidate that lost.

The raster test that matters is therefore not "it got brighter" but "it got
brighter *and stayed the same color*". Brightness alone is satisfied by four of
the five rejected candidates. `PaletteTests` already makes that check against
`courtLit`; what this feature owes is the same check on the marked half as
drawn.

### The strength is one number

It was going to be one per side — what read on turf green did not read on glass
blue. `court-surface` collapsed the two halves into one surface, so there is one
surface to settle the mark against and one number to settle. Whether an opacity
peak below 1 reads better than the full `courtLit` is still a question for a
wrist rather than a canvas.

### The mark has no Always-On case

Every other thing drawn on the court has a dimmed variant, because a court is
held up for ninety minutes. This one is never on screen with the luminance
reduced: the watch marks only a tap you just made on it, so the screen is awake
by definition, and the phone's scoreboard holds the idle timer off. The absence
is deliberate and is written down, because it is the kind of gap that reads as an
oversight.

### It is not gated on Reduce Motion

Reduce Motion exists for vestibular triggers, and the standard remedy for one is
to replace the movement with a crossfade. This mark already *is* a crossfade on a
stationary rectangle: gating it would switch off the thing motion-sensitive
interfaces are meant to degrade to, and would hand the people it is aimed at back
the bare counter. It is also one transition per rally, two orders of magnitude
below the flashing thresholds that guidance is written around.

The comment saying so is the deliverable. Without it this looks like an omission
and gets "fixed".

### The origin filter arrives with `paired-scoring` 05, not before it

Today the watch holds the match and every rally on its screen is one it awarded,
so "the watch marks its own" is true for free. It stops being free when the phone
becomes the host and rallies start arriving. Ticket 02 therefore leaves a `TODO:`
at the place the filter goes, naming `paired-scoring` 05 — the repo's own
mechanism for exactly this, and visible in Xcode's jump bar rather than only in a
spec nobody opens.

## Consequences, stated plainly

- **Every surface shipped after this one names its own strength.** This is the
  price of the candidate that spends no color, and ADR-0011 records it as the
  thing that was bought rather than as a defect. It is one number per surface
  now rather than one per half.
- **The debt about a half's identity is settled, and was never owed.** This
  feature was going to inherit "the mark brightens a surface whose color is the
  only thing saying whose surface it is". `court-surface` paid it first: which
  half is ours is said by position and by the net, and the surface says nothing
  about it either way. A marked half is the court lighting up, and which court
  it is is a question the arrangement already answered.
- **The match-winning rally is not marked in practice.** It would be marked on a
  screen replaced by the outcome in the same update. Consistent with the feature
  marking no match ending, and worth knowing before it is filed as a bug.
- **A refused intent buzzes and does not light.** After `paired-scoring` 05 the
  two feedbacks can disagree, and the mark is the one telling the truth.
- **The phone's ticket cannot unblock on the board.** `.scratch/status.sh` reads
  blockers as numbers within one feature, and ticket 03 waits on a ticket in
  another. It is written so that it can never falsely show as takeable, and it
  carries the one-line instruction for making it takeable when the scoreboard
  exists.

## The tickets

```
01  the mark
02  the watch marks its own rallies
03  the board marks them all
```

01 depends on nothing and is buildable today. 02 waits on 01. 03 waits on 01 and
on `phone-scoring` 04, which has not been built — the scoreboard has to exist
before anything can be laid over it.
