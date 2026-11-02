# Effort proxy: decision-log lines by activity type, wks 2-8.
# Classification = ordered regex rules on section headings (first match wins), hand-written
# after reading every log. Proxy only: line count != hours, but it is the only uniform
# effort record across weeks.
import re, glob, collections
REPO = "/Users/jasongrahn/R-projects/ffootballer"
RULES = [  # (week or None, regex, type)
 (None, r"^\(preamble\)$|decision log|Decisions — 2026|^Decisions$|^Roster moves|^1\. Roster moves|^2\. Decisions|^Retro$|RETRO — appended|^Retro — Week 4|^Standing$|Explicitly NOT|What to learn|Open at freeze|Still open|Open questions|^Retro, part 2", "frame/overhead"),
 (None, r"Trades|TR1|TR2", "trade"),
 (None, r"METHOD|Rankings|Data defect|DEF naming|Data finding", "data/correction"),
 (None, r"Deadline|Lock order|Freeze deadline|5f\.|6e\.|Byes ahead|Bye horizon|bye monitoring|week 11 is the pinch|Week 11 is the pinch", "deadline/bye"),
 (None, r"Stream|DEF|DST|Bengals|Butker|Bates|K —|K1\.|kicker|K rule|Chiefs DEF|Claim \*\*KC|D2\. DEF|W1\. Add \*\*Bengals|D11|W-HOLD", "stream K/DST"),
 (None, r"Head-to-head|head-to-head|Correlation|Hedge|concentration|Opponent|opponent|Chi opponent|5e\.|6c\.|R0b", "opponent/h2h"),
 (None, r"game script|Game-script|Game script|multiplier|SPREAD|D-SPREAD|D-WR-SCRIPT|spread tiebreak|Gameday script|GD1|pair band|S1/S2 at scale|projection error|Projection error|projection sign|Yahoo projection|Method-test|Test [123]|Capstone|Operational finding|League-wide|L1\b|L1,|the sim|seed for the next|Out-of-sample|Production read|The frame|Our own numbers vs Yahoo|What the backtest|Method tests live|stream detector|DST rule HELD|Yahoo moved", "method test"),
 (None, r"Claims\.|W2\. Add|W3\. Add|D9\.|D10\.|D1\. \*\*CORRECTED|D8\.|M0\.|H1\.|Holds|Roster move|Open hole|TE cost|Wire:|wire|6a\. Moves|6b\.|M1\. Post-freeze, 2026-10-21|Etienne -> IR|D4\. Etienne|D5\. Raymond \(Chi\) added|D5 addendum|NO backfield|False lead|Weather", "waiver/roster"),
 (None, r"Kill|kill table|Conditions|conditions|Result|Scoreboard|Regret|regret|Scorecard|Decision wrong|ledger|Carried|carries|R1\. Result|Reading, per decision|Process: the|R2\. Conditions|R1\. Kill|5a\. Closed|5b\.", "retro/scoring"),
 (None, r".", "lineup start/sit"),
]
OVERRIDE = {  # (week, heading-prefix) -> type, for headings the rules misread
 (2, "D6. Dal/Was"): "opponent/h2h", (2, "Sunday 11:30am"): "lineup start/sit",
 (3, "D6 — the week"): "stream K/DST", (3, "D5 — the expensive"): "lineup start/sit",
 (3, "D1 — the QB"): "lineup start/sit", (3, "D7. No lineup"): "lineup start/sit",
 (4, "D3. The bar"): "stream K/DST", (4, "D6a. Clean kill"): "lineup start/sit",
 (4, "D6a. **AMENDMENT"): "lineup start/sit", (4, "D6b."): "lineup start/sit",
 (4, "D6. **CORRECTED"): "lineup start/sit", (4, "2. Lineup"): "lineup start/sit",
 (4, "D7. Forced"): "lineup start/sit",
 (5, "2. Lineup"): "lineup start/sit", (5, "Week 5 lineup, FINAL"): "lineup start/sit",
 (5, "R2. THE SPREAD"): "method test", (5, "**The K rule"): "stream K/DST",
 (5, "R6. Decision wrong"): "retro/scoring", (5, "R3. DST rule"): "stream K/DST",
 (6, "2. Lineup"): "lineup start/sit", (6, "2a."): "lineup start/sit", (6, "6d."): "lineup start/sit",
 (6, "R3. Regret"): "method test", (6, "R9."): "method test", (6, "R6."): "opponent/h2h",
 (6, "R8."): "opponent/h2h", (6, "W1. Claim"): "stream K/DST", (6, "R5."): "method test",
 (6, "R4."): "method test", (6, "0. Headline"): "frame/overhead", (6, "6f."): "retro/scoring",
 (6, "3. Kill"): "retro/scoring", (6, "6. FINAL"): "lineup start/sit",
 (7, "0. Headline"): "lineup start/sit", (7, "1. Lineup"): "lineup start/sit", (7, "T1."): "lineup start/sit",
 (7, "W1. **HOLD"): "lineup start/sit", (7, "D1. Start **Browns"): "stream K/DST",
 (7, "M1. Post-freeze"): "waiver/roster", (7, "R4. L1"): "method test", (7, "R5."): "method test",
 (7, "R3. Regret"): "retro/scoring", (7, "R7."): "method test", (7, "3. Open tests"): "method test",
 (8, "4. Lineup"): "lineup start/sit", (8, "5. Tests"): "method test", (8, "M1. Post-freeze"): "lineup start/sit",
 (8, "R1. T1"): "trade", (6, "6c."): "opponent/h2h", (6, "5a."): "data/correction",
 (6, "5b."): "deadline/bye", (2, "Weather"): "lineup start/sit", (5, "R7. Still"): "frame/overhead", (8, "2. Holds"): "waiver/roster", (8, "1. Claims"): "waiver/roster",
}
def classify(wk, h):
    for (w, pre), t in OVERRIDE.items():
        if w == wk and h.startswith(pre): return t
    for w, rx, t in RULES:
        if (w is None or w == wk) and re.search(rx, h): return t
tot = collections.Counter(); byweek = collections.defaultdict(collections.Counter)
detail = []
for f in sorted(glob.glob(f"{REPO}/data/weekly/2026_week0*_decisions.md")):
    wk = int(re.search(r"week0(\d)", f).group(1))
    lines = open(f, encoding="utf-8").read().split("\n")
    heads = [(i, m.group(2).strip()) for i, ln in enumerate(lines) if (m := re.match(r"^(#{1,4})\s+(.*)", ln))]
    bounds = [(0, "(preamble)")] + heads
    for k, (i, h) in enumerate(bounds):
        j = bounds[k + 1][0] if k + 1 < len(bounds) else len(lines)
        n = j - i; t = classify(wk, h)
        tot[t] += n; byweek[wk][t] += n; detail.append((wk, t, n, h[:80]))
types = [t for t, _ in tot.most_common()]
print("type\t" + "\t".join(f"wk{w}" for w in sorted(byweek)) + "\ttotal\tshare")
N = sum(tot.values())
for t in types:
    print(t + "\t" + "\t".join(str(byweek[w][t]) for w in sorted(byweek)) + f"\t{tot[t]}\t{tot[t]/N:.0%}")
print("TOTAL\t" + "\t".join(str(sum(byweek[w].values())) for w in sorted(byweek)) + f"\t{N}")
with open(__file__.replace(".py", "_detail.tsv"), "w") as fh:
    for r in detail: fh.write("\t".join(map(str, r)) + "\n")
