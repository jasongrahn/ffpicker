# Week 9 Decisions — 2026, JGrahnasaurs (4-4, 6th)

Opened **2026-11-03 Tue**. Opponent: **Steel City (2-6, 9th)**. Wk8 retro: `2026_week08_decisions.md` R2.

Source of record: `docs/uploads/week_8_data/*_actual_2026-11-03.csv` (owners Tue AM, before Wed
clear) + `data/nflreadr/pull_2026.rds` (pulled 11-03 09:23, MNF in). Wire: `wire_scan.R` on those
exports, `WEEK=9`.

## Card

Run 2026-11-03 Tue on `week_9_data/*_2026-11-03.csv` (13:27). Projections = position pages (matchup page differs ~0.02).

| item | read |
|---|---|
| data | 1 pull, 6 pos files, 0 started games ✓. **Washington DEF still on our roster** -> M3 drop didn't land -> 1 open spot, not 2 -> only first successful claim lands. Re-drop |
| wk8 | L 87.50-125.22 -> 4-4, 6th (R2 in wk8 log) |
| odds | P(top 4) **3.5%** (sim reads us ~2pp low). Wk9 v Steel City P(win) **38.6%** (99.9 v 108.1). +5 pts/wk -> +3.9pp |
| DST | **Chiefs hold** v NYJ, opp implied 18.5 (4th; top 3 rostered), Yahoo 7.66 > every free DST -> rule + Yahoo agree -> T3 not run |
| hole | none new. 4 RB tickets clear Wed (§1) |
| trades | **D1 sent.** Re-scan -> **K2, O4, J1 GO** -> send tonight. X1, O3, X2 NO-GO; S1/M1 NO (below) |
| kills | C1 Tucker (wks 8-10 < 5 tgt/g or < 60% snaps); each claim (wks 9-10 < 8 opp/g or < 40% snaps); D1 (Coker share < 15%, wks 10-12) |
| lineup | QB Mahomes 19.77 / RB J. Williams 16.14, **Henry 12.45 (Thu)** / WR Boston 9.43, Tucker 8.30 / TE Hockenson 8.89 / FLEX Gordon 12.29 / K Bates 9.14 / DEF Chiefs 7.66. Re-read Thu before TNF |

Lineup band calls (start higher raw Yahoo, no kill, no retro): Mahomes v Stafford 19.77 v 18.47
(`Q`); Tucker v Odunze 8.30 v 8.28. D1 accepted by Thu -> TE Strange 7.81.

### Trades, re-priced 11-03 (`2026_week09_offer_set_{mean,latest}.out`, Tate-out world, 5 seeds)

| offer | ΔP mean / latest (pp) | partner ppg / paper (latest) | verdict |
|---|---|---|---|
| D1 Hockenson -> Jalen Coker (Dave’s) | +1.81 / +0.76 | **+0.37** / +1.31 | **GO** |
| X1 Mahomes + Tucker + Strange -> Burden + Kraft (Max’s) | +2.08 / +1.50 | **−1.69** / **−2.12** | NO-GO. 11-02 ppg was +0.02: Burden wk8 15.10 -> last-3 16.77 |
| O3 Stafford -> Golden + Kittle (Owl Out) | +5.79 / +9.41 | **−2.05** / −1.20 | NO-GO (expected) |
| S1 J. Williams -> Olave + Kelce (Sunday Kevin) | +0.32 / **−0.84** | +2.07 | NO |
| M1 Gordon -> A. Jones + Skattebo (Michelle) | +1.24 / **−0.68** | +1.31 | NO |

- **D1 pitch (Dave's numbers):** "Your TEs: Pitts 6.8 ppg, Andrews 5.0 (2.5 last 3). Hockenson 9.0
  ppg, 8.8 last 3. You have 6 WRs for 2-3 slots; Coker is your 2nd-best by ppg (11.3, 8.2 last 3)."
- Dave’s 4-4, 5th = rival for 4th. ΔP already nets their gain.
- **SENT 2026-11-03 Tue ~15:20 ET** to Dave’s, with note (TE hole pitch: Pitts 6.8, Andrews 5.0 /
  2.5 last 3; Hockenson 9.0 / 8.8, MIN bye done; Coker = WR surplus). Reply: pending.
- **M3 redone ~15:20 ET:** Commanders dropped (13:27 pull still had them) -> 2 open spots for Wed claims.
- Not accepted by Thu -> re-offer w/ Odunze sweetener if still free (#50 §3).
- ~~Wed: re-scan Max’s + Owl Out~~ -> **re-scanned same day** (user 11-03: neither offer was sent ->
  no rejection, nothing to wait on; ADR 0012 clock = send Tue; "re-scan Wed" was #50's, not ADR).

### Re-scan 11-03 ~15:30 (`lead/wk9_search.R` -> `lead/wk9_menu.R`; `2026_week09_offer_menu_{mean,latest}.out`)

Screen: 137,742 trades (shapes 1-1..3-2, 8 partners, Hockenson + Dave’s out, Tate-out, wks 10-15)
-> fair = partner ppg >= −1 AND paper >= −2 AND ours > 0 -> best per partner -> sim, both bases.

| offer | ΔP mean / latest (pp) | partner ppg / paper (mean, latest) | verdict |
|---|---|---|---|
| **K2** Tucker + Strange -> Christian Watson (GB WR, `Q` ribs) + Travis Kelce (KC TE) (Sunday Kevin) | +5.22 / +6.35 | −0.37 / −1.94, −0.72 | **GO** |
| **O4** Mahomes -> Jaylen Waddle (DEN WR) + George Kittle (SF TE) (Owl Out) | +4.14 / +4.17 | **−0.99** / −1.20, +0.13 | **GO**, ppg 0.01 inside bar |
| **J1** Odunze -> Rhamondre Stevenson (NE RB) + DK Metcalf (PIT WR) (Jazzy) | +2.15 / +1.86 | 0.00 / −1.52, −1.23 | **GO** |
| X2 Kyler -> Parker Washington (JAX WR) (Max’s) | +3.25 / +4.81 | −0.96 / −1.88, **−3.29** | NO-GO (paper, latest) |
| M2 Kyler + Odunze / M3 Mahomes + Odunze -> M. Wilson + LaPorta (Mitchell) | +3.11/+1.78; +2.94/+0.33 | pass | GO alone; share Odunze w/ J1 (+ Mahomes w/ O4) -> J1 set wins |

- **Set D1 + K2 + O4 + J1: +15.66 / +12.00pp** -> P(top 4) ~3% -> ~15-19% if all land. Any subset
  positive. No shared players. Every subset leaves >= 1 TE (K2 brings Kelce), 2 QBs (Stafford, Kyler).
- 1-for-2s (O4, J1) need a drop each when they process -> drop the weaker RB claim ticket(s) (land
  Wed). Never Kyler (QB cover: Stafford `Q` arm, LA bye wk11).
- Kills, wks 10-12: K2 Watson share < 15% avg 3 g or Kelce snaps < 60%; O4 Waddle share < 15% or
  Kittle snaps < 70%; J1 Stevenson < 10 carries+tgt/g or Metcalf share < 15%.
- Pitches (their ppg / last 3):
  - K2: "Tucker 14.3 last 3 v Watson 9.8 + ribs. Warren (9.8) is your TE -> Kelce sits; Strange = backup."
  - O4: "Caleb's played 5 of 8, Bryce 12.9 last 3. Mahomes 18.5 ppg. Kittle sits behind Bowers; Waddle = WR5."
  - J1: "Stevenson is your RB4, Metcalf WR4 — neither starts. 2-for-1 frees a spot for the wire."
- Veto risk: K2 names (Kelce, Watson) — ppg-fair, so arguable. Log every reply.
- **K2 SENT 2026-11-03 Tue** to Sunday Kevin. Yahoo trade screen: us **+35.15** season (wks 9-17), Kevin
  **−5.53** (~−0.6/wk). Note owned the gap ("Yahoo has it slightly in my favor, ~half a pt/wk"), Tucker
  hot v Watson ribs, Kelce sits behind Warren, Strange = TE cover, open to counter. Veto risk up:
  voters see +35 v −5.5. Counter -> price both checks before accepting. Reply: pending.
- **O4 NOT SENT** (user call, 11-03). Yahoo trade screen: us +15.09, Owl Out **−20.20** (wk11 −10.65,
  wk13 −10.60 = their bye weeks, where Kittle/Waddle would start; Mahomes sits behind Caleb) ->
  visible loss -> low acceptance + veto bait. Our ppg check −0.99 was already at the bar. Long-term
  is not the issue: Yahoo shows us + in wks 16-17 too (+1.48, +1.31). Mahomes stays = QB1 while
  Stafford `Q` arm. Owl Out: re-scan only if K2 dies (Strange/Tucker free again).
- **J1 SENT 2026-11-03 Tue** to Jason's Jazzy Team. Yahoo trade screen: us +2.46, Jazzy −4.11 (~−0.5/wk).
  Note: "roughly even", open spot = their upside (Stevenson RB4, Metcalf WR4), Odunze 8.3 last 3,
  open to counter. 2-for-1 -> drop weaker RB claim ticket when it processes. Reply: pending.
- **Offers out 11-03: D1, K2, J1** (3 of >= 4 toward ADR 0012's 11-20 stop rule). O4 skipped.
- `offer_set.R` fix 11-03: `BASE=latest` halted (S1 auto-drop cut Stafford -> S1+O3 chain gave a
  player not on roster). Now skips + prints failed subsets (5, all S1/M1+O3 combos). Mean run
  byte-identical. Subset table + EV under latest = feasible subsets only -> ignore that EV.

---

## 1. Moves. Executed by user 2026-11-03 Tue ~09:50 ET.

| # | move | why |
|---|---|---|
| M1 | **Drop Etienne** (NO RB, IR) | NO's 4th RB behind Kamara, K. Miller, Donaldson -> ~0. Review 002 §2a: drop him when a spot is forced |
| M2 | **Tate** (TEN WR, `O` shoulder) **-> IR** | `O` is IR-eligible. TEN bye wk9 -> costs 0. Frees a roster spot |
| M3 | **Drop Commanders DEF** | wk9 v LA, opp implied 26.5. Chiefs hold (v NYJ 18.5, tied 4th; top 3 rostered) |
| C1-C4 | **Claims, no drop, clear Wed 11-4:** Kendre Miller (NO RB) > Tyler Allgeier (ARI RB) > Mike Washington Jr. (LV RB) > Jadarian Price (SEA RB) | 2 open spots -> first 2 successes land, rest fail on full roster |
| C4x | **Price claim CANCELLED** by user 11-03 Tue pm | C1-C3 stand; 2 open spots (M3 redone) -> first 2 successes land |
| C1-C3 result | **Wed 11-4 (Yahoo email): Miller LIVE, Washington Jr. LIVE, Allgeier DENIED** (higher priority) | 2 spots filled. Kills armed per add (below). Roster 15 active + Tate (IR slot) + Adams (IR) |

Wed 11-4 re-run, `week_9_data/*_2026-11-04.csv` (17:15, 0 started games ✓). Claims already in the
export -> no `TXN` rows. No trade processed (Dave's 15, Kevin 16, Jazzy 15 owned). P(top 4) **3.1%**
(was 3.5); wk9 P(win) **37.0%** (99.1 v 108.6) — projection drift both sides, not the claims
(tickets bench in wk9). Lineup re-read: Odunze 8.74 now > Tucker 8.49 -> start Odunze (band call,
higher raw, no kill). Rest unchanged: Mahomes 19.96 v Stafford 18.55 `Q`; Kyler `Q`.

FA swaps priced Wed 11-4 (`wire_scan.R` + `league_sim.R` TXN variants, same seed, 11-04 pull):

| # | move | P(top 4) mean | latest | why |
|---|---|---|---|---|
| — | none | 3.1% | 4.8% | baseline |
| F1 | **Claim A.J. Brown** (NE WR, `W (Nov 7)`, `Q`), **drop Kyler** | 4.2% (+1.1) | 5.1% (+0.3) | base 11.15 > every WR ours (Boston 9.26). 3rd QB ≈ 0: Stroud 18.26 FA = Kyler 18.28 base. Claim fails -> Kyler stays, cost 0 |
| F2 | **Add Jadarian Price** (SEA RB, FA, instant), **drop Washington Jr.** | 3.2% (+0.1) | 5.1% (+0.3) | Price beats Washington on every usage line: 12.2 v 8.9 opp/g, 48 v 40% snaps, base 9.41 v 5.25. E. Wilson (SEA) no wk8 game, Yahoo 0.58 |
| — | F1 + F2 | 4.2% | 5.4% (+0.6) | both positive, both bases |

- F1 caveat: Brown 2026 = 3 games, 4.1 / 4.2 / 6.3 half-PPR, `Q`. Projection rides name; opp 6.7/g ≈ ours.
  Kill: < 15% tgt share or < 60% snaps, wks 9-12 (NE bye 11).
- F2 kill: < 8 opp/g or < 40% snaps wks 9-10 (same as C1-C3).
- Kyler was "never drop" (#53) for QB cover; superseded by Stroud on wire. J1 lands -> drop = weaker RB ticket.
- DST: Texans (`W (Nov 7)`, opp implied 18.0) v Chiefs 18.75 -> 0.3 pts. Hold Chiefs.

| # | executed by user Wed 11-4 | state |
|---|---|---|
| F2 | **Add Price, drop Washington Jr.** | **LIVE** (instant FA). Post-11-04-pull -> `TXN` row needed |
| F1 | **Claim A.J. Brown, drop Kyler** | **PENDING**, clears Sat 11-7. Success -> `TXN` row; fail -> Kyler stays |

- **Lever 4, dead-spot tickets** (review 002 §2): >= 10 carries+tgt/g -> 15.6% become 12+ ppg
  starters wks 10-15 (n 32). ~+0.5pp each. Order = scan last-3 opp/g: Miller 17.5 (2 g, NO bye
  8), Allgeier 15.7, Washington 14.0, Price 14.0 (1 g). Snaps last 3: 42 / 54 / 40 / 48%.
- **Skipped:** Gainwell (TB) 32%, Dowdle (PIT) 39% snaps -> already under the kill's snap leg.
  Jonah Coleman -> Maybe Mitchell (claimed).
- **Swap v our RBs: rejected** (user asked). Drop rule = usage, never ppg. Weakest ours = Henry:
  18 / 19 / 13 carries+tgt wks 6-8, snaps 58 -> 45% -> >= every candidate but Miller (2 g,
  committee w/ Kamara). Wk8 dip in a 10-36 loss (script). Wk9 BAL +9.5 home dog v JAX ->
  slope 0.924x, expect another light week; not a role read. Gordon, J. Williams 20-28/g, 74-83%.
- **Kill per add (role, wks 9-10 = 2 games after add):** < 8 carries+tgt/g or < 40% snaps ->
  swap (review 002 lever 4). Metric = `wire_scan.R` `opp`.
- **Tate's spot back** (wk10 earliest, no timeline): X1 frees one (3-for-2), or the weaker
  ticket goes under its kill. Neither -> drop Tucker if C1 kill (wk8 log) fired.

Sim notes:
- `league_sim.R` reads Tate as active (tag `O`, not `IR`) -> prices him healthy from wk10.
  Intended (gotcha 3). Claims landed Wed -> roster 15 + Tate -> sim 16 active > `CAP` 15 ->
  `settle()` drops one in trade runs after Wed. Pass Tate as IR there.
- Claims landing Wed = moves after the Tue export -> `TXN` rows. `TXN` loop needs `drop` on
  the roster (`stopifnot`) -> no-drop add needs `drop = NA` support. Fix when they land.
- **O3 expected NO-GO.** ADR 0012 acceptance = partner ppg-world >= −1 AND paper >= −2. Review 002
  §3 (11-02): Owl Out ppg **−1.80** -> already failed; #50 §3 carried it as "long shot" anyway
  (my 11-03 send note too — corrected). Since: Stafford `Q` arm, 9.28 wk8. Tue re-run decides;
  fail -> don't send, re-scan Owl Out Wed for a ppg-fair version (ADR 0012, #50 §3).
- O3 passes after all -> 1-for-2 -> designate Odunze as the drop even though the roster is 13
  now: claims fill it Wed, before the trade processes.

## 2. WR scan, Wed 11-4 (user: "WR game is pretty shit")

Need first: starters v league median (BASE=mean, 11-04 + F2): **WR −9.3/wk** (17.7 v 27.0, 9th of 10),
FLEX −1.3, TE −0.9, RB +0.9, QB/K/DST ~0. Total −15.6 -> WR = 60% of the gap. RB = only surplus.

Search: `lead/wk9_wr_search.R` (wk9_search.R, get side >= 1 WR, partners without a pending offer,
give side excludes D1/K2/J1 players + Kyler + Tate). 23,660 screened, 884 pass both bases + ADR 0012.
Priced with pending set: `lead/wk9_wr_menu.R` -> `2026_week09_wr_menu_{mean,latest}.out` (5 seeds, Tate out).

| # | partner | we give | we get | dP mean / latest | partner ppg / paper |
|---|---|---|---|---|---|
| W1 | Owl Out | Stafford | Jaylen Waddle (DEN WR) + George Kittle (SF TE) | +4.32 / +4.59 | −0.69 / −0.45 |
| W2 | Maybe Mitchell | Boston | Michael Wilson (ARI WR, `Q`) + Sam LaPorta (DET TE) | +4.47 / +1.59 | −0.38 / −1.71 |
| W3 | Steel City | Mahomes + Henry + K. Miller | Nico Collins (HOU WR) + Garrett Wilson (NYJ WR, `Q`) | +3.78 / +3.79 | +3.69 / −1.10 |

- Pending for reference: K2 +5.87 / +5.11, D1 +1.66 / +0.41, J1 +2.13 / +0.24.
- Best subset both bases: **K2+W1+W3** +14.5 / +13.4pp. EV all six at 30% each: +4.6 / +3.2pp.
- No player in two offers ✓. Designated drops overlap across offers (auto-drop conflict in 28-32
  subsets) -> pick drop at accept time from what's left; never Kyler if W1+W3 both land.
- W1 = same get side as O4, which Yahoo's impact screen showed Owl −20.20 -> **screen before send**.
- W3 to our wk9 opponent: accept Wed/Thu -> lands before Sun -> arms them v us (Mahomes, Henry).
  **Send Mon 11-9**, after wk9.
- Usage: Waddle share 21-29% wks 5-8 (ppg 8.0, TD-light); Kittle 22-28%, 12.5 ppg; M. Wilson 15-37%,
  10.8 ppg; LaPorta 6-25%; Collins 16-31% (5 g, HOU bye 8); G. Wilson 10-39%, 11.5 ppg.
- Kills (wks 11-13; DEN bye 10): W1 Waddle share < 15% avg 3 g or Kittle snaps < 60%; W2 M. Wilson
  share < 15% or LaPorta snaps < 60% (wks 10-12); W3 Collins or G. Wilson share < 15% (wks 10-12).

## 3. Cruise control, Wed 11-4 (user call)

User: "we're on cruise control for the rest of the season. we aren't last, and i'm happy about that."
-> Stop rule (CLAUDE.md weekly loop §5) invoked early, wk9 not wk10. P(top 4) 3-5% now; all
pending land ~12-14%. **W1-W3 NOT sent.** D1 / K2 / J1 + Brown claim (F1) left to run.
Weekly from here (<= 15 min): Thu lineup = higher raw Yahoo proj per slot; Sun 11:45 `O` swap;
trade reply -> one-line yes/no. No scans, no retros, no kills scored.
