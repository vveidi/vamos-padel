# 03: The gesture and the stored setting

**What to build:** the mode itself — a `TapMode` the watch remembers, and a score
screen that awards a rally by it. Multi-tap is one tap for our point and two for
the opponents', wherever the finger lands; tap zones is what the screen does
today. No screen to change it yet: that is 04 and 05.

**Blocked by:** 01

**Status:** ready-for-agent

## Verify the gesture before building anything else

This is the first criterion and it is a fork in the road, not a formality.
SwiftUI has a long history of firing both tap handlers here.

- [ ] On a watch (simulator is enough for this one), with
      `.onTapGesture(count: 2)` chained **before** `.onTapGesture(count: 1)`:
      a single tap fires only the single handler, a double fires only the
      double, and `.onLongPressGesture(minimumDuration: 0.5)` still recognizes
      alongside both
- [ ] The wait before a single tap is dispatched is measured and written into
      the closing note. It is Apple's and not tunable; the number matters
      because it is the lag on every point to us
- [ ] If any of that fails, fall back to `.exclusively(before:)` or an explicit
      timer, and say which in the closing note. The design does not change

## The rest

- [ ] `TapMode` lives in `Padel Watch App/Sources/Settings/`, two cases —
      multi-tap and tap zones — `String`-backed so `@AppStorage` can hold it,
      with a doc comment saying what each case does to a touch
- [ ] `@AppStorage("tap-mode")` on the watch, defaulting to **multi-tap**,
      beside `records-to-health` and for the reason `RootView` gives there: it
      is a preference about the app, not a fact about padel
- [ ] It reaches `ScoreView` from `RootView` through `MatchView`, and a change
      takes effect on the running match at once
- [ ] In multi-tap the gesture is on the whole screen and ignores which half was
      hit: one tap awards `.us`, two award `.them`. A double tap landing on our
      green half awards the opponents — the halves are not buttons in this mode
- [ ] In tap zones the two zones behave exactly as they do today
- [ ] The long press undoes in both modes
- [ ] The court is drawn identically in both modes — no digit, ball, line or
      color moves when the mode changes
- [ ] Both zones keep their accessibility element, label, value and
      "Undo the last rally" action in both modes, and tap mode changes nothing
      about them
- [ ] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean

## Notes

**Why nothing can change the mode yet.** The row that changes it is 04's, and
this ticket ships with multi-tap as the default and no way back to tap zones. That
is fine between two tickets and is not fine at the end of the feature — 04
follows immediately.

**VoiceOver never sees any of this.** Under VoiceOver a single tap moves focus and
a double activates, so multi-tap's gesture is already spoken for. The two zones go
on being two zones in both modes, and that is a decision to write no code: the
elements, labels, values and undo action already exist. Do not reach for
`.accessibilityDirectTouch()` — it would stop the screen speaking, which is the
only way a player has to read the score.

**The hazard this mode ships with.** Two quick taps meant as two of our points
award one to the opponents. It is known, it is the price of the default, and the
long press is the answer; no confirmation is added, because any confirmation taxes
every rally to defend against a mistake that costs one gesture.

**For the closing note:** say why multi-tap is the default. It is the one decision
in this feature a future reader will question, and this note is its only home.
