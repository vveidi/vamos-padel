# 01: What travels — the journal out, intents in

**What to build:** the vocabulary of the live link. The match goes out to the
watch as the journal it already is; a request to change it comes back as an
**intent** carrying the journal length it was formed against, and the update
that answers it says whether it was taken.

**Blocked by:** None

**Status:** done

- [x] `MatchIntent` exists in `PadelDelivery`: `start(ruleset:firstServer:)`,
      `rally(wonBy:base:)`, `undo(base:)`, `end(base:)`
- [x] `base` is the number of rallies the watch's screen was showing when the
      intent was formed; `start` carries none, having no journal to stand on
- [x] The outgoing side of the wire is `MatchUpdate`: either the whole match
      (`SavedMatch`) or `noMatch` — the phone saying there is nothing running
- [x] An update sent in answer to an intent carries its **echo**: the intent it
      answers and whether it was `accepted` or `refused`. An update the host
      sends on its own — a rally awarded on the phone, a request for the
      current match — carries none
- [x] `MatchPayload` encodes and decodes all of it, key by key and by hand, as
      it does today: the keys are a contract between two separately updated
      apps and must not follow a rename in the engine
- [x] The existing match keys are unchanged, so a payload written before this
      ticket still decodes, and the delivery of a match scored on the watch
      alone — `Arrival.receipt` included — goes on working untouched
- [x] Tests round-trip every intent, both updates with and without an echo, and
      both rulesets, and assert that a payload missing its journal, its kind, or
      its base is refused rather than defaulted
- [x] `swift test` is green in `PadelDelivery`

## The shape

```swift
public enum MatchIntent: Equatable, Sendable {
    case start(ruleset: Ruleset, firstServer: Side)
    case rally(wonBy: Side, base: Int)
    case undo(base: Int)
    case end(base: Int)
}

public enum MatchUpdate: Equatable, Sendable {
    case match(SavedMatch, echo: Echo?)
    case noMatch(echo: Echo?)
}

public struct Echo: Equatable, Sendable {
    public let intent: MatchIntent
    public let accepted: Bool
}
```

The names are a starting point, not a contract; the keys on the wire are.

## Notes

**Why the score is not on the wire.** The watch is handed the journal and
computes the state with `PadelScoring`, which it already links. Sending
`MatchState` would put a computed value on the wire, and ADR-0001's argument
against storing it beside the journal is the same argument here: two copies of
the score drift, and the one the player is looking at would be the stale one.

**Why `base` and not a sequence number.** A sequence number counts messages; the
journal length counts rallies, which is what an intent is actually about. It
gives idempotency (a message delivered twice records once) and staleness
detection (a tap made against a screen that has fallen behind is refused) with
one integer that needs no state of its own to interpret.

**`end` carries a base too.** Ending is a change to the match like any other,
and an end formed against a stale screen — the player tapped "end" while the
last rally was still in flight — should be refused for the same reason.

**Why the echo.** The watch needs two answers the journal alone cannot give.
Whether its tap was refused, so a refusal can look different from a rally
(ticket 05). And whether a rally that arrived is its own, so it marks the
rallies it awarded and not the ones it is told about (ADR-0011): a rally to us
on top of 27 awarded on the phone a moment before the watch's own looks exactly
like the watch's in the journal, and the watch's was refused.

**The delivery stays.** A match scored on the watch alone still reaches the
history the way it does today (ADR-0017); its keys and its receipt are not this
ticket's to touch.

## Comments

Shipped as sketched: `MatchIntent`, `MatchUpdate` and `Echo` in `Transport/`,
encoded by `MatchPayload` beside the match and the receipt. The new wire kinds
are `intent`, `liveMatch` and `noMatch`. An echo is a nested parcel: the
intent's own keys plus `accepted`. The match keys are untouched, and a test
decodes a parcel written by hand in the old shape. A negative base is refused
along with a missing one. `WatchConnectivityTransport` logs and drops the new
kinds until ticket 03 opens the link.
