# The boards

Six artboards and the canvas that lays them out — the design the app is drawn
from. They came out of the redesign, which shipped; that feature's tickets are
gone and these outlived them, because two of the boards had never been built
and the rest are still what the built screens answer to.

They live in `docs/` rather than under `.scratch/` for that reason: the tracker
holds work in flight and is emptied as features close, while this is what the
repo keeps.

    Main.dc.html            watch · start
    WatchRules.dc.html      watch · rules
    WatchScore.dc.html      watch · score
    PhoneHistory.dc.html    phone · history
    PhoneScore.dc.html      phone · score      — phone-scoring ticket 07
    PhoneNewMatch.dc.html   phone · new match  — phone-scoring ticket 06

`padel-night-court.html` renders the whole canvas and is not in git: it is the
seeded payload, regenerable from the `.dc.html` sources beside it.

## Reading the boards

Doc comments across `PadelDesign` and both apps cite this section by name. It is
one rule and it is not obvious:

> **Layout, proportion and hierarchy transfer from the boards. Type sizes do
> not.**

The watch boards are drawn at 2x (396×484 px = 198×242 pt) and their layout
obeys that — a 46px header is 23pt, a 58px segment is 29pt. Their *type* does
not: a 14px row label would be 7pt, below anything watchOS has a text style for,
and the 92px score would be 46pt against the 64pt the screen used. The boards
were drawn at phone scale and the watch ones doubled afterwards.

So every size comes from the ramp in `PadelDesign/Tokens/Typography.swift`, at
the platform's own scale, and the board decides only which ramp entry a thing
gets. The phone boards are 1x and their numbers are honest — 31pt titles, 128pt
score, 13–15pt supporting text — but they go through the ramp too.

## What the boards say that the app does not do

`PhoneScore.dc.html` is portrait, with the net horizontal and the halves
stacked. The scoreboard `phone-scoring` builds is landscape, with the net
vertical and the halves side by side. Both follow one rule — the net crosses the
long axis — and the board is the reference for everything else on it: the scrim,
the top strip, the corner ball, the bottom controls.

The board also draws an **Undo** and an **End** in that bottom bar. They were
out of scope when it was drawn, because there was no phone scoring to undo. They
are in scope now.
