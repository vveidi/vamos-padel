# 03: The two ends — the host and the remote

**What to build:** the phone's end, which holds the match and judges intents,
and the watch's end, which holds the last journal that arrived and sends them.
Both pure, both tested against a stub transport, neither knowing what
WatchConnectivity is.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `MatchHost` in `PadelDelivery`: holds the running match, applies intents,
      writes to the store after every change, and broadcasts a `MatchUpdate`
      after every change and on every request
- [ ] Its own screens use the same door as the watch does: the scoreboard calls
      `record(rallyWonBy:)`, `undo()`, `end()` on the host, and the host is the
      only place a rally is ever recorded
- [ ] An intent is refused, with nothing changed and the current update sent
      back, when: there is no match, the match is over, or `base` is not the
      current number of rallies
- [ ] `start` is refused while a match is running — one match at a time, which
      is what the history's live tile relies on
- [ ] `MatchRemote` on the other end: keeps the last update, exposes whether the
      link is alive, sends intents, and holds no match of its own
- [ ] Both are `@Observable`, so a screen redraws when an update lands
- [ ] The host restores a match in progress from the store at launch and
      broadcasts it
- [ ] Tests: a rally recorded through an intent and through the host's own
      method reach the same journal; a duplicate intent records once; a stale
      intent is refused and answers with the truth; an intent into a finished
      match is refused; the remote renders exactly what it was sent and nothing
      of its own
- [ ] `swift test` is green in `PadelDelivery`

## The judgment, in one place

```swift
func apply(_ intent: MatchIntent) {
    switch intent {
    case .rally(let side, let base) where stands(on: base):
        record(rallyWonBy: side)
    case .undo(let base) where stands(on: base):
        undo()
    case .end(let base) where stands(on: base):
        end()
    case .start(let ruleset, let firstServer) where match == nil:
        start(ruleset: ruleset, firstServer: firstServer)
    default:
        break
    }

    broadcast()
}
```

`broadcast()` runs on every path, refusals included: a refused intent is exactly
the case where the other end is wrong about the score and most needs telling.

## Notes

**Why the phone's own screens go through the host.** If the scoreboard mutated
the match directly and the host only handled intents, there would be two paths
into the journal and one of them would forget to broadcast. There is one door.

**The remote deliberately keeps nothing.** No store, no journal, no optimistic
copy — the watch's screen is a function of the last update it received.
Closing the app mid-match loses nothing because there is nothing on that end to
lose: on the next launch it asks and is told.

**Failure to write is not failure to score.** The host follows what `MatchView`
does today: a store that will not write gets a line in the log, and the match
goes on. On court the score matters more than what becomes of it in the evening.
