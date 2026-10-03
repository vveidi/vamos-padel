# Diagnostics console: the app's own logs, readable on the device

Status: ready-for-agent

## Problem Statement

Both apps write to `os.Logger`, and only errors and a handful of notices. Reading
them means a Mac, a cable and Console.app at the moment the bug happens. A bug
met on court, on the owner's own phone or watch, leaves nothing behind that he
can read afterwards.

## Solution

Every message goes through one small package, `PadelLogging`, which writes it to
`os.Logger` as before and to a Pulse store (github.com/kean/Pulse, 5.2.x) kept on
the device. Each device carries Pulse's console, `PulseUI`'s `ConsoleView`,
behind a hidden way in: ten taps in a row on the ruleset description. The app
logs its success path too, not only its failures.

## Decisions

- **Every build carries it,** App Store included. Nothing leaves the device
  unless the owner shares it from the console.
- **Products:** `Pulse` and `PulseUI` only. The app has no network of its own,
  so `PulseProxy` is not linked.
- **One way in for messages:** a wrapper in the new `PadelLogging` package that
  writes each message to `os.Logger` and to `LoggerStore.shared`. Pulse does not
  read OSLog by itself. Everything is written `.public`: the logs hold no
  personal data, and `<private>` only gets in the way of reading a device.
- **Retention:** Pulse's defaults (14 days, 256 MB) on both devices.
- **The way in:** ten taps in a row on the ruleset description, with no hint
  along the way. On the phone it is on the "New match" tab, under the rules; on
  the watch, on the settings page under the "Scoring" card. Both are plain text
  that answers no tap today, both are there in every state of the history, and
  neither is on a screen where a tap scores a rally.
- **The console opens in a sheet** with a Done button.
- **The watch keeps its own store and its own console.** Its console sends a
  copy of the store to the phone, which keeps the latest one and opens it as
  "Watch logs" (05): the watch's own share sheet offers only Mail and Messages.
- **Naming:** "diagnostics console" in code and tickets. `CONTEXT.md` gets no
  entry: it is a developer's tool, not the domain, and the glossary already
  keeps "log" away from the rally journal.

## Tickets

1. `PadelLogging`, and every logger moved onto it
2. The phone's console (blocked by 01)
3. The watch's console (blocked by 01)
4. The success path logged (blocked by 01)
5. The watch's logs reach the phone (blocked by 03)

## Out of Scope

- Network logging and Pulse's remote logger
- Any visible setting or menu entry for the console
