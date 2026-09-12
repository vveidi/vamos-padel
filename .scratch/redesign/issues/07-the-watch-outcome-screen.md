# 07: The watch outcome screen

**What to build:** `OutcomeView` in the redesign's language. There is **no
board** for this screen — it is drawn by extension from the ones there are.

**Blocked by:** 02, 03

**Status:** done

- [x] The screen reads as the court it was just played on, not as a system
      alert
- [x] A win by us is warm — the ball's yellow marks it, because the ball marks
      what is yours
- [x] A loss goes cold and grey. **No red anywhere**
- [x] An abandoned match is neither: it holds a trace of the floodlight, the
      same as an abandoned tile in the history
- [x] The score uses `.score` or `.display`, the headline `.display`
- [x] The buttons are `PillButton`s — primary for the one that goes on, quiet
      for undo
- [x] `winner: Side?` still means what it means: `nil` is abandoned, and is not
      "the opponents won"
- [x] The winner's score is still written first
- [x] Previews in both languages, at the largest type, for a win, a loss and an
      abandoned match

## Drawing it by extension

The vocabulary the boards establish, and what it gives this screen:

- **The three outcomes are already coloured** — ticket 03's `CourtTile` maps
  won to turf green, lost to cold glass, abandoned to lit night. That mapping
  is the design's answer to "how does an outcome look", and this screen should
  use the same one rather than invent a second.
- **The ball marks what is yours.** A win by us gets it; a loss does not. This
  is the one accent and it must not become a decoration on both.
- **The floodlight** comes from a corner, as everywhere else.

So: the outcome as a full-bleed field in the tile's tint, the headline and the
score over it, the buttons floating on a `NightScrim` at the bottom. That is
the smallest thing consistent with the six boards, and it needs no new idea.

## What must not change

**`nil` is abandoned.** The doc comment on `winner` says it precisely: an
abandoned match counts as neither a win nor a loss, and this screen is the last
place that difference could be lost. Whatever the styling, the three states stay
three.

**The winner's score first.** The comment records why — the line above names the
winner, and a score that came in the other order would read backwards against
the score screen, where the opponents are on top.

## Notes

**On there being no board.** Do not invent structure. If a decision here needs
something the boards do not give — a new shape, a second accent, a red — that is
a sign the answer is elsewhere in the design, not that the design is missing a
piece. The one thing genuinely absent is what a *loss* feels like at full
screen, and the answer the brief gives is: nothing special. It goes cold.

**On the abandoned match.** It is the state most likely to get lost in a
restyle, because it is neither of the two the eye expects. `CONTEXT.md` gives it
its own entry — "Saved in the history alongside the rest, but marked explicitly,
and counted as neither a win nor a loss" — and the phone's history (ticket 08)
draws it as its own tint. Keep them consistent.

## Comments

### Closing note

The screen is a ground, three lines of content over it and two buttons at the
foot. The three outcomes are one `switch` each on `winner` — the sentence, the
ink it is set in, and the half it stands on — so the three states are three in
every place the screen makes a decision, and `nil` never falls through to
"them".

**The ground is the court primitive, not the tile's colour.** The ticket asked
for "a full-bleed field in the tile's tint", and `CourtHalf(side: winner)` is
that field with the court's own weave and painted lines already on it: turf
green for a win, glass blue for a loss, and `Color.night` where there is no
winner to name a half. The tile's tints and this are the same three colors, and
the weave the tile borrows from the court is `internal` to `PadelDesign`, so a
screen that wanted the tile's exact ground would have needed a new public
primitive — which the ticket rules out. A `Floodlight` from the top trailing
corner — the history's corner — falls on all three, which is the abandoned
match's "trace of the floodlight", and a `NightScrim` fades the foot so the
buttons stay legible over the court.

The win's one accent is its headline in `ball`. The loss carries no accent at
all: the cooled ink at `control`, which is the weight this app already sets a
title in. Nothing is red anywhere.

### The undo moved from a gesture to a button

The ticket asks for a quiet `PillButton` for undo, which leaves the long press
this screen used to carry with nothing to do, so it is gone along with the
`accessibilityAction` that stood in for it — a real button gives VoiceOver both
back. An abandoned match still has no undo, for the reason the old comment gave
and the new one repeats.

**One new key: `Undo the rally` / `Отменить розыгрыш`.** The score screen's
spoken "Undo the last rally" is three lines of Russian inside a pill 187pt
wide, which left the quiet button taller than the primary above it. Both
sentences are pinned in `SharedCatalogTests` now, since what they differ by is
one word and an edit "fixing" one to match the other would go unnoticed.

### It scrolls

At `.accessibility5` the headline, the score and two pills stand taller than
every watch, so the page is a `ScrollView` with the ground behind it — the same
arrangement the start screen's settings page uses. The alternative was a
ceiling on Dynamic Type, which the start screen's capsules pay for a different
reason: there the court must not scroll under the finger, and here nothing is
being tapped for points.

### How it was checked

Built and driven on a 42mm Series 11 in Russian — the smallest screen and the
longer language — through all three outcomes: a match won 6:0, one lost 6:0,
and one stopped from the control page. The win and the loss carry both buttons
and the abandoned match only the primary; undo from the loss screen came back
to 40, 5 games. Relaunched with
`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`
and played the loss again: the page scrolls, both pills are whole and
reachable, and nothing clips. `padelTests` passes, 13 cases.
