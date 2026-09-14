# Targets

What `/build` and `/test` are pointed at, and how to find it. Nothing here
names a package, a scheme or a simulator: every name comes out of the working
tree, so a package added tomorrow is picked up without an edit.

## The two kinds

**A package** is any directory holding a `Package.swift`, and its name is that
directory's:

    find . -name Package.swift -not -path '*/.build/*' -maxdepth 3

**An app scheme** is a scheme the Xcode project lists whose name matches a
top-level directory of the repo:

    ls -d *.xcworkspace 2>/dev/null || ls -d *.xcodeproj
    xcodebuild -list -project <name>.xcodeproj

Read `-project <name>.xcodeproj` as `-workspace <name>.xcworkspace` in every
command here and in both skills when the repo has a workspace. The schemes left
over once the app schemes are taken are the packages' own, and those build and
test under SwiftPM rather than `xcodebuild`.

`all` is every package, then every app scheme.

## Resolving the argument

An argument naming a package or an app scheme is the target. One matching
neither is a stop-and-report error — say what the tree does hold rather than
guessing at the nearest name.

Without an argument, place each path in `git diff HEAD --name-only`:

| Path sits under                                | Target       |
| ---------------------------------------------- | ------------ |
| a directory holding a `Package.swift`          | that package |
| a top-level directory an app scheme is named after | that scheme  |
| anything else                                  | `all`        |

More than one target matches → each of them, packages first.

The last row covers both a file two targets share — a strings catalog, a test
directory — and a file that builds nothing at all, like docs or `.claude/`.
Neither is evidence that nothing needs building, and over-building is cheaper
than missing a break, so both widen to `all`. So does an empty diff.

## A simulator for a scheme

Ask the scheme which destinations it takes rather than guessing its platform:

    xcodebuild -project <name>.xcodeproj -scheme "<scheme>" -showdestinations 2>&1 |
      grep 'platform:.* Simulator' | grep -v placeholder | head -1

The `id:` field is the UUID, and `-destination "id=<uuid>"` is the whole
destination — the platform is the simulator's own and need not be repeated.
Find one per scheme per session and reuse it after. No simulator for a scheme
is a stop-and-report error.

## A scheme's test action

A scheme with no test target of its own can be built but not tested:

    grep -l TestableReference <name>.xcodeproj/xcshareddata/xcschemes/*.xcscheme

A scheme missing from that list has nothing to test, which is not a failure —
`xcodebuild test` on one says `is not currently configured for the test
action`, and the answer is to build it instead and say so.
