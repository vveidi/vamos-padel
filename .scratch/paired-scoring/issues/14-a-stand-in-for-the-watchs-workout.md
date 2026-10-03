# 14: A stand-in for the watch's workout on a simulator

**What to build:** a paired start from the phone cannot be driven on a
simulator. `WatchWorkout.authorize()` raises the system's Health sheet, which
neither the UI automation nor `simctl privacy` can reach — only a person can
close it. Past it, `start()` waits for the watch's mirrored workout, which a
simulator pair may never deliver.

A debug-only launch argument, `-PadelFakesTheWatchWorkout`, makes
`WatchWorkout` answer without HealthKit, so an agent can start a paired match
from the phone's own start screen and drive the rest as usual.

**Blocked by:** —

**Status:** ready-for-agent

- [ ] **Debug builds only.** The argument is read under `#if DEBUG`; a release
      build has no way to skip Health
- [ ] **No Health, no wait.** With the argument, `authorize()` answers granted
      without asking and `start()` answers `.started` at once. Nothing touches
      `HKHealthStore`, and the Health sheet never appears
- [ ] **Everything past the start is the real thing.** The scorer starts the
      match paired, and the watch takes it up over the live link, as it does
      for a start from the wrist
- [ ] **Without the argument nothing changes.** The real flow — the sheet, the
      watch's app launched, the mirrored session awaited — is untouched
- [ ] **Agents can find it.** `docs/agents/targets.md`, or wherever a session
      looks up how to drive a pair, names the argument and the `simctl launch`
      line that passes it
- [ ] Driven on a simulator pair: a paired match started from the phone's start
      screen with the argument, the watch on it, a rally scored from the wrist

## Notes

Found while driving ticket 11, whose paired run had to be started from the
watch: the phone's own paired start stopped at the Health sheet.

The stand-in proves the score's path, not Health's. Whether the sheet, the
watch's app launch and the mirrored session behave is ticket 07's, on a real
pair, and a simulator could not show it anyway. Pre-granting Health in the
simulator's database was considered and left: it is fragile, and it would only
clear the first of the two steps.
