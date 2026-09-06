# Sleeper evaluation — plan

Throwaway. Lives in `dev/`. Nothing enters `_targets.R` unless verdict = YES.

## Pass/fail bars — SET BEFORE MEASURING (2026-09-06, before any new numbers)

Bars fixed by lead, not by haiku. Do not move them after seeing output.

### C1 Coverage
PASS if BOTH:
- >= 90% of `draft_pool` rows (732) carry a non-sentinel `search_rank` after cleaning.
- >= 100 rows in the tail (`ecr_source == "overall" & ecr > 290`) carry one.
FAIL otherwise. Prior probe: 98% raw match -> provisionally passes, must reconfirm post-sentinel-filter.

### C2 Signal
Region = tail (`ecr_source == "overall" & ecr > 290`), n >= 100.
PASS if BOTH:
- |Spearman(search_rank, 2025 PPG)| >= 0.25, correct sign (negative).
- that magnitude >= 2x |Spearman(ecr, PPG)| in the same region.
Prior probe: -0.354 vs -0.014 -> passes. Reconfirm.
Position-added rows (`ecr_source == "position"`) are OUT OF SCOPE. Prior probe says
Sleeper does nothing there (+0.065, wrong sign). Not retested, not claimed.

### C3 Independence  <- the one with no data
Two tests, BOTH must pass.
- Partial Spearman(search_rank, PPG | ecr) in the UNCENSORED band (`ecr <= 290`):
  |rho_partial| >= 0.15, correct sign. Below that -> search_rank is FantasyPros
  consensus wearing a different hat, adds nothing beyond ECR.
- Spearman(search_rank, ecr) in the tail < 0.85. At or above -> re-derived rank.
FAIL either -> verdict NO regardless of C1/C2.

### C4 Actionability  <- run FIRST, it is cheap and can end this
Blend rule under test (lead's choice, the only one evaluated):
  Take rows where `ecr_source == "overall" & ecr > 290`. Keep that set's existing
  `ecr` slots. Reassign those slots by `search_rank` ascending. Head (`ecr <= 290`)
  and all `ecr_source == "position"` rows untouched.
Diff = my 17 picks, baseline dryrun vs Sleeper-reordered dryrun, slot 5, K16/DST15.
PASS if >= 3 of 17 picks change AND >= 2 of those changes fall in rounds 10-17.
FAIL -> verdict NO. Write the numbers into the handoff and close the thread the way
Yahoo and ffscrapr were closed. A clean negative is a successful session.

## Verdict rule
YES only if C1 AND C2 AND C3 AND C4 all pass. Any FAIL -> NO, write it up, stop.

## Run order
1. Units 1-3 (fetch, clean, join)  -> `pool_sleeper.csv`
2. Unit 4a: C4 actionability diff   -> if FAIL, stop here
3. Unit 4b: C1, C2, C3 tables
