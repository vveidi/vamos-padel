# 05: The watch's logs reach the phone

**What to build:** a button in the watch's console sends the watch's whole Pulse
store to the phone as a `.pulse` file. The phone keeps the latest one it got,
and its console opens it as a second console, "Watch logs", with Pulse's own
search, filters and share.

**Blocked by:** 03

**Status:** ready-for-human

- [ ] The watch's console has a "Send to iPhone" button in its top bar
- [x] The file travels over WatchConnectivity's file transfer, so it waits for
      the phone instead of failing when the phone is out of reach
- [x] The phone keeps one watch store: a new one replaces the last
- [x] The phone's console has a "Watch logs" entry that opens that store in
      `ConsoleView`; with nothing received yet, it says so
- [ ] Pulse's share from the watch-logs console works on the phone: AirDrop,
      Files, Mail
- [ ] Verified on a real pair: sent from the watch, read on the phone, shared
      from the phone to a Mac

## Notes

Why: the watch's own share sheet offers only Mail and Messages, and a store
mailed from the watch never arrived — not the full one, not one cut to the last
session as HTML. Without the watch's logs, `paired-scoring/15` cannot be
diagnosed.

Pulse 5.2.3's "Plain Text" output crashes on the watch: its watchOS share screen
force-casts the export to `[URL]`, and plain text exports a `String`. The owner
chose to leave it alone; this ticket does not need it.

## Comments

**2026-10-03, closing note.** Shipped: the watch copies its store's database
and sends it with `transferFile`, the manifest in the metadata; the phone
builds a store from it, keeps the latest, and opens it read-only under "Watch
logs". Pulse 5.2.3 cannot open its own `.pulse` export, so no export travels.

The button sits in the bottom bar: the top bar's two places are the sheet's
close button and Pulse's settings. Left unticked for the owner to accept.

Driven on a simulator pair, in both languages and at AX5: the button, the copy
and the transfer on the watch; the empty state, the store, Share and its
system sheet on the phone, with the watch's real copy put in place by hand.
The pair never hands a transferred file to the phone app, as 04 found for
`transferUserInfo`. Share and the read both default to a session the watch's
store does not hold: that is 06. The last two criteria stay for a real pair.
