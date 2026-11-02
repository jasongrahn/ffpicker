# Review 002 — Season meta-analysis, draft -> wk8. Turnaround levers wks 9-15.

**Date** 2026-11-02 Mon, before wk8 MNF. **State** 4-4 (wk8 L provisional), roster 9th of 10,
**P(top 4) ~3%**. **Method** 5 analysts + 4-expert challenge panel (veteran practitioner,
statistician, decision scientist, red-team engineer). One shared baseline for all
(`simulate_cond()`: `league_sim.R` + wk8 L fixed, common random numbers, 5-10 seeds). Priced
in wins. **Evidence** `docs/review/002-evidence/` (README = index; each agent's `FINDINGS.md`).
**Style** caveman, repo rule.

---

## 0. Verdict

1. **Record = roster, not luck.** All-play 30-33 (8th of 10) -> 4-3 thru wk7 was **+0.67 W lucky**.
   Roster gap = 69% of our margin deficit. **0 of 4 losses winnable by any pre-kickoff call.**
2. **TR1 + TR2 as built: don't send.** Our side holds in every world tested (+1.3..+1.9pp each).
   Partner side fails: both look like losses on the ppg partners see (Madison −8.3/wk, Max's
   −6.1/wk) -> rejection. TR2 also fails its pre-registered Tate-out bound (Max's −0.55pp, 10/10
   seeds) -> log M1 says re-scan. TR1 "win-win" was a `settle()` bug.
3. **Send instead, Tue, in parallel, no shared players: X1 (Max's), D1 (Dave's), O3 (Owl Out,
   long shot).** All positive under both base definitions. X1 + D1 **+3.8pp -> ~6%**; all three
   **+7.9..+11.3pp -> ~10-14%**.
4. **Sim understates us ~2pp**: blind to Adams' IR return (+1.1..+1.9pp) and to DST streaming
   (+1.0..+1.7pp). Changes no decision.
5. **Effort was inverted**: lineup coin flips 18% of log lines for <= 0.1pp; trades 2% for ~+4pp.
   Trade delay ≈ −0.7pp/wk. **Stop rule pre-registered** (§6). Honest ceiling ~10-14% P(top 4),
   ~1% P(champ).

## 1. Where we stand

| item | value | source |
|---|---|---|
| P(top 4), wk8 all 10 scores fixed (provisional) | **2.84%** (lineup-noise range 2.2-3.3) | A1 `q4_sim.R` |
| same, best-supported model (shrunk gaps + per-team tau + horizon noise) | **3.0%** | P2 `s04_sens.R` |
| range across defensible assumptions | 1.0% (our sd 8.3 real) .. 5.8% (tau 8.3, uniform gap) | A1, P2 |
| exp final wins | 6.08; need **9 W = 5-2** (P(top 4 \| 9 W) 70-76%, \| 8 W 7%) | A1, P3 |
| each remaining game | P(win) .27-.35, worth 4.7-6.2pp | A1 |
| exchange, +x pts/wk wks 9-15 | +1 -> +0.47pp, +5 -> +3.5, +10 -> +9.9, +15 -> +19.7 (**convex**) | A1 |
| all-play wks 1-7 | 30-33 (8th); weekly score rank 7,1,6,7,7,5,7 | A1 `q1_luck.R` |
| margin wks 3-8 | −55.1 = roster gap −38.2 + our misses −42.2 − their spikes (−25.3) | A1 `q2_decomp.R` |
| one game | ≈ 30% roster, 70% noise (R² 0.29-0.34) -> roster = only lever that compounds | A1 |
| P(champ) | 0.22%; playoff point-week worth 1.42x a regular one | P3 `01_objective.R` |

Losses, best legal lineup in hindsight v their score: wk1 121.56 v 118.96 (flips only on a 9%-gap
QB coin flip the projection got wrong), wk4 **120.10 v 123.98**, wk6 95.08 v 111.14, wk8 ~100 v
>= 119. **Wk4 opponent was 123.98, not 98.58** (98.58 = replay of their Wed lineup; diff 25.40
= Hubbard exact). Record fixed in `data/weekly/README.md`.

## 2. Levers, ranked by ΔP(top 4)

| # | lever | ΔP(top 4) | ΔW | cost | kill (window starts after decision) |
|---|---|---|---|---|---|
| 1 | **Trade set X1 + D1 (+ O3)**, Tue, parallel | +1.7 each; X1+D1 +3.8; all 3 +7.9..+11.3 | +0.29 each | ~30 min user | per trade §3; process: 0 accepted of >= 4 offers by 11-20 -> stop asking |
| 2 | **Adams (LA WR) back wk12**, activate, plan the spot | +1.1..+1.9 (sim blind) | +0.17 | 1 drop wk12 | not practicing by LA's wk11 bye, or < 60% snaps 1st game back -> value 0, cut for a ticket |
| 3 | **DST stream, one slot** (ADR 0011) | +1.0..+1.7 (sim blind) | +0.15 | 5 min/Tue | none weekly; season-end `dst_test.R` rerun |
| 4 | **Lottery tickets in dead spots** (15th spot, DST2, TE2) | ~+0.5 per RB ticket >= 10 touches+tgt/g | ~+0.05 | claims, ~10 min/wk | < 8 touches+tgt/g or < 40% snaps in the 2 games after add -> swap |
| 5 | **Stop rule + weekly card** (§6, §7) | protects hours, not points | — | — | post-wk10 rerun > 3% despite 4-6 -> resume |

Guard, not a lever: **if Stafford and Kyler both leave, claim a wire QB for LA's wk11 bye**
(Stroud class, 18.3). Empty slot = −2.2pp. X1 + O3 leaves Kyler (MIN, bye done) -> no hole.

### 2a. Lever 2-4 detail

- **Adams**: hamstring IR since wk7, pre-injury base 12.6 = our WR1 when back. No timeline in any
  source; earliest wk12. `league_sim.R` drops IR players -> sim never sees him (P4: +1.14pp,
  A4: +1.92pp in trade world). Playoff weeks weight him ~1.2x more (P3).
- **DST**: wk9 hold **Chiefs** (v NYJ, opp implied 18.5); **drop Commanders Tue** (v LA 26.5,
  23rd). Wks 10-15: target whoever plays **MIA, TEN, NYJ** (A4 table: Colts, Bills, Jets,
  Commanders wk13, Lions, Packers/Colts). All FA -> first-come after Wed clear.
- **Tickets** (A4 base rates, 2021-25, low producers after wk8): >= 10 touches+tgt/g -> **15.6%**
  become 12+ ppg starters wks 10-15 (n 32, CI 6.9-31.8); >= 5/g 7.1%; rising snaps alone 4.1%;
  rookie WR rising targets 4.8% (0 of 11 in 2024-25). Volume beats snaps. Wire now:
  **Jonah Coleman** (DEN rookie RB: snaps 6 -> 40 -> 49 -> 66%, #1 on the 11-02 depth chart,
  wk8 18.4 pts; Yahoo proj 10.2), Mike Washington Jr. (LV rookie RB, 60% snaps wk8), Kenny
  Gainwell (TB RB, `Q`, 14 car/g behind Bucky Irving). **Not Achane** (MIA RB, FA on IR):
  Yahoo = **ACL, season over** — panel suggestion killed by data.
- **Etienne** (NO RB, IR): NO's 4th RB behind Kamara, K. Miller, Donaldson -> ~0. Keep on IR
  (free); drop him, not a body with value, when a spot is forced.

## 3. Tuesday trade set

Tate-out world (pre-registered bound), `settle()` fixed, 5 seeds CRN, baseline 2.17%.
`docs/review/002-evidence/lead/offer_set.R`, run plain and with `BASE=latest`.
"paper" = partner's projected change, pts/wk wks 9-15; "ppg" = same on 0.5 season + 0.5
last-3 ppg (what a manager sees in Yahoo).

| offer | partner | we give -> we get | us pts/wk | ΔP mean base | ΔP latest base | partner paper | partner ppg |
|---|---|---|---|---|---|---|---|
| **X1** | Max's (5-2, 84%) | Mahomes (KC QB3) + Tre Tucker (LV WR) + Brenton Strange (JAX TE2) -> **Luther Burden III** (CHI WR) + **Tucker Kraft** (GB TE) | +3.81 | +1.74 | +1.29 | +0.25 (−0.13 w/ Smith, Harvey out) | +0.02 |
| **D1** | Dave's (4-3, 51%) | T.J. Hockenson (MIN TE) -> **Jalen Coker** (CAR WR) | +3.46 | +1.75 | +1.72 | −0.46 | +0.20 |
| **O3** | Owl Out (91%) | Matthew Stafford (LA QB) -> **Matthew Golden** (GB WR, `Q`) + **George Kittle** (SF TE) | +6.45 | +3.99 | +5.92 | −1.79 | −1.80 |
| X1+D1 | | | +6.51 | **+3.83 -> 6.0%** | | | |
| X1+D1+O3 | | | +10.09 | **+7.93 -> 10.1%** | +11.25 -> 13.9% | | |

Why these partners: Max's is thin at WR (DeVonta Smith, RJ Harvey both `O`) and gets QB cover
for Dak's wk14 bye; Dave's has a TE hole (Andrews 7.4, Pitts 6.8) and is a rival for 4th — D1
costs them 1.7pp, which helps us; Owl Out is a near-lock, so arming them costs ~0 (−0.15pp per
+5/wk), but it is the sharpest manager -> long shot.

**Dropped from the set:**
- **TR1** (Kyler + Hockenson -> Josh Jacobs, Madison): us +1.4..+1.6pp, but Madison −2.0 paper /
  −8.3 ppg, Jacobs' base rests on 2 projections, and Hockenson is worth more in D1.
- **TR2** (Mahomes + Tate -> Burden + Likely): fails Tate-out bound; ppg −6.1. X1 = the re-scan.
- **M1** (Gordon -> Aaron Jones Sr. + Cam Skattebo, Michelle) +1.29 -> **−0.99** and **S1**
  (J. Williams -> Olave + Kelce, Sunday Kevin) +0.66 -> **−0.78** under latest projections:
  stale means undervalue our rising RBs (Gordon 9.6 mean v 11.5 now — MIA's lead back, Achane
  out for the season) and overvalue theirs (Skattebo `Q`, 0.00). **New rule: a trade must be
  positive under both `BASE=mean` and `BASE=latest`** (ADR 0012).

Mechanics. Re-run on the wk9 export Tue before sending (MNF tonight: Burden plays). One offer
per partner, no player in two offers (Yahoo may cancel overlaps). O3 is 1-for-2 -> designate a
drop in the proposal (Odunze: −0.07pp). Pitch in their numbers — season ppg, last 3, their
bye/injury hole — never our projections. Accept by **Thu 11-5** to count wk9 (2-day vote).
Not accepted by Thu -> re-offer with Strange or Odunze as sweetener only if still free.
Log each offer + response (date, partner, give/get, reply): first acceptance data we will have.

Kills (role-based, wks 10-12, after landing; action, not a grade — trades can't be undone):
Burden target share < 15% avg over 3 games (fires 26-45% by chance; never on one week) or
Kraft snaps < 60%; **Coker** target share < 15% over wks 10-12 (already 14%, 14% in wks 7-8 ->
44% stay under by base rate, `target_dip_test.R`); Golden share < 18% or Kittle snaps < 70%.

Ceiling: +10..+13 pts/wk needs 3 accepted trades where each partner loses 1.4-2.0/wk on paper
but looks fair on ppg -> +13.5pp, P ~15.6% (A3 `packages.R`). Paper-win-win packages top out
~+10pp. Expect 1-2 acceptances -> realistic +4..+7pp.

## 4. Panel — assumptions challenged

| assumption | verdict | evidence |
|---|---|---|
| iid normal noise, sd 21.1 | **VERIFIED** | skew −0.08, Shapiro p 0.46, homoskedastic, equal team variances; empirical noise moves P 0.01pp (P2, A2) |
| base = mean Yahoo projection as rest-of-season value | **VERIFIED, with a hole** | RMSE 6.72 v ppg 7.68, ties latest (P2 n 378). Hole: fresh role changes (Coleman, Gordon) -> check `BASE=latest` too |
| points add 1:1 to win odds | **VERIFIED** | player slope 0.95; gate's 1.30 = manager effect + Madison outlier (P2) |
| lineup layer at ceiling (ADR 0010) | **VERIFIED, stronger** | 0/4 losses decision-winnable; 3/4 lose even hindsight-best (A1, A5) |
| 15% band, DST rule, K hold, RB-only game script | **VERIFIED / no pushback** | P2 forking-path check: ex-wk6 53.5% still fires; A2 band still +0.88 pts/pair |
| tau = 0 | **WEAKENED** | data tau 6-9, but pairs with team-gap shrinkage; coherent combined model 3.0% (P2) |
| frozen rosters, no IR | **WEAKENED (against us)** | our 1-wk ceiling beat frozen forecast 4 wks running (+3.8/wk, shrunk ~+1.5); Adams +1.1pp unpriced (P2, P4) |
| kill condition on every decision | **WEAKENED** | ~380 retro lines on coin flips changed nothing; keep for adds + trades (A5) |
| "freeze both lineups is load-bearing" | **WEAKENED** | analytics only; opponent replays missed real scores 3x (A5) |
| "win-win on projections" = acceptance | **BROKEN** | 18 of 58,698 trades pass it; TR1/TR2 −8/−6 on ppg (P1, A3) |
| TR1 win-win (+0.0 Madison) | **BROKEN** | `settle()` dropped Madison's only DEF, FILL refilled free -> fake +1.5/wk; truth −2.0 (A3, P4) |
| wk4 "winnable, lost on 3 swaps" | **BROKEN** | real final 123.98 > best 120.10 (A1, A5) |
| "we're unlucky" | **BROKEN** | +0.67 W lucky (A1) |
| #51 "+1 margin sd ≈ +0.47 proj pts" | **CORRECTED** | +1 *our* sd ≈ **+0.38 pts/wk** (|μ| 16, 0.71 pass-through) (A2, P3) |
| CLAUDE.md "stack that costs points loses" | **HOLDS weekly, not seasonal** | weekly stack worth <= 0.35/wk; persistent upside pays (25% x +8/wk ≈ 1.5x a sure +2) (A2, P3) -> ADR 0013 |

Rejected as levers: weekly variance (stacks, boom-bust, NFL-team overlap: <= 0.3pp total;
boom-bust is ~80% noise, A2); wk16-17 schedule shopping (< 0.05pp P(champ), P3); K streaming
(null n 214); more lineup analysis (<= 0.1pp).

Machinery bugs found (P4, A3): `settle()` sole-slot (fixed); locale — under `LC_ALL=C` Dave's +
Max's silently vanish, P(top 4) read 14.6% (guard added); `read_yahoo_week()` oldest pull (fixed);
`simulate_cond()` unnamed `sig_team` -> P = 1.0 silently (guard in archived helper); FILL ignores
fill player's own bye (<= 0.01pp, not fixed); `score_player_week()` ignores return TDs (32 of
11,901 rows, not fixed); 9 injured non-IR players carry full base (Mitchell most overrated,
immaterial to us).

## 5. Where the experts disagreed

- **Variance tiebreak inside the 15% band.** A1 + P1: lean to the higher ceiling. A2 + P2: costs
  +0.88 pts/pair realized, stack buys <= 0.35, boom-bust unpredictable. P3: legit but tiny.
  -> **No rule.** At a near-exact tie (< ~0.3 pts) the QB-stack option is fine; never spend time.
- **Baseline level.** 2.8% (uniform) v 1.6% (shrunk gaps) v 5.8% (tau). P2: gap + tau must move
  together -> 3.0%. A1 flags our own sd 8.3 (n 6, p ≈ 0.2 corrected) -> ~1%. **Quote ~3%
  (1-6%)**; no decision depends on it.
- **TR1/TR2.** P2/P3: GO (our side). A3/P1: partner side fails. -> Both right: value robust,
  acceptance binding -> send ppg-fair versions (§3).
- **Convexity premium size**: A4 ~1.25x (stash), A2 1.5x (25% x +8), P1 ~2x, P3 CE +6.1 for a
  50/50 {0, +10}. Same direction; size depends on the bet's shape.

## 6. Checkpoints, pre-registered 2026-11-02

P3 `05_checkpoints.R` (P(top 4) with TR1+TR2-sized package from wk9):

| after wk10 | P(state) | P(top 4) | then |
|---|---|---|---|
| 6-4 | ~0.13 | ~23% | full effort to the 11-28 deadline |
| 5-5 | ~0.47 | 6-7% | one more trade push before accept-by ~11-26 |
| **4-6** | ~0.40 | **~1%** | **stop analysis. Weekly = Yahoo-projection lineup + DST stream, <= 15 min** |

Kill on the stop rule: post-wk10 rerun shows > 3% despite 4-6 (rivals lost) -> resume.
Trades beat no trades in every state -> wk9-10 results carry no information for sending now.

## 7. Process — stop / keep / start, weekly loop

**Stop**: start/sit analysis inside the 15% gap, QB included (user may override; log "user
call", no harness); K streaming; underpowered weekly tests (player-week kills, regret
narratives, H2H/hedge maps, game-script descriptions, T4, stream detector); 500-line logs and
190-line handoffs; acting on any prior-doc number without a fresh script read.
**Keep**: DST streaming; Sunday injury swap (+0.11 W per zero avoided); league-wide sim pricing
in wins; role-based multi-week kills for adds + trades; <= 30-min league-wide test before any
new rule (`k_test`, `dst_test` = best value per hour of all method work).
**Start**: trade clock (send Tue; last send Tue 11-24 AM); offer log; "which decision changes
if the answer is X?" gate, 30-min cap; Yahoo matchup-page finals as the only opponent-score
source; one 10-line weekly card as the only weekly agent output.

Loop wks 9-15, user ~30 min/wk (A5):
1. **Tue 7:00pm** — user runs the Yahoo collector (this week's projections + last week's
   actuals) + Matchups screenshot. Agent builds the card: data check, result, odds, DST, hole,
   trades, kills, lineup. User does what it says by 9:00pm.
2. **Thu 6:00pm** — set lineup to the card (5 min). Thanksgiving 11-26: Thu games.
3. **Sun 11:45am** — any starter `O`/IR/inactive -> highest-projected legal bench body. Nothing else.

Effort audit (A5, 3,638 log lines wks 2-8, 26 in-season sessions): >= 55% of lines changed no
decision; 5 sessions empty or superseded within a day; 6 catches by the user the analysis
missed (Sutton v Raymond drop -> ADR 0009; "frozen is not locked"; the arming-cost lens). Week-1
kicker fix cost us **Jacobs** (dropped for McLaughlin) — now the player TR1 tried to buy back.

## 8. Changed this session (uncommitted)

- `dev/weekly/trade_finder.R` `settle()`: never drops a team's only QB/K/DEF. TR1 partner now
  reads −2.02 (A3 = P4). Named-trade recipe (line ranges shifted):
  `L <- readLines("dev/weekly/trade_finder.R"); eval(parse(text = L[1:(grep("^mine <- ", L) - 1)]))`.
- `dev/weekly/league_sim.R`: locale guard (10 owners, 5 games/wk).
- `dev/weekly/read_yahoo_week.R`: `read_yahoo_week(dir, date = NULL)` stops on a folder with 2+
  pulls unless `date` given. `freeze_lineups.R` takes `YDATE` env. Tests 545/545 pass.
- `data/weekly/README.md` wk4 + wk5 opponent scores corrected; `2026_week04_decisions.md`
  correction appended below its retro.
- ADR 0012 (trade acceptance + clock), ADR 0013 (underdog variance); `CLAUDE.md` rules.

## 9. Open

- Wk8 other 4 games, MNF stats (Burden), wk9 export: Tue. Re-run `offer_set.R` (CUR 9, both
  BASE settings) before sending. Expected baseline move <= 0.3pp.
- Acceptance odds and League Votes veto threshold: no data. Offer log starts it.
- Not modelled: IR returns (Adams), DST streaming credit, partner counter-moves, competition
  for wire QBs. All three bias our P low.
- Not built: `weekly_card` script (A5 §9 spec in `002-evidence/a5_process/FINDINGS.md`).
