# Handoff #35 — Week 4 closed and pushed. Week 5 opens on a Wednesday waiver.

Date: 2026-10-05 **Monday**. Branch `week3-gameday`, clean, **PUSHED**.
Head `e65ce27`. PR not opened.

Prior: #34 `ffdraft-handoff-20261004-27-WEEK4-GAMEDAY.md`.
Methodology authority still #33 (§1 `Rankings Actual`). Neither superseded.

---

## 0. The one thing. Waiver claim due Tue night, processes Wed 2026-10-07.

**Top priority is DST, and the window is Wednesday, not Sunday.**

Ravens DST has **no Week 5 game script** — BAL @ ATL has no published line (§2).
The three best replacements by method are all **on waivers clearing Oct 7**:

| DST | wk5 opp implied | status, as of 10-05 export |
|---|---|---|
| **Texans** (@ Ten) | **16.25** — best on board | **ROSTERED** (Sunday Kevin). Not available. |
| **Bengals** (@ Mia) | 17.75 | **`W (Oct 7)`** |
| **Jaguars** (vs Phi) | 18.00 | **`W (Oct 7)`** |
| **Jets** (vs Cle) | 18.50 | **`W (Oct 7)`** |
| Cowboys (vs TB) | 19.00 | **`W (Oct 7)`** |
| Broncos (@ LAC) | 19.50 | ROSTERED (Jason's Jazzy Team) |
| **Ravens** (@ Atl) | **NO LINE** | ours |

Source: `docs/uploads/week_4_data/yahoo_week4_def_actual_2026-10-05.csv`, col 5.
`W (Oct 7)` = on waivers, clears Wednesday. `FA` = addable now — only **Saints**
and **Falcons** are FA, and both are in the two games with no lines, so neither
can be scripted. **Falcons also host Henry** -> self-conflict, do not.

**Roster is full at 15.** Etienne sits in IR, which does not count (D10). So a DST
add needs a drop. Ranked:

| drop | ppg wks1-4 | why |
|---|---|---|
| **Sutton** (WR Den) | **3.28** | Worst on roster by 2.5x. Bye wk10 collides with Odunze + Raymond. **Drop this one.** |
| Raymond (WR Chi) | 9.62 | D6a killed him for FLEX permanently. ppg is backward-looking. #2 if two drops needed. |
| Marks (RB Hou) | 6.82 | **KEEP.** Only RB depth behind Henry/Javonte. |

**Second-order win: carrying two DSTs also closes the wk13 zero-DEF hole**
(#34 §4, flagged and never logged — Ravens bye is wk13). One claim, two problems.

**Open question, needs the Yahoo page:** waiver priority / FAAB balance. Not in any
export. Check before committing to a claim on all three.

---

## 1. Week 4 closed. L 93.00-98.58. Record 2-2. Regret 27.10, worst of four.

Filed, committed, pushed. Numbers live in `data/weekly/2026_week04_decisions.md`
under `## Retro`. **Do not restate them, read them.** Two commits:

- `b100c04` retro + both lineup csvs + README regret row
- `e65ce27` 28 raw Yahoo exports (10-04 projections, 10-05 actuals)

Headlines only, so a reader knows whether to open it:

- **Best legal 120.10** would have won by 21.52. Three swaps: Bates +12.00,
  Robinson +7.90, Odunze +7.20.
- **D6a KILLED on both pre-registered legs.** Odunze 12.40 / 7 tgt vs Raymond
  1.60 / 2 tgt. Burden III took 6 targets — the exact player named at D6a:311.
  **Raymond is out of FLEX permanently.** Start Odunze.
- **D3: method right, HOLD BAR failed.** Literal bar did not fire (+2.00, under
  3) so the kicker rule is not retired. But K projections cluster inside ~1 pt
  while actuals ran 0-19 -> a >3-projected-point bar is **unsatisfiable by
  construction**. Suppressed a correct call twice (wk3 McLaughlin +6.00, wk4
  Bates +12.00). **K bar is now denominated in own implied total.**
- **GD1 fired, table NOT retired** — bar was one player-week per leg, same
  underpowered shape as D3. Transferable: **stop writing kill conditions on
  single player-weeks.**
- Sutton vs Raymond was right by 0.70 and **was never the expensive
  comparison. D6a was.**

**Still open on wk4:** Etienne's `actual` (MNF ATL @ NO tonight; he is IR,
scores 0 for us). Everything else is filled.

---

## 2. Week 5 data state. 13 of 15 lines. Correct a stale claim.

**`load_schedules()` has lines for 13 of 15 Week 5 games, not 15.** An earlier
claim of "15 of 15" came from a **pre-`clear_cache()`** pull and is withdrawn.

**No line: MIN @ NO, and BAL @ ATL.**

Consequence, stated so it is not re-derived: **Henry and Ravens DST have no Week 5
game script.** Any figure of the shape "Henry @ ATL fav 2.5, own implied 23.50,
1.036x" or "Ravens opp implied 21.00" is **withdrawn** — those were cached. #34 §3's
"Ravens degrade 15.50 -> 21.75" is likewise **not currently in the data**.

**Re-pull Wednesday.** Both lines should post, and they settle Henry's multiplier
and the Ravens-vs-claim DST call in one shot.

### Sign convention. Validated. Do not re-derive.

`spread_line` **POSITIVE = HOME team favored.**

```r
home: own = total_line/2 + spread_line/2   opp = total_line/2 - spread_line/2
away: own = total_line/2 - spread_line/2   opp = total_line/2 + spread_line/2
```

Two traps paid for in the last session, both now in `scratchpad/h2h5b.R`:

1. Got it **inverted first**, which produced TEN favored 11.5 at BAL and had
   already been told to the user twice as "CHI dog 3.5" / "DEN favored 3". Truth:
   **CHI favored 3.5, DEN a 3-point dog.** Caught by contradiction with #34's
   known-good BAL 27.0 / 15.5.
2. Do **not** compute `fav = -spread_line` and then `own = tot/2 - fav/2` in the
   same `transmute`. dplyr lets later expressions see earlier ones -> resolves to
   the HOME implied. Use raw `spread_line` in every formula.

Assert it: `all(abs((own + opp) - total) < 1e-9)`, plus two known-goods.

---

## 3. Week 5 slate, chronological. Deadlines are not kickoffs.

| when | game | spread | total | holds |
|---|---|---|---|---|
| **Thu 10-08 20:15** | TB @ **DAL** | DAL -9.5 | 47.5 | **our Javonte + Ferguson**, their Prescott |
| Sun 09:30 (London) | PHI @ JAX | PHI -6.5 | 42.5 | their Hurts + D. Smith; JAX DST claim target |
| Sun 13:00 | CHI @ GB | CHI -3.0 | 45.5 | our Odunze + Raymond, their Burden III + Kraft |
| Sun 13:00 | CLE @ NYJ | CLE -2.5 | 39.5 | our Boston; NYJ DST claim target |
| Sun 13:00 | HOU @ TEN | HOU -7.0 | 39.5 | our Marks + Robinson |
| Sun 13:00 | **MIN @ NO** | **—** | **—** | **no line** |
| Sun 16:25 | DET @ ARI | ARI -4.5 | 54.5 | **our Bates** (Det own **29.50, #1 of 30**) |
| Sun 20:20 | **BAL @ ATL** | **—** | **—** | **our Henry + Ravens. No line.** |
| Mon 10-12 20:15 | BUF @ **LA** | LA -2.5 | 54.5 | **our Stafford + Adams** |

**Deadline rule, per slot: `min(kickoff of legal replacements)`, not the starter's
own kickoff.** Three places that bites in Week 5:

- **RB2 / TE are Thursday calls.** Javonte and Ferguson play Thu 20:15. Nothing
  to decide — both start — but any reversal is dead after Thursday.
- **DST is a Sunday 09:30 call if the claim lands on Jaguars** (London). 13:00
  otherwise. **Not** Ravens' 20:20 kickoff.
- **QB and WR1 look like Monday calls and are not.** Stafford and Adams play Mon
  20:15, but every legal replacement plays Sunday -> **the call is due Sun 09:30**.

**No Wednesday NFL game exists in Week 5.** The Wednesday urgency in §0 is the
**waiver run**, not a kickoff.

---

## 4. Week 5 structural calls. Mostly already settled.

| slot | call | basis |
|---|---|---|
| QB | **Stafford** forced | Mahomes on **KC bye** |
| RB1/RB2 | **Henry + Javonte** | Javonte DAL -9.5, own 28.50 -> RB fav 3-7 **1.078x**. Henry unscriptable. |
| WR1/WR2 | **Adams + Boston** | 15.50 / 12.22 ppg |
| TE | **Ferguson** | 1-deep all season |
| FLEX | **Odunze** | **D6a**, on usage. Not ppg — Raymond still leads ppg 9.62 to 7.58 and that is backward-looking. |
| K | **Bates** forced | Butker on **KC bye**. Det own implied **29.50, highest of all 30 teams with lines.** |
| DST | **§0 claim, else Ravens** | Ravens have no line |

### CORRECTION: Butker is NOT droppable. I said he was. Wrong.

**Butker bye = wk5. Bates bye = wk6. The byes are complementary.** Holding both
covers both weeks; dropping Butker creates a **zero-kicker Week 6** — the exact
failure that cost Week 1 (#24). Keep both. The §0 drop is **Sutton**.

This is the `need before candidates` rule catching a live miss. Bye table first,
then the drop list — in that order, every time.

---

## 5. Week 5 head-to-head. Max's TD Bombers, 1st in league. Dead heat.

Script-adjusted, **skill slots only, 7 of 9** — `score_team_week()` still does not
exist, so **K and DST are out on both sides and this is NOT comparable to Yahoo's
number.** Say that every time it is quoted.

| | ours | theirs |
|---|---|---|
| QB | Stafford 15.88 | Prescott **21.13** |
| RB1 | Henry 21.82 *(unadjusted, no line)* | Taylor 19.18 |
| RB2 | Javonte 20.03 | Jeanty 15.21 |
| WR1 | Adams 15.50 | D. Smith 13.00 |
| WR2 | Boston 12.22 | Deebo 12.72 |
| TE | Ferguson 7.58 | Likely 10.50 |
| FLEX | Raymond 9.62 *(use Odunze, §4)* | Washington 10.78 |
| **best skill-7** | **102.65** | **102.52** |

**0.13 apart.** Their roster: Prescott, Hurts / Walker III, Taylor, Jeanty, Harvey /
Deebo, Burden III, Washington, D. Smith / Kraft, Likely / Fairbairn / Giants,
Steelers. Exact team string uses a **curly apostrophe**: `Max’s TD Bombers`.

### The KC bye is the entire matchup.

Carolina and **Kansas City** are on bye. KC hits both rosters:

- **Us:** Mahomes 21.40 ppg -> Stafford 15.88. Cost **~5.5**.
- **Them:** **Kenneth Walker III — 26.02 ppg, their best player by 5.7 — out.**
  Taylor and Jeanty were already RB1/RB2, so the loss lands on FLEX: Washington
  10.78 instead of Walker. Cost **~15.2**.

**Net +9.7 to us from a bye week.** With Walker they project **~117.8** and this is
a 15-point loss. A dead heat against the 1-seed is a schedule gift, not form.

### Three structural angles

1. **Dallas is load-bearing for both of us.** DAL -9.5, own implied 28.50, second
   only to Detroit. Our Javonte + Ferguson, their Prescott. A Dallas blowout pays
   both sides — it **damps the margin** rather than deciding it. Correlation
   arriving free, not paid for (`CLAUDE.md`).
2. **Their roster fights itself: Taylor (IND @ PIT) vs their own Steelers DEF
   (PIT vs IND).** Cannot profit from both. Steelers opp implied 21.00 is
   mediocre regardless, so expect Taylor started and a weak DST behind him.
3. **Chicago targets contested: their Burden III vs our Odunze + Raymond,** CHI
   @ GB. Burden took 6 targets in wk4 — the D6a player. Zero-sum at the margin.

**Nothing to defend against.** Worst spot is Robinson (TEN, 7-pt dog, own implied
16.25) and **WR is flat across every spread bucket** — that is a projection
problem, not a script problem. Do not bench a WR for being on a dog.

---

## 6. Byes, full horizon. Three real holes, all now visible.

| wk | off | consequence |
|---|---|---|
| **5** | Mahomes, Butker | covered — Stafford, Bates |
| **6** | Bates | **covered ONLY if Butker is kept.** See §4. |
| 7 | Etienne | IR, no impact |
| 8 | Marks | RB3 gone, no FLEX RB |
| 9 | Robinson | fine |
| **10** | **Odunze, Raymond, Sutton** | **three WRs at once.** Adams + Boston = exactly 2. **Zero WR FLEX.** Dropping Sutton for a DST (§0) does not worsen this — he was the 3rd of 3 gone anyway. |
| **11** | **Stafford, Adams, Boston** | Mahomes back covers QB. **WR1 AND WR2 both out.** Worst week on the board. |
| 13 | Henry, **Ravens** | **zero DEF** unless §0 lands. Previously unlogged. |
| 14 | Javonte, **Ferguson** | **zero TE.** Ferguson 1-deep all season. |

**Weeks 10 and 11 are a WR problem that needs solving before week 9**, not in
week 10. Not actionable today — do not let it displace §0.

---

## 7. Traps. Carry forward, do not re-pay.

- **`score_team_week()` does not exist.** DST unscoreable by our code. Every
  comparison is skill-only, 7 of 9. Say so.
- **`renv` out of sync** -> `devtools::load_all()` fails. `source("R/00_config.R")`
  and `source("R/30_scoring.R")` directly. **`R/10_config.R` does not exist** —
  `load_config()` is in `00`.
- **`load_player_stats(2026)` has `team`, not `recent_team`.** Wrap in `any_of()`.
- **Name trap, both sides.** Our `J. Williams` = **Javonte** (Dal, RB). Theirs =
  **Jameson** (Det, WR). Do not collapse.
- **Apostrophes break inline `Rscript -e`** (`Wan'Dale`, `Max’s`). Scratchpad
  `.R` file, always.
- **nflreadr NA is inactivity, not a name miss — prove which.** Achane returned
  NA wk4; verified present wks1-3 under the same display name, absent wk4, no
  injury row, MIA ran Wright/Gordon. Recorded 0.00. **Diff the prior weeks before
  blaming the join.**
- **K method tests must dedupe to one kicker per team.** Backup kickers at 0.00
  (Buf carried Bass + Trujillo + Prater) inflated 30 teams to 51 rows and held
  Spearman at 0.16. `group_by(tm) |> slice_max(pts, n=1, with_ties=FALSE)` ->
  0.300.
- **DEF export has its own column layout.** No `Player ID` -> Roster Status is
  **col 5**, pts **col 8**. Skill positions are col 7 / col 10.
- **`Fantasy Fan Pts` header carries an invisible private-use glyph.** `cat -v`
  reveals it. Do not match that header literally.
- **`Rankings Actual` is a projection restated as a rank.** #33 §1. Never cite as
  performance evidence.

---

## 8. Do next, in order.

1. **Check Yahoo for waiver priority / FAAB.** Not in any export. 2 min.
2. **Claim a DST, drop Sutton. Due Tue night, processes Wed 10-07.** Preference
   order Bengals (17.75) / Jaguars (18.00) / Jets (18.50) — re-rank after the
   Wednesday re-pull, since **BAL @ ATL posting a line could keep the Ravens.**
3. **Wednesday: `clear_cache()` + `load_schedules(2026)`.** Settles Henry's
   multiplier and the DST call. Re-run `scratchpad/h2h5b.R`.
4. **Open `2026_week05_decisions.md`.** Log §4's forced calls, the §0 move, and
   kill conditions — **written on target/usage counts across multiple
   player-weeks, not one player-week.** That is the §1 lesson.
5. **Thursday 20:15 is the first real deadline** (TB @ DAL, Javonte + Ferguson).

Fill Etienne's wk4 `actual` after tonight's MNF. He is IR, scores 0.

Later-scoring, do not touch yet: **D1** (Etienne misses wks 5-6), **D9** (Boston
vs Sutton wks 4-8 — 10.90 vs 0.90 after 1 of 5), **D11**, **§3a**, **GD1**.

---

## 9. Standing

**n = 4. Fit nothing.** The decision logs are accumulating honest test cases, not
a training set. Week 4's lesson was about **bar design** (unsatisfiable thresholds,
single-player-week legs), not about any player.

Separate **"decision wrong"** from **"outcome bad"** at every retro. Week 1 and
Week 3 both proved they diverge, and Week 4's Sutton/Raymond call was right while
the week was lost.
