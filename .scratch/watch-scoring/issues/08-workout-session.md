# 08: The match as a workout

**What to build:** The match is registered as a workout, and the app starts surviving an hour and a half of play. The system stops unloading it from memory between games, the screen works in Always-On, and raising the wrist brings the player back to the score rather than to the watch face.

The side benefits come for free: the match lands in the activity rings and in Health, and heart rate and calories are written by themselves.

The session starts with the match and ends with it. HealthKit permission is requested on first launch, with an honest explanation of why a match counter needs access to health.

**Blocked by:** 02

**Status:** done

- [x] The match runs inside a workout session from beginning to end
- [x] HealthKit permission is requested once, with an understandable explanation
- [x] If permission is denied the match can still be played and the app does not crash
- [x] The score screen stays visible in Always-On
- [x] Raising the wrist returns to the score screen
- [x] The session ends with the match, including when it is stopped early
- [x] After the match the workout is visible in Health

## Comments

### What was built

The match acquires a workout in `MatchView`: it starts with the match and ends with it. The
rule itself is written in one line — `state.outcome == .inProgress` — and deliberately not
through "there is a winner": a match stopped early will become a third outcome in ticket 09,
and the workout has to end with it without waiting for that line to be edited.

`HKWorkoutSession` is hidden behind a `Workout` protocol for the same reason the store and the
transport sit behind protocols (ADR-0002): the screens must know nothing about health. The
immediate benefit is the previews: `NoWorkout` asks for no Health access and writes nothing
there, whereas otherwise the canvas would demand permission and create a workout every time it
was opened.

`HealthKitWorkout` is a thin wrapper, not covered by tests (as decided in the spec). What it
adds of its own are two promises. First: no HealthKit failure reaches the match — health being
unavailable, permission not being granted, and a session dying mid-game all produce a line in
the log and nothing more. Second: a workout is either running or not; starting and ending are
lined up in a queue, otherwise an undo on the outcome screen would manage to start a new
workout before the previous one had ended.

The build: `WKBackgroundModes = workout-processing` (without it the system would unload the
app between games and would not enable Always-On), the HealthKit entitlement, and
`NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` — the very explanation of
why a match counter needs access to health. For the sake of the array in `WKBackgroundModes`
the watch target got an `Info.plist` of its own for the first time: `INFOPLIST_KEY_*` cannot
generate arrays. The file is excluded from Copy Bundle Resources through the synchronized
group's exception set — otherwise the build fails on two commands producing the same
`Info.plist`.

**Workout** was added to the glossary.

### Decisions departing from the ticket

- **The workout type is tennis.** Padel is not among `HKWorkoutActivityType` (checked against
  the watchOS 26.5 SDK headers), and tennis is the closest: the same racket doubles court, the
  same estimate of effort. In Health the match will appear under the word "Теннис".
- **The court counts as indoor** (`locationType = .indoor`). We do not measure distance, and
  `.outdoor` would wake the GPS for an hour and a half for nothing.
- **An undo on the outcome screen starts a new workout.** Ticket 05 allows a match finished by
  a mistaken tap to be brought back into play — and an ended workout cannot be restarted. What
  is left in Health is two records instead of one. The price is accepted deliberately: the
  alternative is playing the match out without Always-On and without protection from being
  unloaded, that is, exactly what this ticket is against. There is as yet no explicit "the
  match is over" in the app by which the workout could be closed once; that arrives in ticket
  09.
- **The score screen was not touched.** The Always-On criterion is met by the workout itself;
  tuning the brightness against `isLuminanceReduced` was not done — there are no animations
  and no per-second values on the screen, and the brightest thing on it is the very score the
  criterion was written for.

### What the agent checked

- Both targets build, and the package's 68 tests are green.
- In the built watch bundle: `WKBackgroundModes = [workout-processing]`, both
  `NSHealth*UsageDescription` in place, the Xcode-generated keys not lost, and the
  `com.apple.developer.healthkit` entitlement present in the signature.
- On a 46 mm simulator the app launches and asks permission for exactly what is declared:
  writing the workout and active calories, reading heart rate and active calories (visible in
  the HealthKit log).
- The score screen lives behind the permission dialog: the app neither crashes nor waits for
  an answer before showing the score.

### What is left to check by hand

The agent could not press the permission dialog — the Simulator still does not hand out its
window, and synthetic taps do not reach the app (the same wall as in tickets 04 and 05).
Everything behind that dialog is unchecked:

1. Grant access — the workout starts and the match runs.
2. Relaunch the app — the permission dialog no longer appears.
3. Deny access (on a clean install) — the match is played all the same and the app does not
   crash.
4. **On a device:** lower your wrist mid-match — the score stays on the screen.
5. **On a device:** raise your wrist — the score comes back, not the watch face.
6. Play a match out to the end — the workout appears in Health.

Points 4 and 5 cannot be reproduced by the simulator at all: Always-On and raising the wrist
exist only on the watch.

### Checked by hand, 5 September 2026

The owner ran the six checks left above on a real watch and confirmed all of them: the
permission dialog and what lies behind it (granted, relaunched, denied on a clean install),
the wrist lowered and raised mid-match, and the workout appearing in Health after a match
played out. That is the whole of what the agent could not reach — Always-On and raising the
wrist do not exist in the simulator at all — so the ticket is closed on the owner's word for
those, and on the agent's checks above for everything else.

One criterion had shifted since the note above was written. "The session ends with the match,
including when it is stopped early" was described here as waiting for ticket 09, which had no
early stop yet. Ticket 09 landed, and the workout needed no edit to follow it: `MatchView`
closes the workout on `state.outcome == .inProgress` turning false, and an abandoned match is
exactly that — the line the note called "deliberately not through «there is a winner»" paid
for itself. Verified by reading the wiring, and by the owner stopping a match early on the
watch.
