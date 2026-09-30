# The rally mark, drawn in the court's own color

When a rally is recorded the winning side's half brightens in its own tint and falls back. It is the only thing either score screen says that is not a number, and it exists because a counter moving from 30 to 40 is not something four people on a bench notice.

Two decisions, recorded together because separating them would make the second look like a bug.

## What it is made of

Five candidates were drawn and fired side by side across four surfaces — `docs/design/RallyMark.html`, which is kept for the four that lost. A burst of the floodlight's warm white; the court's three painted lines flaring to full strength; a wash of ball yellow; the half's own tint lifted; and the reference app's green.

The tint won, and what decided it was not this app but the next one. Every other candidate carries a hue, and a hue has to be re-decided the day the court can be Roland Garros clay or Wimbledon grass. A mark that *is* the surface, brightened, has nothing to re-decide: it is whatever the court is. ADR-0006 gives the app one accent and spends its whole argument refusing a second, and this is the only one of the five that never asks for one.

The green was never available. On grass a green flash on green is nearly invisible and on clay it is the one hue with no business being there — but it was out before either, because ADR-0006 is exactly the decision it would spend. The reference app can flash green because its field is black and carries no information. Ours is a court whose halves already mean something.

## Where it fires

**A device marks the rallies it awarded, not the rallies it is told about.** The watch marks a tap made on the watch; a rally awarded on the phone reaches it as a changed number and nothing else. The phone marks every rally whatever its origin.

The asymmetry is the room and not the code. On the wrist the mark confirms something you just did, and you already know you did it — the haptic said so. On the bench nobody is holding the phone: it is a scoreboard being read by four people, none of whom awarded anything, and a rally that moves it silently is the problem this feature was opened to fix.

It fires on the journal changing and never on the tap. On a device scoring a match of its own that is a distinction without a difference — the journal changes because of the tap — and it is written this way for the day it stops being one. If the two devices are ever paired (`.scratch/paired-scoring/`), the watch draws nothing it has not been given back, and a mark fired from the tap would be the one thing on the screen that had not waited.

## Consequences

The consequences that leaned on there being two surfaces were corrected in place after ADR-0012 removed the second one, rather than left standing under a superseding note: 0012 supersedes nothing decided above — the tint still wins, and it still fires where it fired — only the facts about the court those consequences rested on.

- **Strength belongs to the surface, not to the mark.** A mark with no color of its own has no strength of its own: the number is a property of whatever surface it fires on, and it is re-settled for every surface that ships. ADR-0012 left one surface, so there is one number to settle rather than one per half. It belongs in `CourtColors.swift` beside `CourtDimming` rather than in the view — that file already owns what the geometry is painted in, and the mark is paint. It needs no seam of its own: `courtSurface`, `courtInk` and `courtWeave` all answer in that one file already, so the day a theme is threaded through them the mark's number is threaded with them. This is the price of the option that spends nothing, and it is paid once per surface forever.
- **The two tiers are carried by duration.** A rally that also took a game or a set holds at its peak before it falls. It must not be carried by strength, because strength is already the surface's — a tier that moved it too would make every theme tune two numbers instead of one.
- **A refused intent buzzes and does not light** — once there are intents to refuse, which is `.scratch/paired-scoring/` and not today. The haptic is optimistic and fires with the finger; the mark waits for the journal. Where they disagree the mark is the honest one, and `watch-tap-mode` 02 has already accepted the other half of that trade.
- **An undo is not marked.** The obvious answer was the mark reversed — the half starts lit and drains — and it does not survive being looked at: the only difference is a 73ms rise inside a 520ms mark, which no eye reads as a different event. Marking an undo indistinguishably from a point is worse than leaving it unmarked. The study keeps the rejected version so the next person can check rather than re-derive.
- **Always-On never arises.** The watch marks only a tap you just made on it, so its screen is awake by definition. There is no `isLuminanceReduced` case to handle, which is why — unlike `Floodlight` and the weave — this one has no dimmed variant.
- **It is not gated on Reduce Motion.** That setting exists for vestibular triggers, and the standard remedy for one is to replace the movement with a crossfade. This mark already is a crossfade on a stationary rectangle: gating it would switch off the thing motion-sensitive interfaces are meant to degrade *to*, and would hand the people it is aimed at back the bare counter. It is also one transition per rally, two orders of magnitude below the flashing thresholds these guidelines are written around.
- **Nothing the mark brightens says whose half it is, and that settles this.** The worry recorded here was that themes would degrade the identity of a half from a difference in hue to a difference in value, with the mark sitting directly on top of the color carrying it. ADR-0012 removed the premise rather than answering it: identity is carried by position and the net, which no theme reaches. Brightening a half therefore cannot dilute what says the half is ours. What survives is the first consequence above and nothing else: the mark is still made of the surface, so a theme still names its strength.
- **Nothing is drawn twice.** The mark is geometry-free, so the phone's landscape board needs no second version of it — unlike `serveAlignment(for:from:)`, which is written once per screen because a corner is domain knowledge wearing layout's clothes.
