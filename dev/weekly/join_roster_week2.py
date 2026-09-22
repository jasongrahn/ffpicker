#!/usr/bin/env python3
"""Join Week 2 Yahoo pastes onto the 15-man roster.

Yahoo projections are hand-entered from the matchup page (screenshot); the
pasted player tables carry Week 1 actuals, not projections. See the upload
README for why.
"""
import csv
from pathlib import Path

SRC = Path(__file__).resolve().parents[2] / "docs/uploads/week_2_data"

# player, pos, team, yahoo Wk2 proj, current slot
ROSTER = [
    ("Patrick Mahomes",    "QB", "KC",  18.50, "QB"),
    ("Matthew Stafford",   "QB", "LAR", 18.22, "BN"),
    ("Javonte Williams",   "RB", "Dal", 15.75, "RB"),
    ("Derrick Henry",      "RB", "Bal", 15.58, "RB"),
    ("Travis Etienne Jr.", "RB", "NO",   9.41, "W/R/T"),
    ("Kenny Gainwell",     "RB", "TB",   8.01, "BN"),
    ("Woody Marks",        "RB", "Hou",  7.44, "BN"),
    ("Davante Adams",      "WR", "LAR", 10.02, "WR"),
    ("Courtland Sutton",   "WR", "Den",  8.98, "WR"),
    ("Rome Odunze",        "WR", "Chi",  8.64, "BN"),
    ("Wan'Dale Robinson",  "WR", "Ten",  6.96, "BN"),
    ("Kalif Raymond",      "WR", "Chi",  3.47, "BN"),
    ("Jake Ferguson",      "TE", "Dal",  8.11, "TE"),
    ("Chase McLaughlin",   "K",  "TB",   7.69, "K"),
    ("Patriots",           "DEF","NE",   6.86, "DEF"),
]


def index(fname):
    p = SRC / fname
    return {r["player"]: r for r in csv.DictReader(open(p))} if p.exists() else {}


def main():
    players = index("week_2_players.csv")
    calls = index("week_2_game_day_calls.csv")
    inj = index("week_2_injury_report.csv")

    rows = []
    for name, pos, team, proj, slot in ROSTER:
        p = players.get(name, {})
        c = calls.get(name, {})
        i = inj.get(name, {})
        rows.append({
            "player": name, "pos": pos, "nfl_team": team,
            "slot": slot, "proj": proj,
            "opponent": p.get("opponent") or c.get("opponent", ""),
            "home_away": p.get("home_away") or c.get("home_away", ""),
            "kickoff": p.get("kickoff") or c.get("kickoff", ""),
            "status": p.get("status") or c.get("status") or i.get("status", ""),
            "injury": c.get("injury", "") or i.get("injury_type", ""),
            "injury_updated": c.get("updated", ""),
            "wk1_pts": p.get("fan_pts", ""),
            "wk1_tgt": p.get("tgt", ""), "wk1_rec": p.get("rec", ""),
            "wk1_rec_yds": p.get("rec_yds", ""),
            "wk1_rush_att": p.get("rush_att", ""),
            "pct_rostered": p.get("pct_rostered", ""),
            "in_players": bool(p), "in_calls": bool(c), "in_injury": bool(i),
        })

    out = SRC / "week_2_roster_joined.csv"
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"-> {out.name}  {len(rows)} rows")

    hit = sum(r["in_players"] for r in rows)
    print(f"matched in players table: {hit}/15")
    for r in rows:
        if not r["in_players"]:
            print(f"  MISS players: {r['player']} ({r['pos']} {r['nfl_team']})")

    print("\nflagged (any status or injury):")
    for r in rows:
        if r["status"] or r["injury"]:
            print(f"  {r['player']:<20} {r['slot']:<6} {r['status'] or '-':<4} "
                  f"{r['injury'] or '-'}  ({r['injury_updated']})")

    print("\nsame-game stacks (handoff #29 §3):")
    games = {}
    for r in rows:
        if r["opponent"]:
            games.setdefault(frozenset([r["nfl_team"], r["opponent"]]), []).append(r)
    for g, mem in games.items():
        if len(mem) > 1:
            tag = " ".join(f"{m['player']}({m['pos']},{m['slot']})" for m in mem)
            print(f"  {'/'.join(sorted(g))}: {tag}")


if __name__ == "__main__":
    main()
