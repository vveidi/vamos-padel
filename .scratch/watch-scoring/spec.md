# A padel match counter on Apple Watch (v1)

Status: ready-for-agent

## Problem Statement

The score of a padel match lives in people's heads and disappears with the match. Between rallies the four on court try to remember who has how many games, and argue separately about whose serve it is — and after the game nothing is left: neither the score nor how it came about.

A phone is useless in that situation: it lies in a bag behind the net or in the changing room, and nobody is going to fetch it between rallies. The existing apps either need the phone in your hands or count classic scoring only, whereas an amateur group on a court paid for by the hour often plays to a fixed number of points.

## Solution

An Apple Watch app that keeps the score right on the wrist and needs no phone nearby. The match is registered as a workout, so it survives an hour and a half of play: the screen never fully goes dark, the app is not unloaded, and raising your wrist brings back the score rather than the watch face.

The score screen is split into two zones filling the display — a tap in your own half awards a point to that side; the Double Tap gesture awards a point to our side without touching the watch at all. A mistaken tap can be undone. There are exactly three things on the screen: the current points in large type, the game score smaller, and the serving-side indicator.

The app knows two **rulesets** — **classic scoring** and **the match to N points** — and remembers the previous match's settings, so an ordinary start is a single tap. Every match is saved as a **rally journal** and travels to the iPhone, where it can be looked at in the history.

## User Stories

### Starting a match

1. As a player, I want to start a match with one tap, so that I am not configuring the app while my partners wait on court.
2. As a player, I want the app to remember the previous match's ruleset, so that I am not setting the same thing every game.
3. As a player, I want to choose between classic scoring and the match to N points, so that the app counts by the rules we are playing by today.
4. As a player, I want to switch the golden point on and off, because on a court paid for by the hour there is no time to play out deuce.
5. As a player, I want to choose the number of sets in classic scoring, so that the app knows when the match is over.
6. As a player, I want to set N in the match to N points, so that we can play to 16, 21 or whatever else we agreed on.
7. As a player, I want to set X — how many points before the serve changes — because in different groups it is 2 or 4.
8. As a player, I want to say who serves first, so that the serve indicator tells the truth from the start.
9. As a player, I want to see the default values (N = 16, X = 4, one set), so that a new match can be started without thinking.

### Keeping the score

10. As a player, I want to award a point by tapping my half of the screen, so that I can hit it without looking and with a wet hand.
11. As a player, I want to award a point to our side with the Double Tap gesture, so that I do not have to let go of my racket.
12. As a player, I want to see the current points in large type, so that I can read them at a glance between rallies.
13. As a player, I want to see the game score, so that I know where we stand in the set.
14. As a player, I want to see whose serve it is, so as to end the one argument that comes up on court regularly.
15. As a player, I want the serve to pass to the other side by itself after a game in classic scoring, so that I do not have to track it by hand.
16. As a player, I want the serve to pass by itself every X points in the match to N points, for the same reason.
17. As a player, I want to undo the last point, because mis-taps on the zones and false Double Tap triggers are inevitable.
18. As a player, I want to undo several points in a row, in case the mistake was not noticed at once.
19. As a player, I want the score, the serve and the state of completion to come back to exactly what they were after an undo.
20. As a player, I want deuce to be settled by a single decisive rally when the golden point is on, rather than by playing on for a two-point lead.
21. As a player, I want a tiebreak by padel's rules to begin at 6:6.
22. As a player, I want the app to work out the end of a game, a set and a match by itself, so that nobody counts in their head.

### A match an hour and a half long

23. As a player, I want the app not to be unloaded from memory in the middle of a match, so that the score is not lost.
24. As a player, I want to see the score with my wrist down, so that I do not have to wake the watch to look at the screen.
25. As a player, I want raising my wrist to bring me back to the score, not to the watch face.
26. As a player, I want the match to land in the activity rings and in Health, because an hour and a half of padel is a workout.
27. As a player, I want heart rate and calories written by themselves, without a single action from me.
28. As a player, I want the match restored from the same place after the app is relaunched, because a dead battery must not erase an hour of play.

### The end of a match

29. As a player, I want to see the outcome right after the last rally, so as to know how it all ended.
30. As a player, I want to stop a match early, because the court time is running out, it is starting to rain, or somebody pulled their back.
31. As a player, I want a stopped match saved all the same, so that an hour of play is not lost.
32. As a player, I want an abandoned match marked explicitly and counted as neither a win nor a loss.

### The history on the phone

33. As the owner of the history, I want a finished match to end up on the phone by itself, without pressing "sync".
34. As the owner of the history, I want the hand-off to happen once the phone is nearby, rather than requiring it during play.
35. As the owner of the history, I want to see a list of the matches played, with the date, the score and the duration.
36. As the owner of the history, I want to open a match and see how the score came about, not only how it ended.
37. As the owner of the history, I want to tell abandoned matches apart in the list at a glance.
38. As the owner of the history, I want to see which ruleset a match was played by, so that "16:14" does not look like a strange tennis score.
39. As the owner of the history, I want the history to survive a restart of the phone and an update of the app.

## Implementation Decisions

### The `PadelScoring` package

A local Swift package holding the rules engine. It depends on neither SwiftUI, nor GRDB, nor HealthKit, nor WatchConnectivity — the constraint is enforced by the package physically not linking against them, not by convention. Both app targets reference the package.

The public interface rests on three concepts:

- **Ruleset** — a value describing a way of scoring: classic (the number of sets and the golden point; a tiebreak at 6:6 is a rule of padel, not a setting) or to N points (N, X). A value precisely, and not a branch in the code: "we are playing to 9 games" has to become a different number, not a different branch.
- **Rally journal** — an ordered sequence in which every element says which side won the rally.
- **Match state** — the computed result: points, games, sets, serving side, whether it is over.

The engine is a pure function from the ruleset and the journal to a state. Adding a rally appends an element to the journal; an undo removes the last one. The state is nowhere stored in parallel with the journal (ADR-0001), so an undo needs no arithmetic run backwards and cannot drift out of sync.

The serving side is likewise computed from the journal and the ruleset rather than stored: in classic scoring it changes on a game boundary, in the match to N points every X rallies, counting from the first server named before the match.

### The store

SQLite through GRDB on both devices (ADR-0003). Access is hidden behind a store protocol, so that the engine and the screens know nothing about the database. The schema is versioned by GRDB migrations from its first version — it will certainly change once players appear.

A match is stored together with its ruleset: without it the journal cannot be interpreted, and the rules will change over time. The moment of the start, the duration and the abandoned mark are written as well.

The journal is written after every rally, not at the end of the match. That is what makes restoring after the app is unloaded nearly free: an unfinished match is a journal without a final state, and at launch the app offers to continue that very one.

### The app on the watch

Three screens: start (ruleset and first server) → score → outcome. There is no list of matches on the watch.

The match runs inside an `HKWorkoutSession` — the only way to guarantee that the app survives an hour and a half and gets Always-On. It requires HealthKit permission on first launch. The session starts with the match and ends with it, including when the match is stopped early.

The score screen is two tap zones filling the display, one per side. The Double Tap gesture is bound to our side through `.handGestureShortcut(.primaryAction)`; there is exactly one primaryAction in the system, so the other side is reachable by tap only. Undoing the last point is mandatory; the exact gesture is to be settled by the prototype.

Exactly three quantities are shown: the points in large type, the games smaller, and the serve indicator. Heart rate and match time are available from the workout session but are kept off the screen — they compete for room with the very thing the watch is looked at for.

The previous match's ruleset is saved and filled into the start screen.

### The hand-off to the phone

A finished match is put in a queue for hand-off through WatchConnectivity (`transferUserInfo`), which survives a relaunch of the app and delivers once the phone becomes reachable. The watch stays the source of truth until delivery is confirmed and does not delete the match before that.

The transport is hidden behind a protocol (ADR-0002): this is precisely the seam that is later swapped for CloudKit or a server without moving the data.

There is no cloud, no server and no accounts in v1. The consequence is accepted deliberately: no backup exists, and losing the device before the hand-off means losing the match.

### The app on the phone

Two screens: the list of matches and the match card. The list shows the date, the score, the duration and the abandoned mark. The card shows how the score came about, reconstructing the course of the match from the journal with the same engine that counted it on the watch — and that is the payoff for the engine living in a shared package.

iPhone only; the iPad is out of the target.

### Minimum versions

iOS 18 and watchOS 11. The versions are chosen as a pair rather than separately:
watchOS 11 requires iOS 18 on the paired iPhone, so a combination like
"iOS 17 + watchOS 11" does not exist in nature.

The lower bound is set by watchOS 11 (Apple Watch Series 6 and newer), and the
reason is the score screen specifically: Always-On arrived with the Series 5,
while watchOS 10 includes the Series 4, which does not have it at all.
Supporting a version on which the app's main screen behaves fundamentally
differently costs more than dropping it. A side benefit is that Double Tap is
available without availability checks.

## Testing Decisions

A good test here checks **external behaviour**: you feed in a ruleset and a sequence of won rallies, and assert about the observable match state. The test knows nothing about how the computation is arranged inside, does not reach for private types, and does not break when internal functions are renamed.

There is no prior code in the repository, so no prototype tests exist — these tests will become the pattern for the ones that follow.

### Seam 1: the public API of `PadelScoring`

The main seam, through which the whole of the domain logic is checked. The tests live in the package and run without a simulator and without a device.

Covered:

- Classic scoring: 15/30/40, a game at a two-point lead, deuce and advantage.
- The golden point: at 40:40 a single decisive point is played.
- The end of a set, a tiebreak at 6:6, the end of a match at the given number of sets.
- The match to N points: the match ends as soon as a side is first to reach N.
- Changes of serve: on a game boundary in classic scoring, every X rallies in the match to N points, taking the first server into account.
- Undo: one and several in a row; the state after an undo matches the state before the corresponding rally, serve and completion included.
- An abandoned match: a journal without a final state reads back correctly.
- Boundary values of the ruleset (N = 1, X = 1) do not lead to an invalid state.

One property worth checking on its own: **the state depends on nothing but the ruleset and the journal**. The same journal read twice yields the same state — that is exactly what makes restoring after an unload, and replaying a match on the phone, dependable.

### Seam 2: `MatchStore`

The round trip through a store on an in-memory SQLite database: a saved match reads back with the same journal, ruleset and abandoned mark. Schema migrations are checked separately — GRDB was chosen for their sake (ADR-0003).

### What the tests do not cover

- **WatchConnectivity**: needs two devices. It sits behind a protocol with a stub, and is checked by hand.
- **`HKWorkoutSession`**: a thin wrapper over a system API.
- **The SwiftUI screens**: the tap zones, Double Tap and the undo gesture are checked by the prototype and by hand — no test will show whether a wet hand misses.

## Out of Scope

- **Players and names.** The sides are anonymous: "us" and "them". The journal is saved in a form that players can be attached to later, but in v1 there are none.
- **Statistics.** Without players it comes down to "62% of matches won" — a figure with no use.
- **Americano.** A tournament format for 8–16 players with rotating partners and individual scoring. A separate product for the organiser's phone, not this one. The term is reserved for the tournament and does not denote the match to N points.
- **Cloud sync, accounts, a server.** Deferred behind the transport seam.
- **Android.** Accounted for only in the choice of storage format: an SQLite file is portable.
- **Booking courts, finding partners, ratings.**
- **The iPad.**
- **A match history on the watch itself.**

## Further Notes

An open question that cannot be settled on paper: the geometry of the tap zones, the undo gesture, and how dependable Double Tap is with a sweaty hand. This is a candidate for a `/prototype` detour before the score screen is implemented; the result will refine the decisions about the score screen but will not touch a single seam.

Worth checking on a real device before committing to a decision: how Always-On behaves in the dimmed state. Tap-to-wake cannot be switched off, so a tap with the wrist down wakes the screen rather than awarding a point. With the wrist raised the watch is functional at once and the tap counts — but that is an assumption, not a measured fact.

The order of implementation is set by the dependencies: the rules engine in the package depends on nothing and is done first; the store and the score screen rest on it; the hand-off to the phone and the history screens come last, because until then there is nothing to hand off.
