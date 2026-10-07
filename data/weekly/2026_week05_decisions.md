# Week 5 Decisions — 2026, JGrahnasaurs (2-2)

Opened 2026-10-06 Tue. Opponent: **Max's TD Bombers (1st in league)**.
Frozen before Wed 10-07 waiver run. Nothing below the `## Retro` line edited after.

Source of record: `docs/uploads/week_5_data/*_2026-10-06.csv` (Yahoo), plus
`load_player_stats(2026)` / `load_snap_counts(2026)` re-pulled 10-06.

---

## 00. METHOD CORRECTION. Read before trusting handoff #36.

**#36 ranked the roster by ppg and named the wrong drop.** It called Sutton the drop at
3.28 ppg, "worst by 2.5x." Wrong player. ppg embeds the efficiency the project's core
principle says to regress, so it mis-ranks a bench in both directions at once.

| wks1-4 | tgt/g | snap % 1→4 | aDOT | catch % | yd/tgt | ppg |
|---|---|---|---|---|---|---|
| Sutton | 5.50 | 76/73/87/**73** | 11.5 | **0.41** | 3.91 | 3.28 |
| Raymond | 5.75 | 60/62/75/**51** | 5.7 | **0.91** | 9.57 | 9.63 |

Raymond is **third in the Chicago room** behind Odunze (89%) and rookie Luther Burden III
(56%), no injury row in `load_injuries(2026)` — role loss, not a bruise. His 91% catch
rate on aDOT 5.7 regresses down. Sutton holds a stable #1 boundary role on a 41% catch
rate that regresses up. Yahoo's own wk5 projections: Sutton 8.96, Raymond **5.71**.

**The user caught this, not the analysis.** Rules written into `CLAUDE.md` as a result:
drop is ranked by snap share and target trend, never ppg; a handoff doc is a prior claim,
not a source.

Second consequence: #36 §4's FLEX line (Raymond 9.62 / Odunze 7.58) is **season ppg, not
a week-5 projection**. The "we trail by 1.61" figure inherits the ppg error.

---

## 1. Roster moves. Three waiver claims, submitted 10-06, process **Wed 10-07**.

All unowned players in this league read `W (Oct 7)` — 121 QB / 217 RB / 407 WR / 222 TE /
45 K / 27 DEF in the 10-06 export. **There is no free-agent pool.** Nothing is addable
without a claim. Priority 9 of 10; a win moves to 10, so stacking costs ~nothing and
claim order is not worth optimising.

### W1. Add **Bengals DST**, drop **Kalif Raymond**.

Ravens opponent implied total wk5 is **23.50 — worst of all 27 available DSTs.** Bengals
@ Mia is **17.75, lowest in the league**, tied with Jacksonville.

Tiebreak is *variance of opponent realised scoring*, not opponent defensive quality —
defensive quality is already priced into the implied total (#33's "one source counted
twice"). Miami scored 10/10/13/13 → tier payout 4/4/4/4, mean **4.00**. Philadelphia
7/20/24/24 → 4/1/0/0, mean 1.25.

**Byes are complementary: Bengals 6, Ravens 13.** Carrying both closes the wk13 zero-DST
hole. `roster.max_at_position` saying `DST: 1` is our own draft-time cap, not a league
rule — we already carry two kickers.

**Correction to #36's queue:** it listed Jets second. Jets bye = **13, same as Ravens** —
fails the wk13 test. Correct fallback order is Jaguars (bye 7) then Commanders (bye 7).

**Kill condition:** Bengals opponent implied total > 21.0 in any future week → stream off
them, do not hold on name. Scored weekly, not once.

### W2. Add **Ollie Gordon II** (RB, Mia), drop **Woody Marks**.

**De'Von Achane is on IR, knee, ACL** (`yahoo_week5_injuries_2026-10-06.csv`). Season
over. Gordon inherited the backfield.

| opportunities | wk1 | wk2 | wk3 | wk4 | opp/g | trend |
|---|---|---|---|---|---|---|
| Achane | 16 | 26 | 4 | **IR** | — | — |
| **Gordon II** | — | 3 | **20** | **11** | 11.33 | **+12.5** |
| Marks (dropped) | 10 | 14 | 6 | 7 | 9.25 | **−5.5** |

Largest positive trend in the entire available pool. The ACL makes the role durable, not
a one-week fill-in.

**Kill condition:** Gordon under **10 opportunities in each of two consecutive weeks**
→ drop. Two weeks, not one — single player-weeks broke D3 and GD1.

**Accepted cost:** RB room becomes Henry / Javonte / Gordon, three bodies for two RB
slots. Depth, not a hole, but any Henry or Javonte injury forces a wire RB.

### W3. Add **Carnell Tate** (WR, Ten), drop **Wan'Dale Robinson**.

| TEN targets | wk1 | wk2 | wk3 | wk4 | opp/g | snap % 1→4 |
|---|---|---|---|---|---|---|
| **Tate** | 6 | 5 | 9 | **12** | 8.00 | — |
| Robinson (dropped) | 6 | 1 | 11 | 6 | 6.00 | 82/53/63/**67** |

Four straight weeks rising — a multi-player-week signal, not a spike. Same offense, so
holding both double-bets one target pool; Tate's rise comes out of Robinson's share.
Robinson's 6.00 opp/g is one wk3 outlier.

**Bye-neutral.** Both TEN, bye 9. wk10 and wk11 WR counts unchanged at 3 bodies.

**Kill condition:** Tate under **6 targets in each of two consecutive weeks** → he is the
drop for the next claim.

### W-HOLD. **Butker is not droppable.** Butker bye 5, Bates bye 6 — complementary.
Dropping him recreates the Week 1 zero-kicker failure (#24). Recorded because the advice
has been wrong on this twice before.

---

## 2. Lineup. Nine slots. Settled except FLEX and DST, both waiver-dependent.

Script multipliers from the CLAUDE.md game-script table, applied to our own ppg base.
**K and DST excluded from every total below — `score_team_week()` does not exist.**
Skill slots only, 7 of 9. Not comparable to Yahoo's number.

| slot | start | basis |
|---|---|---|
| QB | **Stafford** | forced, Mahomes on KC bye. LA −3.0 → QB fav 3-7 **1.028x** |
| RB1 | **Henry** | 3.5-point **dog** → RB dog **0.945x**, 21.82 → **20.62**. Worst script of any RB on either roster |
| RB2 | **Javonte** | DAL −8.5, own implied 28.00, RB fav 3-7 **1.078x** |
| WR1 | **Adams** | 15.50 |
| WR2 | **Boston** | 12.22 |
| TE | **Ferguson** | 1-deep. See §4 |
| FLEX | **pending Wed** | Tate 9.81 / Gordon 9.80 / Odunze 8.62 (Yahoo wk5). Decided by W2/W3 |
| K | **Bates** | Butker on KC bye |
| DST | **pending Wed** | Bengals if W1 lands, else Ravens (opp implied 23.50) |

### D-SPREAD. **Stafford sits 0.0 off a multiplier cliff. Flagged, not resolved.**

LA moved −2.5 → −3.0. **QB fav 0-3 = 0.939x; QB fav 3-7 = 1.028x** — a 9.5% jump on a
half-point. Stafford went 15.88 → 17.38 with nothing real changing. If the line moves back
inside 3, his number falls ~9.5%. **Do not quote his adjusted number to two decimals.**

Cliff edges: **QB at 3 and 10. RB at 0, 3, 10, 13. WR has none — flat across every
bucket.**

### D-WR-SCRIPT. **No WR is benched for being on a dog.** Robinson's TEN was a 7.5-point
dog before the drop; WR is flat across all spread buckets. That is a projection question,
never a script question.

---

## 3. Head-to-head. We trail. Re-run on complete lines 10-06.

| | ours | Max's TD Bombers |
|---|---|---|
| QB | Stafford 17.38 | Prescott 21.13 |
| RB1 | Henry **20.62** | Taylor 19.18 |
| RB2 | Javonte 20.03 | Jeanty 15.21 |
| WR1 | Adams 15.50 | D. Smith 13.00 |
| WR2 | Boston 12.22 | Deebo 12.72 |
| TE | Ferguson 7.58 | Likely 10.50 |
| FLEX | pending | Washington 10.78 |
| **total, skill only** | **~100.9–102.1** | **102.52** |

Structural reads: KC bye costs us Mahomes; Chicago targets are contested between Odunze
and Burden III; nothing on their roster is defensible against.

---

## 4. Open hole, not yet acted on: **TE.**

**Ferguson is at 3.75 opp/g — below the ~5 opp/g bar this project sets for even ranking a
wire body.** He is our only TE and Dallas byes in **wk14**.

T.J. Hockenson is available: 6.50 opp/g, trend +4.0, 9.12 ppg, bye 6. Not claimed this
week — his edge leans on a 13-opportunity wk4 spike, **n=1**, which is exactly the leg
that broke D3 and GD1.

**Pre-registered:** if Hockenson clears 8 opportunities again in wk5, claim him wk6 and
drop Sutton or Odunze, whichever has the lower snap share at that point.

---

## 5. Deadlines. Per slot: `min(kickoff of legal replacements)`.

| due | slot | why |
|---|---|---|
| **Wed 10-07** | waivers | claims process. No Wednesday NFL game exists in wk5 |
| **Thu 10-08 20:15** | RB2, TE | TB @ DAL — Javonte + Ferguson. Both auto-start; any reversal dies here |
| **Sun 09:30** | QB, WR1, DST | Stafford and Adams play Mon 20:15, but every legal replacement plays Sunday. PHI @ JAX is the 09:30 London game |
| Sun 13:00 | FLEX, WR2 | CHI @ GB, CLE @ NYJ |
| Sun 16:25 | K | DET @ ARI |
| Sun 20:20 | RB1 | BAL @ ATL — Henry. Latest on roster |

---

## 6. Byes ahead. Two real crises.

| wk | off | consequence |
|---|---|---|
| 6 | Bates | covered **only if Butker kept** |
| 8 | Etienne (IR) | no impact |
| 9 | Tate | WR room to 3 |
| **10** | **Odunze, Sutton** | WR falls to Adams, Boston, Tate — exactly 3 for WR1/WR2/FLEX |
| **11** | **Stafford, Adams, Boston** | Mahomes covers QB. **WR1 and WR2 both out.** Worst week of the season |
| 13 | Henry, Ravens | **DST covered iff W1 landed.** RB to Javonte + Gordon |
| **14** | **Javonte, Ferguson** | **zero TE.** See §4 |

---

## 7. Explicitly NOT being learned this week

- Whether the DST streaming method works. n too small; bar deliberately loose.
- Anything about Gordon from one week of Achane being out.
- Any model fit. **n = 5. Fit nothing.** These logs are honest test cases, not a
  training set.

---

## Retro

*Append after Monday 10-13. Never edit above this line.*
