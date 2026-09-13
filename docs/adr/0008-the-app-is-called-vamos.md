# The app is called Vamos

The app is **Vamos** on the wrist and **Vamos: Padel & Tennis Score** in the
App Store. The two spellings are one decision, taken together with the subtitle
and the keyword line, because the App Store's 30-character name field is small
enough that the name, the sports and the search terms compete for the same
room.

## Why a word and not a description

The obvious name is some permutation of "Padel Score Tracker", and eight apps
already have it. Between them they hold five ratings. Exact-match naming gets an
app indexed; it does not get it installed, and it leaves nothing for a player to
remember or to say out loud to the three people they just played with. The
names that rank in this category on merit — Playtomic, Padelio, SwingVision —
are words, and none of them describes what the app does.

`Vamos` is what a padel player actually shouts. It carries no sport inside it,
which is the second reason: pickleball, squash and badminton are all a subtitle
edit away, where `Racket` or `Padel` in the name would be a rename.

## What was taken

Nearly every padel-native word is gone, and mostly to direct competitors.
`Golden Point` has two exact matches in Sports. `Rally` — the word this
codebase builds its whole model on — belongs to *Rally: Tennis & Padel
Tracker*. `Tanteo`, `Pala`, `Deuce`, `Bandeja`, `Saque`, `Volea` and `Víbora`
are all padel scorekeepers already. Bare `Vamos` is taken too, twice, by apps in
Entertainment and Travel.

The App Store's uniqueness is on the exact name string, not on the word —
`Tally: The Anything Tracker` and `Tally - Clicker Counter` coexist today. So
`Vamos: Padel & Tennis Score` is registrable even though `Vamos` alone is not,
and `CFBundleDisplayName` is a separate field from the Store listing, which is
what lets the icon read `Vamos` on its own.

## Why the name carries the sports and not the verb

Three things want the 30 characters and only two fit: the brand, both sports,
and the phrase *padel score tracker* contiguous. `Tracker` is the one that
leaves, because it is the most generic of the four words and because the claim
that Apple rewards an adjacent phrase is practitioner lore — [Apple's own
account of App Store search](https://developer.apple.com/app-store/search/)
describes combining terms across the name, the subtitle and the keywords. Both
sports in the highest-weighted field is a measurable asset; adjacency is not.

Tennis stays in the name rather than moving to the subtitle because it is not
the weaker half. The top fifteen results for *tennis score tracker* have a
median of ten ratings against padel's five, and in both sports the entrenched
apps are doing something else — booking courts, analyzing video. The
scorekeeper slot is open in both.

## The metadata

    Name      Vamos: Padel & Tennis Score                                  27
    Subtitle  Match Tracker for Apple Watch                                29
    Keywords  scorekeeper,scoreboard,counter,point,games,sets,tiebreak,
              paddle,racket,racquet,umpire,court                           91

No word repeats across the three fields; a second copy adds nothing and costs
characters. `paddle` is the common misspelling of padel and indexes separately,
`racquet` covers the other spelling of racket, and the nine spare characters in
the keyword line are held for `pickleball`.

The subtitle spends its room on *Watch* rather than on more score synonyms
because `padel apple watch` is the least contested term the app has any claim
to, and the only one where being watch-first is the differentiator.

## What the rename touched

`INFOPLIST_KEY_CFBundleDisplayName` on both targets — the phone had none at all
and was showing its target name off `PRODUCT_NAME` — and the two Health usage
descriptions, which name the app to the player.

`CFBundleName` is not the display name and was left to follow `PRODUCT_NAME`,
which is the target name. The targets were recapitalized in the same breath as
this rename — `Padel`, `Padel Watch App`, `PadelTests`, in a project called
`Padel.xcodeproj` — so it reads `Padel` now. That is the project's name, not
the app's: the project keeps the sport, the app is Vamos.
