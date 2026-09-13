# 04: The transport becomes live

**What to build:** one transport protocol carrying payloads both ways over
`sendMessage`, with reachability surfaced as a value a screen can draw, and the
system queue left behind.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `MatchTransport` replaces `MatchSender` and `MatchReceiver`: send a
      payload, be told when one arrives, be told when reachability changes, and
      report reachability now
- [ ] `WatchConnectivityTransport` sends with `sendMessage` and no longer calls
      `transferUserInfo`
- [ ] It is still the only file in the codebase that knows what
      WatchConnectivity is, and it is still one object standing at both ends
- [ ] `sessionReachabilityDidChange` reaches the ends as a value; a send while
      unreachable fails immediately instead of queueing
- [ ] `NoMatchTransport` keeps its place for previews, for an iPad, and for a
      phone with no watch
- [ ] Tests against a stub cover: a payload that goes out and comes back, a send
      refused while unreachable, and reachability changing under an end
- [ ] `swift test` is green in `PadelDelivery`

## Notes

**Why `sendMessage` and not the queue.** `transferUserInfo` guarantees arrival
and promises nothing about when — right for a finished match, wrong for a live
one. The queue's other virtue, surviving the app being unloaded, is no longer
wanted: an intent that arrives ten minutes late is an intent formed against a
journal that has moved on, and the host would refuse it anyway (ticket 02's
`base`).

**Reachability is a value, not a log line.** The watch has to say "no link to
the phone" and stop taking taps (ticket 09), and the scoreboard has to say the
watch is gone. Both read it here.

**The mirrored session's own channel is not used** — ADR-0010 says why, and the
same ADR names it as the fallback if `sendMessage` misbehaves on a live pair.
Should that happen, it is a second implementation of this protocol and no screen
changes.
