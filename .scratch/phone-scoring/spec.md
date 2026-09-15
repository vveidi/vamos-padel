# Phone scoring: the phone scores a match of its own (v1)

Status: ready-for-agent

## Problem Statement

The watch is the whole app and the phone is a window onto what the watch
finished. That leaves the phone doing nothing while a match is being played, and
the four people on court with nothing to look at. A padel match is watched by
the pair that is losing it as much as by the pair that is winning; the score
belongs on the bench, not only on one wrist.

This feature gives the phone a match of its own. It is scored on a landscape
scoreboard split in two, both halves tapped to award a rally, the digits as
large as the screen allows, and the ball in the corner of the half that serves.
The journal is written into the same store the history is read from, so the
match is in the history from its first point.

**The watch is not touched.** It goes on scoring matches of its own exactly as
it does today — its own store, its own workout, the delivery that hands a
finished match to the phone. A match has one scorer and it is the device it was
started on (ADR-0009). The two devices say nothing to each other while a match
runs.

## What is in, and what is not

In:

- The **scoreboard** on the phone: landscape, two tappable halves, the largest
  digits the screen allows, the ball in the corners, and the controls the
  `PhoneScore` board draws.
- The phone's **new match** screen, which `PhoneNewMatch.dc.html` has been
  waiting for since the redesign (`SegmentedChoice` and `StepperRow` shipped
  unused and marked unavailable on watchOS for exactly this).
- The **history** learning that a match can be running while it is on screen,
  and what to do with one left running yesterday.
- The **storage modules** getting their boundary named and their names fixed, so
  that nothing outside the composition root says SQLite.

Not in:

- **The two devices in one match.** The live link, the intent protocol, the
  mirrored workout, the watch as a remote, and the removal of the delivery are
  all `paired-scoring`, which is v1 and comes after this. Every argument for
  them is written down there; none of it is lost.
- **Named sides.** The glossary's "in v1 the sides are anonymous" stands. Naming
  them changes every string, both catalogs and the VoiceOver of every screen,
  and it is a feature of its own.
- **Announcing the score out loud.** Wanted, and a feature of its own. It is
  also the thing that will one day keep the phone awake honestly — real audio
  output, not the silence guideline 2.5.4 exists to catch.
- **A second scoreboard layout in portrait.** The scoreboard is landscape and
  forces the rotation; the rest of the app is free in both orientations.
- **Light mode** and the **two custom fonts** — both declined, both recorded in
  ADR-0006.

## The design, in words

**A match scored on the phone is written down as it is played.** The journal
goes into the store after every rally, into the same table the history reads, so
there is no hand-off, nothing to deliver, and nothing that can be lost by the
app being backgrounded or terminated: the match comes back from the store.

**Nothing keeps the phone alive, and nothing needs to.** Every rally arrives
through the phone's own screen, so the app is in front of the player whenever
anything happens. The idle timer is held while the board is up; that is the
whole of it. There is no workout, no HealthKit, no background session and no
warning to show — the thing those would protect against cannot happen when
there is no second device feeding the match.

**A phone-scored match has no workout**, and that is the trade. The watch has
the sensors and the session to run them in; the phone has the screen the four
players read. Choosing one is giving up the other, and the honest answer to
wanting both is `paired-scoring`.

**The scoreboard is a court seen from above, turned.** The net crosses the long
axis, so in landscape it stands vertical and the halves lie left and right. Both
are the one surface `court-surface` 01 collapsed them into, the ball sits in the
corner of the serving half, and which half is drawn on the left is a setting — a
button mirrors the board so nobody has to walk around the bench.

## Solution

### No host, and no second journal

The scoreboard holds the match in its own `@State` and applies a rally, an undo
or an end through `SavedMatch`'s own methods, persisting after each — precisely
what `MatchView` does on the watch today. There is no host object, because there
is nothing for it to arbitrate: the scoreboard is the only door into the
journal.

The history's live tile needs no plumbing of its own either. `matches()` already
returns matches in progress and `matchesObserved()` already re-reads after every
transaction that touched a match or its rallies, so a rally recorded on the
board reaches the tile through the observation the history is already running.

When `paired-scoring` 02 builds `MatchHost`, that mutation moves behind it in
one move. Keeping it in one small cluster of `private func`s is the only thing
this feature does to make that cheap, and it is the shape the watch already has.

### The storage modules get their names

`PadelStorage` is two targets along the line its folders draw: the protocols and
`SavedMatch` on one side, the database that implements them on the other. That
boundary is what lets `PadelDelivery` — and, after pairing, the watch — name a
`SavedMatch` without linking GRDB.

What the boundary is called has to change. `Seam/` becomes `Interface/`,
`SQLite/` becomes `Database/`, `PadelStorageSQLite` becomes
`PadelStorageDatabase` and `SQLiteMatchStore` becomes `DatabaseMatchStore`. The
technology is named where the technology is chosen — ADR-0003 — and in the file
that imports GRDB, and nowhere an app can see it. A second provider would pair
naturally: `PadelStorageCloud`, `CloudMatchStore`.

The import at each composition root stays visible and is meant to: `PadelApp`
and `PadelWatchApp` are the two files whose job is to say which provider is
being built.

### Both orientations everywhere except the scoreboard

The app declares all orientations. The scoreboard asks for landscape on the way
in with `requestGeometryUpdate` and lets go on the way out. This is the only
non-SwiftUI code in the app, and it earns its place: it is the one way the board
is landscape for a player who has rotation lock on.

## Consequences, stated plainly

- **A phone-scored match leaves no row in Health.** No heart rate, no calories,
  no ring. `HKWorkoutSession` is watchOS's and the phone has no equivalent.
- **Both devices may be scoring at once.** Neither can see the other's match
  while it runs, so nothing stops two — and nothing tries to, because any
  warning would be a guess. They land in the history as two matches, which is
  what there were.
- **Nothing is lost by leaving the app.** The journal is in the store after
  every rally. A phone-scored match survives backgrounding, termination and a
  flat battery, and resumes from the store.
- **All of this is verifiable in a simulator**, which was not true of the design
  this feature was cut out of. There is no `ready-for-human` ticket here.

## The tickets

```
01  the storage seam splits away from GRDB        done
02  the storage modules get their names
03  the phone's new match screen
04  the scoreboard
05  the history: the live tile, the stale match, landscape
```

01 is done. Nothing blocks anything else: 02 renames modules the three screens
only ever reach through `any MatchStore`, and 03, 04 and 05 are independent of
one another. 01 keeps the title it was closed under — it was worked before the
word changed, and a closed ticket is a record of what happened.
