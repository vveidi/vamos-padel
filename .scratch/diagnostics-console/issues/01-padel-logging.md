# 01: PadelLogging, and every logger moved onto it

**What to build:** a new package, `PadelLogging`, depending on Pulse 5.2.x
(`Pulse` product only). It offers a logger named by subsystem and category,
like today's `os.Logger`, whose `debug`, `info`, `notice`, `error` and `fault`
take a plain `String` and write it twice: to `os.Logger`, `.public`, and to
`LoggerStore.shared` with the category as the label and the matching level.

Every one of today's nine `Logger(subsystem:category:)` — one in
`PadelDelivery`, the rest in the two apps — moves onto it, and the 33 call
sites keep reading `logger.error("…")`. The move is one `ast-grep` rule, not
33 edits.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `Packages/PadelLogging` exists, depends on Pulse, and supports the same
      platforms as the other packages
- [ ] `PadelDelivery` and both app targets depend on it, and no file in the
      repo builds an `os.Logger` of its own any more
- [ ] The three `privacy: .public` interpolations in `HealthKitWorkout.swift`
      are plain interpolations: everything is public now
- [ ] A message written through it shows up in `LoggerStore` with its level
      and its category as the label — covered by a test against an in-memory
      store
- [ ] Subsystems stay as they are: `com.vveidi.padel` on the phone,
      `com.vveidi.padel.watchkitapp` on the watch
- [ ] Both packages and both app schemes build; all tests pass
- [ ] `CLAUDE.md`'s "Where things live in the packages" names the new package

## Notes

Pulse builds in Swift 5 mode inside a Swift 6 project (its manifest sets no
language mode) and its public types are `Sendable`, so the wrapper can be
`Sendable` too.

The store a test writes to must not be `LoggerStore.shared`: Pulse offers an
`.inMemory` option. The wrapper takes its store as a parameter defaulting to
`.shared`.

Pulse ships a `PrivacyInfo.xcprivacy` of its own (FileTimestamp, UserDefaults);
nothing needs adding to ours.

## Comments
