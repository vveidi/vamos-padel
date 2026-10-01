# 09: The phone match card

**What to build:** `MatchCard` in the redesign's language — the summary as a
field in the outcome's tint, the course of the score beneath it. There is **no
board** for this screen.

**Blocked by:** 02, 03

**Status:** done

- [x] The card is dark and full-bleed, continuous with the tile it was opened
      from — no `List` sections
- [x] The summary takes the outcome's tint, the same three as `CourtTile`
- [x] The final score uses `.score` or `.display`; nothing uses `.system(size:
      44)`
- [x] The course of the score is readable as a progression, not as a table
- [x] The navigation bar is either hidden with the day drawn as content, or
      kept minimal and tinted to the court — decide and say which in the
      closing note
- [x] Nothing is read from the store beyond the ruleset and the rally journal;
      the state is still computed, not cached
- [x] `MatchWording` is untouched
- [x] Previews in both languages for a win, a loss, an abandoned match, and
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

## Comments

### Closing note

`night` under the history's own light, the summary on a `CourtTile` of the
outcome's tint at the history tile's radius, and the course of the score under
it as a column of bands. The card is the tile it was opened from, opened out.

**The bar is kept, stripped to its chevron; the day is drawn as content.** That
is the ticket's first answer for the title and not its second: the day is set in
`.display` as a proper header, because a bar would put this screen's one piece
of information in the system's type on a shelf over a court meant to run to the
edge. What the ticket did not weigh is that the bar also holds the way back. A
pushed screen with no chevron takes away the one exit every reader knows, so
`.toolbarBackground(.hidden, for: .navigationBar)` keeps the chevron and loses
the rest. The day then scrolls with the card rather than staying put the way the
history's title does: a date wraps to two lines at the accessibility settings,
and pinned it held a quarter of the screen for the whole reading. Under the
chevron is a `NightScrim(edge: .top)` — the primitive ticket 02 wrote for
exactly this, a control floating over a court with nothing behind it.

### The course as a progression

One band per step, running down the page, cut from the half that took the
step — turf for ours, glass for theirs. A run of three is read off the page
without reading a number, which is the history screen's argument brought down to
the size of a line. Inside a band the score is written our side first, and the
numeral that just moved is the one left at full strength; the other drops to
`.secondary`. The tiebreak and the unfinished game are not steps and do not
stand on a half: they take the app's quiet panel surface, with the label leading
and the score trailing.

**The serve changes are marked, in the match to N points.** The ticket asked for
them "if that comes cheaply" and they are: the serve passes over every `n`
rallies, the ruleset carries `n`, and a wider gap between runs says *when* it
changed without claiming *who* was serving. Classic scoring needs nothing —
every band there is a game, and a game is already one side's serve. The number
itself is on the card already, in the footnote above.

### Two things outside the ticket's lines

**`Color.courtInk(_ outcome:)` is new in `PadelDesign`.** The three-way "which
ink goes on a tile of this tint" was `MatchRow`'s private static; the card needs
the same answer, and written in both it would drift in one. It sits beside
`CourtTile`'s tint, which already takes the same `MatchOutcome`, and `MatchRow`
now calls it. That is a package edit inside a screen ticket — flagged rather
than hidden.

**`"Us"` and `"Opponents"` are gone from the catalog.** They were the row labels
of the `ScoreStrip` the bands replaced, and nothing else in either app says
them. Every key the card still uses is unchanged, so the catalog is two entries
shorter and no wider.

### Driven, not reasoned

Every state on an iPhone 17 simulator with the fixtures written into the store:
a win, a defeat, two sets with a tiebreak, a match to 16 points, and a match
stopped inside a tiebreak — in both languages, and again at `accessibility5`.
Two defects came out of driving it and neither would have come out of reading
it: the day sliding under the chevron, and the pinned header at the largest
type. The one state that stayed a preview is the empty journal — the watch does
not send one, and there is no way to put one into the store through the app.
