# Vamos

A padel scorer that runs on a phone and on a watch. Either device scores a match
on its own: the one a match is started on holds its rally journal from the first
rally to the last, and is called that match's scorer (ADR-0009). The history is
the phone's — a match scored there is in it from its first point, and a match
scored on the watch arrives once it is over.

## Written language

The code and every document around it — doc comments, test names, ADRs,
tickets, this glossary — are written in English, and so is every string the app
says: a screen title, a button label, a VoiceOver label stands in the source in
English, and that English sentence is at once the key its Russian translation is
found by (ADR-0005).

That English is American in the strings and in anything else a player reads: a
tiebreak is one word and a color has no "u". The prose around them — comments,
doc comments, commit messages — is exempt, and either spelling is correct there
(ADR-0005).

The app itself speaks two languages, and the reader's phone chooses between
them; a phone set to neither gets English. On screen the two are equal. In the
source they are not: a sentence is written once, and it is written in English.

## Language

**Rally**:
A unit of play that ends with one of the sides winning a point. The smallest
event the app records.
_Avoid_: point (that is the result of a rally, not the rally itself)

**Rally journal**:
The ordered sequence of a match's rallies — the single stored truth about the
match. The score is computed from the journal rather than stored beside it.
_Avoid_: history, log, event log

**Side**:
One of the two pairs on court. In v1 the sides are anonymous: "us" and "the
opponents", with no player names.
_Avoid_: team, pair, couple

**Half**:
One of the two pieces of ground the net divides the court into — a region, not a
pair. Each side plays from one of them, drawn where it is when you stand at our
end: theirs across the net, ours nearest. It is what a screen taps, what a rally
mark brightens and what a light falls on. The pairs change ends during a match
and the halves do not change name, because the app does not know which end
anybody is standing at.
_Avoid_: side (that is the pair), court side, zone, quadrant (that is the
serving half)

**Golden point**:
The rule by which deuce is settled by a single decisive point instead of
playing on for a two-point lead. Switched on by a setting before the match.
_Avoid_: punto de oro, deciding point

**Ruleset**:
The data that decides how the score is computed from the rally journal and when
the match is over. Set before the match and remembered until the next one.
_Avoid_: settings, config, mode

**Match**:
A single game from the first rally to the moment the ruleset declares it over.
The unit the app saves and shows in the history.
_Avoid_: game (that is a unit inside a set), session, round

**Classic scoring**:
The padel ruleset with games and sets: 15/30/40, a game at a two-point lead, a
set to six games, a tiebreak at 6:6. The serve passes to the other side after
every game.
_Avoid_: tennis scoring, normal mode

**The match to N points**:
The ruleset in which the match ends as soon as a side is first to reach N
points. The serve passes to the other side every X points; both N and X are set
before the match.
_Avoid_: americano, quick match

**Americano**:
A tournament format for 8–16 players with partners rotating every round and
points counted individually. **Not part of v1.** The word is reserved for the
tournament and never denotes a way of scoring — the match to N points is what
that is called.
_Avoid_: using it as a synonym for the match to N points

**Serving side**:
The side serving the current rally. The app asks for it before the match and
shows it on screen. With anonymous sides only the side is tracked, never the
particular player within the pair.
_Avoid_: server, the serve (as an entity)

**Serving half**:
The half of the court, right or left of the center line, the serve is played
from. The first rally of a game comes from the right, and the half changes with
every rally after it — inside a tiebreak as well, where the serve itself passes
on a different rhythm. In the match to N points a service turn stands in for a
game: its first rally comes from the right. Right and left are the server's
own, facing the net, so they do not move when the pairs change ends.
On a golden point the half is not known: the receiving pair chooses which side
to take the serve on, and the app is not told which.
_Avoid_: service box (that is where the ball has to land, diagonally opposite
the half it was served from), side (that is the pair), quadrant

**Abandoned match**:
A match stopped before the ruleset declared it over. Saved in the history
alongside the rest, but marked explicitly, and counted as neither a win nor a
loss.
_Avoid_: dropped, canceled, interrupted

**Match duration**:
The time from the first rally to the last. Counted neither from the app
launching — between "opened it on court" and "served" there is a warm-up — nor
up to "now": a match cut short by a dead battery lasted until its last point,
not until the moment it was opened again. A taken-back rally ends the match at
the undo instead — rallies carry no time, so the moment of the rally now last
is not written down anywhere; undoing the last one left returns the match to no
duration at all.
_Avoid_: match time, length of play

**Match state**:
The score and the outcome, computed from the rally journal according to the
ruleset. The score is not stored beside the journal and therefore cannot drift
out of sync with it (ADR-0001); of the whole state, one abandoned mark is
stored — there is nowhere to compute it from.
_Avoid_: status, score (as a separately stored value)

**Course of the score**:
How the match came about, and not only how it ended: the score at every step it
moved by — a game in classic scoring, a rally in the match to N points.
Computed from the rally journal by the same engine that computes the state and
stored nowhere (ADR-0001); this is what keeping the journal instead of the
result was for. Shown on the match card on the phone.
_Avoid_: history (that is the phone's list of matches), timeline, chart

**Match outcome**:
How the match ended: still in progress, won by one of the sides, or left
abandoned.
_Avoid_: result, status, completeness

**Workout**:
The record of the match in Health — what the match pretends to be so that the
app can live through an hour and a half of play. It belongs to the watch, which
has the sensors: while the workout runs the system does not unload the app, the
watch keeps its screen in Always-On and returns to it when the wrist is raised.
Heart rate, calories and activity rings come as a side effect. It starts and
ends with the match, and neither the score nor the rally journal knows about it.
A match scored on the phone has none: the phone has neither the sensors nor a
session to run them in, and gives up the workout in exchange for the board the
four players read.
_Avoid_: session (the glossary already keeps that word away from "match")

**Scorer**:
The device that holds a match's rally journal and records its rallies. It is
decided when the match starts — it is the device the match was started on — and
never changes afterwards: a match has one scorer and never two. The phone and
the watch say nothing to each other while a match runs, so each may be scoring
one of its own, and neither is the other's backup.
_Avoid_: host, source of truth, primary device

**Match delivery**:
The journey of a finished match from the watch to the phone, where it becomes
history. It happens by itself, without the player, and at whatever moment the
phone becomes reachable — during play it is not needed. A match counts as
delivered when the phone has signed for having written it down, not when the
watch sent it: until the receipt, the watch is the only place the match exists
(ADR-0002). The same match may arrive twice — the phone recognizes it by its
identifier and does not create a second one. A match scored on the phone is
delivered nowhere: it is written into the history as it is played.
_Avoid_: synchronization, sync (this is not a two-way exchange)

**Scoreboard**:
The phone's landscape screen showing the running match: the court across the
long axis, a half per side, both of them tapped to award a rally. It is what the
players on the bench read, and it is the phone's screen alone — the watch's is
the score screen, which is a different size and a different argument.
_Avoid_: score screen (that is the watch's), display, board

**Mirroring the board**:
Swapping which half of the scoreboard is drawn on which side, so that a phone
lying on a bench can be read from where the players happen to be standing. A
setting of one screen and nothing else: the sides keep their identity and their
colors, and nothing is written down. It is emphatically not the change of ends
that padel has after odd games — the app does not know which end anybody is
standing at.
_Avoid_: swap sides, change of ends, switching sides

**Tap mode**:
How the watch's score screen turns a touch into a rally — *multi-tap*, where one
tap awards us the rally and two award it to the opponents wherever the finger
lands, or *tap zones*, where the half that is tapped is the side that scores. A
preference of the watch and of nothing else: no match records which was in
force, and the phone is never told. A long press undoes the last rally in both.
_Avoid_: input mode, tap scheme, scoring mode, gesture settings

**Rally mark**:
What the court does when a rally is recorded: the winning side's half brightens
in its own color and falls back, so that a rally landing is seen and not only
counted. It marks harder for one that also took a game or a set, and an undo is
not marked at all. It belongs to the device the rally was awarded on, which is
the match's scorer and therefore marks every rally in it (ADR-0011).
_Avoid_: flash, point mark, highlight, glow (that is light, and this is the
surface's own color)
