# 09: The phone match card

**What to build:** `MatchCard` in the redesign's language — the summary as a
field in the outcome's tint, the course of the score beneath it. There is **no
board** for this screen.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] The card is dark and full-bleed, continuous with the tile it was opened
      from — no `List` sections
- [ ] The summary takes the outcome's tint, the same three as `CourtTile`
- [ ] The final score uses `.score` or `.display`; nothing uses `.system(size:
      44)`
- [ ] The course of the score is readable as a progression, not as a table
- [ ] The navigation bar is either hidden with the day drawn as content, or
      kept minimal and tinted to the court — decide and say which in the
      closing note
- [ ] Nothing is read from the store beyond the ruleset and the rally journal;
      the state is still computed, not cached
- [ ] `MatchWording` is untouched
- [ ] Previews in both languages for a win, a loss, an abandoned match, and
      both rulesets

## The course of the score

The one thing on this screen the boards have no vocabulary for, and the reason
the card is worth its own ticket rather than a paragraph in ticket 08.

`CONTEXT.md` defines it: *how the match came about, and not only how it ended —
the score at every step it moved by, a game in classic scoring, a rally in the
match to N points*. It is what keeping the rally journal instead of the result
was for (ADR-0001).

Today it is a `List` section. In the redesign it should read as a progression
down the screen — the two sides' numbers advancing, our side's colour and
theirs distinguishable, the moments the serve changed hands legible if that
comes cheaply. The court's two colours are already the vocabulary for "ours"
and "theirs"; use them rather than a legend.

Do **not** turn it into a chart. It is a sequence of scores, it is read by
someone who was there, and a line graph of a padel match is a shape nobody
recognizes.

## What must not change

**Recomputation over caching.** The comment is explicit: the state is asked of
the engine every time rather than kept in `@State`, because recomputing costs a
walk over a few hundred rallies and a copy would be one more thing that can
disagree with the journal. The redesign does not make this screen expensive
enough to change that.

**Our side first**, matching the row the card was opened from — a score that
swapped sides on the way in would have to be read twice.

**The ruleset on the card.** Same argument as the history row: without it the
score cannot be read.

## Notes

**On the navigation bar.** This is the one screen in the app reached by a push
where the title carries information — it is the day the match was played. The
watch screens hide their bars because their titles were labels; this one's is
not. Both answers are defensible: hide it and draw the day in `.display` as a
proper header, or keep an inline bar tinted to the court. Pick one, and write
down why — a future reader comparing this screen to the watch's will wonder.

**On there being no board.** As with ticket 07: draw by extension, and treat a
need for something the boards do not give as a sign to look again rather than
to invent.
