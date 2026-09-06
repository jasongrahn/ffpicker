# Event-sourced pick log, not a mutable picks table

Phase 3.5's pick-entry app needs to persist every draft pick to disk immediately (crash
during a live, un-repeatable draft is not an acceptable data-loss risk), and needs to
support correcting a mis-entered pick — expected to happen at least once given a 1-minute
clock and manual entry. A plain table with one row per pick, updated/deleted in place on
correction, risks corrupting the file on a crash mid-write and loses the audit trail of
what was corrected.

Decided instead: an append-only log of typed events (`pick_made`, `pick_corrected`,
`draft_started`), never mutated in place. Current draft state (who owns which player,
each team's roster) is derived by replaying the log — a correction is just another
appended event, and a crash only risks losing the single in-flight write, never
corrupting prior history.

**Considered and rejected**: a fixed-column CSV/table with in-place edits — simpler, but
doesn't support corrections without either destroying history or risking file corruption
on a crash mid-overwrite.
