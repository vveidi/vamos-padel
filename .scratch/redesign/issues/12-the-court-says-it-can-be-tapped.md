# 12: The court says it can be tapped

**What to build:** the two halves of the start screen, made to read as the
control they already are — without putting furniture on the one screen that has
none.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] A half answers the finger: it lifts while pressed and starts the match on
      release, so a tentative press teaches the screen instead of committing to
      a match
- [ ] A press that leaves the half — dragged across the net, or off the court —
      starts nothing
- [ ] The paging survives: a swipe down the court still reaches the settings
      page without starting a match, which is the whole reason `StartView` uses
      a gesture and not a `Button`
- [ ] Starting a match plays a haptic
- [ ] The ball says both halves are live before anything is touched, and on the
      tap it travels to the chosen half's corner — where the score screen keeps
      it
- [ ] Under Reduce Motion nothing travels and nothing breathes: the ball sits
      on the net as it does today, and the press state is the whole of the
      feedback
- [ ] Each half carries its own light, so the screen reads as two objects
      rather than one picture of a court
- [ ] Not one word is added to the screen, and the two sentences keep their
      wording and their place
- [ ] VoiceOver still finds exactly two elements — "We serve" and "Opponents
      serve" — each a button, and the ball is still not one of them
- [ ] Both languages and both ends of the Dynamic Type range still hold
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

**Where the press state belongs.** Probably in `StartView` and not in
`PadelDesign`: `CourtHalf` is "one half of the court, seen from above" and
knows nothing about a rally, let alone about a finger. If the lift turns out to
be worth a token — a weight on the ramp, or a brightness step — that token goes
in `Tokens/`, and the state stays here.

**`contentShape(Rectangle())` must stay.** Without it the tap catches the
painted surface but not the weave and the lines over it, which is a note
already in the file.

**The ball must stay out of the hit test.** It is `.allowsHitTesting(false)`
today, and it is about to move across the net — a ball that swallowed a tap on
its way past would be a ball that decides who serves.
