#!/usr/bin/env python3
"""League-wide retro harness. Rerunnable.

Reconstructs all 10 rosters from the `Roster Status` column of the six
*_actual_* position exports, joins Wednesday projections, and scores three
things the single-roster retro cannot:

  1. regret per roster, conditioned on following the Yahoo projection
  2. Yahoo projection error by position (n ~ 150, not 15)
  3. the S1/S2 question at scale -- within-roster RB/WR/TE pairs, does the
     higher Yahoo projection actually outscore the lower one, by gap band

Usage:  python3 dev/weekly/leaguewide_retro.py 6 2026-10-14 2026-10-20
Pooled: python3 dev/weekly/leaguewide_retro.py --pool 4:2026-10-01:2026-10-05 \
            5:2026-10-07:2026-10-13 6:2026-10-14:2026-10-20 7:2026-10-21:<wk7 actual date>
        Pair bands only, pooled across weeks, plus the wk6 §R4 pre-registered
        verdict. Pre-registration: pool wks 4-7, read at week 8 -- not before.

Traps handled (see CLAUDE.md):
  - headers carry invisible private-use-area chars -> "Fantasy Fan Pts"
  - DEF export has no `Player ID` column -> keyed on Team
  - an export is a snapshot, not a roster. The *_actual_* exports reconstruct
    all ten MONDAY rosters cleanly, but CANNOT show a player added and dropped
    inside the same week -- streaming is invisible in arrears. Week 6: the
    opponent scored 111.14, unreachable from their Monday 15.
  - no started/bench flag exists -> other teams' real lineups are NOT
    recoverable. Column `they got` below is a projection-following
    counterfactual, not what they started.
"""
import csv, sys, json, math, itertools, statistics as st

POS = ["qb", "rb", "wr", "te", "k", "def"]

pua = lambda s: "".join(c for c in s if not (0xE000 <= ord(c) <= 0xF8FF)).strip()


def num(v):
    v = (v or "").strip()
    if v in ("", "-", "--"):
        return None
    try:
        return float(v)
    except ValueError:
        return None


def load(path):
    r = csv.reader(open(path, encoding="utf-8"))
    h = [pua(c) for c in next(r)]
    return [dict(zip(h, row)) for row in r if row and row[0].strip()]


def load_week(week, proj_date, act_date):
    """Players keyed by Yahoo id (DEF by team), and rosters by owner."""
    D = f"docs/uploads/week_{week}_data"
    rows = {}
    for p in POS:
        act = load(f"{D}/yahoo_week{week}_{p}_actual_{act_date}.csv")
        prj = {}
        for d in load(f"{D}/yahoo_week{week}_{p}_{proj_date}.csv"):
            prj[d.get("Player ID") or "DEF:" + d["Team"]] = d
        for d in act:
            k = d.get("Player ID") or "DEF:" + d["Team"]
            pr = prj.get(k, {})
            a, q = num(d.get("Fantasy Fan Pts")), num(pr.get("Fantasy Fan Pts"))
            rows[k] = dict(
                pos=p.upper(), name=d["Player"], team=d["Team"],
                owner=d.get("Roster Status", "").strip(),
                played=a is not None, A=a or 0.0, P=q or 0.0,
                tgt=num(d.get("Receiving Tgt*")),
            )
    by = {}
    for x in rows.values():
        o = x["owner"]
        if o and not o.startswith("W (") and o not in ("FA", "W"):
            by.setdefault(o, []).append(x)
    return rows, by


def best(r, f):
    """Max total over legal lineups: QB/RB/RB/WR/WR/TE/FLEX/K/DEF."""
    g = lambda P: sorted([p for p in r if p["pos"] == P], key=lambda p: -p[f])
    qb, k, d, rb, wr, te = (g(x) for x in ("QB", "K", "DEF", "RB", "WR", "TE"))
    if not (qb and k and d and te) or len(rb) < 2 or len(wr) < 2:
        return None, None
    bv, bl = -1, None
    for nr, nw, nt in itertools.product((2, 3), (2, 3), (1, 2)):
        if nr + nw + nt != 6 or len(rb) < nr or len(wr) < nw or len(te) < nt:
            continue
        sel = qb[:1] + k[:1] + d[:1] + rb[:nr] + wr[:nw] + te[:nt]
        v = sum(p[f] for p in sel)
        if v > bv:
            bv, bl = v, sel
    return bv, bl


def pairs_of(by):
    """Within-roster RB/WR/TE pairs: (relative proj gap, higher-proj right, pts diff)."""
    pairs = []
    for t, r in by.items():
        f = [x for x in r if x["pos"] in ("RB", "WR", "TE") and x["played"]]
        for a, b in itertools.combinations(f, 2):
            hi, lo = (a, b) if a["P"] > b["P"] else (b, a)
            if hi["P"] == lo["P"]:
                continue
            pairs.append(((hi["P"] - lo["P"]) / max(hi["P"], 0.01),
                          hi["A"] > lo["A"], hi["A"] - lo["A"]))
    return pairs


def band(v, lab):
    d = [x for x in v if x[2] != 0]
    if not d:
        return 0, 0
    n = len(d)
    w = sum(1 for x in d if x[1])
    p = w / n
    se = math.sqrt(p * (1 - p) / n)
    print(f"{lab:28s} pairs {len(v):5d}  decided {n:5d}  right {w:4d} ({100*p:5.1f}%)"
          f"  CI [{100*(p-1.96*se):.1f}, {100*(p+1.96*se):.1f}]"
          f"  pts {st.mean(x[2] for x in d):+6.2f}")
    return n, w


def bands(pairs):
    band(pairs, "ALL")
    band([x for x in pairs if x[0] <= 0.05], "gap <= 5%  (dead band)")
    mid = band([x for x in pairs if 0.05 < x[0] <= 0.15], "gap 5-15%  (S2 band)")
    band([x for x in pairs if x[0] > 0.15], "gap > 15%   (S1 band)")
    return mid


if len(sys.argv) > 1 and sys.argv[1] == "--pool":
    spec = [a.split(":") for a in sys.argv[2:]]
    allp = []
    print(f"== R4 pooled: within-roster RB/WR/TE pairs, weeks {','.join(s[0] for s in spec)} ==")
    for w, pd, ad in spec:
        _, by = load_week(w, pd, ad)
        p = pairs_of(by)
        allp += p
        print(f"week {w}: {len(by)} rosters, {len(p)} pairs, "
              f"{sum(1 for x in p if 0.05 < x[0] <= 0.15)} in the 5-15% band")
    n, w = bands(allp)
    print("\nPRE-REGISTERED (2026_week06_decisions.md §R4): 5-15% band under 55% at n >= 200 "
          "decided -> dead band widens 5% -> 15%.")
    if n < 200:
        print(f"VERDICT: UNDERPOWERED, n = {n} < 200. Keep pooling; no change.")
    elif w / n < 0.55:
        print(f"VERDICT: WIDEN. {100*w/n:.1f}% at n = {n}. Dead band 5% -> 15%; "
              "pairs under a 15% gap stop being decisions.")
    else:
        print(f"VERDICT: HOLD. {100*w/n:.1f}% at n = {n} clears 55%. Dead band stays 5%.")
    sys.exit(0)

WEEK = sys.argv[1] if len(sys.argv) > 1 else "6"
PROJ_DATE = sys.argv[2] if len(sys.argv) > 2 else "2026-10-14"
ACT_DATE = sys.argv[3] if len(sys.argv) > 3 else "2026-10-20"
rows, by = load_week(WEEK, PROJ_DATE, ACT_DATE)

print(f"== week {WEEK}: regret per roster, conditioned on following the projection ==")
print("NOTE: `if-followed` is a COUNTERFACTUAL, not what they started. Week 6 showed\n      one team beating it by +27.24 via an add-and-drop stream. Do not rank by it.")
print(f"{'team':26s} {'projopt':>8s} {'if-followed':>12s} {'hindopt':>8s} {'regret':>7s}")
reg = []
for t, r in sorted(by.items()):
    pv, pl = best(r, "P")
    hv, _ = best(r, "A")
    if pl is None or hv is None:
        print(f"{t[:26]:26s}  NO LEGAL LINEUP")
        continue
    pa = sum(p["A"] for p in pl)
    reg.append(hv - pa)
    print(f"{t[:26]:26s} {pv:8.2f} {pa:12.2f} {hv:8.2f} {hv - pa:7.2f}")
print(f"\nmean {st.mean(reg):.2f}  median {st.median(reg):.2f}  "
      f"min {min(reg):.2f}  max {max(reg):.2f}  n={len(reg)}")

print(f"\n== Yahoo projection error, rostered players with a game ==")
pool = [x for x in rows.values() if x["owner"] in by and x["played"]]
print(f"{'pos':6s} {'n':>4s} {'MAE':>6s} {'bias':>7s}")
for P in POS:
    v = [x for x in pool if x["pos"] == P.upper()]
    if v:
        print(f"{P.upper():6s} {len(v):4d} "
              f"{st.mean(abs(x['A'] - x['P']) for x in v):6.2f} "
              f"{st.mean(x['A'] - x['P'] for x in v):+7.2f}")
print(f"{'ALL':6s} {len(pool):4d} {st.mean(abs(x['A'] - x['P']) for x in pool):6.2f} "
      f"{st.mean(x['A'] - x['P'] for x in pool):+7.2f}")

print(f"\n== S1/S2 at scale: within-roster RB/WR/TE pairs, higher proj vs lower ==")
bands(pairs_of(by))
