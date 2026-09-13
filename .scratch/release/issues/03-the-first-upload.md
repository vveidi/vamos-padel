# 03: The first upload

**What to build:** Nothing. This ticket is the proof that the other two work —
a build that leaves the machine, finishes processing, and appears on a wrist.

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] `fastlane beta` runs clean from a clean tree, end to end, without a
      manual step in the middle
- [ ] The build finishes processing in App Store Connect without being
      rejected — the icon, the entitlements and the export-compliance answer
      all pass
- [ ] The build's "What to Test" reads as the last commit's subject line
- [ ] The build number is one higher than whatever TestFlight already had
- [ ] The app installs from TestFlight onto a phone, and the watch app arrives
      with it rather than needing a second install
- [ ] A match played on the pair reaches the phone's history on the installed
      build — the one thing no simulator has ever proved. `phone-scoring`
      rewrites what that sentence means: the match is recorded on the phone as
      it is played, and nothing is delivered afterwards. Take this criterion
      from that feature's ticket 11, not from the delivery this line was
      written for
- [ ] Anything that had to be done by hand is written into the closing note, so
      that the second upload does not rediscover it

## The icon

Drawn, and in both catalogs. It was the blocker this ticket could not fix
itself; it is not one any more, and the criterion above is now just a check
that processing accepts what is there.

## Why "a match reaches the phone" is a criterion here

Match delivery has never run anywhere but a pair of simulators. A real pairing
has a real `WCSession`, a real reachability story and a real moment where the
phone is asleep, and none of the three exist in the simulator. This is the
first build on which any of it can be true, and a TestFlight install that was
never opened proves only that the upload worked.

## Notes

**On what to do when it bounces.** The first upload usually does. The failure
arrives by email from App Store Connect, minutes after the lane has already
reported success, because processing happens after the transfer. `fastlane
pilot builds` says what state the build is in without opening a browser.

**On the closing note.** This ticket's whole value is the list of things that
were not in the plan. Write them down even when they are embarrassing,
especially the ones that took an hour.
