# Phone scoring: the match lives on the phone, the watch is its remote (v1)

Status: ready-for-agent

## Problem Statement

Today the watch is the whole app and the phone is a window onto what the watch
finished. `CONTEXT.md` opens with that sentence, ADR-0002 makes it a rule — "the
watch stays the source of truth until the hand-off, and therefore has to see a
match through to the end with no phone nearby" — and every piece of the delivery
machinery exists to carry a finished match across that gap once.

That leaves the phone doing nothing while a match is being played, and the four
people on court with nothing to look at. A padel match is watched by the pair
that is losing it as much as by the pair that is winning; the score belongs on
the bench, not only on one wrist.

This feature moves the match onto the phone and turns the watch into its remote.
The score is shown on a landscape scoreboard split in two, both halves tapped to
award a rally, the digits as large as the screen allows, and the ball in the
corner of the half that serves. The watch keeps the screen it has, keeps the
workout, and stops keeping the match.

## What is in, and what is not

In:

- The **scoreboard** on the phone: landscape, two tappable halves, the largest
  digits the screen allows, the ball in the corners, and the controls the
  `PhoneScore` board draws.
- The phone's **new match** screen, which `PhoneNewMatch.dc.html` has been
  waiting for since the redesign (`SegmentedChoice` and `StepperRow` shipped
  unused and marked unavailable on watchOS for exactly this).
- The **live link** in both directions: the journal out to the watch, intents
  back from it.
- The **mirrored workout session**, which is what keeps the phone's app alive
  in the background while the match runs.
- **Removing the delivery**: `MatchDelivery`, `MatchReception`, the receipt, the
  queue, the delivery mark, and the database on the watch.

Not in:

- **Named sides.** The glossary's "in v1 the sides are anonymous" stands. The
  reference app this was compared against names four players; naming them
  changes every string, both catalogs and the VoiceOver of every screen, and it
  is a feature of its own.
- **Announcing the score out loud.** Wanted, and mentioned during the grilling
  as a later feature. It needs the phone awake and audible, which the mirrored
  session gives it — so it is cheap *after* this, and it is not in this.
- **A second scoreboard layout in portrait.** The scoreboard is landscape and
  forces the rotation; the rest of the app is free in both orientations.
- **Light mode** and the **two custom fonts** — both declined, both recorded in
  ADR-0006.

## The design, in words

**The match has one home, and it is the phone.** The rally journal is written
there after every rally, into the same store the history is read from, so a
match is in the history from its first point rather than after a hand-off. There
is no second journal anywhere, at any moment, and therefore nothing to merge.

**The watch asks; it does not record.** A tap on the wrist is an *intent* — "a
rally to us, on top of a journal of 27" — which the phone either records or
refuses. What comes back is the journal, and the watch computes the score from
it with the same engine the phone uses. The watch stores nothing and survives
nothing: close the app mid-match and it rejoins where the phone is.

**A match needs both devices to begin.** Starting on the phone raises the watch
app into a workout (`HKHealthStore.startWatchApp(with:)`); starting on the watch
requires the phone to answer. Neither device plays padel alone. This is the
sharpest departure from what the app is today, and the cost is named in the
consequences below.

**The workout is the watch's, and the phone mirrors it.** That is not a detail
of Health: a mirrored workout session is what entitles the phone's app to keep
running in the background for the length of the match, which is the only thing
standing between "the owner of the journal" and "an app iOS may suspend at any
moment".

**The scoreboard is a court seen from above, turned.** The net crosses the long
axis, so in landscape it stands vertical and the halves lie left and right. Ours
is turf green, theirs glass blue, the ball sits in the corner of the serving
half, and which half is drawn on the left is a setting — a button mirrors the
board so nobody has to walk around the bench.

## Solution

### The seam

`PadelDelivery` stops being a post office and becomes a link. Two ends, named
for what they do rather than for the device they run on:

- **`MatchHost`** — holds the match, applies intents to it, writes it to the
  store, and broadcasts the journal after every change. The phone runs it.
- **`MatchRemote`** — holds the last journal that arrived, renders it, and sends
  intents. The watch runs it.

Both sit on a transport protocol, as `MatchSender`/`MatchReceiver` do today, so
the pair is tested against a stub instead of against two devices on a desk.

### What travels

Out of the host: the whole match — id, ruleset, first server, the journal as an
array of winners, the abandoned mark, the two moments. The same content
`MatchPayload` already encodes, because the score is not on the wire any more
than it is in the database (ADR-0001): the watch is handed the journal and
computes the state itself.

Into the host: an intent — record a rally for a side, undo, end the match, start
a match with this ruleset and this first server — each carrying the **journal
length it was formed against**. The host refuses an intent whose base does not
match what it holds. That one integer is what makes a message delivered twice
score once, and a tap made against a stale screen fail loudly instead of
quietly.

### What dies

`MatchDelivery`, `MatchReception`, `Arrival.receipt`, `MatchDeliveryQueue`, the
`delivered` column, `SQLiteMatchStore` on the watch and the GRDB dependency with
it. ADR-0004 goes with them; ADR-0002 survives only in the half that says
storage is local and behind a seam.

## Implementation Decisions

### The phone owns the journal, though it is the device iOS may kill

The watch is the device the system promises to keep alive during a workout, and
putting the journal on the phone means putting it where it can be suspended. The
mirrored workout session is the answer, and it is Apple's own answer to this
exact shape of app: the watch runs the session, calls
`startMirroringToCompanionDevice()`, and iOS launches the phone's app in the
background and keeps it there for the duration.

The alternative — the journal on the watch, the phone as a live mirror with a
remote — was argued for at length during the grilling and rejected: the history
is the phone's, the scoreboard is the phone's, and a design in which the phone
draws and controls a match it does not hold needs two journals or a round trip
for its own taps.

**Background audio was considered and refused.** Playing silence to stay alive
is what guideline 2.5.4 exists to catch, and this feature ships before the first
release.

### WatchConnectivity carries the data; the mirrored session buys the life

Two channels are available once a workout is mirrored — WatchConnectivity
messages and `sendToRemoteWorkoutSession(data:)`. Using both for data would mean
two orderings and two failure modes for one conversation.

So: the mirrored session is used for what only it can do, which is keeping the
phone's app running. Every byte goes over WatchConnectivity `sendMessage`, which
is immediate, bidirectional, and already the only place in the codebase that
knows what WatchConnectivity is. `transferUserInfo` — today's queue — is wrong
here for the reason it was right before: it guarantees arrival and promises
nothing about when.

If the live pair shows `sendMessage` dropping under the mirrored session, the
fallback is the session's own channel, and it is a change behind the transport
protocol rather than in any screen.

### The intent carries its base, and the host is the only judge

An intent is not a rally. It is refused when the match is over, when the base
does not match, and when there is no match. The watch draws nothing until the
journal comes back — no optimistic point, ever, because a scoreboard that shows
40 and takes it back is worse than one that is 200 ms late.

### The store splits along the line its folders already draw

`PadelStorage` is `Seam/` and `SQLite/` in two folders, and the watch needs the
first without the second: it has to name a `SavedMatch` on the wire and must not
link GRDB to do it. They become two targets in the same package, which is a
manifest change and no moved file.

### The board's geometry is one sentence

The net crosses the long axis. In landscape that puts it vertical with the
halves left and right; in portrait it is horizontal with the halves stacked,
which is what `PhoneScore.dc.html` draws and what the watch already does. Only
the landscape half of that sentence ships here — the scoreboard forces landscape
— but the rule is written down so the portrait board, if it is ever wanted, is
not a second design.

### Both orientations everywhere except the scoreboard

The app declares all orientations. The scoreboard asks for landscape on the way
in with `requestGeometryUpdate` and lets go on the way out. This is the only
non-SwiftUI code in the app, and it earns its place twice: it is the one way the
board is landscape for a player who has rotation lock on.

## Consequences, stated plainly

- **No phone, no padel.** A player who leaves the phone in a locker cannot score
  a match. This is a deliberate reversal of the app's opening sentence and of
  ADR-0002's second consequence, and it is what the new ADR-0009 records.
- **No watch, no padel either.** The pair is required in both directions.
- **A match interrupted by a flat phone is not lost**, but it is frozen: the
  watch refuses taps while the phone is unreachable, and the rallies played in
  the meantime are not recorded anywhere.
- **Almost none of this can be verified in a simulator.** Mirrored workout
  sessions, `startWatchApp`, and WatchConnectivity reachability all need a real
  paired watch and phone. Ticket 11 is that run-through, and it is
  `ready-for-human`.

## The tickets

```
01  the storage seam splits away from GRDB
02  what travels: the journal out, intents in
03  the two ends: the host and the remote
04  the transport becomes live
05  the workout mirrors, and the phone stays awake
06  the phone's new match screen
07  the scoreboard
08  the history: the live tile, the stale match, landscape
09  the watch becomes a remote
10  the delivery is removed
11  the live pair run-through            (ready-for-human)
```

01 blocks 02, which blocks everything. 06, 07 and 08 are independent of one
another; 09 waits on the transport; 10 waits on 09; 11 waits on all of it.
