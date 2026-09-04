# 10: Handing a match to the phone

**What to build:** A finished match travels to the iPhone by itself. The player presses nothing: the watch puts the match in a queue, and it arrives once the phone is reachable — in an hour, or at home that evening. During play the phone is not needed.

The watch stays the source of truth until delivery is confirmed and does not delete the match before that. The queue survives a relaunch of the app.

The transport is hidden behind a protocol (ADR-0002): this is precisely the seam that is later swapped for a cloud or a server without moving the data. The tests cover the enqueuing logic against a stub; real delivery is checked by hand on two devices.

**Blocked by:** 07

**Status:** done

- [x] A finished match is put in the hand-off queue automatically
- [x] The queue survives a relaunch of the app on the watch
- [x] The match is delivered once the phone becomes reachable, with no action from the player
- [x] The phone saves the received match into its own store
- [x] Delivering the same match again does not create a duplicate
- [x] The watch does not delete the match before delivery is confirmed
- [x] The transport is reached through a protocol, not directly through the system API

## Comments

**What was built.**

The `PadelDelivery` package — a third one alongside `PadelScoring` and `PadelStorage`, linked
into both targets. It holds the seam from ADR-0002 (`MatchSender` and `MatchReceiver`), the
parcel format (`MatchPayload`), the two halves of delivery — `MatchDelivery` on the watch and
`MatchReception` on the phone — and the only implementation of the transport,
`WatchConnectivityTransport`, hidden behind `#if canImport(WatchConnectivity)`. The package's
tests run on macOS: a transport stub is possible precisely because the transport sits behind a
protocol rather than behind `WCSession`.

**The delivery queue is the store itself.** There is no separate "what to send" list: the
match is already written after every rally, and a second queue beside the first would diverge
from it sooner or later — the same argument by which the score is not stored beside the
journal (ADR-0001). The `match` table gained a `delivered` column;
`matchesAwaitingDelivery()` hands back the rows with an uncleared mark, filtering out matches
in progress by the engine rather than by a column. The queue survives a relaunch for free —
along with the matches.

**What takes a match off the queue is the receipt from the phone, not the sending.**
`transferUserInfo` puts the parcel into the system queue, which survives the app being
unloaded and the watch being restarted. That it arrived (`didFinish`) is not enough: the
system only knows that it carried a dictionary to the app, whereas the watch needs to know
that the match reached the history. So the phone, having written the match down, sends a
receipt back — the same parcel with a different key — and only that clears the queue. If the
database did not open on the phone there is no receipt, and the match will arrive again.

**Sending waits for the transport to be ready.** The session to the phone comes up
asynchronously, and a match handed to it before that would go nowhere, with no second attempt
in that launch. So what has piled up leaves from the readiness handler rather than from a
screen at launch.

**What gets delivered is a version, not a match.** A point undone in a finished match
(ticket 05) brings it back into play, and once played out again it diverges from what has
already left. So `save()` clears `delivered`, and the match leaves a second time; and the
receipt arrives with the whole match and sets the mark only if the watch still holds the same
version — otherwise a late receipt for a previous version would clear the queue the match had
just returned to.

**A match without a single rally does not leave.** A match begins with its first rally (the
glossary), and one stopped earlier is the trace of a mis-tap: "0:0, 0 minutes" is not history.
Ticket 11 will not have to filter such matches out of the list — they never reach the phone.

**A test found a bug in the store along the way.** Writing the journal used to be
incremental — "cut off what was undone, append what is missing" — and that is only right while
the journal changes at the tail. A match arrives on the phone as any version, though, and one
played out after a point was undone is no continuation of the previous one: appending a tail
to somebody else's middle assembled a journal nobody played, and did so silently — the length
added up. The journal is now rewritten in full; a match of two hundred rallies is one short
transaction.

**The watch deletes nothing.** Not here and nowhere else in v1: the match stays on the watch
after the confirmation too. The criterion is met with room to spare, and deliberately so —
there is no backup (ADR-0002), and it is too early to count the space a journal of two hundred
rows takes.

**How it was checked.** 21 tests in `PadelDelivery` and 11 new ones in `PadelStorage`: a
finished match lands in the queue, one in progress does not; an abandoned one lands (play in
it has ended); the queue survives a relaunch (a second connection to the same database); a
confirmed match is not sent again, an unconfirmed one is; one changed after delivery returns
to the queue; a match that arrives lands in the phone's store; one that arrives twice does not
create a second, and the second arrival updates the first; a parcel survives the round trip
with every ruleset, the abandoned mark and the journal; an unreadable parcel does not turn
into a match but throws; nothing leaves before the transport is ready; a receipt for a
previous version does not clear the queue; a match without rallies does not leave; the phone
does not sign for a match it failed to store. Real delivery on a pair of devices is for a
human, as the ticket assumed.

**A departure from the ticket: `matches()` and a screen on the phone.** The store gained a
list of matches, and the phone a `HistoryView`: the score, the date, the abandoned mark, a
sensible empty screen, freshest first. Without it there is no way to check the criterion "the
phone saves the received match" either by test (a duplicate is only visible in a list) or by
hand (a human has nowhere to look). This closes four of ticket 11's six criteria — not two,
and not with a "stub": what stays uncovered there is the duration and the ruleset, while the
live updating of the list and the presentation it will redo entirely.

**The behavior of the closed ticket 07 was changed.** `SQLiteMatchStore.save` no longer
appends to the journal at the tail but rewrites it in full (see above), and clears the
delivery mark. The first is a bug fix, the second is new behavior; both change a method
ticket 07 considered finished.

**ADR-0004 appeared** — "The delivery queue lives in the store": the decision to create a
second non-computable column beside the journal argues with ADR-0001's wording ("the only
exception"), and something like that cannot live in a comment.
