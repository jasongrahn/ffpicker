# Wins accounting, wks 1-8: margin, own-roster hindsight max, flippable by one swap?, all-play.
# Inputs: data/weekly/2026_league_schedule.csv (Yahoo finals wks 1-7), README regret table
# (hindsight optimum per week), wk8 numbers from handoff #50 (nflreadr calc; Yahoo confirms Tue).
import csv, collections
REPO = "/Users/jasongrahn/R-projects/ffootballer"
ME = "JGrahnasaurs"
rows = [r for r in csv.DictReader(open(f"{REPO}/data/weekly/2026_league_schedule.csv", encoding="utf-8")) if r["pf"]]
by_wk = collections.defaultdict(dict)
for r in rows: by_wk[int(r["week"])][r["team"]] = float(r["pf"])
# hindsight-optimal own-roster lineup per week (README + logs); wk8 = Mahomes for Kyler (+4.54) only known swap
hind = {1: 121.56, 2: 155.08, 3: 133.80, 4: 120.10, 5: 130.32, 6: 95.08, 7: 104.00}
best_swap = {1: ("Mahomes 22.66 for Stafford 5.10", 17.56, "proj Stafford 18.06 v Mahomes 16.39 = +1.67 (9%, inside 15% band)"),
             4: ("Bates 18.00 for Butker 6.00", 12.00, "K: hold rule; K test null n 214"),
             6: ("Mahomes 11.48 / Browns 9.00 / Odunze 5.40 for Stafford/Boston", 3.40, "regret 3.40 total"),
             8: ("Mahomes 25.44 for Kyler 20.90", 4.54, "proj Kyler 17.93 v Stafford 17.89 v Mahomes 16.32")}
print("wk  us      opp     margin  hind-max  hind-margin  1-swap flips?")
for w in sorted(by_wk):
    us = by_wk[w][ME]
    opp_t = [r["opponent"] for r in rows if int(r["week"]) == w and r["team"] == ME][0]
    opp = by_wk[w][opp_t]; m = us - opp
    hm = hind[w] - opp
    sw = best_swap.get(w)
    flip = "n/a (won)" if m > 0 else (f"YES ({sw[0]}, +{sw[1]:.2f})" if sw and sw[1] > -m else "NO")
    print(f"{w}   {us:6.2f}  {opp:6.2f}  {m:+7.2f}  {hind[w]:7.2f}   {hm:+7.2f}      {flip}")
print("8   87.50   ~113-133  -25.5..-45.5  ~92.04+Odunze(MNF)  <0 unless Odunze>25.5   NO")
# all-play wks 1-7
ap_w = ap_l = 0; pf_rank = []
for w in sorted(by_wk):
    sc = by_wk[w]; us = sc[ME]
    ap_w += sum(us > v for t, v in sc.items() if t != ME); ap_l += sum(us < v for t, v in sc.items() if t != ME)
    pf_rank.append(1 + sum(v > us for t, v in sc.items() if t != ME))
print(f"\nall-play wks 1-7: {ap_w}-{ap_l} ({ap_w/(ap_w+ap_l):.3f}); actual 4-3 (0.571)")
print("weekly PF rank (1 = best of 10):", pf_rank)
# PF/PA season wks 1-7
pf = collections.Counter(); pa = collections.Counter()
for r in rows: pf[r["team"]] += float(r["pf"]); pa[r["team"]] += float(r["pa"])
rk_pf = sorted(pf, key=lambda t: -pf[t]).index(ME) + 1
rk_pa = sorted(pa, key=lambda t: -pa[t]).index(ME) + 1
print(f"PF {pf[ME]:.2f} rank {rk_pf}/10; PA {pa[ME]:.2f} rank {rk_pa}/10 (1 = most against)")
# expected wins from all-play pct over 7 games
print(f"all-play-implied wins over 7: {7*ap_w/(ap_w+ap_l):.2f} vs actual 4 -> luck {4 - 7*ap_w/(ap_w+ap_l):+.2f} W")
