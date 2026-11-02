# Meta-analysis brief — 2026-11-02 (Mon). Read fully before any work.

Repo: `/Users/jasongrahn/R-projects/ffootballer` (R package, load with `pkgload::load_all(".")`;
`devtools` NOT installed; `renv` warning on every Rscript = cosmetic).
Scratch root (all your output goes here): `docs/review/002-evidence/`

## 1. Mandate

Yahoo fantasy football, one 10-team company league. Our team **JGrahnasaurs is 4-4**, projected
**9th of 10** in roster strength, **P(make top 4) ≈ 2.6%**. Goal: a meta-analysis of everything
done draft -> wk8 to **turn the season around**. Output = ranked levers for wks 9-15, each priced
in **wins and ΔP(top 4)**, with evidence, cost, and a pre-registered kill condition; plus a
stop-doing list. Objective = championship probability -> first P(top 4). "Win each matchup, even
by 1 point": price everything in wins, not points.

**Clock:** Tue 11-3 = waivers + wk9 data pull + trade sends (TR1, TR2 below). Thu 11-5 = wk9
lineup freeze. Trade deadline 11-28 (league-vote review, 2 days -> accept by ~11-26). A finding
that changes TR1/TR2 must surface before Tue.

## 2. League facts (full: `CLAUDE.md`, `config/league.json`, `config/scoring.json`)

- 10 teams, H2H. Roster QB1 RB2 WR2 TE1 FLEX(RB/WR/TE)1 K1 DST1 + 6 bench + 2 IR (IR outside
  the 15). Half-PPR, 4/pass TD, -1/INT, 0.04/pass yd, 0.1/rush-rec yd, 6/rush-rec TD.
- Regular season wks 1-15; **top 4 make playoffs (wks 16-17)**; standings tiebreak = points for.
- Waivers: rolling priority, **no FAAB**; dropped players clear in 2 days; after the Wed clear,
  first-come. Trades: no cap, league votes, deadline 11-28.
- 10 teams x 1 QB -> starting-calibre QBs sit on the wire (Stroud base 18.3 on waivers now).

## 3. Where we stand (computed 11-02 with the helper below)

Standings after wk7 (wk8 not entered; Yahoo finals land Tue):

| team | W-L | PF | wk8 opp |
|---|---|---|---|
| Owl Out Blitz | 6-1 | 843.0 | Dave's |
| Max's TD Bombers | 5-2 | 868.3 | Sunday Kevin |
| Jason's Jazzy Team | 5-2 | 766.8 | Maybe Mitchell |
| Sunday Kevin | 4-3 | 812.4 | Max's |
| **JGrahnasaurs** | 4-3 | 754.1 | Michelle -> **LOST, 87.50 v ~113-133** |
| Dave's Bone Crushers | 4-3 | 749.4 | Owl Out |
| Maybe Mitchell | 3-4 | 769.5 | Jazzy |
| Locked In Michelle | 2-5 | 796.0 | us |
| Steel City | 1-6 | 637.1 | Madison |
| Monday Night Madison | 1-6 | 495.4 | Steel City |

Sim (wk8 L fixed): **P(top 4) 2.6%** (tau 0) / 4.1% (tau 6); expected final wins 6.08.
P(top 4 | final wins): 8 -> 6.5%, **9 -> 70%**, 10 -> 100%. Need 5-2 over wks 9-15.
Remaining (P(win), leverage = P(top4|W) - P(top4|L) ≈ 5pp each):
wk9 Steel City 0.33 | wk10 Dave's 0.28 | wk11 Sunday Kevin 0.29 | wk12 Mitchell 0.35 |
wk13 Jazzy 0.27 | wk14 Max's 0.27 | wk15 Owl Out 0.29.
Exchange rate (pts/wk added to our strength wks 9-15 -> ΔP(top 4)): +1 -> +0.46pp, +3 -> +1.6pp,
+5 -> +3.2pp, +10 -> +9.3pp, +15 -> +18.9pp. **Convex** — big moves earn more per point.

Projected weekly strength (projection-optimal lineup, sim units; `fut` = mean wks 9-15):
Sunday Kevin 117.0, Michelle 116.7, Dave's 115.3, Jazzy 114.7, Owl Out 114.3, Max's 113.9,
Steel City 112.6, Mitchell 109.1, **us 98.5**, Madison 93.4. Our deficit to the pack ≈ 13-18/wk.

Our roster (10-28 export; base = mean of non-zero Yahoo weekly projections wks 4-8):

| pos | player (NFL team) | base | note |
|---|---|---|---|
| QB | Matthew Stafford (LA) | 18.9 | bye wk11 |
| QB | Kyler Murray (MIN) | 18.3 | in TR1 |
| QB | Patrick Mahomes (KC) | 17.9 | in TR2 |
| RB | Derrick Henry (BAL) | 16.1 | bye wk13 |
| RB | Javonte Williams (DAL) | 14.6 | bye wk14 |
| RB | Ollie Gordon II (MIA) | 9.6 | |
| RB | Travis Etienne Jr. (NO) | IR | back from bye; activation needs a drop |
| WR | Carnell Tate (TEN) | 9.4 | **OUT shoulder** (wk8), TEN bye wk9, in TR2 |
| WR | Denzel Boston (CLE) | 9.3 | bye wk11 |
| WR | Rome Odunze (CHI) | 8.3 | bye wk10 |
| WR | Tre Tucker (LV) | 7.8 | claimed 10-28; bye wk13 |
| WR | Davante Adams (LA) | IR | earliest wk12 |
| TE | T.J. Hockenson (MIN) | 7.8 | in TR1 |
| TE | Brenton Strange (JAX) | 7.9 | |
| K | Jake Bates (DET) | 8.5 | |
| DST | Commanders, Chiefs | 5.7, 6.4 | DST streamed weekly |

Pending trades (not sent; re-run Tue): **TR1** Kyler + Hockenson -> Josh Jacobs (GB RB) from
Monday Night Madison. **TR2** Mahomes + Tate -> Luther Burden III (CHI WR) + Isaiah Likely (NYG TE)
from Max's. 10-28 sim: TR1 alone 5.1 -> 8.1%, TR2 alone -> 7.1%, both -> 11.0% (pre-wk8-L
baseline). Details: `data/weekly/2026_week08_decisions.md` §3, `data/weekly/2026_week08_trade_ideas.md`.

## 4. Machinery

- `dev/weekly/league_sim.R` — rosters, base, bye fill, `strength_matrix()`, `simulate()` (normal
  noise sd SIG = 21.08 per team-week, mean gap GAP = -4.24 vs ceiling, n 50 team-wks wks 3-7;
  TAU2 = 43.5 = between-team variance of the gap, used only with env GAPMODE=shrunk; `tau` =
  persistent strength offset, default 0). READ IT before using it.
- **Shared helper (use it — common baseline for every agent):**
  `source(".../scratchpad/meta/sim_helpers.R")` from repo root -> loads `league_sim.R`, builds
  `M0`, and adds `simulate_cond(M, tau, sig_team = NULL)` (wk8 scores fixed: us 87.50 L, Michelle
  120 est.), `pt4(s)` (our P(top 4), exp wins), `exch(M)`. Same seed -> common random numbers:
  deltas between calls = the move, not MC noise.
- Trade machinery: `eval(parse(text = readLines("dev/weekly/trade_finder.R")[c(18, 23:40)]))`
  (after sourcing the helper) defines `CAP`, `settle()`, `apply_trade(R, team, give, get)`, `lab()`
  without running the scan. NFL byes left: LA 11, GB 11, CLE 11, CHI 10, TEN 9, BAL 13, LV 13,
  DAL 14; MIN/KC/MIA/JAX/DET/WAS/NO/NYG already had theirs. Then
  `s <- simulate_cond(strength_matrix(x$R))`. Tate-out bound: `R$base[R$player == "Carnell Tate"] <- 0`.
- Data: Yahoo exports `docs/uploads/week_N_data/` (read via `dev/weekly/read_yahoo_week.R`:
  `read_yahoo_position(file)`; `read_yahoo_week()` has a bug — keeps the OLDEST pull when a folder
  has 2+ dates; read by dated file instead). `_actual_` files = Yahoo points scored (`-` = DNP ->
  NA). 2026 NFL data: `readRDS("data/nflreadr/pull_2026.rds")` (schedules, player_stats wks 1-8
  minus MNF wk8, snaps, injuries, team_stats, depth, ids). History 2015-2026:
  `arrow::read_parquet("data/raw/player_stats.parquet")`, `data/raw/ff_opportunity.parquet`;
  live `nflreadr::load_*(2024:2025)` works (network). Scoring: `score_player_week(stats,
  load_config("scoring"))` after `pkgload::load_all(".")` — validated 35/35 vs Yahoo; DST not covered.
- League results: `data/weekly/2026_league_schedule.csv` (all 10 teams' weekly PF/PA wks 1-7).
  Frozen predictions: `data/weekly/2026_week0{7,8}_leaguewide_predictions.csv`. Yahoo set-lineup
  projections wk8: `data/weekly/2026_week08_yahoo_matchups.csv`. Ceilings: `data/weekly/2026_ceilings.rds`.
- Decision logs (every decision + pre-registered kill + retro): `data/weekly/2026_week0{2..8}_decisions.md`.
  Regret table: `data/weekly/README.md`. Rules + key numbers: `CLAUDE.md`. Evidence: `docs/adr/0002-0011`.
  Session history: `docs/handoff/` (newest = #51 `...-44-META-ANALYSIS-TURNAROUND.md`, #50 `...-43-...`).

## 5. Rules — non-negotiable

1. **Write ONLY under your own scratch subfolder** (`.../scratchpad/meta/<your-id>/`). Never
   create, edit, or delete a repo file. No git commands that change state.
2. **Never run as-is:** `dev/weekly/trade_finder.R` (overwrites `data/weekly/2026_trade_scan_wk8.rds`),
   `ceiling_vs_margin.R` (overwrites `2026_ceilings.rds`), `predictions.R`, `freeze_lineups.R`,
   `pull_nflreadr.R` (clears cache, rewrites the 2026 pull), `schedule_check.R`. Copy what you
   need into your scratch dir and change output paths.
3. Run R from repo root: `cd /Users/jasongrahn/R-projects/ffootballer && Rscript <scratch>/x.R`.
4. Team names are byte-exact: "Dave’s Bone Crushers", "Max’s TD Bombers" use U+2019; "Jason's
   Jazzy Team" a straight apostrophe. Align matrices by name, never by sort position.
5. Every delta uses common random numbers (same seed). Report n, CI or MC error where it matters.
   A ΔP under ~0.5pp at N 20000 is near MC noise for one seed — say so, or use ≥ 5 seeds.
6. Don't re-derive what's settled (§6) unless your data contradicts it — then say exactly how.
7. Explain football facts only as needed; the user is a lead data engineer (fluent in stats/R),
   casual football fan.

## 6. Settled (reopen only with new evidence)

Lineup layer at its ceiling (wks 1-4: 0.80 pts choice regret vs 73.62 projection error, ADR 0010).
Inside a 15% projection gap -> start higher raw Yahoo projection (52% vs 71% accuracy; ADR 0008).
Yahoo projection = best one-week estimate (MAE 4.29 vs 6.71 usage-based; ADR 0009).
DST: stream on opponent implied total (+1.92 pts/wk, n 128; ADR 0011). K: hold (null, n 214).
Spread tiebreak retired. Game script = RB slope only (ADR 0007). Gate passed: roster-ceiling diff
-> margin r +0.54, n 25 (wks 3-7).

## 7. Output

Write `<your-id>/FINDINGS.md` (≤ ~150 lines; tight, fragments fine). Structure:
1. **Headline** — 1-3 lines, the verdict.
2. **Numbers** — each with n / CI / seed count; name the script that produced it (keep scripts in
   your folder).
3. **Lever(s)** — each priced: Δ pts/wk, ΔP(top 4), Δ expected wins; cost (user time, roster
   spots, risk); a pre-registered kill condition (role/usage-based, window starting after the
   decision, never a single player-week of points).
4. **Assumptions challenged** — which project assumption your work supports, weakens, or breaks.
5. **Open / not done** — what you could not test and why.
Your final message back = the FINDINGS.md content (it's what the lead reads).
