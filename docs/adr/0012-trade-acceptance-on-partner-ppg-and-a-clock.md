# Trades: price acceptance on the partner's ppg view; positive under both bases; send in parallel on a clock

2026-11-02, review 002. In-season.

Context. Roster = 9th of 10 and the lineup layer is at its ceiling (ADR 0010) -> trades are the
only lever that moves P(top 4) by points, not tenths. TR1 + TR2 were priced 10-21 and still
unsent 11-02. Two defects sat under them:

1. **Acceptance proxy = "win-win on projections".** Managers don't see Yahoo mean projections;
   they see season ppg, last-3 ppg, names. On that view TR1 = Madison −8.3/wk, TR2 = Max's
   −6.1/wk -> expect rejection. Of 58,698 trades adding >= 3/wk for us, projection win-win
   passes 18; a casual-manager ppg filter passes 558; both: 0 (`002-evidence/p1_veteran/06_trade_scan.R`).
2. **`settle()` could drop a team's only QB/K/DEF**, then FILL refilled it from the wire free,
   with no roster spot -> fake partner gain. Madison: sole DEF dropped, +1.5/wk phantom -> TR1
   read "win-win +0.0"; truth −2.02 (`a3_trades/common.R`, confirmed `p4_redteam/10_signs.R`).
   Our side unbiased today; latent once our 0-cost bodies are traded.

Decided:

- **Acceptance check = partner's ppg-world change >= −1 pts/wk AND projection change >= −2.**
  ppg-world = each player at 0.5 x season ppg + 0.5 x last-3 ppg, same lineup logic.
- **Our gain must be positive under `BASE=mean` AND `BASE=latest`.** Mean-of-projections lags
  role changes: M1 (Gordon -> A. Jones + Skattebo) +1.29pp -> −0.99; S1 (J. Williams -> Olave +
  Kelce) +0.66 -> −0.78 (`lead/offer_set.R`). Sign flips -> don't send.
- **Send in parallel**: one offer per partner, no player in two offers. Each offer self-contained
  on roster count (designate the drop). Two trades together beat the sum (+23%, P3).
- **Clock**: send Tuesday after the re-run; accept-by Thu for that week (2-day vote); last send
  Tue 11-24 AM (deadline 11-28). Delay costs ~−0.7..−0.8pp/wk for a +6/wk package (P3, A5).
- **Partners**: arming non-contenders and near-locks is cheap (+5/wk to them costs us 0.04-0.15pp;
  to a 4th-place rival 0.3-0.44pp; Madison +0.21 = helps us; P3 `03_trades_seq.R`).
- **`settle()` protects sole QB/K/DEF** on both sides (`dev/weekly/trade_finder.R`).
- **Log every offer**: date, partner, give/get, reply. First acceptance data this league has.

**Considered and rejected**:
- Projection win-win as the filter — passes almost nothing, and what it passes looks lopsided
  on ppg (above).
- "Fleece" tier (ppg-fair but partner −2+ on paper, name-heavy, e.g. Gordon + Tucker + Hockenson
  -> Bijan Robinson + Drake London, +18.5pp): veto bait under League Votes.
- Waiting for a desperate partner: wk9-10 results don't change the decision (trades beat no
  trades in every state); waiting to wk11 breaks even only if the later deal is +32% better
  (P3 `05_checkpoints.R`).

Evidence: `docs/review/002-evidence/` — `a3_trades/named.R` (TR1/TR2/X1/D1/O1, 10 seeds),
`lead/offer_set.R` (Tue set, every subset, both bases), `p1_veteran/06_trade_scan.R`,
`p4_redteam/10_signs.R` (signs hold in every world), `p3_decision/03_trades_seq.R`.

Revisit: 0 acceptances from >= 4 offers by 11-20 -> stop asking; keep what landed. Season end:
offer log v proxy -> recalibrate (n will be tiny; direction only).
