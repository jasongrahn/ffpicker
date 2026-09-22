import json, glob, os, collections, statistics as st

root = os.path.expanduser("~/.claude/projects")
files = glob.glob(f"{root}/**/*.jsonl", recursive=True)

tool_calls = collections.Counter()
tool_result_chars = collections.Counter()
skills = collections.Counter()
agents = collections.Counter()
sessions = []
id2tool = {}

for f in files:
    is_sub = "/subagents/" in f
    s = dict(file=f, sub=is_sub, out=0, inp=0, cr=0, cw=0, turns=0,
             caveman=False, adhd=False, rtk=0, serena=0, start=None)
    seen_msg = set()
    for line in open(f, errors="ignore"):
        try: d = json.loads(line)
        except: continue
        if s["start"] is None and d.get("timestamp"): s["start"] = d["timestamp"][:10]
        raw = line
        if "caveman" in raw.lower() and ('"Skill"' in raw or "CAVEMAN" in raw): s["caveman"] = True
        if "ADHD MODE ACTIVE" in raw: s["adhd"] = True
        m = d.get("message") or {}
        if d.get("type") == "assistant":
            mid = m.get("id")
            u = m.get("usage") or {}
            if mid and mid not in seen_msg:
                seen_msg.add(mid); s["turns"] += 1
                s["out"] += u.get("output_tokens", 0)
                s["inp"] += u.get("input_tokens", 0)
                s["cr"] += u.get("cache_read_input_tokens", 0)
                s["cw"] += u.get("cache_creation_input_tokens", 0)
            for c in m.get("content") or []:
                if isinstance(c, dict) and c.get("type") == "tool_use":
                    n = c["name"]; tool_calls[n] += 1; id2tool[c["id"]] = n
                    inp = c.get("input") or {}
                    if n == "Skill": skills[inp.get("skill")] += 1
                    if n in ("Agent", "Task"): agents[inp.get("subagent_type", "general")] += 1
                    if n.startswith("mcp__serena"): s["serena"] += 1
                    if n == "Bash" and str(inp.get("command", "")).startswith("rtk"): s["rtk"] += 1
        if d.get("type") == "user" and isinstance(m.get("content"), list):
            for c in m["content"]:
                if isinstance(c, dict) and c.get("type") == "tool_result":
                    n = id2tool.get(c.get("tool_use_id"), "?")
                    cc = c.get("content")
                    tool_result_chars[n] += len(json.dumps(cc)) if not isinstance(cc, str) else len(cc)
    sessions.append(s)

main = [s for s in sessions if not s["sub"] and s["turns"] > 0]
sub = [s for s in sessions if s["sub"] and s["turns"] > 0]
print(f"main sessions {len(main)}, subagent transcripts {len(sub)}")
tot = lambda L, k: sum(x[k] for x in L)
for lab, L in [("main", main), ("sub", sub)]:
    print(lab, {k: tot(L, k) for k in ["turns", "out", "inp", "cr", "cw"]})

print("\nTop tools by calls / result chars (~chars/4 = tokens):")
for n, c in tool_calls.most_common(25):
    print(f"  {n:45s} {c:6d} calls  {tool_result_chars[n]/4/1000:9.1f}K tok")
print("\nSkills:", skills.most_common())
print("Agents:", agents.most_common())

def grp(L, key):
    a = [x for x in L if x[key]]; b = [x for x in L if not x[key]]
    for lab, g in [("with", a), ("without", b)]:
        if not g: continue
        t = tot(g, "turns")
        print(f"  {key} {lab}: n={len(g)} turns={t} out/turn={tot(g,'out')/t:.0f} ctx/turn={(tot(g,'cr')+tot(g,'cw')+tot(g,'inp'))/t:.0f}")
print(); grp(main, "caveman"); grp(main, "adhd")
print("\nBy session start date:")
for s in sorted(main, key=lambda x: x["start"] or ""):
    print(f"  {s['start']} {os.path.basename(os.path.dirname(s['file']))[-28:]:28s} turns={s['turns']:4d} out/turn={s['out']/s['turns']:5.0f} cav={int(s['caveman'])} adhd={int(s['adhd'])} rtk={s['rtk']} serena={s['serena']}")
