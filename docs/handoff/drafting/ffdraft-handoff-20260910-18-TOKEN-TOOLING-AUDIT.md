# Handoff #25 — token-tooling audit, serena fix (2026-09-10)

Off-track from ffdraft. Tooling session, not football. Goal: decide which token-saving tools go to work laptop (dbt/Snowflake).

## Next session focus

1. Verify serena works after restart (R language server now installed).
2. Pin serena launch to fixed commit — current config pulls unpinned from GitHub every launch.

## Findings

| Tool | Measured | Source |
|---|---|---|
| headroom | ~5% input cut, steady 3-8%/mo all projects since 2026-06-14; 12.2M tok lifetime | `headroom perf --hours 720`, `~/.headroom/proxy_savings.json` |
| rtk | 101K tok saved, 38.8% on what it touches; Bash only; ~3M effective w/ re-send (estimate) | `rtk gain -a` |
| serena | 0 calls ever | transcripts |
| context7 | 0 calls | transcripts |
| caveman | 2 sessions, unmeasurable | transcripts |
| i-have-adhd | no control group; formatting, not savings | transcripts |

- headroom "$1233 cache savings" = Anthropic prompt caching, NOT headroom. Real headroom $ = $37-46 compression, list-price, overstated (93% cache hit rate).
- `Read` tool output = largest tool-result source (~1.0M tok ffootballer). rtk doesn't touch it (Bash only). headroom excludes Read/Glob (34% of msgs).
- barquentine_pipeline (most work-like): Read 229K vs Bash 22K -> rtk weak on pipeline work. n small (196 turns).
- Transcripts pruned: 18 project dirs in `~/.claude/history.jsonl`, only 3 have jsonl left. headroom = only all-project source.
- Audit scripts: `dev/token_audit/audit.py`, `dev/token_audit/byproj.py`. Parse `~/.claude/projects/**/*.jsonl`.

## Changes made

- **greptile uninstalled** (`claude plugin uninstall greptile@claude-plugins-official`). Confirmed gone after `/reload-plugins`.
- **R `languageserver` 0.3.18 installed** into ffootballer renv lib via `renv::install()`. `renv.lock` unchanged (snapshot.type implicit). **Did not fix serena** — see below.
- **Real fix (post-restart session):** serena runs `R --vanilla` (`solidlsp/language_servers/r_language_server.py:46,67`) -> skips `.Rprofile` -> renv inactive -> only system lib. Installed `languageserver` into system lib (`install.packages(..., lib=.Library)`). Repro `R --vanilla --slave -e "if (!require('languageserver', quietly=TRUE)) quit(status=1)"` exit 1 -> 0. Root cause of serena 0 calls: log `~/.serena/logs/2026-09-10/mcp_20260910-104523_83971.txt` -> `R languageserver package is not installed`.
- **`~/.claude/CLAUDE.md`**: added `## Code navigation` block -> prefer serena `get_symbols_overview` / `find_symbol` / `find_referencing_symbols` over Read for code.
- Memory: `token-tooling-audit.md` in project memory.
- Not committed: `dev/token_audit/`, this handoff.

Why serena unused beyond LS failure: tools deferred (need ToolSearch load), Read/Grep always loaded -> default. CLAUDE.md block addresses this.

## Serena security concern — CLOSED 2026-09-10

Pinned: user scope, `@701e7c843f46c6a649203a488cece1bf19f1df90` (main, reports `version=1.7.1.dev0`, 48 commits past v1.7.0). Verified: overview/find_symbol/references match grep (22/22 real `simulate_draft` calls; `dev/mc_golden.R:55` grep hit is inside a string). Bump = new SHA + review diff.

Pin history: first pinned v1.7.0 (`949a27e`) -> refs returned `{}` -> blamed v1.7.0 -> repinned main -> refs STILL `{}`. Real cause: R languageserver answers references only for files parsed this process lifetime. Warm serena symbol cache -> files never opened -> `{}`. Fix: `find_symbol` with no `relative_path` first (project-wide scan; cache 31K -> 578K), then refs work. v1.7.0 likely fine, never retested with scan. Kept main pin anyway: includes `dc59a893` (LS subprocess leak fix) — saw ~5 orphan R LS procs, ~950 MB.
Also: `max_answer_chars` too small -> silent `{}`. Both gotchas added to `~/.claude/CLAUDE.md`.
Not killed: other Claude window (pid 67841) still runs 2 serenas (unpinned + v1.7.0) — restart it.

Original notes:

Current launch (`claude mcp list`):
```
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --project-from-cwd --context claude-code
```
No ref -> latest `main` each launch -> supply-chain risk. User flagged as real concern. Fix: pin to commit SHA (strongest) or release tag:
```bash
claude mcp remove serena
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena@<SHA> serena start-mcp-server --project-from-cwd --context claude-code
```
Check scope (user vs local) before remove — `claude mcp get serena`. Pick SHA from a tagged release; review diff before bumping.

Other serena corp flags: writes `.serena/` into repos (gitignore it); has edit tools (same trust as Edit).

## Work-laptop verdicts

- rtk: bring. Local, low risk. Modest on pipeline work.
- serena: bring for Python/R repos, pinned. Weak for dbt (SQL+Jinja, no symbol server). dbt alternative lead: dbt Labs `dbt-mcp` — untested.
- headroom: only if security approves (proxy in path of all API traffic incl. company code) AND work bills per token. Seat plan -> skip. Overhead 287ms avg, 307 reqs >500ms.
- Open question for user: work Claude = seat plan or API billing?
- Suggested: `"cleanupPeriodDays": 365` in `~/.claude/settings.json` both laptops -> keep transcripts for future audits. Not applied.

## Suggested skills

- `update-config` — pin serena / add `cleanupPeriodDays`.
- `diagnose` — if serena still fails after restart.
- `caveman` — repo doc style for any follow-up notes.
