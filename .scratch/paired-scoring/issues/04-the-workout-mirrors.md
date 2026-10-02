# 04: The workout mirrors, and the phone stays awake

**What to build:** in a paired match the watch's workout mirrors to the phone,
the phone holds the mirrored session for the length of the match, and a paired
match started on the phone raises the watch app into that workout.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] ADR-0010 is filed from the spec's "The mirrored workout keeps the phone
      alive" — verbatim but for the lines the pair being a third way has made
      false (the queue does not go; the switch changes meaning in a paired
      match only)
- [ ] In a paired match `HealthKitWorkout` calls
      `startMirroringToCompanionDevice()` when the session starts and stops
      mirroring when it ends. A solo match on the watch does not mirror
- [ ] The phone subscribes to `workoutSessionMirroringStartHandler` when the app
      is assembled — before any screen exists, for the reason `MatchReception`
      subscribes early: the app is launched into the background for this and
      there may be no screen at all
- [ ] The phone holds the mirrored session for as long as the match runs and
      lets go when it ends
- [ ] Starting a paired match on the phone with no watch app running calls
      `HKHealthStore.startWatchApp(with:)` and waits for the watch to appear
- [ ] The phone target gains the HealthKit capability, the two usage strings in
      its `Info.plist`, and both of them in the catalog in both languages
      (ADR-0005 — the English string is the key)
- [ ] Authorization is asked for once, the first time a paired match is started
      or the setting is turned on, not at launch
- [ ] **Health refused on the phone means no paired match.** With no mirrored
      session the phone lives only while its screen is on, and a paired match
      that dies in a pocket is worse than a solo one. The setting says why it is
      off and leads to the Settings app (ticket 08 draws it)
- [ ] In a paired match the watch's "Recording to Health" switch governs whether
      the workout is **saved**, not whether a session runs; in a solo match it
      keeps doing what it does today
- [ ] A paired match started on the phone saves to Health by the switch's last
      value on the watch — the phone has no switch of its own
- [ ] **The watch lost mid-match.** Flat, out of range, or its app closed: the
      scoreboard says the watch is unreachable and goes on scoring from its own
      taps, with the idle timer held as in a solo match. No new workout is
      started; when the watch comes back it rejoins and is handed the journal
- [ ] Driven on a live pair as part of ticket 07; the simulator cannot see any
      of this

## Notes

**On the switch changing meaning.** With the match on the phone, no workout
means no mirrored session and no background life, so in a paired match the
session has to run regardless. What the player was turning off was a row in
Health, and that is what the switch keeps doing. The wording on the start
screen may need to change with it — check it against the string, not against
this sentence.

**On `startWatchApp(with:)` taking a workout configuration.** It launches the
watch app into a workout, which is precisely what is wanted here — the
configuration is the same one the watch would have built for itself.

**On the watch being lost.** The phone is the match's scorer either way, so
nothing is handed over and nothing is merged: the match simply goes on with one
device fewer. What it loses is its background life, which is why the idle timer
comes back.
