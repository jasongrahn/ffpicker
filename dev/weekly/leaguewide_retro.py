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

Traps handled (see CLAUDE.md):
  - headers carry invisible private-use-area chars -> "Fantasy Fan Pts"
  - DEF export has no `Player ID` column -> keyed on Team
  - an export is a snapshot, not a roster, but the *_actual_* exports are
    post-game and do reconstruct all ten cleanly
  - no started/bench flag exists -> other teams' real lineups are NOT
    recoverable. Column `they got` below is a projection-following
    counterfactual, not what they started.
"""
import csv, sys, json, math, itertools, statistics as st

WEEK = sys.argv[1] if len(sys.argv) > 1 else "6"
PROJ_DATE = sys.argv[2] if len(sys.argv) > 2 else "2026-10-14"
ACT_DATE = sys.argv[3] if len(sys.argv) > 3 else "2026-10-20"
D = f"docs/uploads/week_{WEEK}_data"
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


rows = {}
for p in POS:
    act = load(f"{D}/yahoo_week{WEEK}_{p}_actual_{ACT_DATE}.csv")
    prj = {}
    for d in load(f"{D}/yahoo_week{WEEK}_{p}_{PROJ_DATE}.csv"):
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


print(f"== week {WEEK}: regret per roster, conditioned on following the projection ==")
print(f"{'team':26s} {'projopt':>8s} {'they got':>9s} {'hindopt':>8s} {'regret':>7s}")
reg = []
for t, r in sorted(by.items()):
    pv, pl = best(r, "P")
    hv, _ = best(r, "A")
    if pl is None or hv is None:
        print(f"{t[:26]:26s}  NO LEGAL LINEUP")
        continue
    pa = sum(p["A"] for p in pl)
    reg.append(hv - pa)
    print(f"{t[:26]:26s} {pv:8.2f} {pa:9.2f} {hv:8.2f} {hv - pa:7.2f}")
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
pairs = []
for t, r in by.items():
    f = [x for x in r if x["pos"] in ("RB", "WR", "TE") and x["played"]]
    for a, b in itertools.combinations(f, 2):
        hi, lo = (a, b) if a["P"] > b["P"] else (b, a)
        if hi["P"] == lo["P"]:
            continue
        pairs.append(((hi["P"] - lo["P"]) / max(hi["P"], 0.01),
                      hi["A"] > lo["A"], hi["A"] - lo["A"]))


def band(v, lab):
    d = [x for x in v if x[2] != 0]
    if not d:
        return
    n = len(d)
    w = sum(1 for x in d if x[1])
    p = w / n
    se = math.sqrt(p * (1 - p) / n)
    print(f"{lab:28s} pairs {len(v):5d}  decided {n:5d}  right {w:4d} ({100*p:5.1f}%)"
          f"  CI [{100*(p-1.96*se):.1f}, {100*(p+1.96*se):.1f}]"
          f"  pts {st.mean(x[2] for x in d):+6.2f}")


band(pairs, "ALL")
band([x for x in pairs if x[0] <= 0.05], "gap <= 5%  (dead band)")
band([x for x in pairs if 0.05 < x[0] <= 0.15], "gap 5-15%  (S2 band)")
band([x for x in pairs if x[0] > 0.15], "gap > 15%   (S1 band)")
