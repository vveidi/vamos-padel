# 04: The workout mirrors, and the phone stays awake

**What to build:** the watch's workout starts mirroring to the phone, the phone
holds the mirrored session for the length of the match, and a match started on
the phone raises the watch app into that workout.

**Blocked by:** 02, 03

**Status:** needs-triage

- [ ] `HealthKitWorkout` calls `startMirroringToCompanionDevice()` when the
      session starts and stops mirroring when it ends
- [ ] The phone subscribes to `workoutSessionMirroringStartHandler` when the app
      is assembled — before any screen exists, for the reason `MatchReception`
      subscribes early today: the app is launched into the background for this
      and there may be no screen at all
- [ ] The phone holds the mirrored session for as long as the match runs and
      lets go when it ends
- [ ] Starting a match on the phone with no watch app running calls
      `HKHealthStore.startWatchApp(with:)` and waits for the watch to appear;
      the match starts either way, and the watch joins when it can
- [ ] The phone target gains the HealthKit capability, the two usage strings in
      its `Info.plist`, and both of them in the catalog in both languages
      (ADR-0005 — the English string is the key)
- [ ] Authorization is asked for once, at the moment a match is first started,
      not at launch
- [ ] Refusing Health does not refuse the match: no session means no background
      life, and the consequence is stated in the ticket's note below, not
      papered over
- [ ] The "Recording to Health" switch now governs whether the workout is
      **saved**, not whether a session runs
- [ ] Driven on a live pair as part of ticket 07; the simulator cannot see any
      of this

## Notes

**On the switch changing meaning.** The spec records it: with the match on the
phone, no workout means no mirrored session and no background life, so the
session has to run regardless. What the player was actually turning off was a
row in Health, and that is what the switch keeps doing. The wording on the start
screen may need to change with it — check it against the string, not against
this sentence.

**On Health being refused.** A player who says no to Health gets a match that
lives only while the phone's screen is on. That is a real degradation and it
belongs in the open, not behind a silent retry: the scoreboard should say that
backgrounding will stop the match. Whether it says it once or every time is the
owner's call — raise it in the closing note rather than inventing a dialog.

**On `startWatchApp(with:)` taking a workout configuration.** It launches the
watch app into a workout, which is precisely what is wanted here — the
configuration is the same one the watch would have built for itself.
