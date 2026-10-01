# 06: PadelDelivery

**What to build:** `Packages/PadelDelivery` held to `CLAUDE.md`'s rewritten
"Writing comments" — 11 files, 1,177 lines, 245 doc-comment lines and 34 inline.
The lightest area, and the last of the six.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Packages/PadelDelivery` — `Sources/Transport/`,
      `Sources/Ends/`, `Logging.swift` and `Tests/` — is read and its comments
      held to the rule
- [x] The **17 doc-comment blocks of 6 or more lines, 151 lines between them**,
      are gone or cut to four
- [x] No `public` symbol is exempt
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code**
- [x] `swift test --package-path Packages/PadelDelivery` is clean
- [x] The closing note states the area's doc and inline line counts **before and
      after**, and — since this is the last ticket in the feature — the repo-wide
      totals against the 13,779 lines / 4,479 comments this feature started from

## Notes

**`WatchConnectivity` is the reason this area's keeps are real.** Its delegate
callbacks arrive on a queue that is not the main one, transfers survive app
launches, and a parcel handed to an app with no handler registered does not
arrive twice. Every one of those is a threading rule or a failure mode — the
rule's own keep list — and they are invisible in the signatures. Cut them to
four lines; do not delete them.

**The `Ends/` types are two halves of one conversation, and both say so at
length.** The watch's end and the phone's end each open by explaining the other.
One sentence naming the counterpart is enough; the protocol between them is
`Transport/`'s to describe, and it should describe it once.

**`Logging.swift` sits at the target root because it belongs to no subsystem.**
`CLAUDE.md` says that, so the comment repeating it goes.

**This ticket closes the feature, so its closing note is the feature's.** State
the repo-wide before and after, and say whether the under-10% target was
reached. If it was not, say by how much and which area carries the remainder
rather than leaving the number to be re-measured later.

## Comments

**Done.** 10 `.swift` files under `Sources/` and `Tests/`, read in full and cut.

| | before | after |
| ---------------- | ----: | ----: |
| total lines | 1,138 | 941 |
| doc comments | 245 | 63 |
| inline comments | 26 | 11 |
| comment share | 24% | 7.9% |

Those are the ten files this pass touched. Including `Package.swift`, which the
first criterion does not enumerate and which was left alone, the area's header
number of 1,177 lines becomes 980, and 34 inline become 19.

**All 17 doc-comment blocks of 6 or more lines are gone or cut to four**, and
no comment block of five lines or more is left in the ten files, doc or inline,
checked mechanically. There were no `// MARK:` lines to preserve and no `TODO:`
or `FIXME:` to convert.

**The diff contains no line of code**, checked the way tickets 01, 03 and 05
were: every file stripped of comments and blank lines before and after the
pass, and the two compared. The comparison is empty.

`swift test --package-path Packages/PadelDelivery` is clean. Both app schemes
also build clean, and here that is not a formality: `WatchConnectivityTransport`
sits behind `#if canImport(WatchConnectivity)` and never compiles under
`swift test` on macOS, so the schemes are the only proof its comments are still
well-formed.

- **Rescue 1 — ADR-0003 gains a clause, and it is the only rescue.**
  `MatchPayload`'s type doc said the parcel is laid out like the database
  schema and for the same reason: half the ruleset keys are empty for each
  case, but the parcel can be read without knowing our code. Ticket 05 had
  already rescued that rule for the schema into ADR-0003's "Nothing is folded
  into a column only our code can read", where it bound columns alone. It now
  names the parcel too. Everything else deleted from this area was either
  narration or already in ADR-0002, which carries the interface argument in
  full — that the transport is a protocol so a cloud or a server can be swapped
  in, that `WatchConnectivity` lives in one implementation, and that the watch
  stays the source of truth until the hand-off.

- **Kept, as the notes asked: the WatchConnectivity rules.** The delegate
  queue not being the main one (on `Handlers`, two lines); `transferUserInfo`'s
  queue surviving the app being unloaded and the watch restarting (the class
  doc, four); a parcel arriving into an app with no handler registered not
  arriving again (`activate()`, three); `didFinish` not being a delivery
  confirmation (two); an unactivated session dropping what it is handed
  (`transfer`, two); `onReady` existing because activation is asynchronous
  (three); `session` being `nil` on a device without a pair (two); and the
  `#if os(iOS)` pair being required by the protocol (three).

- **Kept elsewhere:** `MatchPayload`'s key names being a contract with a
  separately updated app; the decoder's journal `guard` not being defaulted;
  `Arrival`'s one channel in both directions, and the receipt being what clears
  the watch's queue (ADR-0002); `onDelivery` taking the whole match because a
  receipt is for a version; `confirmArrival` being called after the write, not
  on arrival; `send` enqueueing rather than sending; both `Ends/` types' one
  sentence naming the counterpart and the two failure modes at their `catch`
  sites; `deliverPending`'s double delivery by design. In the tests, `aMoment`
  being a round second because the store keeps milliseconds, the relaunch being
  a second connection to the same in-memory database, the delivery mark being
  cleared by any write, `matchesObserved`'s first value, and
  `MatchPayloadTests`' cases living in the body because `[String: Any]` is not
  `Sendable`.

### The feature, measured

In the spec's own scope — the six areas of its table, each package including
its `Package.swift`, `PadelTests` excluded, which is the scope that reproduces
its 13,779 lines and 3,715 doc-comment lines exactly:

| | before | after |
| ---------------- | -----: | ----: |
| total lines | 13,779 | 10,429 |
| doc comments | 3,715 | 747 |
| inline comments | 783 | 407 |
| comment share | 32.6% | 11.1% |

The inline figure is 783 against the spec's 764 because this count includes
`// MARK:` and the spec's appears to have dropped some; the 19-line difference
is classification, not work.

**The under-10% target was not reached. The six areas sit at 11.1%, about 120
comment lines over** — 10.3% and about 30 lines over if `// MARK:` is excluded,
which the spec's "what is not in" section says it should be.

**`PadelDesign` and the watch app carry the whole remainder.** By area, ignoring
the manifests, comment share after this pass: `PadelDesign` 13.2% (478 lines),
the watch app 12.8% (193), `PadelScoring` 9.3% (191), `PadelStorage` 8.9%
(100), the phone app 8.1% (84), `PadelDelivery` 7.9% (74). The four small areas
are already under 10%; bringing `PadelDesign` alone to 9% would shed roughly
170 lines and put the whole scope under the target with room to spare. That is
a second pass over the area `01` already cleared, not a missed ticket, and it
has no ticket of its own.

`PadelTests` sits outside these numbers and outside every closed ticket: 373
lines, 153 of them doc comments, 41%. It is ticket `07`, still open, and it is
the last of this feature's work.

**Two things left for the owner.**

- **`Package.swift` was left alone**, on the same reading tickets 01–05 used:
  the first criterion enumerates `Sources/Transport/`, `Sources/Ends/`,
  `Logging.swift` and `Tests/`, and the manifest is in none of them. Unlike
  `PadelStorage`'s, this one carries a block of five lines — one over the
  ceiling, in the ticket that closes the feature. Both review axes said to
  leave it and say so; it is one edit away if you would rather it went.

- **Three judgment calls from `code-review`, left as they are.** It called the
  matching "the watch's end / the phone's end" sentences on `MatchDelivery` and
  `MatchReception` a duplication, but the ticket's own notes ask for exactly
  one sentence naming the counterpart on each. It called `FakeTransport`'s
  `sent` and `receipts` one-liners restatements of their names; they say
  "since the last `forget()`", which the names do not. And it called
  `MatchDeliveryTests`' "The match changes while the receipt is in flight."
  mild restatement of the three lines under it; the timing is the half the code
  cannot show. Say the word on any of the three and they go.
