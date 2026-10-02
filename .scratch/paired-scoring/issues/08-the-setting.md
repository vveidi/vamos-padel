# 08: The setting — whether a match starts paired

**What to build:** a switch on each device's start screen that says whether a
match started there is a paired match, and what happens when the other device
cannot take part.

**Blocked by:** 04, 05

**Status:** ready-for-agent

- [ ] The watch's start screen gains a row beside "Recording to Health"; the
      phone's new match screen gains one too. Each is remembered on its device
      until the next match, the way the ruleset is, and both start off
- [ ] **The device the match is started on decides.** Its own switch says
      whether the match is paired; the other device's switch plays no part
- [ ] Paired, started on the watch: the watch asks the phone to start it
      (ticket 05). Paired, started on the phone: the phone starts it and raises
      the watch (ticket 04)
- [ ] **The other device cannot take part** — unreachable, or already scoring a
      match of its own: the start screen says which, and offers to start this
      match alone on this device in one tap. It never falls back silently, and
      it never takes over the other device's match
- [ ] With Health refused on the phone, its switch is off and cannot be turned
      on, says why, and leads to the Settings app (ticket 04)
- [ ] The rows' wording is checked against the string, not this ticket — the
      working labels are "Score on iPhone" on the watch and "Use Watch" on the
      phone, each naming what the other device will do
- [ ] The new strings are in the catalogs in both languages, English as the
      source (ADR-0005), and spoken by VoiceOver
- [ ] Previews cover each start screen with the switch on and off, and each of
      the two refusals

## Notes

**Why a switch on each device and not one shared.** It is a preference about
starting from here: on the watch it means "when I start from the wrist, let the
phone hold the match". A shared setting would make one device's choice overrule
the other's, and a player who turned it on on the watch would not know why a
match started on the phone did not pair. ADR-0017 records it.

**Why it starts off.** The paired match is the most fragile of the three ways to
score, and ticket 07 is the first time anyone will know how fragile. It is
switched on by a player who asked for it.
