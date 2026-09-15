# A design package, one court, and no light mode

The app's look lives in a fourth local package, `PadelDesign`, and not in the
two app targets. It draws one thing — a padel court at dusk, seen from above —
in one palette, with one accent color, and it has no light variant.

Three decisions, recorded together because they are one design and separating
them would make each look arbitrary.

## A package rather than styling per target

The watch and the phone are separate Xcode targets and cannot share a file
without a package between them. Five of the six artboards draw the net, four
draw the two-half court, four draw the ball; left in the targets, those are
drawn twice each at best and drift apart by the second ticket.

A tokens-only package — colors and fonts, shapes redrawn per screen — was the
alternative. It fixes color drift and none of the shape drift, and the shape
drift is the one that shows: a net with the posts at the wrong end reads as a
different app.

The interface is that **the package knows about a court, a net and a ball, and
never about a match**. `ScoreView` keeps the mapping from a serving half to a
corner of the screen, because which corner a serve belongs in is domain knowledge
wearing layout's clothes. The package is asked for a ball in a corner and
nothing more.

`PadelDesign` depends on `PadelScoring` — for `Side`, and for `Outcome`. A local
`CourtSide` would keep the package free of the domain at the price of a second
name for a thing `CONTEXT.md` has already named and already listed the synonyms
to avoid for. The dependency runs one way and stays that way: nothing in
`PadelScoring`, `PadelStorage` or `PadelDelivery` imports `PadelDesign`.

## One accent, and it is the ball

The ball's yellow is the only color in the app, and it means one thing: *this
is yours, or this is chosen*. It marks the serve, the half you picked, and the
button that starts the match. Losses go cold and gray.

There is no red anywhere — not on the destructive "End", not on a loss. A red
would be the second color, and a second color argues with the first: once
loss is red, the yellow stops meaning "yours" and starts meaning "good", which
is a different and much weaker idea.

This is why the serve indicator went from white to yellow, retiring the comment
that argued for white on the grounds that a fifth color would be spent on the
smallest thing on screen. In this design the smallest thing on screen is exactly
what the one color is for.

## Dark only

There is no light palette. A court at noon is a second design, with its own
artboards and its own argument about where the light comes from, and nobody has
drawn it. The phone pins `.dark`; the watch is dark already.

Recorded here because it is the decision most likely to be mistaken for an
oversight — a phone app that ignores the system appearance looks unfinished
unless somebody says it was chosen.

## Consequences

- **A phone in light mode gets the night court anyway.** Accepted. The
  alternative is a design that does not exist.
- **The redesign creates an Always-On problem the app did not have.** A
  full-bleed saturated court held up for a ninety-minute match is a burn-in and
  battery cost the old near-black screen did not carry, so the court primitives
  gained a dimmed variant: the geometry and the score survive, the light and the
  texture go.
- **The screens no longer get accessibility for free.** `List` rows, `Picker`s
  and `Toggle`s came with VoiceOver and Dynamic Type built in; a floating
  control on a full-bleed court does not. Every affordance the system gave has
  to be put back by hand, and the Digital Crown is part of that — the rules
  screen's numbers are stepper rows precisely so the crown still scrubs a range
  of thirty-six values.
- **The type ramp is an interface of its own.** Screens name ramp entries, never
  faces, so the two custom faces the design was drawn in can arrive — or be
  declined — by changing one file.
- **They were declined.** The boards are set in Unbounded and Golos Text; the
  app ships on SF Rounded for the numbers and titles and SF for the rest. The
  court, the colors and the ball carry the design, and two families with
  Cyrillic in several weights are weight on a watch app for a difference the
  built screens did not show. The ramp is where this would be reversed, and it
  is still one file.
