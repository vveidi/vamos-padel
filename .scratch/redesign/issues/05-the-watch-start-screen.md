# 05: The watch start screen

**What to build:** `StartView` becomes the court before the match: both halves
labelled with the side and "to serve", the ball waiting on the net, the rules
on a floating card, and a line saying the watch will record to Health.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] The screen is a full-bleed `Court` — no `List`, no `NavigationStack`
      chrome
- [ ] `.toolbar(.hidden, for: .navigationBar)`; the "New match" title goes,
      since the board has none
- [ ] `NavigationStack` **stays**, purely for the push to the rules screen and
      the edge-swipe back it gives free
- [ ] Tapping a half starts the match with that side serving — one tap, exactly
      as today
- [ ] The ball sits on the net, centred, waiting
- [ ] A floating `SettingsCard` at the bottom shows the ruleset and pushes to
      the rules screen
- [ ] A lit `ball`-yellow dot and **"Recording to Health"** sit under it
- [ ] A `NightScrim` at the bottom edge carries the floating controls
- [ ] Both halves' labels are whole sentences per side, not a name in a frame
- [ ] The new string is in `Localizable.xcstrings` in both languages and pinned
      in `padelTests`
- [ ] Previews in both languages, at the largest type, for both rulesets

## The layout

From `Main.dc.html`: their half on top with "Them / to serve", ours below with
"Us / to serve", the labels sitting ~20% down each half rather than centred —
the ball is centred on the net and the labels clear it. The floodlight comes
from the top left.

The rules card is the board's one row: the ruleset's name in `.control`
semibold, its numbers in `.caption` beneath, and a chevron in a circular
`ink`-at-0.14 well at the trailing edge.

## What must not change

**The one-tap start.** `StartView`'s doc comment is emphatic: the tap that names
the serving side *is* the start, and a separate "Start" button would be a second
tap that says nothing new. The board agrees — there is no start button on it.
(The phone board has one, because a phone screen has room for a decision the
watch does not; it is out of scope anyway.)

**The two sentences.** `serves(_:)` returns "We serve" / "Opponents serve" as
whole sentences because English puts the side before the verb and Russian after
it. The board's "Them / to serve" is a two-line English arrangement that does
**not** survive translation. Keep whole sentences; let them wrap to two lines if
they must. Getting this wrong produces "Они / подавать", which is not Russian.

**The ruleset naming.** `name(of:)` and `parameters(of:)` stay as they are,
including the two-line allowance under the name — the comment there records
that at the largest type neither language fits one line, and that hiding the
golden point is the wrong way out.

## "Recording to Health"

New, and the one behavior the redesign adds. A `ball`-yellow dot and a line in
`.caption` at `ink` 0.62, centred beneath the rules card.

It is a **statement of intent, not a live status**: the workout starts with the
match, so before the match there is nothing running to report. Word it that way
and do not wire it to `Workout`. If Health access was refused the line is a
lie — check what `HealthKitWorkout` knows about authorization, and if it can
answer cheaply, hide the line when it cannot record. If it cannot answer without
prompting, leave the line unconditional and note it in the closing comment;
prompting for HealthKit on the start screen to decide whether to draw a caption
is a bad trade.

## Notes

**On hiding the navigation bar.** The system clock stays drawn at the top right
and cannot be hidden by a third-party app. The board's layout leaves it clear;
check on the smallest watch, not only the 46mm the board is drawn at.

**On the edge-swipe back.** It belongs to `NavigationStack`, not to the bar, so
hiding the bar keeps it. Verify anyway — it is the only way back from the rules
screen once the title is gone.
