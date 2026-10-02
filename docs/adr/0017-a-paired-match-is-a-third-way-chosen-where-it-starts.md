# A paired match is a third way to score, chosen on the device it starts on

A paired match lives on the phone and takes the watch as its remote (`.scratch/paired-scoring/`). It joins the two ways of scoring alone rather than replacing them: a player who leaves the phone in a locker, or whose watch is flat, still scores a match. Each device's start screen carries a switch, off until a player turns it on, and the device a match is started on decides by its own switch whether that match is paired. The other device's switch plays no part.

Three other answers were weighed. **Replacing** both solo ways makes every match need both devices. **Pairing automatically** whenever the other device answers at the start hides a choice the player cannot see being made, and a phone that answered at the start may be out of range a set later. **One shared setting** lets one device's switch overrule the other's, and a player who turned it on on the wrist would not know why a match started on the phone did not pair.

## Consequences

- **ADR-0009 holds for a solo match only.** Its scorer is still the device it was started on; a paired match's scorer is the phone, wherever it was started. "The scorer is not a setting" no longer holds: pairing is one.
- **ADR-0002 and ADR-0004 stand.** A match scored on the watch alone is delivered as before, so the delivery, the receipt, the queue and the watch's store all stay.
- **Never a silent fallback.** When the other device is out of reach or already scoring a match of its own, the start screen says which and offers to score this one alone. It never takes over the other device's match.
- **The two halves of a broken link are not symmetrical.** The phone is the scorer, so a lost watch leaves the match going on the scoreboard, and a lost phone freezes it on the wrist.
- **Health refused on the phone means no paired match there.** Without a mirrored workout session the phone lives only while its screen is on (ADR-0010).
