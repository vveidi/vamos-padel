# The score screen is drawn from our end of the court

The watch's score screen is a court seen from where we stand: our half below the
net, the opponents' above it. Everything positional on that screen is in the
viewer's frame, and the one place that converts into it is
`serveAlignment(for:from:)` in `ScoreView.swift`.

## The two halves mirror, and that is not a slip

A `ServingHalf` is the server's own right or left — it is what the players say
to each other on court, and it is what the scoring package stores. Drawn from
our end, our right is at screen **trailing**; the opponents are facing us, so
their right is at screen **leading**.

That is why one enum case produces two opposite alignments:

    case (.us, .right):   .topTrailing
    case (.them, .right): .bottomLeading

The correction not to make is flattening it to one case per half —
`case (_, .right): .trailing` — which puts both balls down the same edge and
draws our serve to the opponents' box as a straight line up the screen. Padel
has no such serve; the diagonal is the whole point of the indicator.

**Nothing goes red for that mistake.** No test target reaches the watch app, so
the app is simply wrong about the opponents' half from then on, in a way only
somebody standing on a court notices. The four corner previews in
`ScoreView.swift` are named for the surprise — "the opponents serve from their
right (screen left)" — because a picture is the only check there is.

## The ball sits in the zone's inner corner

Both balls go to the corners nearest the net: our half's top, the opponents'
bottom. The vertical position carries no meaning, and the outer corners would
have been the truthful ones, since the server stands at the back of the court.
They are not used, for two reasons that have nothing to do with padel:

- **The watch's clock** is drawn over the opponents' top trailing corner and
  cannot be hidden by a third-party app.
- **`ScorePages`' page dots** sit over our bottom.

The inner corners are clear of both, they keep their distance from the sets
digit at the trailing edge, and they put the two balls either side of the net,
mirroring each other the way the halves do.

## Consequences

- **`ServingHalf` never reaches the screen unconverted.** Anything else that
  wants to draw the serving half — the phone's scoreboard, a future tap-mode
  layout — converts through the same frame or states its own.
- **VoiceOver speaks the server's frame, not the screen's.** `servingClause`
  says "serving from the right" meaning the server's right; the mirroring is a
  drawing concern and is never spoken.
- **A golden point has no half.** The ball goes to the middle of the inner edge,
  still saying who serves and no longer saying from where.
