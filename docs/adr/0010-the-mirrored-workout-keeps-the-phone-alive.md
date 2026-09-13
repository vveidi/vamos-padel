# The mirrored workout keeps the phone alive; WatchConnectivity carries the data

The match lives on the phone (ADR-0009), and iOS is free to suspend and terminate an app the moment it leaves the screen. What entitles the phone's app to keep running for an hour and a half is a **mirrored workout session**: the watch starts the `HKWorkoutSession` it already starts for every match and calls `startMirroringToCompanionDevice()`, the system launches the phone's app in the background and hands it the mirrored session, and the app stays alive for as long as the workout does — which is exactly as long as the match does.

Two alternatives were weighed. **Background audio** — playing silence to stay resident — works and is what guideline 2.5.4 exists to catch; this feature ships before the first release, so it is not a bet worth taking. **Relying on WatchConnectivity to wake the app for every message** works too: a message from the watch launches a suspended or system-terminated iOS app in the background. But each rally would then pay for a wake-up of unpromised duration, and the app would be recording a match it is not allowed to keep thinking about between points.

A mirrored session also offers a data channel of its own, `sendToRemoteWorkoutSession(data:)`. It is deliberately not used. Two channels for one conversation is two orderings and two failure modes; the session is used for the one thing only it can do, and every byte goes over WatchConnectivity `sendMessage`.

## Consequences

- **`sendMessage`, not `transferUserInfo`.** Today's transport guarantees arrival and promises nothing about when, which was right for a finished match and is wrong for a live one. The queue goes with the delivery.
- **The workout stops being optional in the way it was.** The "Recording to Health" switch on the watch's start screen turned the workout off; with the match on the phone, no workout means no mirrored session and no background life. The switch now governs whether the workout is *saved to Health*, not whether a session runs.
- **A user who force-quits the phone's app breaks the link on purpose.** WatchConnectivity will not relaunch an app the user swiped away, and the mirrored session ends with it. The watch reports the phone as unreachable and refuses taps until the app is opened again.
- **Almost none of this is verifiable in a simulator.** Mirrored sessions, `startWatchApp(with:)` and reachability all require a real pair. The feature carries a `ready-for-human` run-through ticket for that reason.
- **The fallback is behind the transport protocol.** If `sendMessage` proves unreliable under a mirrored session on real hardware, moving the data onto the session's own channel changes one implementation and no screen.
