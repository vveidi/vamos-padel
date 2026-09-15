# 01: What travels — the journal out, intents in

**What to build:** the vocabulary of the live link. The match goes out to the
watch as the journal it already is; a request to change it comes back as an
**intent** carrying the journal length it was formed against.

**Blocked by:** None

**Status:** needs-triage

- [ ] `MatchIntent` exists in `PadelDelivery`: `start(ruleset:firstServer:)`,
      `rally(wonBy:base:)`, `undo(base:)`, `end(base:)`
- [ ] `base` is the number of rallies the watch's screen was showing when the
      intent was formed; `start` carries none, having no journal to stand on
- [ ] The outgoing side of the wire is `MatchUpdate`: either the whole match
      (`SavedMatch`) or `noMatch` — the phone saying there is nothing running
- [ ] `MatchPayload` encodes and decodes all of it, key by key and by hand, as
      it does today: the keys are a contract between two separately updated
      apps and must not follow a rename in the engine
- [ ] The existing match keys are unchanged, so a payload written before this
      ticket still decodes
- [ ] `Arrival.receipt` is gone from the payload's vocabulary; nothing signs for
      anything any more
- [ ] Tests round-trip every intent, both updates, and both rulesets, and
      assert that a payload missing its journal, its kind, or its base is
      refused rather than defaulted
- [ ] `swift test` is green in `PadelDelivery`

## The shape

```swift
public enum MatchIntent: Equatable, Sendable {
    case start(ruleset: Ruleset, firstServer: Side)
    case rally(wonBy: Side, base: Int)
    case undo(base: Int)
    case end(base: Int)
}

public enum MatchUpdate: Equatable, Sendable {
    case match(SavedMatch)
    case noMatch
}
```

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
