# Handoff docs

Session-to-session continuity. Each one written at the end of a session, read at the
start of the next. Newest last.

Lived in `/tmp` until 2026-09-06 — nine docs, no version control, one macOS purge from
gone. Moved here. **Write new ones here, not `/tmp`.**

Filenames are `ffdraft-handoff-YYYYMMDD[-N].md`, `-N` for the Nth of that day. Date
order is the read order; filename sort is not (`-2` sorts before the unsuffixed file).
Use this index.

| # | File | What it settled |
|---|---|---|
| 1 | `20260829.md` | Phases 0-2 done. Starting Phase 3. |
| 2 | `20260904.md` | Phase 3 done. Decision pending on what came next. |
| 3 | `20260904-2.md` | Real Yahoo league settings applied. Ready for Phase 3.5. |
| 4 | `20260905.md` | Phase 3.5 UI shape resolved via `grill-with-docs`. |
| 5 | `20260905-2.md` | Pick Log + tiering + minimal pick-entry loop, live-verified. |
| 6 | `20260905-3.md` | Rookie fallback section built, live-verified. |
| 7 | `20260905-4.md` | Phase 3.5 hardened. Phase 8 identified as next. |
| 8 | `20260906.md` | Team-assignment gap found and fixed. Phase 3.5 actually done. |
| 9 | `20260906-2.md` | Phase 3.6 run guide built. Expected-points ranking ready to wire. Budget rules. |
| 10 | `20260906-3.md` | Expected-points wired. Three recommendation bugs killed, all found by screenshot. `dev/relaunch.sh`. |
| 11 | `20260906-4.md` | Deferred rows greyed on board. First full 17-round dry run (`dev/dryrun.R`) — found deferral was demotion not exclusion. Rookie sources settled: use FantasyPros `sd`, don't scrape. |
| 12 | `20260906-5.md` | Rookies priced onto Board. Yahoo import CSV built + names aligned — 292/510 imported, cause unsettled. |
| 13 | `20260906-6.md` | **Current.** Position-page CSVs wired in — 473/510 Yahoo-confirmed. Naming ruled out as the import cause; probe file built to settle it. |

## Reading rule

Read the newest first. Go back only when it points you back. Each doc supersedes the
ones before it — an older doc's "do next" list is history, not instruction.

Docs are `/caveman` style per `CLAUDE.md`.
