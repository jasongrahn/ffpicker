# Yahoo Fantasy Sports API — access application

Form: https://sports.yahoo.com/developer/access/
Status: **SUBMITTED 2026-09-16.** Awaiting human review. No SLA published.

Turnaround unknown and not guessable. `yfpy` issue #84 (opened 2026-07-22) asked the
same question publicly and has **zero replies** — no one has reported an approval yet.
Do not chase this. Nothing in the weekly pipeline depends on it.

Re-check cadence: once a week. Test is one command, `yahoo_open_consent("fspt-r")` —
`error=invalid_scope` means still pending, a consent screen means approved.

## Client library, for when/if approved

Use **`yfpy`** (`github.com/uberfastman/yfpy`, Python). Handles the OAuth2 three-legged
handshake, token refresh, and Yahoo's nested XML/JSON parsing. Saves roughly a day.

Caveat: its README is stale the same way Yahoo's docs are — tells you to check a
`Fantasy Sports` permission box that no longer exists, and claims public-league reads
need no developer app (our probe got 403 on public `/fantasy/v2/game/nfl`). Follow the
approval path here, not that README's setup section.

Form rejects vague submissions without correspondence. Text below is ready to paste.
Personal / single-league use is explicitly eligible.

---

## Field answers

**Expected Users**: `Small (< 1,000 users)`

**Client ID**: paste from `.Renviron` -> `YAHOO_CLIENT_ID`. Never paste the secret;
the form does not ask for it.

**Description** — paste verbatim:

Personal, single-league fantasy football tool. Not a product, not distributed, no other users.

I am a member of one private 10-team Yahoo fantasy football league (league ID 1541392, game NFL). I have built a local R application that helps me set my own weekly starting lineup. It runs on my laptop, stores data in a local DuckDB file, and is not hosted, published, or shared. I am the only user and will remain the only user.

Data required, read-only:

1. My own team roster for league 1541392, weekly — the ~15 players I control, so the tool knows which players it is choosing among.
2. Player ownership / stats / availability within that league — which players are unowned, so the tool knows which players are available for waiver additions. I can evaluate waiver additions.
3. League settings (roster slots, scoring) — to confirm my local scoring config matches Yahoo's, which I currently verify by hand against box scores.

Everything else the tool uses comes from public NFL play-by-play and statistics via the nflverse project. Yahoo is the only source for my league's own roster and ownership state, which is why I am applying.

Currently I copy this information by hand from the Yahoo web UI each week. The API would replace manual copying with an equivalent read. It would not increase the volume of data I access, and request volume would be a handful of calls per week  during the NFL season.

Read access only. I do not need write access — I set my lineup in the Yahoo app. I will include the attribution "Fantasy data provided by Yahoo Fantasy" linking to Yahoo Fantasy in the application interface.

---

## If approved

- Scope is `fspt-r`. Write access does not exist; do not request it.
- Re-run `dev/yahoo/auth_probe.R`: `yahoo_open_consent("fspt-r")` should now render a
  consent screen listing Fantasy Sports instead of `error=invalid_scope`.
- Then `yahoo_exchange(code)` -> `yahoo_get(token, "game/nfl")`. A **200** confirms
  provisioning. 401 `additional_authorization_required` means still unprovisioned.
- Add the attribution string to the Shiny UI before using any Yahoo data in it.
- Priority once live, per handoff #28 s3: waiver ownership first. Start/sit needs
  only the 15 rostered players plus nflreadr, both already in hand.

## If rejected

Record the rejection text and date here. Manual paste continues; nothing in the
weekly pipeline depends on Yahoo.
