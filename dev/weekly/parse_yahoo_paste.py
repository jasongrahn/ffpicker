#!/usr/bin/env python3
"""Parse copy/pasted Yahoo fantasy tables into tidy CSV.

Paste shape: every table cell on its own line, cells separated by a lone-tab
line. Splitting raw text on "\n\t\n" yields one field per cell.

Three table schemas, all sharing the same player-blob cell:

    Name\nNameSTATUSnote-blurb TEAM - POS\nMatchup

Player stats  (qb/rb/te/wr/wrt.txt) -> week_2_players.csv
Game day calls (game-day-calls.txt) -> week_2_game_day_calls.csv
Injury report  (injury-report.txt)  -> week_2_injury_report.csv

Note: in the calls/injury tables the LAST column of a row is not followed by a
tab-line, so it arrives glued to the next player blob. normalize_cells() splits
player blobs back out, which makes all three schemas parse identically.
"""
import csv
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parents[2] / "docs/uploads/week_2_data"

STAT_COLS = [
    "roster_status", "gp", "bye", "fan_pts", "rank_preseason", "rank_actual",
    "pct_rostered", "pass_yds", "pass_td", "pass_int", "rush_att", "rush_yds",
    "rush_td", "tgt", "rec", "rec_yds", "rec_td", "ret_td", "two_pt", "fum_lost",
]
CALL_COLS = ["injury", "status_col", "updated", "depth_chart"]
INJ_COLS = ["injury_type", "depth_chart"]
# The "Action" header is two icon-button cells, so a txn row is 4 cells
# after the player blob, not 3. The icons are dropped on write.
TXN_COLS = ["roster_status", "_icon_add", "_icon_watch", "change"]
TXN_OUT = ["roster_status", "change"]

POS = r"(?:QB|RB|WR|TE|K|DEF|EDGE|LB|DE|DT|DL|DB|CB|FB|S)"
META_RE = re.compile(r"\s([A-Za-z]{2,3}) - (" + POS + r"(?:," + POS + r")*)\s*$")
STATUS_RE = re.compile(r"^(IR-R|IR|SUSP|PUP|NFI|NA|Q|D|O|P)(?=[A-Z]|$)")
# Yahoo icon-font glyphs live in the Unicode private-use area. Escape-built on
# purpose: pasting the literal range into source flattens it to "[-]", which
# strips hyphens and breaks the "TEAM - POS" match.
PRIV_RE = re.compile("[\ue000-\uf8ff]")


def clean(s):
    return PRIV_RE.sub("", s).strip()


def num(s):
    s = clean(s).replace(",", "").replace("%", "")
    return "" if s in ("", "-", "--") else s


def split_cells(text):
    """One cell per lone-tab-delimited run of lines.

    Do NOT str.split("\n\t\n") here: two adjacent empty cells share a tab line,
    so the split collapses them into one and every later cell in the row shifts
    left. Rows with a blank Injury/Status then swallow the next player's cells.
    """
    cells, cur = [], []
    for ln in text.split("\n"):
        if ln == "\t":
            cells.append("\n".join(cur))
            cur = []
        else:
            cur.append(ln)
    cells.append("\n".join(cur))
    return cells


def normalize_cells(text):
    """Split raw paste into cells, with each player blob as its own cell."""
    out = []
    for field in split_cells(text):
        lines = field.split("\n")
        idx = next((i for i, ln in enumerate(lines) if META_RE.search(ln)), None)
        if idx is None or idx == 0:
            out.append(field)
            continue
        before = lines[:idx - 1]          # tail of the previous cell
        blob = lines[idx - 1:idx + 2]     # name / meta / matchup
        after = lines[idx + 2:]           # head of the next cell
        if before:
            out.append("\n".join(before))
        out.append("\n".join(blob))
        if after:
            out.append("\n".join(after))
    return out


def parse_player(blob):
    lines = [clean(x) for x in blob.split("\n")]
    name = lines[0]
    meta = lines[1] if len(lines) > 1 else ""
    matchup = lines[2] if len(lines) > 2 else ""

    m = META_RE.search(meta)
    team, pos = (m.group(1), m.group(2)) if m else ("", "")

    # status sits right after the repeated name: "Elijah Mitchell" + "NA" + note
    tail = meta[len(name):] if meta.startswith(name) else meta
    sm = STATUS_RE.match(tail)

    om = re.search(r"(?:vs|@)\s+([A-Za-z]{2,3})", matchup)
    km = re.match(r"([A-Za-z]{3}\s+\d{1,2}:\d{2}\s*[ap]m)", matchup)

    return {
        "player": name,
        "pos": pos.split(",")[0],
        "pos_eligible": pos,
        "nfl_team": team,
        "status": sm.group(1) if sm else "",
        "opponent": om.group(1) if om else "",
        "home_away": "" if not matchup else ("away" if "@" in matchup else "home"),
        "kickoff": km.group(1) if km else "",
    }


def parse_file(path, cols, numeric, date_prefixed=False):
    """date_prefixed: transaction tables put Date BEFORE the player, and the
    next row's date rides on the tail of the last column's cell. So the date
    for row N is the last line of the cell just before row N's player blob."""
    cells = normalize_cells(path.read_text(encoding="utf-8"))
    rows, i = [], 0
    while i < len(cells):
        lines = cells[i].split("\n")
        if len(lines) >= 2 and META_RE.search(lines[1]):
            vals = cells[i + 1: i + 1 + len(cols)]
            if len(vals) < len(cols):
                break
            row = parse_player(cells[i])
            if date_prefixed:
                prev = clean(cells[i - 1]).split("\n") if i else [""]
                row["date"] = prev[-1].strip()
                vals = list(vals)
                vals[-1] = clean(vals[-1]).split("\n")[0]
            for c, v in zip(cols, vals):
                row[c] = num(v) if c in numeric else clean(v)
            row["source_file"] = path.name
            rows.append(row)
            i += 1 + len(cols)
        else:
            i += 1
    return rows


PLAYER_KEYS = ["player", "pos", "pos_eligible", "nfl_team", "status",
               "opponent", "home_away", "kickoff"]


def write_csv(out, rows, cols, extra=()):
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(extra) + PLAYER_KEYS + cols
                           + ["source_file"])
        w.writeheader()
        w.writerows(rows)
    print(f"-> {out.name}  {len(rows)} rows", file=sys.stderr)


def build_players():
    numeric = set(STAT_COLS) - {"roster_status"}
    all_rows = []
    for name in ["qb", "rb", "te", "wr", "wrt"]:
        p = SRC / f"{name}.txt"
        if not p.exists():
            print(f"skip {p.name}: missing", file=sys.stderr)
            continue
        r = parse_file(p, STAT_COLS, numeric)
        print(f"{p.name}: {len(r)} players", file=sys.stderr)
        all_rows.extend(r)

    # wrt.txt is the FLEX view: all dupes of rb/wr/te. Position file wins.
    seen = {}
    for r in all_rows:
        key = (r["player"], r["nfl_team"])
        prev = seen.get(key)
        if prev is None or prev["source_file"] == "wrt.txt":
            seen[key] = r
        elif len(r["pos_eligible"]) > len(prev["pos_eligible"]):
            prev["pos_eligible"] = r["pos_eligible"]
    write_csv(SRC / "week_2_players.csv", list(seen.values()), STAT_COLS)


def build_simple(src_name, out_name, cols):
    p = SRC / src_name
    if not p.exists():
        print(f"skip {src_name}: missing", file=sys.stderr)
        return
    rows = parse_file(p, cols, numeric=set())
    print(f"{src_name}: {len(rows)} players", file=sys.stderr)
    write_csv(SRC / out_name, rows, cols)


def build_txn(src_name, out_name):
    p = SRC / src_name
    if not p.exists():
        print(f"skip {src_name}: missing", file=sys.stderr)
        return
    rows = parse_file(p, TXN_COLS, numeric=set(), date_prefixed=True)
    for r in rows:
        r.pop("_icon_add", None)
        r.pop("_icon_watch", None)
    print(f"{src_name}: {len(rows)} rows", file=sys.stderr)
    write_csv(SRC / out_name, rows, TXN_OUT, extra=["date"])


if __name__ == "__main__":
    build_players()
    build_simple("game-day-calls.txt", "week_2_game_day_calls.csv", CALL_COLS)
    build_simple("injury-report.txt", "week_2_injury_report.csv", INJ_COLS)
    build_txn("ir-reserved", "week_2_ir_reserved.csv")
    build_txn("league-team-changes", "week_2_nfl_team_changes.csv")
    build_txn("roster-changes", "week_2_roster_changes.csv")
