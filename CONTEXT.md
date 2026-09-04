# Padel

An Apple Watch app that scores a padel match right on the court and saves what
was played. The phone serves as the shop window for the history.

## Written language

The code and every document around it — doc comments, test names, ADRs,
tickets, this glossary — are written in English. The app's own strings are
Russian: screen titles, button labels, VoiceOver labels. Do not translate the
strings: Russian is the language of the app, English is the language of the
work around it.

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

**Abandoned match**:
A match stopped before the ruleset declared it over. Saved in the history
alongside the rest, but marked explicitly, and counted as neither a win nor a
loss.
_Avoid_: dropped, cancelled, interrupted

**Match duration**:
The time from the first rally to the last. Counted neither from the app
launching — between "opened it on court" and "served" there is a warm-up — nor
up to "now": a match cut short by a dead battery lasted until its last point,
not until the moment it was opened again.
_Avoid_: match time, length of play

**Match state**:
The score and the outcome, computed from the rally journal according to the
ruleset. The score is not stored beside the journal and therefore cannot drift
out of sync with it (ADR-0001); of the whole state, one abandoned mark is
stored — there is nowhere to compute it from.
_Avoid_: status, score (as a separately stored value)

**Match outcome**:
How the match ended: still in progress, won by one of the sides, or left
abandoned.
_Avoid_: result, status, completeness

**Workout**:
The record of the match in Health — what the match pretends to be so that the
watch can live through an hour and a half of play. While the workout is running
the system does not unload the app, keeps the score screen in Always-On and
returns to it when the wrist is raised; heart rate, calories and activity rings
come as a side effect. It starts and ends with the match and is not a separate
entity of the domain: neither the score nor the rally journal knows about it.
_Avoid_: session (the glossary already keeps that word away from "match")

**Match delivery**:
The journey of a finished match from the watch to the phone, where it becomes
history. It happens by itself, without the player, and at whatever moment the
phone becomes reachable — during play it is not needed. A match counts as
delivered when the phone has signed for having written it down, not when the
watch sent it: until the receipt, the watch is the only place the match exists
(ADR-0002). The same match may arrive twice — the phone recognises it by its
identifier and does not create a second one.
_Avoid_: synchronisation, sync (this is not a two-way exchange)
