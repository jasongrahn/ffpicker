# ffdraft Handoff #23: draft day close. QB fade shipped, slot 10 captured, log holds 150 picks

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-08 — draft day, draft 6:00pm ET
**Prior**: `docs/handoff/ffdraft-handoff-20260908-15-MOCK-DRAFT-ANALYSIS.md` (#22)
**Git**: `main`, working tree DIRTY, nothing committed today

**NEXT SESSION RECEIVES OFFICIAL DRAFT RESULTS FROM USER.**
Read "Open question: pick log provenance" before trusting `data/pick_log.jsonl`.

---

## 1. DEF/K binary — ANSWERED. Lever does not exist. Stop tuning.

#22 posed it: does sinking DEF/K in the uploaded rank file move where Yahoo autodraft takes them?

| | DEF pick | K pick | our DEF rank | our K rank |
|---|---|---|---|---|
| Mock #1 | 78 | 83 | 142 | 162 |
| Mock #2 | 75 | 86 | 252 | 284 |

Sank DEF 110 slots -> pick moved **3 spots earlier**. Yahoo fills mandatory slots by round, ignores uploaded rank.

**Record it, stop tuning `data/yahoo_rankings_v2.csv` for DEF/K.** No lower left anyway — both already sit below all 250 skill players.

**Confound, not chased:** v2 imported 255/300 rows. If ranks 252-300 (all DEF/K) were among the 45 rejected, Yahoo used its own board and the test proves nothing. Action identical either way, so not worth resolving.

---

## 2. Mock #2 cross-read (slot 6). Four findings.

Full round-by-round in conversation only, not committed. Salient:

1. **Autodraft burns picks ~75 and ~86 on DEF/K in both mocks.** Both mocks had DEF/K freely available R14-15 (mock #2: 9 DEF and 8 K gone by end of R15, from pools of 32). Two real starters lost to disconnection.
2. **Autodraft duplicates capped positions.** Mock #1: QB2 R11, DST2 R15. Mock #2: Mahomes R10, Pittsburgh DST R15. `max_at_position` is enforced by our app, never by Yahoo.
3. **Board over-rates QB by ~1 round.** Stafford our #30 / ECR 106 went 55 (mock #2) and 58 (mock #1). Confirms #22's positional Spearman table (QB +0.45 vs ECR +0.80). Root cause still not diagnosed — open.
4. **WR came out thin.** Mock #2 finished 3 WR for 2 WR + FLEX. Elite WRs cleared by pick 30.

---

## 3. Shipped: QB fade

**One line**, `config/league.json:8`:

```json
"defer_until_round": { "K": 16, "DST": 15, "QB": 7 }
```

Zero R code touched. Rides machinery that already existed and was already tested (`deferred` -> `draftable_now()` / `bench_open()` -> `target_position()`; `mark_deferred()` for the greyed board row).

Verified:
- `scarcity_report()` marks QB deferred rounds 1-6, released round 7.
- Board renders `<span style="color: #9aa0a6;">Matthew Stafford — wait til rd 7</span>`; non-deferred rows undimmed.
- Recommendation pane names no QB before round 7.
- Full suite **533 pass / 0 fail**.

**Round 7 not a hard block, deliberately.** Mock #2's QB run was picks 54-96, ten QBs gone by 96. R7 costs the top tier, saves the ~1-round overpay. If an elite QB falls, the row is greyed not hidden — override by hand.

### Trap for anyone editing this again

`inst/app/app.R:16` reads `targets::tar_read(league_config)`, **not** `load_config()`. Editing `config/league.json` does NOT reach the running app. Must `tar_make()` (rebuilds `league_config_file`, `league_config`, `draft_board` — ~1s, no data re-pull) **and** restart the app. I claimed otherwise mid-session and was wrong.

### Rules that were already coded — do not re-implement

User asked for three rules. Two already existed:
- "no DEF before R14 / no K before R15" -> `defer_until_round` already had `DST: 15`, `K: 16`, both **stricter** than asked.
- "only 1 DEF, 1 K, max 2 QB" -> `max_at_position` -> `bench_room` gate in `bench_open()` (`R/90_explain.R:128`).

---

## 4. Slot captured: 10 of 10

Draft order confirmed by user, listed order = draft order, JGrahnasaurs last:

`Bone Crushers, Locked In Michelle, Steel City, Game Plan Nicole, Monday Night Madison, Max's TD Bombers, Jason's Jazzy Team (Pete), Sunday Kevin, Maybe Mitchell, JGrahnasaurs`

First table the user pasted was **standings**, not draft order — all ten tied at 5.5, all zeros. Second paste was the real order. Confirms #22: user is not "Jason's Jazzy Team".

Wrote via `start_draft("data/pick_log.jsonl", teams=10L, my_team="JGrahnasaurs", my_slot=10L)` rather than the app setup screen.

**Slot 10 picks:** 10, 11, 30, 31, 50, 51, 70, 71, 90, 91, 110, 111, 130, 131, 150, 151, 170.
Gaps **1, 19, 1, 19…** — back-to-back every turn, then 19-pick wait. Turn slot. Tier cliffs bite hardest here; QB (70/71), DST (150) and K (151) deferrals all land on back-to-back pairs, which is convenient rather than planned.

---

## 5. Open question: pick log provenance — RESOLVE FIRST

`data/pick_log.jsonl` was empty (`wc -l` = 0) when `start_draft()` ran this session. At session close it holds **151 events: 1 `draft_started` + 150 `pick_made`**, slots 1-150, no `pick_corrected`.

Nothing in this session wrote those 150. **User confirmed at session close: this is them entering the live draft through the running app.** It is a live-entry record, not the authoritative one — user is supplying official Yahoo results next session.

**Known corruption, user's own report:** several opponents drafted players who were not on our board or fallback. The app can only record a `player_key` that exists in `combined_selectable_pool()`, so the user **substituted other players** to keep the log advancing under the pick clock. Some unknown subset of the 150 opponent picks therefore name the wrong player.

Consequences:
- **Opponent picks are unreliable.** Any downstream use — empirical Yahoo ADP, `p_available` validation, opponent-model calibration — must wait for the official results.
- **User's own 15 picks are trustworthy**, since they picked from the board by construction. Verify anyway against official.
- **`drafted_players` is wrong in both directions**: substituted players are marked drafted when they were not, and the actually-drafted off-board players are still marked available. So the board the user saw in later rounds was subtly wrong.
- **Root cause is a coverage gap, not a bug.** `combined_selectable_pool()` spans Board + fallback; anything outside it is unenterable. Worth a "record an off-board pick" escape hatch before any future draft — an opaque `player_key` with a typed name would do.

State as found:
- 150 of 170 picks. **Rounds 16-17 missing** (picks 151-170), so no K logged — consistent with `K: 16` deferral, K would have been pick 151.
- Team names: slot-1 team entered as "Bone Crushers", slots 2-9 left as autofilled "Team 2".."Team 9". Real names never typed.
- Negative `player_key`s (`-900017` etc.) are DST fallback keys, expected.

### Roster as logged (15 picks)

| pick | player | pos | team |
|---|---|---|---|
| 10 | Javonte Williams | RB | DAL |
| 11 | Derrick Henry | RB | BAL |
| 30 | Davante Adams | WR | LAR |
| 31 | Travis Etienne Jr. | RB | NO |
| 50 | Rome Odunze | WR | CHI |
| 51 | Jake Ferguson | TE | DAL |
| 70 | Matthew Stafford | QB | LAR |
| 71 | Josh Jacobs | RB | GB |
| 90 | Kenny Gainwell | RB | TB |
| 91 | Courtland Sutton | WR | DEN |
| 110 | Patrick Mahomes II | QB | KC |
| 111 | Woody Marks | RB | HOU |
| 130 | Tyrone Tracy Jr. | RB | NYG |
| 131 | Wan'Dale Robinson | WR | TEN |
| 150 | New England Patriots | DST | NE |

Counts: RB 7 (**at `max_at_position` cap**), WR 4, QB 2 (at cap), TE 1, DST 1, K 0.

Three reads worth carrying:
- **QB fade held.** Stafford at 70 = round 7 = the first legal round, not round 6. Behaved exactly as shipped.
- **Josh Jacobs at 71 is on `data/inactive_do_not_draft.csv` (row 20, GB RB, exempt list).** Same failure #22 predicted: Status column NOT wired to `inst/app/app.R`, so the board showed him unflagged. Mock #1 lost picks to this too. **If this log is the real draft, that is a dead roster spot and the strongest possible argument for wiring the flag before any future draft.**
- **WR 4 for 2 WR + FLEX**, same thinness both mocks produced at every slot. Recurring, not slot-specific.

---

## 6. App state

- Running, port **4321**, PID 73771 at close, `http 200`. Stale 7645 and an older 4321 killed this session.
- Opens straight to pick entry — `needs_setup()` now FALSE.
- Reads `tar_read(draft_board)`; board changes need `tar_make()` + restart (see trap above).
- **Status / inactive column still NOT wired.** Offered three times across #22 and this session, never approved. See Jacobs above.
- If wiring it: flag, never filter. Opponents must stay searchable in `combined_selectable_pool()` or their picks cannot be recorded.

---

## 7. Uncommitted

```
 M R/95_export.R
 M config/league.json          <- QB: 7, the only shipped change this session
 M data/pick_log.jsonl         <- provenance unresolved, see §5
 M data/yahoo_rankings.csv
 M docs/handoff/README.md
 D docs/{qb,rb,te,wr}.csv      <- consolidated into docs/uploads/ in #22
?? data/inactive_do_not_draft.csv
?? data/yahoo_rankings_v2.csv
?? dev/rebuild_yahoo_export.R
?? docs/handoff/ffdraft-handoff-20260908-15-MOCK-DRAFT-ANALYSIS.md
?? docs/uploads/
```

Tests green at 533/0 as of the config change. Nothing committed since `7820e8f`.

---

## 8. First actions, in order

1. **Take official draft results from user.** They have them.
2. **Rebuild `data/pick_log.jsonl` from official results.** Do NOT reconcile pick-by-pick — the substituted opponent picks (§5) make the live log untrustworthy as a base. Back it up first: `dev/pick_log_archive/pick_log_<ts>.jsonl`, the existing convention.
3. **Expect names outside the pool.** Off-board players are why the log is corrupt. Rebuilding needs a path for them; a `player_key` gap is the thing to solve, not work around again.
4. Confirm the Jacobs pick at 71 against official — real, or a substitution artifact.
5. `git status`, run tests, decide the commit. Working tree has carried uncommitted work for two sessions.

## 9. Not draft work — parked

- **Injury/Status column wiring.** Cheapest remaining win, blocked only on user go-ahead. Third time of asking.
- **Off-board pick entry.** New, from this draft. Opponents took players absent from Board + fallback and the app had no way to record them (§5). Blocks trustworthy opponent data from any live draft.
- **QB board miscalibration.** Real defect, undiagnosed. Only worth chasing if a 2027 draft happens; does not transfer in-season.
- **`p_available` / `survival_display()`** (`R/81_vona.R`), still unwired. #22 named it the one surviving piece of the VONA thread. Draft-only, so its window has closed for 2026.
- **Next project (#21): in-season weekly start/sit picker.** Mock and draft work does **not** transfer — no turn order in waivers, XRank stale by ~week 3. Backtest 2024+2025 first.

---

## Suggested skills

- **`caveman`** — repo doc rule, applies to anything this session writes
- **`handoff`** — close the next session as #24
- **`session-close`** — working tree dirty across two sessions now, unresolved
- **`to-prd`** — if the Status column or `p_available` graduates to a build; repo culture is pre-registered bars before shipping (#19, #20, #21)
- **`tdd`** — `dev/rebuild_yahoo_export.R` still has no tests
