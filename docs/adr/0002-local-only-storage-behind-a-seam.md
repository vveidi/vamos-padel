# Storage is local only, and syncing is hidden behind a seam

> **Partly superseded by ADR-0009.** What stands is that storage is local and
> reached through a protocol. What does not is the second consequence below: the
> match now lives on the phone from its first rally, and the watch is its
> remote, holding nothing.

The data never leaves the user's devices: the watch writes the match locally and hands it to the iPhone over WatchConnectivity. No cloud, no server, no accounts. CloudKit was considered (free, but Apple-only), as was a cross-platform backend such as Supabase (works with Android, but demands accounts and a monthly bill for a hypothesis not a single person is using yet).

What matters in the decision is not "local" but that access to the store and the delivery of matches are hidden behind a protocol: CloudKit or a server can be added later by swapping one implementation, without moving the data.

## Consequences

- **There is no backup.** Losing the watch before a match has been handed to the phone means losing the match; losing the phone means losing the history. This is accepted deliberately.
- The watch stays the source of truth until the hand-off, and therefore has to see a match through to the end with no phone nearby.
