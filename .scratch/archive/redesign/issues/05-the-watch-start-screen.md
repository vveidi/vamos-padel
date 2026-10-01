# 05: The watch start screen

**What to build:** `StartView` becomes the court before the match: both halves
labelled with the side and "to serve", the ball waiting on the net, and nothing
else. The rules and whether the match goes to Health are a page below it.

**Blocked by:** 02, 03

**Status:** done

- [x] The screen is a full-bleed `Court` — no `List`, no `NavigationStack`
      chrome
- [x] `.toolbar(.hidden, for: .navigationBar)`; the "New match" title goes,
      since the board has none
- [x] `NavigationStack` **stays**, purely for the push to the rules screen and
      the edge-swipe back it gives free
- [x] Tapping a half starts the match with that side serving — one tap, exactly
      as today
- [x] The ball sits on the net, centred, waiting
- [x] The court page carries the two halves and the ball, and nothing else
- [x] A scroll down reaches a settings page: a `SettingsCard` with the ruleset,
      which pushes to the rules screen, and a switch for Health
- [x] The Health switch is remembered between matches and is honoured — off
      means no workout is started at all
- [x] Both halves' labels are whole sentences per side, not a name in a frame
- [x] The new strings are in `Localizable.xcstrings` in both languages and
      pinned in `PadelTests`
- [x] Previews in both languages, at the largest type, for both rulesets

**The last six criteria were rewritten mid-ticket**, on the owner's call: the
start screen should be the two serve halves and nothing more, with the rules
and the Health setting a scroll below. What they replaced is kept here so the
board and the ticket can still be read against each other:

> - [ ] A floating `SettingsCard` at the bottom shows the ruleset and pushes to
>       the rules screen
> - [ ] A lit `ball`-yellow dot and **"Recording to Health"** sit under it
> - [ ] A `NightScrim` at the bottom edge carries the floating controls

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

## Comments

### The design changed mid-ticket

The board puts the rules and the Health line on the court, floating over a
`NightScrim` at the bottom edge. Built that way and looked at on three watches,
the owner's call was that the start screen should be **the two serve halves and
nothing else**, with the rules and the Health setting one scroll below. The
criteria above are rewritten to that; what follows is what was built.

It is the better screen for what the court is. The court is one question — whose
serve — and it asks it with two tap targets that fill the display. Everything
that had been floating over it was standing on our half, and on the 40mm the
card reached the ball.

### Closing note

Two files where there was one, the same split `ScorePages`/`ScoreView` already
makes for a match in progress:

- **`StartView`** is the court page and nothing else: `CourtHalf` / `NetLine` /
  `CourtHalf` in a `VStack(spacing: 0)` so the halves meet on the tape, one
  `Floodlight(corner: .topLeading, strength: 0.17)` over the whole court as the
  board draws it, and a `Ball(size: 20)` centred — which is the middle of the
  tape, the two halves being equal.
- **`StartPages`** is the `NavigationStack` around a
  `TabView(.tabViewStyle(.verticalPage))` holding the court and `StartSettings`.
  The stack is around the pages rather than inside one, so the rules screen
  pushed from the settings page covers the paging instead of being pushed under
  the page indicator. The bar is hidden; "New match" goes with it.
- **`StartSettings`** is `night` with the rules board's softer light on it, a
  "Settings" title at `.display`, and a `SettingsCard` holding two rows: the
  ruleset — name at `.control`, numbers at `.caption`, a chevron in a 13pt
  `ink`-at-`surface` well, pushing `RulesetView` — and a `Toggle` tinted `.ball`
  for Health.

**The halves are a tap gesture and not a `Button`.** The court page lives inside
a paging `TabView` whose next page is a swipe down the court, and a button there
is a half that starts a match out of the swipe going past. `ScoreView` made the
same choice in ticket 04 for a different reason and has been two tap zones
inside that same paging ever since. Everything a button gave VoiceOver is put
back by hand: `.isButton`, and the sentence as the label.

**The two sentences are unchanged** — `serves(_:)` still returns "We serve" /
"Opponents serve" as whole sentences, and the board's "Them / to serve" is not
translated piecewise. They sit high in their halves rather than centred: the
board's 21% and 16% are two numbers measured from opposite ends of the court —
their half's top is the top of the screen, ours is the net — so theirs lands
near the outer edge and ours just clear of the ball. Their sentence is pushed
below whatever the watch reserves for the clock, read off a `GeometryReader`
that is laid out in the safe rect while the court inside it runs to the glass.

**`name(of:)`, `parameters(of:)` and the two-line allowance moved with the card
and are otherwise untouched**, as the ticket asks.

### Health became a switch, not a caption

The ticket's line was a statement of intent and deliberately not wired to
`Workout`. The redesign makes it a setting instead, so it is wired all the way:

- `@AppStorage("records-to-health")` on `RootView`, defaulting to on. In
  `UserDefaults` and not in the store, and that does not break `lastRuleset()`'s
  rule against a second copy: no match says this, and no match can be asked for
  it. It is a preference about the app, not a fact about padel.
- Off is answered by handing `MatchView` a `NoWorkout` instead of the real one —
  which is precisely what `NoWorkout` is for. The match screen goes on calling
  `start()` and `end()` without being told which it is holding.
- Read once, when the match screen is built. Nobody can reach the switch while a
  match runs: the settings page is behind the start screen.

**`Workout.recordsToHealth` was written and then removed.** Following the
ticket, `HealthKitWorkout` grew a cheap non-prompting
`authorizationStatus(for: HKObjectType.workoutType()) != .sharingDenied`, and
the caption was hidden when Health had been refused. It worked — one simulator
carrying an old denial drew no line while another drew one. With the caption
gone the capability had no reader: a switch is the player's own intent, and a
refusal is HealthKit's business, answered by writing nothing. The protocol is
back to `start()` and `end()`. If a later ticket wants the switch disabled on a
refusal, that method is four lines and is in this file's history.

### How each criterion was checked

Built for watchOS; `PadelTests` green — 11 cases on the iPhone 17 Pro, including
the new `Record to Health` in both languages.

Run on the 46mm Series 11 (Russian), the 44mm SE 3 (English) and the 40mm SE 3:

- The court page snapshots as exactly two elements — "Подают соперники" and
  "Подаём мы" — with nothing else on it.
- Tapping a half starts the match with that side serving: their half gave
  "Очко соперникам … подача справа", i.e. they serve.
- The rules row pushes `RulesetView`, which keeps its own bar and Back button;
  switching Classic → By points and coming back redrew the card as
  "Point scoring · 16 points · Serve changes every 4 rallies".
- The Health switch, end to end: turned off on the settings page, the app
  reinstalled over itself so the preference survived, a match started — and the
  log has no line at all, where the same simulator had logged
  "health share permission before asking: … authorized" with the switch on.
- The largest of the twelve Dynamic Type settings, pinned temporarily in the
  app because the watch simulator has no `content_size`: both pages hold. The
  card grows and the page stays legible; the sentences wrap to two lines and
  shrink to 0.6 rather than crossing the net.

### Two things not verified, and why

**The page scroll and the edge-swipe back could not be driven from the CLI.**
The automation's synthetic gestures arrive on watchOS as taps: `scroll-up` on
the *shipped* score screen scores a point rather than changing page, which is
what proves it is the tool and not either screen. The back gesture belongs to
`NavigationStack` and the pushed rules screen also carries a visible Back
button, so there is a way back either way — but the swipe itself wants a wrist.

**The `Toggle`'s knob comes out white, not the deep teal `Color.knob`.**
`SettingsCard`'s doc says the board's switch is "a `Toggle` with `.tint(.ball)`
and nothing else" and then says to check the knob against `knob` — and `.tint`
does not reach the knob. That is ticket 03's control and ticket 03's number, so
it is left alone and written down here.

### Two lines of this ticket that ticket 06 has since overtaken

The knob is the boards' now: ticket 06 needed it for the golden point, wrote
`PadelDesign/BallSwitch` for it, and the Health row on this page wears the same
style — one switch drawn one way, a scroll apart. `.frame(minHeight:)` on that
row went with it; the style carries the height.

And there is no rules screen any more. Ticket 06 hid its bar, which is that
ticket's own criterion — and hiding the bar on a *pushed* watchOS screen takes
the only way back with it: the edge swipe does not answer for the Back button,
so the screen was a trap. The rules are a section of this page now, under its
title and above the Health switch, and the page scrolls. The row that pushed
them is gone, and `name(of:)` and `parameters(of:)` went with it — this
ticket's "otherwise untouched" outlived the row it was about.

**This page's own `.toolbar(.hidden, for: .navigationBar)` went too**, and the
criterion above should be read as "no bar is drawn" rather than as that line.
It was drawing none either way — neither page has a title, and watchOS reserves
nothing for an empty bar; the two pages screenshot identically with the line
and without it. What the line did cost was the stack's bar model, and every
push logged two SaltUICore faults for it. Ticket 06 has the log and the bisect.
