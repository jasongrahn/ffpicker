import json,glob,os,collections
root=os.path.expanduser("~/.claude/projects")
P=collections.defaultdict(lambda: collections.Counter())
for f in glob.glob(f"{root}/**/*.jsonl",recursive=True):
    proj=f[len(root)+1:].split("/")[0].replace("-Users-jasongrahn-R-projects","") or "(R-projects root)"
    p=P[proj]; p["files"]+=1; ids={}; seen=set(); dates=set()
    for line in open(f,errors="ignore"):
        try:d=json.loads(line)
        except:continue
        if d.get("timestamp"): dates.add(d["timestamp"][:10])
        m=d.get("message") or {}
        if d.get("type")=="assistant":
            u=m.get("usage") or {}
            if m.get("id") not in seen:
                seen.add(m.get("id")); p["turns"]+=1; p["ctx"]+=u.get("cache_read_input_tokens",0)+u.get("cache_creation_input_tokens",0)+u.get("input_tokens",0); p["out"]+=u.get("output_tokens",0)
            for c in m.get("content") or []:
                if isinstance(c,dict) and c.get("type")=="tool_use":
                    ids[c["id"]]=c["name"]
                    if c["name"]=="Bash":
                        p["bash"]+=1
                        if str(c["input"].get("command","")).startswith("rtk"): p["rtk_explicit"]+=1
        if d.get("type")=="user" and isinstance(m.get("content"),list):
            for c in m["content"]:
                if isinstance(c,dict) and c.get("type")=="tool_result":
                    n=ids.get(c.get("tool_use_id"),"?"); cc=c.get("content")
                    k={"Read":"read_tok","Bash":"bash_tok"}.get(n,"other_tok")
                    p[k]+=(len(cc) if isinstance(cc,str) else len(json.dumps(cc)))//4
    p["first"]=min(dates) if dates else ""; p["last"]=max(dates) if dates else ""
print(f"{'project':32s} files turns  ctx(M) out(K) readK bashK othK  bash  dates")
for k,p in sorted(P.items(),key=lambda x:-x[1]["ctx"]):
    print(f"{k[-32:]:32s} {p['files']:5d} {p['turns']:5d} {p['ctx']/1e6:7.1f} {p['out']/1e3:6.0f} {p['read_tok']/1e3:5.0f} {p['bash_tok']/1e3:5.0f} {p['other_tok']/1e3:4.0f} {p['bash']:5d}  {p['first']}..{p['last']}")
