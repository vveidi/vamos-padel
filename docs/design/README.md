# The boards

One artboard and the canvas that lays it out — the phone screen that has not
been built yet. It came out of the redesign, which shipped; that feature's
tickets are in `.scratch/archive/redesign/` and this outlived them, because it
is what `phone-scoring` will be drawn from.

    PhoneScore.dc.html      phone · score      — phone-scoring ticket 04

It lives in `docs/` rather than under `.scratch/` because the tracker holds
work in flight and archives each feature as it closes, while a board outlives
the ticket that reads it.

Beside them sit two **studies** — pages that are not artboards and are not in
the canvas. See "The studies" below.

`padel-night-court.html` renders the canvas and is not in git: it is the seeded
payload, regenerable from the `.dc.html` sources beside it.

## A board is deleted when its screen is built

There were six. The five that shipped — the watch's start, rules and score
screens, and the phone's history and new match — were deleted once the screens
existed, because after that the screen is the design and a second drawing of it
is a second source of truth that quietly goes stale. What they were is in the
git history (`git show c349a34:docs/design/Main.dc.html`); what they *are* is in
`PadelDesign` and in the screens themselves.

What stayed behind is the numbers they gave: each built screen keeps a private
`Board` enum holding the paddings and gaps read off its artboard, and those doc
comments still say "the board's 16px". That provenance is history now, and the
number in the code is the live one.

## Reading the boards

Doc comments across `PadelDesign` and both apps cite this section by name. It is
one rule and it is not obvious:

> **Layout, proportion and hierarchy transfer from the boards. Type sizes do
> not, and neither do the typefaces.**

The remaining board is a phone board, drawn 1x, and its numbers are honest —
31pt titles, 128pt score, 13–15pt supporting text. Every size still goes through
the ramp in `PadelDesign/Tokens/Typography.swift`, at the platform's own scale,
and the board decides only which ramp entry a thing gets. The two faces the
boards are set in — Unbounded and Golos Text — were declined (ADR-0006): the app
is the system face with `.rounded`.

The watch boards, while they existed, were drawn at 2x (396×484 px = 198×242
pt), which is why the watch's `Board` enums halve every number they quote.

## What `PhoneScore.dc.html` says that the app will not do

It is portrait, with the net horizontal and the halves stacked — the
scoreboard's arrangement in any window that is not wider than it is tall. A wide
window turns it, the net vertical and the halves side by side. Both follow one
rule — the net crosses the long axis (ADR-0015) — and the board is the reference
for everything else on it: the scrim, the top strip, the bottom controls. Its
ball is not: the corners are the watch's (ADR-0013).

It also labels the halves "Them" and "Us". The watch's score screen decided
otherwise and the phone follows it: which half is ours is said by where it is —
theirs across the net, ours on our side of it — and never by a label that takes
room from the digit the board is being read for. The board draws two halves in
two colors, and that is the second thing on it that no longer ships:
`court-surface` collapsed them into one blue with no painted lines, so position
and the net carry that on their own.

The **Undo** and **End** it draws in the bottom bar were out of scope when it was
drawn, because there was no phone scoring to undo. They are in scope now.

## The studies

    RallyMark.html   the rally mark, and the four candidates it beat — ADR-0011
    AppIcon.html     the app icon, the candidate it beat, and the icon it replaced — ADR-0016

A study is not a board. A board draws a screen that has not been built and is
deleted the day it ships; a study answers one question that several screens will
be built against, and it survives because the **alternatives** are the thing
worth keeping. A decision with its rejected options thrown away is not a
decision, it is an assertion, and the next person to ask "why not green?" has
nowhere to read the answer.

`RallyMark.html` fires five candidate marks across four court surfaces — the
night court that ships and three themes that do not exist yet — and keeps the
rejected undo beside them, because the reason it was rejected is only visible by
pressing it. ADR-0011 states what was decided and what it costs; this is where it
can be seen.

Studies are not in `canvas.json` — they are pages to open, not artboards to lay
out — and they are not drawn 1x or 2x, because they draw no screen.
