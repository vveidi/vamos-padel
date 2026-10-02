# 02: The two ends — the host and the remote

**What to build:** the phone's end, which holds the match and judges intents,
and the watch's end, which holds the last update that arrived and sends them.
Both pure, both tested against a stub transport, neither knowing what
WatchConnectivity is.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `MatchHost` in `PadelDelivery`: holds the running match, applies intents,
      writes to the store after every change, and broadcasts a `MatchUpdate`
      after every change and on every request
- [ ] Every match the phone scores goes through it — a paired match and one the
      phone scores alone. The scoreboard calls `record(rallyWonBy:)`, `undo()`,
      `end()` on the host, and the host is the only place on the phone a rally
      is ever recorded
- [ ] An intent is refused, with nothing changed and the current update sent
      back with a refused echo, when: there is no match, the match is over, or
      `base` is not the current number of rallies
- [ ] `start` is refused while a match is running — paired or not, one match at
      a time, which is what the history's live tile relies on and what the watch
      is told when the phone is busy (ticket 08)
- [ ] `MatchRemote` on the other end: keeps the last update, sends intents, and
      holds no match of its own
- [ ] Both hand their state out as an `AsyncStream` — the updates, and on the
      remote whether the link is alive — and neither is `@Observable`: the
      screen holds the `@State`, as everywhere else in the packages
- [ ] The host restores a match in progress from the store at launch and
      broadcasts it
- [ ] Tests: a rally recorded through an intent and through the host's own
      method reach the same journal; a duplicate intent records once; a stale
      intent is refused and answers with the truth; an intent into a finished
      match is refused; the echo names the intent it answers; the remote's
      stream yields exactly what it was sent and nothing of its own
- [ ] `swift test` is green in `PadelDelivery`

## The judgment, in one place

```swift
func apply(_ intent: MatchIntent) {
    let accepted: Bool
    switch intent {
    case .rally(let side, let base) where stands(on: base):
        record(rallyWonBy: side)
        accepted = true
    case .undo(let base) where stands(on: base):
        undo()
        accepted = true
    case .end(let base) where stands(on: base):
        end()
        accepted = true
    case .start(let ruleset, let firstServer) where match == nil:
        start(ruleset: ruleset, firstServer: firstServer)
        accepted = true
    default:
        accepted = false
    }

    broadcast(echo: Echo(intent: intent, accepted: accepted))
}
```

`broadcast` runs on every path, refusals included: a refused intent is exactly
the case where the other end is wrong about the score and most needs telling.

## Notes

**Why the phone's own screens go through the host.** If the scoreboard mutated
the match directly and the host only handled intents, there would be two paths
into the journal and one of them would forget to broadcast. There is one door,
and a match the phone scores alone uses it too: it then broadcasts to nobody.

**The remote deliberately keeps nothing.** No store, no journal, no optimistic
copy — the watch's screen is a function of the last update it received.
Closing the app mid-match loses nothing because there is nothing on that end to
lose: on the next launch it asks and is told. The watch's own store stays, for
the matches it scores alone; the remote never writes to it.

**Failure to write is not failure to score.** The host follows what `MatchView`
does today: a store that will not write gets a line in the log, and the match
goes on. On court the score matters more than what becomes of it in the evening.
