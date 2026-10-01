# The boards

One board file is waiting, and the canvas lays it out:

    WatchTapMode.dc.html    watch · tap mode   — watch-tap-mode tickets 03, 04 and 05

It holds three boards: the tap-mode page, the start settings page with the
tap-mode card in it, and the score screen's trailing edge under the page
indicator. Each is deleted as its ticket closes — 03 and 04 the first and
third, 05 the second — and the canvas is left with its notes and no boards.

Every screen the redesign drew has been built; its tickets are in
`.scratch/archive/redesign/`.

A board lives in `docs/` rather than under `.scratch/` because the tracker holds
work in flight and archives each feature as it closes, while a board outlives
the ticket that reads it.

Beside the canvas sit two **studies** — pages that are not artboards and are
not in the canvas. See "The studies" below.

## A board is deleted when its screen is built

There were six — the watch's start, rules and score screens, and the phone's
history, new match and scoreboard — and each was deleted once its screen
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

The phone boards were drawn 1x, and their numbers were honest — 31pt titles,
128pt score, 13–15pt supporting text. Every size still went through the ramp in
`PadelDesign/Tokens/Typography.swift`, at the platform's own scale, and the
board decided only which ramp entry a thing got. The two faces the boards are
set in — Unbounded and Golos Text — were declined (ADR-0006): the app is the
system face with `.rounded`.

The watch boards are drawn at 2x (396×484 px = 198×242 pt), which is why the
watch's `Board` enums halve every number they quote.

`WatchTapMode` is the exception on type: it is set in SF Compact at the ramp's
own sizes, doubled, because two of its boards exist to show where a line wraps
and how long a scroll is. Its sizes still do not transfer — the ramp already
holds them.

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
