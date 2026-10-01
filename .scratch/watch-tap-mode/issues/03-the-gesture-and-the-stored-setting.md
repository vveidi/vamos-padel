# 03: The gesture and the stored setting

**What to build:** the mode itself — a `TapMode` the watch remembers, and a score
screen that awards a rally by it. Multi-tap is one tap for our point and two for
the opponents', wherever the finger lands; tap zones is what the screen does
today. No screen to change it yet: that is 04 and 05.

**Blocked by:** 01

**Status:** done

## Verify the gesture before building anything else

This is the first criterion and it is a fork in the road, not a formality.
SwiftUI has a long history of firing both tap handlers here.

- [x] On a watch (simulator is enough for this one), with
      `.onTapGesture(count: 2)` chained **before** `.onTapGesture(count: 1)`:
      a single tap fires only the single handler, a double fires only the
      double, and `.onLongPressGesture(minimumDuration: 0.5)` still recognizes
      alongside both
- [x] The wait before a single tap is dispatched is measured and written into
      the closing note. It is Apple's and not tunable; the number matters
      because it is the lag on every point to us
- [x] If any of that fails, fall back to `.exclusively(before:)` or an explicit
      timer, and say which in the closing note. The design does not change

## The rest

- [x] `TapMode` lives in `Padel Watch App/Sources/Settings/`, two cases —
      multi-tap and tap zones — `String`-backed so `@AppStorage` can hold it,
      with a doc comment saying what each case does to a touch
- [x] `@AppStorage("tap-mode")` on the watch, defaulting to **multi-tap**,
      beside `records-to-health` and for the reason `RootView` gives there: it
      is a preference about the app, not a fact about padel
- [x] It reaches `ScoreView` from `RootView` through `MatchView`, and a change
      takes effect on the running match at once
- [x] In multi-tap the gesture is on the whole screen and ignores which half was
      hit: one tap awards `.us`, two award `.them`. A double tap landing on our
      green half awards the opponents — the halves are not buttons in this mode
- [x] In tap zones the two zones behave exactly as they do today
- [x] The long press undoes in both modes
- [x] The court is drawn identically in both modes — no digit, ball, line or
      color moves when the mode changes
- [x] Both zones keep their accessibility element, label, value and
      "Undo the last rally" action in both modes, and tap mode changes nothing
      about them
- [x] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean

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

## Comments

**Why multi-tap is the default.** Tap zones makes the player aim on every rally:
a 40mm screen, a wet hand, a racket in the other one, and a glance that has to
land on the right half before the finger does. Multi-tap needs no glance at all,
and with the four haptics from 02 it needs no look afterwards either. Its price
is the two-quick-taps hazard below, which costs one long press when it happens;
aiming costs something on every point.

**The gesture held, and no fallback was needed.** Verified on a watchOS 26.5
simulator, with taps driven by AXe and timed from the app's own log:
`.onTapGesture(count: 2)` before `.onTapGesture(count: 1)` and
`.onLongPressGesture(minimumDuration: 0.5)` on one view — a single tap fired the
single handler only, a double fired the double only, and a long press fired the
undo only.

**The wait is 350 ms**, from the single tap's release to its dispatch, the same
in every run (350–352 ms). That is the lag on every point to us. A tap zone
dispatches within 1–13 ms of release.

**What shipped is the same chain, switchable.** The two counts became
`.gesture(TapGesture(count: 2)…, isEnabled:)` then `.gesture(TapGesture()…,
isEnabled:)` on the whole screen, enabled in multi-tap only; the zone's own tap
is the same modifier, enabled in tap zones only. The long press stays on each
zone, as it was, so it sits one level below the multi-tap taps rather than on
the same view. All of it was driven again in its shipped form: one tap on their
half → us after 350 ms, two on our half → them, one on the net → us, a long press
→ undo and nothing else; in tap zones, each half scores for itself at once, two
taps on top are two of their points, a long press undoes.

**One line of VoiceOver code, despite "a decision to write no code".** Turning the
zone's tap off in multi-tap would also take away the activation VoiceOver derives
from it, so each zone now states its default action — `onRallyWon(side)` —
explicitly. Labels, values and the undo action are unchanged and read the same in
both modes. The activation itself could not be exercised from the CLI; it is
ticked on reasoning, not evidence.

**A second hazard, found while measuring: 06.** A second tap that goes down
inside the window but lifts after it is swallowed — no point to anyone. It is
filed as `needs-triage` because it is a decision, not a fix.

**Checked otherwise.** The setting was flipped with `defaults write` while a
match ran and took effect at once; screenshots in the two modes are
byte-identical; with no stored value the mode is multi-tap. `RootView` gives no
reason beside `records-to-health` to sit next to — neither line carries a
comment — so `tap-mode` sits beside it without one: the reason, a preference
about the app and not a fact about padel, lives in the spec. `CLAUDE.md`'s folder
table gains `Settings/`.
