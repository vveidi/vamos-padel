# Watch tap mode: how a touch becomes a rally, and what the wrist says back

Status: ready-for-agent

## Problem Statement

The watch's score screen is two halves of a court, and the half you hit is the
side that scores. It asks the player to aim. A 40mm screen, a wet hand, a racket
in the other one, and a glance that has to land on the right half before the
finger does — that aim is the cost, and it is paid on every rally.

The screen also says nothing back. A tap is confirmed by a digit changing, which
means confirmation requires looking, which is the thing the player was trying not
to do.

This feature gives the score screen a second way of being tapped — one tap for
our point, two for the opponents', anywhere on the glass — and gives the wrist
four distinct haptics so that what happened is felt rather than read.

## What is in, and what is not

In:

- **Tap mode**: a watch-only preference with two values, *multi-tap* and *tap
  zones*, stored across matches and reachable both before a match and during one.
- **The four haptics**: our point, their point, undo, and the confirmed End —
  in both modes.
- **The match's pages turn vertical**, three of them, to make room for the
  tap-mode page without spending a swipe on the one that ends the match.
- **A board** for all of it, drawn before any of it is built.

Not in:

- **The phone's scoreboard.** It keeps its two tappable halves. It is read from
  a bench by four people at a distance, which is the opposite of the problem
  here, and `phone-scoring` ticket 07 has not built it yet in any case.
- **A haptic when the match ends by itself.** The last rally has already buzzed;
  a second buzz on top of it is two answers to one tap. `.stop` fires on the
  confirmation button and nowhere else.
- **An app-level switch for haptics.** watchOS has a system one.
- **Anything for VoiceOver.** Tap mode never reaches the accessibility layer —
  see the decision below, which is a decision to write no code.
- **A haptic on the start screen's serve capsules.** `.start` already plays
  there and is unchanged.

## The design, in words

**Multi-tap** ignores where the finger lands. One tap awards us the rally, two
award it to the opponents, a long press undoes the last one. **Tap zones** is
what the screen does today: the opponents on top, us at the bottom, the half you
hit is the side that scores, long press undoes. Multi-tap is the default.

The court is drawn identically in both. Which number is ours is said by the
ground it stands on — turf green against glass blue — and that is how the score
is *read*, independently of how it is *entered*. Changing tap mode must not move
a digit, or every change costs the player a re-orientation on court.

The setting lives in two places and is one component in both: a `ChoiceRow`
naming its value and pushing a list of the two, with three lines under it
spelling out the gestures of whichever value is selected.

| Multi-tap            | Tap zones                |
| -------------------- | ------------------------ |
| 1 tap → your point   | tap bottom → your point  |
| 2 taps → their point | tap top → their point    |
| long press → undo    | long press → undo        |

Those lines are the only place in the app where an invisible gesture is ever
stated, and they change as the pills are changed, which demonstrates the choice
as well as describing it. Multi-tap counts taps and tap zones places them; the
asymmetry between the two columns is informative, so tap zones is not given
counts it does not need.

## Solution

### The mode

A `TapMode` with two cases, held in `@AppStorage` on the watch beside
`records-to-health`. It is a preference about the app: no match records which
mode was in force, nothing about a match can be asked for it, and it never
crosses the live link. Changing it takes effect on the running match at once,
and on every match after it.

### Where it is reached

Before a match: a card on `StartPages`' settings page, between the rules and the
Health switch — it is about the match being set up, and the Health switch is the
page's odd one out and reads best last.

During a match: `ScorePages` turns `.verticalPage`, the arrangement `StartPages`
already uses, with three pages — **End** above, **score** in the middle and
still what opens, **tap mode** below. A `NavigationStack` goes around the pages
so the row has somewhere to push its list, bar *not* hidden: the score page has
no title and reserves no bar, the tap-mode page is titled and gets one, and the
End page stays as it is.

### The haptics

Four, fired from `MatchView`'s `record(rallyWonBy:)` and `undo()` — the funnel
every path already goes through — plus the confirmation button on the control
page.

| what happened  | haptic            |
| -------------- | ----------------- |
| our point      | `.directionDown`  |
| their point    | `.directionUp`    |
| undo           | `.retry`          |
| End confirmed  | `.stop`           |

`.start` and `.stop` now bracket the match.

### The trailing edge

`.verticalPage` draws its page indicator on the trailing edge, level with the
middle of the screen. That is occupied twice on the score screen: the sets digit
sits at `.trailing`, and the serve ball's inner corners are `.topTrailing` in our
zone and `.bottomTrailing` in theirs. All of it is indented to clear the
indicator, by a number read off a screenshot of a real screen rather than
reasoned to.

## Implementation Decisions

### The framework owns the double-tap wait

`.onTapGesture(count: 2)` chained before `count: 1`, so the single tap is
dispatched only once the system has decided no second one is coming. No timer of
ours. Three things are verified before anything else is built, because SwiftUI
has a history here: that the single is genuinely suppressed on a double rather
than fired first, that `.onLongPressGesture` still coexists once two counts are
attached, and what the window actually is — it is Apple's and not tunable. If
that fails the fallback is `.exclusively(before:)` or our own timer, and nothing
in this design changes either way.

### VoiceOver never sees tap mode

Under VoiceOver a single tap moves focus and a double tap activates, so the
gesture multi-tap is built on is already spoken for. Making it work anyway would
mean `.accessibilityDirectTouch()` — which stops the screen speaking, the only
way a player had to read the score — or collapsing the two zones into one
element with rotor actions, which is tap zones with one zone. Both are more work
than doing nothing, and doing nothing is correct: the two halves are already
separate accessibility elements with labels, values and an undo action, and they
go on behaving as zones in both modes.

### The haptics fire from the funnel, not from the gesture

The buzz answers the finger, not the journal — but `MatchView`'s two methods are
the same millisecond as the gesture today, and stay the same millisecond after
`phone-scoring` ticket 09, where the intent is sent and not awaited. Firing from
there rather than from the gesture recognizers costs nothing and picks up the two
paths that would otherwise be silent: the VoiceOver action, and the undo on the
outcome screen after a match-ending mis-tap.

The consequence to accept is that a refused intent will have buzzed before the
refusal arrives. That is ticket 09's to answer with feedback of its own; making
the watch feel slow on every accepted tap to be honest about the rare refused one
is the wrong trade.

### A `Settings/` folder, and it is an exception

The type, the component and the mid-match page go in `Padel Watch App/Sources/
Settings/`. The watch app's folders are otherwise named for what the player is
doing — `Start`, `Match`, `Workout` — and this one is named for a screen.
CLAUDE.md's table gains the row and says so; `StartSettings` stays in `Start/`
and uses the component, because moving it would split the start pages across two
folders for nothing.

### A board first, and it is not a `/next-ticket`

Ticket 01 draws three artboards, and one of them is the score screen that already
ships — what is being drawn there is a new object on its trailing edge, and that
is a layout question a board answers and an argument does not.
`docs/design/README.md` says a board exists only for a screen that has not been
built and is deleted when it ships; all three are deleted as their tickets close,
and the README's "Two artboards" goes to three and back again.

## Consequences, stated plainly

- **Two quick taps meant as two of our points award one to the opponents.** This
  is the default mode, so it is the default hazard. The answer is the long press,
  which is one gesture to fix a mistake that any confirmation would tax every
  rally to prevent.
- **Forty buzzes a match**, in both modes. Deliberate: the wrist is the feedback
  channel that does not require looking, and that is the whole point.
- **The haptics cannot be judged in a simulator**, which has none. The pair
  `.directionUp`/`.directionDown` is provisional until it is felt: two people on
  a court, blind, telling which side just scored. If they are indistinguishable
  the fallback is `.click` for us and `.notification` for them.
- **Two doc comments become false and are rewritten.** `ScoreView.swift`'s serve
  indicator justifies its inner corners partly by "the page dots of `ScorePages`
  sit over our bottom", which the vertical stack ends; and `StartView.swift`'s
  "a match starting is worth one, a rally scored is not" is precisely what this
  feature reverses.
- **`phone-scoring` ticket 09 will touch the same two files.** It changes where a
  tap goes, not how it is made; the overlap is a merge in `ScoreView` and
  `ScorePages`, not a redesign.

## The tickets

```
01  the board
02  the four haptics
03  the gesture and the stored setting
04  the vertical match stack and the tap-mode page
05  the card on the start settings page
```

02 depends on nothing and can be taken first. 01 blocks 03; 03 and 01 block 04;
05 waits on both 03 and 04, because it is the component built in 04 put in a
second place.
