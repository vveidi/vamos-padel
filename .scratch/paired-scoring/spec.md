# Paired scoring: one match, both devices, the watch as its remote

Status: needs-triage

## Problem Statement

A match has one scorer, and it is the device it was started on (ADR-0009). That
buys a phone that scores on its own and a watch that goes on scoring on its own,
and it buys them cheaply — neither device needs the other to be present, awake,
or in Bluetooth range.

What it does not buy is the two of them in one match. Today a player choosing
the phone gets the board the four of them read from the bench and gives up the
workout, the heart rate and the wrist; a player choosing the watch gets all of
those and gives up the board. Every match is that trade, made before the first
rally and unchangeable afterwards.

This feature removes the trade. The match lives on the phone from its first
rally — the journal written there, the history read there, the scoreboard there
— and the watch becomes its remote: it shows the match and awards the rallies,
and keeps nothing. The workout still belongs to the watch and the phone mirrors
it, which is also what keeps the phone's app alive for the length of a match it
is holding but not looking at.

**This is a third way to score, not a replacement for the other two.** Whether
it is chosen automatically when both devices are present, or offered as a
setting, or made the only way once it works — that is the first question this
feature has to answer, and the reason every ticket in it is `needs-triage`
rather than ready. The design below was written when it *was* the replacement,
and it has to be read again in the world it now lands in.

## What is in

- The **live link** in both directions: the journal out to the watch, intents
  back from it.
- The **mirrored workout session**, which is what keeps the phone's app alive in
  the background while the match runs.
- The **watch as a remote**: the same score screen, drawing a journal that
  arrived, its taps asking rather than recording.
- **Removing the delivery**: `MatchDelivery`, `MatchReception`, the receipt, the
  queue, the delivery mark, and the database on the watch.
- The **live pair run-through**, which is the half of this no simulator can see.

## What it depends on

`phone-scoring` in full. The scoreboard, the phone's new match screen and the
history's live tile are that feature's; this one changes where the match they
draw comes from, and it cannot start before they exist.

## The design, in words

**The match has one home, and it is the phone.** The rally journal is written
there after every rally, into the same store the history is read from. There is
no second journal anywhere, at any moment, and therefore nothing to merge.

**The watch asks; it does not record.** A tap on the wrist is an *intent* — "a
rally to us, on top of a journal of 27" — which the phone either records or
refuses. What comes back is the journal, and the watch computes the score from
it with the same engine the phone uses. The watch stores nothing and survives
nothing: close the app mid-match and it rejoins where the phone is.

**A paired match needs both devices to begin.** Starting on the phone raises the
watch app into a workout (`HKHealthStore.startWatchApp(with:)`); starting on the
watch requires the phone to answer. This is the sharpest departure from the app
as it stands, and it is why the question of whether pairing replaces the other
two ways of scoring or joins them has to be settled first.

**The workout is the watch's, and the phone mirrors it.** That is not a detail
of Health: a mirrored workout session is what entitles the phone's app to keep
running in the background for the length of the match, which is the only thing
standing between "the owner of the journal" and "an app iOS may suspend at any
moment".

## Solution

### The two ends

`PadelDelivery` stops being a post office and becomes a link. Two ends, named
for what they do rather than for the device they run on:

- **`MatchHost`** — holds the match, applies intents to it, writes it to the
  store, and broadcasts the journal after every change. The phone runs it.
- **`MatchRemote`** — holds the last journal that arrived, renders it, and sends
  intents. The watch runs it.

Both sit on a transport protocol, so the pair is tested against a stub instead
of against two devices on a desk.

`phone-scoring` deliberately built no host: its scoreboard holds the match in
its own `@State` and persists it, the way `MatchView` does on the watch. Ticket
02 is where that mutation moves behind one door.

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
`delivered` column, the database on the watch and the GRDB dependency with it.
ADR-0004 is superseded; ADR-0002 survives only in the half that says storage is
local and behind an interface; ADR-0009 is rewritten, because a paired match has
no one device that holds it.

## Implementation Decisions

### The phone owns the journal, though it is the device iOS may kill

The watch is the device the system promises to keep alive during a workout, and
putting the journal on the phone means putting it where it can be suspended. The
mirrored workout session is the answer, and it is Apple's own answer to this
exact shape of app: the watch runs the session, calls
`startMirroringToCompanionDevice()`, and iOS launches the phone's app in the
background and keeps it there for the duration.

The alternative — the journal on the watch, the phone as a live mirror with a
remote — was argued for at length and rejected: the history is the phone's, the
scoreboard is the phone's, and a design in which the phone draws and controls a
match it does not hold needs two journals or a round trip for its own taps.

**Background audio was considered and refused.** Playing silence to stay alive is
what guideline 2.5.4 exists to catch. Announcing the score out loud is a
different thing entirely — that is real output, and when it ships it will keep
the phone awake honestly.

### The mirrored workout keeps the phone alive; WatchConnectivity carries the data

*This is ADR-0010, written and then withdrawn when pairing was deferred. It is
kept here verbatim, and filed as a numbered ADR when this feature is built. The
tickets refer to it by this heading.*

> The match lives on the phone (ADR-0009), and iOS is free to suspend and
> terminate an app the moment it leaves the screen. What entitles the phone's
> app to keep running for an hour and a half is a **mirrored workout session**:
> the watch starts the `HKWorkoutSession` it already starts for every match and
> calls `startMirroringToCompanionDevice()`, the system launches the phone's app
> in the background and hands it the mirrored session, and the app stays alive
> for as long as the workout does — which is exactly as long as the match does.
>
> Two alternatives were weighed. **Background audio** — playing silence to stay
> resident — works and is what guideline 2.5.4 exists to catch; this feature
> ships before the first release, so it is not a bet worth taking. **Relying on
> WatchConnectivity to wake the app for every message** works too: a message
> from the watch launches a suspended or system-terminated iOS app in the
> background. But each rally would then pay for a wake-up of unpromised
> duration, and the app would be recording a match it is not allowed to go on
> thinking about between points.
>
> A mirrored session also offers a data channel of its own,
> `sendToRemoteWorkoutSession(data:)`. It is deliberately not used. Two channels
> for one conversation is two orderings and two failure modes; the session is
> used for the one thing only it can do, and every byte goes over
> WatchConnectivity `sendMessage`.
>
> **Consequences**
>
> - **`sendMessage`, not `transferUserInfo`.** Today's transport guarantees
>   arrival and promises nothing about when, which was right for a finished
>   match and is wrong for a live one. The queue goes with the delivery.
> - **The workout stops being optional in the way it was.** The "Recording to
>   Health" switch on the watch's start screen turned the workout off; with the
>   match on the phone, no workout means no mirrored session and no background
>   life. The switch now governs whether the workout is *saved to Health*, not
>   whether a session runs.
> - **A user who force-quits the phone's app breaks the link on purpose.**
>   WatchConnectivity will not relaunch an app the user swiped away, and the
>   mirrored session ends with it. The watch reports the phone as unreachable
>   and refuses taps until the app is opened again.
> - **Almost none of this is verifiable in a simulator.** Mirrored sessions,
>   `startWatchApp(with:)` and reachability all require a real pair. The feature
>   carries a run-through ticket for that reason.
> - **The fallback is behind the transport protocol.** If `sendMessage` proves
>   unreliable under a mirrored session on real hardware, moving the data onto
>   the session's own channel changes one implementation and no screen.

### The intent carries its base, and the host is the only judge

An intent is not a rally. It is refused when the match is over, when the base
does not match, and when there is no match. The watch draws nothing until the
journal comes back — no optimistic point, ever, because a scoreboard that shows
40 and takes it back is worse than one that is 200 ms late.

## The vocabulary this feature restores

Both entries were written into `CONTEXT.md` ahead of the code and lifted back
out when pairing was deferred. They return to the glossary in ticket 06, along
with the removal of **Match delivery** and of **Scorer**.

**Live link**:
The conversation between the phone and the watch while a match runs: the journal
goes out to the watch after every change, intents come back from it. It is not a
hand-off and not a backup — there is one match, in one place, and the link is
how the other device sees it and reaches it. Lose the link and the match stands
still: the watch says so and stops taking taps, and what is played in the
meantime is recorded nowhere.
_Avoid_: synchronization, sync, delivery (there is nothing to deliver any more)

**Intent**:
A request from the watch to change the match — a rally to a side, an undo, an
end, a start. It is not a rally until the phone records it, and the phone is the
only judge: an intent is refused when the match is over, when there is no match,
and when the journal it was formed against is no longer the journal the phone
holds. The watch draws nothing until the journal comes back.
_Avoid_: command, event, action, message

## Consequences, stated plainly

- **A paired match needs both devices.** A player who leaves the phone in a
  locker cannot score one, and neither can a player whose watch is flat. What
  this means for the other two ways of scoring is the open question above.
- **A match interrupted by a flat phone is not lost**, but it is frozen: the
  watch refuses taps while the phone is unreachable, and the rallies played in
  the meantime are recorded nowhere.
- **Almost none of this can be verified in a simulator.** Ticket 07 is that
  run-through, and it needs a human and a real pair.

## The tickets

```
01  what travels: the journal out, intents in
02  the two ends: the host and the remote
03  the transport becomes live
04  the workout mirrors, and the phone stays awake
05  the watch becomes a remote
06  the delivery is removed
07  the live pair run-through
```

01 blocks 02 and 03. 04 and 05 wait on both of those; 06 waits on 05; 07 waits
on all of it, and on `phone-scoring` having landed.
