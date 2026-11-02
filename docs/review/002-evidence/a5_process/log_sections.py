# Split each weekly decision log into heading sections; print (week, level, heading, n_lines).
import re, sys, glob, os
REPO = "/Users/jasongrahn/R-projects/ffootballer"
rows = []
for f in sorted(glob.glob(f"{REPO}/data/weekly/2026_week0*_decisions.md")):
    wk = int(re.search(r"week0(\d)", f).group(1))
    lines = open(f, encoding="utf-8").read().split("\n")
    cur = ("(preamble)", 0); start = 0
    secs = []
    for i, ln in enumerate(lines):
        m = re.match(r"^(#{1,4})\s+(.*)", ln)
        if m:
            secs.append((cur[0], cur[1], i - start))
            cur = (m.group(2).strip(), len(m.group(1))); start = i
    secs.append((cur[0], cur[1], len(lines) - start))
    for h, lvl, n in secs:
        rows.append((wk, lvl, h, n))
for r in rows:
    print(f"{r[0]}\t{r[1]}\t{r[3]}\t{r[2][:110]}")
