# 03: The transport becomes live

**What to build:** a live channel beside the queue. The paired match travels
over `sendMessage`, with reachability surfaced as a value a screen can draw;
the delivery of a match scored on the watch alone keeps `transferUserInfo`.

**Blocked by:** 01

**Status:** done

- [x] The transport protocol gains a live half: send a payload now, be told when
      one arrives, be told when reachability changes, and report reachability
      now
- [x] `WatchConnectivityTransport` sends the live half with `sendMessage`, and
      goes on sending a finished solo match with `transferUserInfo` exactly as
      it does today
- [x] It is still the only file in the codebase that knows what
      WatchConnectivity is, and it is still one object standing at both ends
- [x] `sessionReachabilityDidChange` reaches the ends as a value; a live send
      while unreachable fails immediately instead of queueing
- [x] `NoMatchTransport` keeps its place for previews, for an iPad, and for a
      phone with no watch
- [x] Tests against a stub cover: a payload that goes out and comes back, a live
      send refused while unreachable, reachability changing under an end, and a
      delivery still queued while the live half is unreachable
- [x] `swift test` is green in `PadelDelivery`

## Notes

**Why `sendMessage` for the live link.** `transferUserInfo` guarantees arrival
and promises nothing about when — right for a finished match, wrong for a live
one. The queue's other virtue, surviving the app being unloaded, is not wanted
here: an intent that arrives ten minutes late is an intent formed against a
journal that has moved on, and the host would refuse it anyway (ticket 01's
`base`).

**Why the queue stays.** A match scored on the watch alone is still delivered
once it is over (ADR-0017), and that is still the right channel for it. Two
channels, two kinds of traffic: the live one for a paired match, the queue for a
finished solo one. Neither carries the other's.

**Reachability is a value, not a log line.** The watch has to say "no link to
the phone" and stop taking taps (ticket 05), the scoreboard has to say the watch
is gone (ticket 04), and the start screens have to say a paired match cannot
begin (ticket 08). All three read it here.

**The mirrored session's own channel is not used** — ADR-0010 says why (ticket
04 files it), and names it as the fallback if `sendMessage` misbehaves on a live
pair. Should that happen, it is a second implementation of the live half and no
screen changes.

## Comments

The live half is `LiveLink` (reachability now, and when it changes), with
`ScorerLink` for the phone (sends updates, takes intents) and `RemoteLink` for
the watch (the reverse). Not `HostLink`: CONTEXT.md avoids "host". A live send
while unreachable throws `LiveLinkError.unreachable`. The logic sits in a
WatchConnectivity-free `SessionTransport` over a `DeviceSession`, so it runs
under `swift test`. The WatchConnectivity file is the adapter: one public
object, still the only file that imports the framework. Reachability is pushed
after activation and when an iOS session goes inactive. "An end" in the tests
is the transport's reachability handler, because the ends are ticket 02's. Each
handler is one slot, so fanning reachability out to several screens is up to
the ends.
