# 06: The watch logs open on a session they hold

**What to build:** the phone's "Watch logs" console, and its Share, start on the
watch's sessions instead of on none.

**Blocked by:** 05

**Status:** needs-triage

- [ ] Opening "Watch logs" lists the watch's messages without first picking a
      session
- [ ] Share from "Watch logs" exports the watch's messages with its defaults
- [ ] Verified on a real pair

## Notes

Pulse 5.2.3 gives a store opened `.readonly` the phone's own launch as its
current session, and its console and its Share both filter on the current
session by default. The watch's store holds none of the phone's sessions, so
"Watch logs" opens on "0 Logs", and Share defaults to an export of nothing,
until a session is picked through the sessions button. Nothing public in
`ConsoleView`, `ConsoleDelegate` or `LoggerStore` sets that session.

Pulse also files every launch's messages under the first session of the store
it opened (`initializeViewContext` takes the latest session before its own is
saved), so on the watch all messages sit in session #1 and later sessions look
empty.

The ways out are the owner's call: a fork or a patch of Pulse, a newer Pulse
if one fixes either, or living with the extra tap.

## Comments
