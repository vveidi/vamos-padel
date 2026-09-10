# 07: The watch outcome screen

**What to build:** `OutcomeView` in the redesign's language. There is **no
board** for this screen — it is drawn by extension from the ones there are.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] The screen reads as the court it was just played on, not as a system
      alert
- [ ] A win by us is warm — the ball's yellow marks it, because the ball marks
      what is yours
- [ ] A loss goes cold and grey. **No red anywhere**
- [ ] An abandoned match is neither: it holds a trace of the floodlight, the
      same as an abandoned tile in the history
- [ ] The score uses `.score` or `.display`, the headline `.display`
- [ ] The buttons are `PillButton`s — primary for the one that goes on, quiet
      for undo
- [ ] `winner: Side?` still means what it means: `nil` is abandoned, and is not
      "the opponents won"
- [ ] The winner's score is still written first
- [ ] Previews in both languages, at the largest type, for a win, a loss and an
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
