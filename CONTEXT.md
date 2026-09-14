# Vamos

A padel scorer that runs on a phone and a watch at once. The match lives on the
phone: the journal is written there, the history is read there, and the
scoreboard the four players read from the bench is there. The watch is the
remote on the wrist — it shows the match and awards the rallies, and keeps
nothing (ADR-0009). Neither device scores a match on its own.

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
The record of the match in Health — what the match pretends to be so that both
apps can live through an hour and a half of play. It belongs to the watch, which
has the sensors, and the phone mirrors it: while the workout runs the system
does not unload either app, the watch keeps its screen in Always-On and returns
to it when the wrist is raised, and the phone is allowed to go on holding the
match in the background (ADR-0010). Heart rate, calories and activity rings come
as a side effect. It starts and ends with the match, and neither the score nor
the rally journal knows about it.
_Avoid_: session (the glossary already keeps that word away from "match")

**Live link**:
The conversation between the phone and the watch while a match runs: the journal
goes out to the watch after every change, intents come back from it. It is not a
hand-off and not a backup — there is one match, in one place, and the link is
how the other device sees it and reaches it. Lose the link and the match stands
still: the watch says so and stops taking taps, and what is played in the
meantime is recorded nowhere.
_Avoid_: synchronization, sync, delivery (there is nothing to deliver any more)

**Intent**:
A request from the watch to change the match — a rally to a side, an undo, an
end, a start. It is not a rally until the phone records it, and the phone is the
only judge: an intent is refused when the match is over, when there is no match,
and when the journal it was formed against is no longer the journal the phone
holds. The watch draws nothing until the journal comes back.
_Avoid_: command, event, action, message

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
not marked at all. It belongs to the device the rally was awarded on — the watch
marks the rallies it asked for and not those that arrive from the phone, the
phone marks them all (ADR-0011).
_Avoid_: flash, point mark, highlight, glow (that is light, and this is the
surface's own color)
