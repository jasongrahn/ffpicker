# Manual paste, not the Yahoo API — Fantasy access denied

Yahoo Fantasy API (`fantasysports.yahooapis.com/fantasy/v2`) gated. Yahoo removed self-serve
Fantasy provisioning ~May 2026 -> manual approval program. `developer.yahoo.com/fantasysports/guide/`
now 308-redirects to `sports.yahoo.com/developer`. Creating an app = **necessary, not
sufficient**: yields client id/secret; Fantasy entitlement granted separately, on approval.
Legacy apps de-provisioned 2026-07-22 without notice (`github.com/uberfastman/yfpy` issue #84)
-> hit working integrations too, not just new apps. Our league is private.

Decided: **manual paste is the only path.** League settings: user reads Yahoo settings page
-> `config/league.json`. Draft: manual pick entry. In-season: user-pulled Yahoo exports ->
`docs/uploads/week_NN_data/`. Applied at `https://sports.yahoo.com/developer/access/` ->
denied (Status). If access is ever granted -> thin `httr2` OAuth2 client. Never build live
sync as a dependency.

**Considered and rejected**:
- Scraping / reverse-engineering — Yahoo terms prohibit.
- OAuth 1.0a via Yahoo's own published sample code — 403, probe table below.
- `YFAR` — wraps the OAuth1 flow; its request-token endpoint now returns 401. Appears
  unmaintained.
- `ffscrapr` — no Yahoo support. Whole category closed in ADR 0003.
- Declaring the API closed for good — done twice, wrong twice. See last section.

## Status

**Application DENIED** — reported by the user 2026-10-27. Yahoo's reason: **not enough
information** (matches the form's warning below). Was "not submitted" as of 2026-10-21
(handoff #45). **User decision 2026-10-27: not re-applying — go without the API.** Manual
paste is the only path. A fuller re-application is the one untried route — parked by
choice, not blocked. Do not carry it as an open item. Probes below = correct description of
an unprovisioned app; re-running them changes nothing.

## Form facts, read from the live page 2026-09-16

- Read-only. "Write access is not available at this time." `fspt-r` is the only scope.
- Asks: Expected Users (Small <1,000 / Medium / Large), Client ID (optional, ours exists),
  description.
- **Personal / single-league use explicitly in scope** — our case.
- "incomplete or insufficiently detailed submissions cannot be evaluated and will be closed
  without further correspondence." Write it properly the first time.
- Attribution required if approved: "Fantasy data provided by Yahoo Fantasy", linking back to
  Yahoo Fantasy.

## Error shapes are diagnostic

Per the community thread, matching our probes:
- `401 additional_authorization_required` = never provisioned (us, new app).
- `403 This application is not authorized` = de-provisioned legacy app.

## Probes, 2026-09-15. Do not re-run.

Real app credentials (app id, consumer key, secret, redirect `https://127.0.0.1:7645/`).
Harnesses `dev/yahoo/auth_probe.R` (OAuth2), `dev/yahoo/oauth1_probe.py` (OAuth 1.0a).

Both auth generations tested. First OAuth2-only pass was incomplete: Yahoo's own
still-published sample code (gists under `VerizonMediaOwner`, Copyright Yahoo Inc. 2017,
zLib) is OAuth 1.0a, carries no `scope` concept, incl. a two-legged consumer-key-only call to
`/fantasy/v2/game/nfl` -> had to run before any verdict. Fails too, more informatively.

| probe | status | body |
|---|---|---|
| `GET /fantasy/v2/game/nfl`, no token | 401 | `oauth_problem="unable_to_determine_oauth_type"` |
| `GET /fantasy/v2/league/449.l.1541392`, no token | 401 | identical — private league leaks nothing |
| `POST /oauth2/get_token` `grant_type=client_credentials` | 400 | `client assertion cannot be empty` — enterprise JWT flow, not ours |
| authorize URL `scope=fspt-r` | 302 | -> redirect `?error=invalid_scope` **before login** |
| authorize URL `scope=fspt-w` | 302 | -> same |
| authorize URL `scope=bogus-scope-xyz` | 302 | -> same, so curl cannot discriminate scopes |
| authorize URL `scope=openid` (control) | 200 | real consent screen, **offers only "Yahoo Auction (read/write)" + "Profile (read)"** |
| `POST /oauth2/get_token` `grant_type=authorization_code` | **200** | valid `access_token` issued, `scope` field absent |
| `GET /fantasy/v2/game/nfl` **with valid bearer token** | **401** | `oauth_problem="additional_authorization_required"` |
| **OAuth1 two-legged** `GET /fantasy/v2/game/nfl`, HMAC-SHA1 signed | **403** | **"This application is not authorized to perform this action."** |
| OAuth1 same, `format=json` | 403 | identical |
| OAuth1 `GET /oauth/v2/get_request_token` | 401 | `Unauthorized` — OAuth1 three-legged endpoint retired |

Reading. Three mechanisms, three refusals, all at the entitlement layer.

- **OAuth1 403 = strongest single datapoint.** Yahoo accepted the HMAC-SHA1 signature (bad
  signature -> signature error, not this one) -> parsed the request, identified the app by
  consumer key, refused on authorization. Yahoo's own words, via Yahoo's own sample code.
- OAuth2: token valid, entitlement absent. `fspt-r` rejected at the authorize endpoint
  *before login* -> ungrantable to self-serve apps, not merely unchecked on the form. Consent
  screen for a working `openid` flow offers only Yahoo Auction + Profile.
- Gap = entitlement layer. Not the docs, not the form UI, not OAuth version, not our code.
  `sports.yahoo.com/developer/docs/` documenting the endpoint is not evidence of access —
  endpoint exists and answers; it refuses this class of app.
- Handoff #28 §3's four gaps, all answered: (1) `fspt-r` not grantable at the authorize URL;
  (2) 401 `additional_authorization_required`, actually called; (3) private vs public moot —
  refusal precedes league resolution, public `/game/nfl` refused identically; (4) `YFAR` moot,
  wraps OAuth1, request-token endpoint 401.

## Called closed twice, wrong twice

1. **2026-09-06, inferred from the form UI.** `sports.yahoo.com/developer/docs/` documents a
   self-serve flow: "select either Read or Read/Write access for Fantasy Sports" when creating
   an app. Checkbox gone — live form at `developer.yahoo.com/apps/create` offers exactly two
   API Permissions, "OpenID Connect Permissions" and "TW Auction". App + consumer key/secret
   obtainable, nothing grants the Fantasy scope. Verdict: "do not re-investigate."
2. **2026-09-15, from the probes above.** Verdict: "CLOSED, do not re-investigate". Probes
   accurate — they prove the *app* lacks the entitlement. Conclusion wrong in scope: never
   looked for a provisioning process outside the create-app form.
3. **2026-09-16.** Found the approval form. Corrected to "blocked on a form", not "closed".
4. **Reported 2026-10-27: applied, denied — "not enough information".** Closed on a real
   answer this time — the provisioning process itself said no. User chose not to re-apply.

Same failure mode in 1 and 2: **absence of a checkbox read as absence of a path.**
