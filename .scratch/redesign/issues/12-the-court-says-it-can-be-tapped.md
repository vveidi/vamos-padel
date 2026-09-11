# 12: The court says it can be tapped

**What to build:** the two halves of the start screen, made to read as the
control they already are — without putting furniture on the one screen that has
none.

**Blocked by:** 05

**Status:** ready-for-human

The lines below are the criteria as they were written, corrected where the
owner redirected the work — a tick has to mean what the code does, or it tells
the next session to go and build something else. The reasons are in the
Comments.

- [x] The control answers the finger: it lights while pressed and starts the
      match on release, so a tentative press teaches the screen instead of
      committing to a match — **the capsule and not the half around it, which
      is inert**
- [x] A press that leaves the control starts nothing — the `Button` cancels it,
      the way it cancels for a swipe
- [x] The paging survives: a swipe down the court still reaches the settings
      page without starting a match — with a `Button`, and **not** with the
      gesture this line was written for
- [x] Starting a match plays a haptic
- [x] The ball says both halves are live before anything is touched —
      **the travel to the chosen corner is retracted: the match screen is up
      by the time it would be drawn**
- [x] Under Reduce Motion nothing travels and nothing breathes: the ball sits
      on the net as it does today
- [ ] Each half carries its own light, so the screen reads as two objects
      rather than one picture of a court — **retracted: two lights did not
      read as two objects, and the court's single light is back**
- [x] Not one word is added to the screen and the two sentences keep their
      wording — **their place moved: both now stand the same distance from the
      net rather than a fifth down their half**
- [x] VoiceOver still finds exactly two elements — "We serve" and "Opponents
      serve" — each a button, and the ball is still not one of them
- [x] Both languages hold, and the Dynamic Type range up to the ceiling the
      capsules set at `.accessibility2`
- [ ] Verified on a wrist or in the simulator rather than by reasoning about
      it, and the verdict written into the closing note: if the halves still do
      not read as tappable, **the capsule below is what to do next**

## What is wrong today

The screen asks the only question it exists to ask — whose serve — and a player
meeting it does not know the answer is a tap. Three decisions, each defensible
on its own, add up to that:

**The words are statements.** "We serve" and "Opponents serve" describe a state
of the world. Nothing on the screen asks anything, so nothing looks like an
answer. This is the one of the three that must *not* be fixed by rewording —
see "What this must not become".

**Nothing answers the finger.** `StartView.half(_:clearing:)` hangs an
`onTapGesture` on the half and that is the whole of the interaction: no pressed
state, no haptic, no sound. `grep` for `sensoryFeedback`, `isPressed` and
`WKInterfaceDevice` across the app and the packages returns nothing — there is
no touch feedback anywhere in this app yet. So the affordance cannot be
discovered by poking at it either: the match simply starts, which is also the
one way this screen can be got wrong by accident.

**One light crosses both halves.** `StartView` spends a single top-leading
`Floodlight` at 0.17 over the whole court, and says so deliberately — it is
what makes this board different from the score screen's. It is also what makes
the screen read as *one photograph of a court* rather than as two objects. The
score screen lights the serving half alone, and that is a good part of why its
halves read as separate things.

VoiceOver is already fine: the half carries `.isButton` and the sentence as its
label, put back by hand where a `Button` would have given them. It is the
sighted glance that fails.

## The four changes

**The press state, and the gesture that carries it.** Replace the
`onTapGesture` with a zero-distance `DragGesture`, tracking whether the finger
is still inside the half, and fire `onStart` on release. Pressed, the half
lifts — brighter surface, the same court, no new colour. This is a fix for a
hazard as much as for an affordance: today there is no way to touch a half and
back out of it.

**The haptic.** `.sensoryFeedback` on watchOS 11, which is the deployment
target. It is the first haptic in the app and so it sets the precedent: the
match starting is worth one, a press is not.

**The ball.** It means *this is yours, or this is chosen* (ADR-0006), and
before a match nothing is either — which is exactly why it sits still on the
net today. Give it something to say instead: a slow lean toward each half in
turn, or a soft pulse of light passing from one to the other, so that without a
word the screen says both halves are live. On the tap the ball travels into the
chosen half's corner, which is precisely where `ScoreView` keeps it during
play, so the animation teaches the next screen on the way there. This is the
one of the four that is *this app* rather than generic UI — and the one with
the real risk, which is motion on a glance screen. It is why Reduce Motion is
an acceptance criterion and not a footnote.

**The two lights.** One `Floodlight` per half instead of one across the court.
Nearly free, given `Floodlight` is already an overlay that takes no room, and
it costs the board its "one light crossing the net" note — which is a note
about atmosphere, on a screen that is failing at being usable.

## The fallback, if it still does not read

Wrap each sentence in a `ChoiceCapsule`-shaped chip. The half stays the tap
target; the chip is what says *pressable*. It is vocabulary the app already
speaks — the same capsule is what "chosen" looks like on the rules screen, and
`ChoiceCapsule`'s own doc argues that a player who learns it on one wrist
should not learn it again in the hand.

It is the fallback and not the plan because it is the one option here that puts
furniture on the screen whose whole argument is that it has none. It also
cannot fail, which is why it is written down: if the four changes above are
tested on a wrist and the screen still reads as a picture, do not invent a
fifth thing — draw the capsule.

## What this must not become

**A "Start" button.** `StartView`'s doc has the argument: a separate button
beside the serve choice is a second tap that says nothing new. The tap that
names the server *is* the start.

**"Tap a half to start", or any other instruction.** A screen that has to
explain itself has lost, and the words would have to be translated, wrapped,
and scaled into halves that are already carrying a sentence each.

**A question over the court.** "Who serves?" would genuinely turn the two
sentences from facts into answers, and it was considered. It needs somewhere to
live: the net's centre is the ball's, the top inset is the system clock's, and
anywhere else pushes a sentence out of the place the board puts it. A third
line of text is also the thing this screen has spent two tickets not having.

**A chevron on a half.** `StartSettings` draws the one chevron in the app and
says at length why it is the only one. A chevron means *this leads somewhere*;
a half does not lead anywhere, it starts the match.

**A first-run coach mark.** Honest and cheap, and an admission that the screen
is not self-evident. Keep it in reserve behind even the capsule.

## Notes

**Where the code is.** `padel Watch App/StartView.swift` — `half(_:clearing:)`
for the gesture and the light, `ball` for the ball, `Board` for whatever new
numbers this needs. The court primitives it draws with are
`PadelDesign/Court/`: `CourtHalf`, `NetLine`, `Ball`, `Floodlight`.
*(As built: `half(_:)` takes no clock, the press lives in the `ServeCapsule`
button style, and the capsule's look comes from `PadelDesign`'s
`choiceCapsule(isChosen:restingInk:isRingedAtRest:)`.)*

**Where the press state belongs.** Probably in `StartView` and not in
`PadelDesign`: `CourtHalf` is "one half of the court, seen from above" and
knows nothing about a rally, let alone about a finger. If the lift turns out to
be worth a token — a weight on the ramp, or a brightness step — that token goes
in `Tokens/`, and the state stays here.

**~~`contentShape(Rectangle())` must stay.~~** Retired: the half stopped being
the target, so there is nothing on it to shape. The capsule takes the hit test
instead, as the rounded shape itself rather than its bounding box.

**The ball must stay out of the hit test.** It is `.allowsHitTesting(false)`
today, and it is about to move across the net — a ball that swallowed a tap on
its way past would be a ball that decides who serves.

## Comments

**Built, then reworked on the owner's call: the fallback capsule is the plan.**
The four changes went in first and were shown on a simulator; three of them
were rejected there and the capsule this ticket held in reserve was drawn
instead.

**What the screen is now.** Each half carries its sentence in a rounded capsule
— `ink` at `surface` behind it, a 1pt `ink`-at-`strong` border around it —
standing the same distance from the net on both sides, so the pair reads as
centred on the net with the ball in the gap between them. Pressing a half turns
its capsule into what `ChoiceCapsule` draws for a chosen option: `ballWash`
behind a `ball` label inside a `ball` ring. One floodlight over the whole
court, as before this ticket.

**What was rejected, and what replaced it:**

- *Two lights, one per half.* They did not read as two objects. Reverted to the
  board's single top-leading light at 0.17.
- *The pressed half lighting up.* The whole-half wash is gone; the press shows
  on the capsule alone.
- *The sentences where the board puts them,* a fifth down each half. They are
  anchored to the net now, `netGap` = 16 either side, and grow away from it, so
  the gap the ball leans in stays fixed as the type grows. This is the one
  departure from "the two sentences keep their wording and their place": the
  wording is untouched, the place moved.

**Dynamic Type.** Anchored to the net, their capsule grows toward the clock and
at the top of the range reached it. The sentences are capped at
`.accessibility2` — a ceiling, not a fixed size. Screenshotted at `.xSmall` and
at the cap in both languages: the Russian pair takes two lines and stops 6pt
clear of the clock, the English does the same.

**What survived the rework, and how it was checked:**

- **The gesture.** A zero-distance `DragGesture` per half, `@GestureState` for
  which half is under the finger, release inside the half starts the match. A
  press dragged from our half to theirs starts nothing — `isOn(_:_:)` rejects
  a touch that has left the bounds or travelled past 10pt.
- **The haptic** is `.sensoryFeedback(.start, trigger: chosen)`, hung on the
  chosen half rather than on the call to `onStart`: a view torn down in the
  same update never plays its feedback, and the screen stays up while the ball
  travels. **No simulator has a Taptic Engine**, so this one was written and
  not heard.
- **The ball.** Leans 4pt into each half in turn, 1.6s each way — sampled
  across six screenshots its centre runs 214.6 to 229.0, the 8pt asked for. On
  release it crosses to the chosen half's inner corner in 0.28s and halves in
  size, landing where the score screen keeps the first serve: (339.5, 258.4)
  measured there against (339, 256.4) aimed at here, one point nearer the net,
  which is half the net's tape.
- **The match is held back for the length of the travel,** so that the journey
  is drawn somewhere. Gone under Reduce Motion.
- **Reduce Motion.** Ball dead still at y=222.49 across three screenshots, and
  a release goes straight to the score screen with nothing travelling.
- **VoiceOver.** `axe describe-ui` finds exactly two elements, an `AXButton`
  per half at `{0,0}–{187,110.5}` and `{0,112.5}–{187,110.5}`, labelled
  "Opponents serve" and "We serve"; the ball is not in the tree. An explicit
  default `accessibilityAction` was added — VoiceOver activates an element
  rather than touching it, and a drag gesture is not something it can
  activate, so without it a blind player would have had two buttons that did
  nothing.
- **Not a word added.** No string was written or moved.

**Left to a wrist:**

- **The paging.** No CLI swipe reaches a watch `TabView`. The control is that
  the same `axe drag` run on the untouched score screen scored a point instead
  of paging, so the start screen's refusal to page under it says nothing about
  the gesture. Swipe down the court on the device: the settings page must
  still arrive, and no match may start on the way. **If the paging is dead the
  fix is one word:** `simultaneousGesture` in place of `gesture` in
  `half(_:)`, which leaves the `TabView`'s own recogniser alone and leans on
  the 10pt slip.
- **The haptic**, for the reason above.
- **Whether the capsules do the job.** They are this ticket's own fallback and
  they cannot fail in the sense it means — a bordered capsule is a button
  anywhere — but only a first glance on a wrist says whether the screen now
  asks its question plainly.

**After the wrist: the paging was dead, and the travel is gone.** Two findings
from the owner, and both supersede what is written above.

- **The swipe did not reach the settings page.** The zero-distance
  `DragGesture` took the court outright, exactly as the note above warned it
  might. `.gesture` is now `.simultaneousGesture`, which leaves the `TabView`'s
  own recogniser in place; the 10pt slip in `isOn(_:_:)` is what keeps a swipe
  that pages from also starting a match, and scrolling begins at about that
  distance. **Still unchecked:** the fix cannot be tried from the CLI either,
  so the swipe wants one more go on the wrist.
- **The ball no longer travels.** The match screen is up the moment the finger
  lifts, so there was nowhere to draw the journey — the screen was being held
  back for a quarter of a second to draw an animation nobody could see through
  to its end. `chosen`, the travel, the corner and the two numbers behind them
  are deleted; the ball leans and does nothing else. The first half of that
  criterion — the ball saying both halves are live — stands; the second was
  retracted.
- **The haptic moved to `WKInterfaceDevice.current().play(.start)`.** With the
  travel gone, `.sensoryFeedback`'s trigger would change in the same update
  that replaces this screen, and a view being torn down never plays its
  feedback. The imperative call fires before the screen goes. Still unheard on
  a simulator.

**Second wrist: the press state is out, and so is the haptic.**
`simultaneousGesture` did not save the paging either — the page below still did
not arrive, and the capsule lit up under a swipe passing over it. Three of the
ticket's criteria go with it.

- **What is left is `onTapGesture`,** which is the gesture this screen shipped
  with and the one the score screen has paged alongside since ticket 04. A
  tracked finger and a paging `TabView` want the same touches, and on this
  screen the paging wins: whatever holds the press — a `DragGesture` either way
  round, or a `Button` with a style — is a thing that takes the swipe. So there
  is no pressed state, and the capsule is static.
- **The haptic is back.** It was taken out as "the sound at the start of a
  match" and put back once that turned out to be what it was: a `WKHapticType`
  is a tap and a click together, and a simulator, having no Taptic Engine,
  plays only the click. `.start` is the type; `.click` is the quieter one if
  the tap ever wants to be smaller. Silent Mode leaves the tap and drops the
  sound — there is no API that does that.
- **What the affordance rests on now** is the capsule alone: a bordered chip
  around each sentence, which is the ticket's own fallback and the thing it
  said cannot fail.
- Checked after the cut: a held finger changes nothing on screen (the label's
  pixel is `#F6FEFB` before and during), a release starts the match, the ball
  still leans, and `axe describe-ui` still finds exactly two buttons, one per
  half. `StartView.swift` is 255 lines, down from 410 two rounds ago.

**Third try, and the one that works: a `Button` with a `ButtonStyle`.** The
ticket's own "must not become" list did not forbid this — what it forbids is a
separate "Start" button — and the doc comment inherited from ticket 04 warned
that a half which is a button starts a match out of a swipe. That warning is
wrong, and this is what was measured instead.

- **The half is a `Button`, the sentence is its label, and `HalfButton`, a
  `ButtonStyle`, draws the court half and the capsule around it.** The pressed
  state comes from `configuration.isPressed` — the platform's own answer to a
  press inside something scrollable, where the scroll *cancels* the press
  rather than competing with it. Yellow is back: pressed, the capsule is what
  `ChoiceCapsule` draws for a chosen option.
- **The paging is verified, not reasoned about.** `axe drag` up the court now
  reaches the settings page — the ruleset row and the Health switch in the
  accessibility dump — and no match starts; a drag back down returns to the
  court; a drag beginning over their half starts nothing either. **This also
  corrects the note above:** the CLI *can* page a watch `TabView`. It could
  not before because whatever gesture was on the half swallowed the drag
  first — which is why the same drag scored a point on the score screen.
- **The accessibility tree came out cleaner.** Two `AXButton`s, one per half,
  labelled by their sentences, and no `AXStaticText` mirroring them: the
  button owns its label, so none of the traits are put on by hand any more.
- The haptic, the leaning ball, the type ceiling and the capsule's geometry
  are untouched by this round.

**And then the target shrank to the capsule.** With the half as the button, a
thumb anywhere on the court lit a capsule it was nowhere near, which the owner
read as the light meaning nothing. The `Button` is now the capsule alone — its
two paddings moved outside it, so they position it without growing what the
finger can hit, and `contentShape(RoundedRectangle(…))` keeps the corners
court. This is a departure from the ticket's "the whole half is the control",
and from the spec's "hitting your own half has to work without looking": that
argument is the score screen's, where a rally is scored mid-point with a wet
hand, and this screen is tapped once before anything has started.

- The two targets are `{39.5, 43.5} 108×51` and `{38, 128.5} 111.5×30.5`,
  which is watch-sized — the system's own buttons are about 30pt tall.
- A finger on the bare court lights nothing and starts nothing; on the capsule
  it lights and the release starts the match.
- **The paging is nearly as good, and the exception is worth knowing.** A
  swipe beginning anywhere on the court pages every time. One that begins on
  the capsule pages when it is brisk and does not when it is slow — a slow
  drag off a button reads as a press the button then cancels. No match starts
  either way, which is the property that matters.

**After review: the capsule's look moved into `PadelDesign`.** A two-axis
review of the commit found the start screen hand-drawing what `ChoiceCapsule`
already draws — `ballWash`, a `ball` label, a `ball` ring, the `.segment`
radius — which is the drift ADR-0006 exists to stop, plus a `capsuleBorder`
number restating `ControlMetrics.segmentRing`.

- `choiceCapsule(isChosen:restingInk:isRingedAtRest:)` is now public on `View`
  in `Controls/ChoiceCapsule.swift`, and both capsules go through it.
  `ChoiceCapsule` itself stays internal: the start screen's capsule is not one
  — it is `display` rather than `control`, and it hugs its sentence rather
  than filling a column — so what is shared is the look and not the control.
- The two parameters are the two honest differences. `restingInk` is the ink
  on `night` in a card against the court's own ink on a half; `isRingedAtRest`
  is false among a column of capsules, which explain each other, and true on
  the court, where nothing else says the thing is a control. The resting ring
  is `strong` and not `hairline` — the weight the vocabulary keeps for a
  border — because 0.12 of the ink disappears on a lit court; that argument
  now lives beside the ring.
- Also from the review: a dangling doc reference to a `HalfButton` that no
  longer exists, "server" where `CONTEXT.md` says serving side, a `makeBody`
  that only unpacked its configuration, and two comments retelling this
  ticket's history — all fixed. The package's tests and the watch build are
  green, and the screen is pixel-for-pixel what it was.
