# 11: The two fonts

**What to decide, then build:** whether Unbounded and Golos Text ship with the
app, and if so how they get there.

**Blocked by:** 01

**Status:** needs-triage

This ticket is deliberately not `ready-for-agent`. The redesign ships on system
faces first (ticket 01), and this is the conversation about replacing them, held
against a running app rather than against a mockup.

## What the boards ask for

`canvas-court/` is set in two faces:

- **Unbounded** for numbers and titles — geometric, wide, tight tracking. It is
  what makes the score screen look like a scoreboard and not like a system app.
- **Golos Text** for everything else — a neutral grotesque.

Both are OFL, and both carry Cyrillic, which is not optional: the app speaks two
languages and they are equal on screen (ADR-0005).

## The three ways in

**(a) Bundle in `PadelDesign`.** `Info.plist`'s `UIAppFonts` only reads the
*app* bundle, so a font shipped as an SPM resource has to be registered at
launch with `CTFontManagerRegisterFontsForURL`. Roughly twenty lines. The prize
is that the package is the whole look — import one thing, get the design. The
cost is a registration step that fails silently and leaves the app in its
fallback face with nothing to show for it.

**(b) Bundle in the app targets.** Font files in `Padel/` and `Padel Watch
App/`, `UIAppFonts` in each `Info.plist`, and `PadelDesign` holds only the
names. System-blessed and simple; the files are duplicated and the package
stops being self-contained.

**(c) Don't.** Keep the ramp on SF Rounded and SF. The court, the colours and
the ball carry the design; the type does less work than the mockup suggests.

## What to decide it on

The reason this waits for a running app: **the boards' type sizes are not
trustworthy** (see the spec's "Reading the boards" — the watch boards are 2x and
their type was drawn at phone scale). So the question "does Unbounded look
better than SF Rounded here" cannot be answered from `canvas-court/`. It can be
answered from a build.

Things worth having in hand before deciding:

- The score screen on an actual wrist, at 46pt and at 64pt, in both faces
- Cyrillic in both faces at caption size — this is where a Latin-first
  geometric face usually falls apart
- What the app weighs. Two families with Cyrillic, several weights each, on a
  watch app, is not nothing
- Whether Dynamic Type still behaves. A custom face needs `relativeTo:` on
  every call, and the ramp already provides it — but the *metrics* differ, and
  a face that is wider at the same point size will break the rules screen's
  label column before SF does

## If it ships

- [ ] The licences travel with the files, and an acknowledgements entry exists
- [ ] The ramp is the only file that changes — no screen names a face
- [ ] Registration failure falls back to the system faces rather than to
      whatever `Font.custom` returns for a missing name
- [ ] Cyrillic is checked at every ramp entry, in a preview, at the largest and
      smallest Dynamic Type settings
- [ ] The watch app's size on disk is compared before and after, and written
      into the closing note

## Notes

**On why the ramp came first.** Ticket 01 builds the ramp with system faces
precisely so that this ticket is a one-file change. If it turns out to be more
than that, something in 01 leaked — a screen naming a face — and that is the
bug, not this ticket's scope.

**On (c) being a real answer.** It is the current state, and the app will have
shipped a full redesign on it. "The system face is fine here" is a legitimate
outcome, not a failure to finish.
