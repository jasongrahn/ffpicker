# Yahoo OAuth probe. Dev only. Never sourced by targets or the app.
#
# Purpose: settle handoff #28 s3 gap (1) -- is the Fantasy Sports scope
# grantable at the authorize URL even though the create-app form never
# offers it? Only a real consent screen answers this. curl cannot: Yahoo
# returns 302 for a bogus scope too, so it defers scope validation until
# after login.
#
# Secrets come from .Renviron via Sys.getenv(). Never literal here.
# .Renviron is gitignored. This file is not -- keep it value-free.

yahoo_creds <- function() {
  v <- c("YAHOO_CLIENT_ID", "YAHOO_CLIENT_SECRET", "YAHOO_REDIRECT_URI")
  x <- stats::setNames(Sys.getenv(v), v)
  if (any(!nzchar(x))) {
    stop("missing in .Renviron: ", paste(v[!nzchar(x)], collapse = ", "))
  }
  as.list(x)
}

# Build the 3-legged authorize URL. scope: "fspt-r" read, "fspt-w" read/write.
yahoo_auth_url <- function(scope = "fspt-r", state = "probe") {
  cr <- yahoo_creds()
  paste0(
    "https://api.login.yahoo.com/oauth2/request_auth",
    "?client_id=", utils::URLencode(cr$YAHOO_CLIENT_ID, reserved = TRUE),
    "&redirect_uri=", utils::URLencode(cr$YAHOO_REDIRECT_URI, reserved = TRUE),
    "&response_type=code",
    "&scope=", utils::URLencode(scope, reserved = TRUE),
    "&state=", utils::URLencode(state, reserved = TRUE)
  )
}

# Open consent screen in the default browser. Read what it asks to grant.
yahoo_open_consent <- function(scope = "fspt-r") {
  utils::browseURL(yahoo_auth_url(scope))
  invisible(TRUE)
}

# Exchange the code from the redirect URL bar for a token.
# Redirect is https://127.0.0.1:7645/ -- nothing listens there, browser shows
# a connection error. The code is still in the URL bar. Copy it, paste here.
yahoo_exchange <- function(code) {
  cr <- yahoo_creds()
  resp <- httr2::request("https://api.login.yahoo.com/oauth2/get_token") |>
    httr2::req_auth_basic(cr$YAHOO_CLIENT_ID, cr$YAHOO_CLIENT_SECRET) |>
    httr2::req_body_form(
      grant_type   = "authorization_code",
      redirect_uri = cr$YAHOO_REDIRECT_URI,
      code         = code
    ) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()

  list(status = httr2::resp_status(resp), body = httr2::resp_body_json(resp))
}

# Hit the Fantasy API with a bearer token. Returns status + body, never throws,
# so a 401/403 is data rather than an exception.
yahoo_get <- function(token, path = "game/nfl") {
  resp <- httr2::request("https://fantasysports.yahooapis.com/fantasy/v2") |>
    httr2::req_url_path_append(path) |>
    httr2::req_url_query(format = "json") |>
    httr2::req_auth_bearer_token(token) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()

  list(status = httr2::resp_status(resp), body = httr2::resp_body_string(resp))
}
