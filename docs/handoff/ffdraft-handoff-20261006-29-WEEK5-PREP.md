# Handoff #36 — Week 4 fully closed. Week 5 lines complete. Two calls moved.

Date: 2026-10-06 **Tuesday**. Branch `week3-gameday`, **PUSHED** through `136ec75`.
Next session: **re-pull through the packages, prep Week 5.**

Prior: #35 `20261005-28-WEEK5-OPEN.md`. Methodology authority still #33 (§1
`Rankings Actual`). **#35 §2 is now superseded on one point — the lines posted.**

---

## 0. What changed in 24h. Re-pull done 10-06, `clear_cache()` first.

**`load_schedules(2026)` week 5 is now 15 of 15.** Both blanks filled.

| game | line | effect |
|---|---|---|
| **BAL @ ATL** | **ATL favored 3.5**, total 43.5 | BAL own **20.00**, opp implied **23.50** |
| MIN @ NO | MIN favored 1.5, total 42.5 | no roster exposure |

**#35's "13 of 15" was true when written and is now stale. Do not re-withdraw it —
it was correct at the time.** The lesson that survives: **a `load_schedules()` number
is a snapshot, not a fact.** Re-pull before any line-derived claim, `clear_cache()`
first, and date the number.

### Two calls moved. Both material.

**1. Henry is a 3.5-point DOG, not unscriptable.**
RB dog -> **0.945x**. Henry **21.82 -> 20.62 adj**. #35 carried him unadjusted at
21.82 because there was no line; that number is now wrong by 1.20 and the direction
is **down**. This is the worst script of any RB on either roster.

**2. Ravens DST opponent implied is 23.50 — the WORST of all five candidates.**
The claim in #35 §0 is **CONFIRMED, and more strongly than it was argued.**

| DST | wk5 | opp implied | status |
|---|---|---|---|
| **Bengals** | @ Mia | **17.75** | waiver, clears Wed 10-07 |
| **Jaguars** | vs Phi | **17.75** | waiver, clears Wed 10-07 |
| Jets | vs Cle | 18.50 | waiver |
| Cowboys | vs TB | 19.50 | waiver — **do not claim**, see §3 |
| **Ravens** | @ Atl | **23.50** | **ours. Worst on the board.** |

Texans (opp implied 15.00 now, @ Ten) remain **rostered** by Sunday Kevin.

---

## 1. Week 4 is CLOSED. Nothing left to fill.

**Etienne `actual` written 0.00** (IR; wk4 MNF final ATL 45, NO 24 — he scores 0
for us). **Both csvs now have zero blank actuals**, verified by awk on col 11
(myteam) and col 12 (opponent).

Final: **L 93.00-98.58, record 2-2, regret 27.10.** Etienne at 0.00 changes no
total — he was IR and not started.

The wk4 opponent csv has **no NO or ATL players at all**, so no MNF exposure was
left stale on their side either. (A loose note about Kamara came from the Yahoo RB
*export*, not our logged opponent roster. Not a gap.)

**Uncommitted:** the one-character Etienne edit to
`data/weekly/2026_week04_myteam.csv`. Commit it with the Week 5 log.

---

## 2. The waiver move. Submitted state UNKNOWN.

**Recommendation given: drop Sutton (3.28 ppg, worst on roster by 2.5x), claim
Bengals DST**, with Jaguars and Jets queued behind it.

**I do not know whether the user submitted it.** Waivers process **Wed 10-07**.
**Ask first thing — do not assume either way.** If it processed, the roster and
every DST number below changes.

Waiver facts, read off the Yahoo settings page 10-05 and now in memory
(`waiver-system.md`):

- **Continual rolling list. NO FAAB. There is no budget — do not reason about bids.**
- **Waiver Time 2 days**, so the pool refreshes *daily*; there is no single weekly
  run. `W (Oct 7)` in an export means "clears Wednesday Oct 7".
- **Our priority was 9 of 10.** A rolling list sends a successful claimant to the
  bottom, so at 9th the priority is **nearly worthless and spending it costs ~nothing**
  (9 -> 10). Stack several claims; you win at most one at identical cost.
- **At low priority the real opportunity is the FA pool after a player clears** —
  first-come-first-served, priority irrelevant. **Check Thu and Fri too.**
- **Injured players may be added from waivers/FA directly to an injury slot.** 2 IR
  slots, Etienne holds one, and IR does not count against the 15 (D10). **One empty
  IR slot is a free roster spot for an injured stash, no drop required.** Offered,
  never acted on.

`config/league.json` cannot hold any of this — top-level
`additionalProperties: false` in `config/schema/league.schema.json`. Recording it
needs a schema edit. **Offered, not done, not approved.**

Also: that file's `roster.max_at_position` says `K: 1, DST: 1`. **That is our own
draft-time cap, NOT a league rule** — we demonstrably carry two kickers (Butker +
Bates, D11). So carrying two DSTs is legal, which is what closes the wk13 hole.

---

## 3. Method finding: the implied total ALREADY contains defensive quality.

Worth more than the week it came from.

Bengals and Jaguars are now **tied at 17.75 opponent implied**. Reaching for a
tiebreaker, I nearly used **own points allowed per game** — JAX 13.2 vs CIN 21.2 —
and that would have flipped the pick to Jacksonville.

**That is invalid. It is #33's "one source counted twice" in a new costume.** An
opponent's implied total is the market's forecast of *points that opponent will
score against this specific defense*. JAX's 13.2 ppg allowed is **already priced
into Philadelphia's 17.75.** Adding it as an independent tiebreaker double-counts it.

**What IS independent: the variance of the opponent's realized scoring**, because
the payout is **tiered**, and the implied total is a mean. Our tiers
(`config/scoring.json`): `0`=10, `1-6`=7, `7-13`=4, `14-20`=1, `21-27`=0, `28-34`=-1,
`35+`=-4.

| DST | opponent | opp scores wks1-4 | tier payout each | mean |
|---|---|---|---|---|
| **Bengals** | Miami | **10/10/13/13** | **4/4/4/4** | **4.00** |
| Jaguars | Philadelphia | 7/20/24/24 | 4/1/0/0 | 1.25 |
| Jets | Cleveland | 10/21/23/27 | 4/0/0/0 | 1.00 |
| Cowboys | Tampa Bay | 14/16/19/27 | 1/1/1/0 | 0.75 |
| Ravens | Atlanta | 3/13/35 | 7/4/**-4** | 2.33 |

**Miami has parked in the 4-point band four times out of four, range of 3 points.**
Philadelphia spans 7 to 24. On a tiered payout that tightness is real and is not in
the mean. **Bengals stays the pick.**

**Cowboys cut from the queue** — I had them 4th in #35 on implied total alone; the
payout profile (0.75, worst) plus Dallas allowing 28.0 ppg makes them **worse than
holding the Ravens.**

**Caveats, because the table looks harder than it is.** n = 3 or 4 games; **Atlanta
has played 3, the others 4**, so the means are not on equal footing. Opponent points
*scored* is a **proxy** for the implied total, used only where a line was missing —
it does not price venue, injuries or rest. Tiers are one component; sacks (1), INTs
(2), fumbles (2), TDs (6) add variance on top. And these are **hand-computed tier
lookups, not scored output — `score_team_week()` still does not exist.**

---

## 4. Week 5 head-to-head, re-run on complete lines. We are now BEHIND.

Max's TD Bombers, **1st in league**. Script-adjusted, **skill slots only, 7 of 9**.
**K and DST excluded on both sides. NOT comparable to Yahoo's number.** Say it.

| | ours | theirs |
|---|---|---|
| QB | Stafford **17.38** | Prescott 21.13 |
| RB1 | Henry **20.62** | Taylor 19.18 |
| RB2 | Javonte 20.03 | Jeanty 15.21 |
| WR1 | Adams 15.50 | D. Smith 13.00 |
| WR2 | Boston 12.22 | Deebo 12.72 |
| TE | Ferguson 7.58 | Likely 10.50 |
| FLEX | Raymond 9.62 / **Odunze 7.58** | Washington 10.78 |
| **ppg-optimal** | **102.95** | **102.52** |
| **as we will actually start it (D6a)** | **100.91** | **102.52** |

**#35 said "dead heat, 102.65 vs 102.52, we lead by 0.13." Revised: we trail by
1.61 on the lineup we will actually field.** Henry's dog script took 1.20 and
Stafford's line move gave back 1.50 (§5).

**The structural reads from #35 all survive unchanged** and are the reason this is
close at all:

1. **The KC bye is the whole matchup.** Costs us Mahomes (~5.5). Costs them
   **Kenneth Walker III, 26.02 ppg, their best player by 5.7** (~15.2). **Net +9.7
   to us.** With Walker they project ~117.8 and this is a 15-point loss.
2. **Dallas is load-bearing for both sides** — DAL -8.5, own implied 28.00. Our
   Javonte + Ferguson vs their Prescott. **Damps the margin.** Correlation arriving
   free, not paid for.
3. **Their roster fights itself** — Taylor (IND @ PIT) against their own Steelers DEF.
4. **Chicago targets contested** — their Burden III vs our Odunze + Raymond, CHI @ GB.
5. **Nothing to defend against.** Robinson is now a **7.5-point dog** (TEN own
   implied 15.00, worst of anyone we roster) but **WR is flat across every spread
   bucket.** That is a projection problem, not a script problem. **Do not bench a WR
   for being on a dog.**

---

## 5. New fragility: the QB multiplier has a CLIFF at 3 points.

LA moved **-2.5 -> -3.0**. That half-point crossed a bucket boundary:

**QB fav 0-3 = 0.939x. QB fav 3-7 = 1.028x.** A **9.5% jump** on a 0.5-point line
move. Stafford went **15.88 -> 17.38** without anything real changing.

**Treat any player sitting within ~0.5 of a bucket edge as unresolved**, and say so
instead of quoting the adjusted number to two decimals. Same shape as the D3/GD1
lesson: **a bar that a half-point of noise can flip is not measuring anything.**

Cliff edges in the CLAUDE.md table: **QB at 3 and 10. RB at 0, 3, 10, 13.** WR is
flat everywhere, so WR has no cliff — one more reason not to script receivers.

---

## 6. Week 5 lineup. Settled unless the waiver lands.

| slot | start | basis |
|---|---|---|
| QB | **Stafford** | forced, Mahomes on KC bye. 1.028x — **but see §5, he is 0.0 off the cliff edge** |
| RB1 | **Henry** | 20.62 adj. **3.5-pt dog, 0.945x — his worst script of the season** |
| RB2 | **Javonte** | DAL -8.5, own 28.00, RB fav 3-7 **1.078x** |
| WR1 | **Adams** | 15.50 |
| WR2 | **Boston** | 12.22 |
| TE | **Ferguson** | 1-deep all season |
| FLEX | **Odunze** | **D6a, on usage.** Raymond still leads ppg 9.62 to 7.58 and **that is backward-looking** — his early weeks were a 48%-snap role. Do not re-litigate. |
| K | **Bates** | forced, Butker on KC bye. Det own implied **29.50, #1 of 30** |
| DST | **waiver winner, else Ravens** | Ravens opp implied **23.50, worst of five** |

**Butker is NOT droppable.** Butker bye wk5, **Bates bye wk6** — complementary.
Dropping him recreates the Week 1 zero-kicker failure (#24). #35 carries the same
correction; it is restated because the earlier advice was wrong twice.

---

## 7. Deadlines. Per slot: `min(kickoff of legal replacements)`.

| due | slot | why |
|---|---|---|
| **Wed 10-07** | waiver | claims process. Not a kickoff. **No Wednesday NFL game exists in wk5.** |
| **Thu 10-08 20:15** | **RB2, TE** | TB @ DAL — Javonte + Ferguson. Both auto-start, but **any reversal dies here.** |
| **Sun 09:30** | **QB, WR1, DST** | Stafford and Adams kick **Mon 20:15**, but every legal replacement plays Sunday -> **the call is due Sunday morning, not Monday.** PHI @ JAX is the 09:30 London game. |
| Sun 13:00 | FLEX, WR2 | CHI @ GB, CLE @ NYJ |
| Sun 16:25 | K | DET @ ARI |
| Sun 20:20 | RB1 | BAL @ ATL — Henry. Latest on the roster. |

---

## 8. Byes. Fully mapped. Two real crises ahead.

| wk | off | consequence |
|---|---|---|
| 5 | Mahomes, Butker | covered — Stafford, Bates |
| **6** | **Bates** | **covered ONLY if Butker is kept.** §6. |
| 7 | Etienne | IR, no impact |
| 8 | Marks | no FLEX RB |
| 9 | Robinson | fine |
| **10** | **Odunze, Raymond, Sutton** | **three WRs at once. Zero WR FLEX.** Dropping Sutton does not worsen it — he was 3rd of 3 gone anyway. |
| **11** | **Stafford, Adams, Boston** | Mahomes covers QB. **WR1 AND WR2 both out. Worst week on the board.** |
| 13 | Henry, **Ravens** | **zero DEF** unless a 2nd DST is held |
| 14 | Javonte, **Ferguson** | **zero TE.** Ferguson 1-deep all season. |

**Weeks 10-11 are a WR problem to solve by week 9, not in week 10.** Not actionable
this week. Do not let it displace §2.

---

## 9. Do next, in order.

1. **Ask whether the waiver was submitted and what landed.** Everything in §6
   depends on it. Do not assume.
2. **Re-pull: `clear_cache()`, `load_player_stats(2026)`, `load_schedules(2026)`,
   `load_injuries(2026)`.** Week 4 stats are final now, so wks1-4 ppg are stable.
   Injuries are the live variable — **#34 proved reports are unfiled early in the
   week and arrive by Sunday.** An absent row is **not** evidence of health.
3. **Open `data/weekly/2026_week05_decisions.md`.** Log §6's forced calls, the
   waiver move, and kill conditions — **written on target/usage counts across
   MULTIPLE player-weeks.** Single-player-week legs are what broke D3 and GD1.
4. **Commit the Etienne edit** with the Week 5 log.
5. **Log both lineups pre-kickoff**, ours and theirs (CLAUDE.md). Their Walker III
   slot is the thing to watch — if they stash him and start Harvey, §4 holds.

**Do NOT** re-derive the sign convention, re-validate `score_player_week()` (57/57),
or re-investigate Yahoo API / VONA / Sleeper. All closed.

---

## 10. Traps. Carry forward.

- **`score_team_week()` does not exist.** DST unscoreable by our code. Every
  comparison is skill-only, 7 of 9. **Say so or the number reads as Yahoo-comparable.**
- **`renv` out of sync** -> `devtools::load_all()` fails. `source("R/00_config.R")`
  then `source("R/30_scoring.R")`. **`R/10_config.R` does not exist** — `load_config()`
  lives in `00`.
- **`spread_line` POSITIVE = HOME favored.** Validated twice. Assert
  `all(abs((own+opp)-total) < 1e-9)` plus a known-good. And **never** write
  `fav = -spread_line` then `own = tot/2 - fav/2` in one `transmute` — dplyr lets
  later expressions see earlier ones, so it silently resolves to the HOME implied.
  Use raw `spread_line` in every formula. Working version: `scratchpad/h2h5b.R`.
- **A `load_schedules()` line is a snapshot.** `clear_cache()` and re-date before
  quoting. §0.
- **`load_player_stats(2026)` has `team`, not `recent_team`.** Wrap in `any_of()`.
- **Name trap, both sides.** Our `J. Williams` = **Javonte** (Dal, RB). Theirs =
  **Jameson** (Det, WR).
- **Apostrophes break inline `Rscript -e`** (`Wan'Dale`, `Max’s TD Bombers` — curly
  apostrophe). Scratchpad `.R` file, always.
- **nflreadr NA is inactivity, not a name miss — prove which.** Diff the prior weeks
  before blaming the join.
- **K method tests must dedupe to one kicker per team.** Backups at 0.00 inflated 30
  teams to 51 rows and held Spearman at 0.16.
  `group_by(tm) |> slice_max(pts, n=1, with_ties=FALSE)` -> 0.300.
- **DEF export has its own column layout.** No `Player ID` -> Roster Status **col 5**,
  pts **col 8**. Skill positions are col 7 / col 10.
- **`Fantasy Fan Pts` header carries an invisible private-use glyph.** `cat -v` shows
  it. Never match that header literally.
- **`Rankings Actual` is a projection restated as a rank.** #33 §1. Never performance
  evidence.
- **`rosterchanges_injured_reserve.csv` is not trustworthy** — listed healthy starters
  as both On and Off IR the same day. Use `injuries` + `gamedaycalls`.

---

## 11. Standing

**n = 4. Fit nothing.** The logs are honest test cases, not a training set.

Week 4's lesson was about **bar design**, not any player: thresholds that noise can
flip, and legs written on single player-weeks. §5 is the same lesson arriving from a
new direction — a 0.5-point line move moved a multiplier 9.5%.

Separate **"decision wrong"** from **"outcome bad"** at every retro. Weeks 1 and 3
proved they diverge, and Week 4's Sutton/Raymond call was right by 0.70 while the
week was lost by 5.58.
