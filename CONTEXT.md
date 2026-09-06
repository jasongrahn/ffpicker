# ffdraft

Local fantasy football draft engine. Exists to maximize P(championship) for one specific
Yahoo league, not to produce generic rankings.

## Language

**Pick**:
A single (team, player, draft slot number) assignment made during the live draft.
_Avoid_: Selection, choice.

**Pick Log**:
The append-only, source-of-truth event stream for the live draft (`pick_made`,
`pick_corrected`, `draft_started` events). Never mutated in place — a correction is a new
event, not an edit to an old one. Current draft state is derived by replaying it.
_Avoid_: Picks table, draft history (ambiguous with historical past-season data).

**Draft Pool**:
Every player FantasyPros considers draft-relevant for the current season (has an ECR),
regardless of whether real production data exists yet. Superset of the Draft Board.
_Avoid_: Player universe, all players.

**Draft Board**:
The subset of the Draft Pool with real current-season production (`has_current_data`),
ranked into VOR tiers. Players in the Pool but not the Board (mostly rookies — no games
played yet, not "no data": they still have an ECR) appear in a separate ECR-sorted
fallback section, not omitted. Static input to a draft session, not derived from the Pick
Log.
_Avoid_: Cheat sheet (used loosely elsewhere for the same artifact, but "board" is the
canonical term going forward). Also avoid treating "no VOR" and "no data" as synonyms —
see Draft Pool.

**Roster**:
A single team's current set of drafted players, derived by replaying the Pick Log
filtered to that team. Not persisted directly — always a projection of the Pick Log.
_Avoid_: Team roster (redundant — a Roster always belongs to exactly one Team).

**Lineup**:
The 9 players from a Roster assigned to starting slots for one specific week (QB 1, RB 2,
WR 2, TE 1, FLEX 1, K 1, DST 1). Distinct from Roster: a Roster is who you *own* and
changes only via draft/waiver/trade; a Lineup is who *scores* and is re-chosen every week
from that Roster. The other 6 are benched and score nothing.
_Avoid_: Starters (ambiguous — also means the league-wide starter counts in
`league.json`), team.

**Defensive Matchup**:
The opposing team's defense that one of your players faces in a given week — context for
whether that player is likely to score more or less than usual.
_Avoid_: Matchup unqualified. In fantasy that word overloads onto two unrelated things;
always qualify which. See Weekly Opponent.

**Weekly Opponent**:
The rival *fantasy team* you are scored head-to-head against in a given week. Determined by
Yahoo's league schedule, which the Pick Log cannot know — entered manually.
_Avoid_: Matchup unqualified (see Defensive Matchup), opponent (ambiguous with the NFL
team a player faces).

**Lock Time**:
The kickoff of a player's own NFL game, after which he cannot be moved into or out of the
Lineup. Per-player, not per-week — a Week 1 roster can span six lock windows across six
days.
_Avoid_: Deadline, lineup deadline (both imply one weekly cutoff, which is wrong).

**Positional Run**:
A burst of consecutive draft Picks at one position, which empties that position's live tier
faster than the Board's ordering implies. The thing the Phase 3.6 guide predicts: whether a
position survives until your next turn.
_Avoid_: Run (ambiguous with a rushing play).

## Example dialogue

> Dev: "Does the Roster update automatically when I enter a Pick?"
> Domain expert: "Yes — a Roster isn't its own stored thing, it's just replaying the Pick
> Log for that team. Enter a `pick_made` event, every team's Roster and the remaining
> Draft Board recompute from that."
