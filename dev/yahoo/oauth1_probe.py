#!/usr/bin/env python3
"""OAuth 1.0a probe against Yahoo Fantasy, per Yahoo's own 2017 gist samples.

Two-legged: consumer key/secret only, HMAC-SHA1, params in query string.
Also probes the OAuth1 request-token endpoint (three-legged step 1).
Prints status codes and bodies. Never prints the key or secret.
"""
import hashlib
import hmac
import os
import random
import time
import urllib.parse
import urllib.request

KEY = os.environ["YAHOO_CLIENT_ID"]
SECRET = os.environ["YAHOO_CLIENT_SECRET"]


def sign(method, url, params, token_secret=""):
    """RFC5849 signature base string -> HMAC-SHA1 -> base64."""
    import base64
    enc = lambda s: urllib.parse.quote(str(s), safe="~")
    param_string = "&".join(
        f"{enc(k)}={enc(v)}" for k, v in sorted(params.items())
    )
    base = f"{method}&{enc(url)}&{enc(param_string)}"
    signing_key = f"{enc(SECRET)}&{enc(token_secret)}"
    digest = hmac.new(signing_key.encode(), base.encode(), hashlib.sha1).digest()
    return base64.b64encode(digest).decode()


def oauth_params(extra=None):
    p = {
        "oauth_consumer_key": KEY,
        "oauth_nonce": str(random.randint(0, 999999)),
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": str(int(time.time())),
        "oauth_version": "1.0",
    }
    if extra:
        p.update(extra)
    return p


def call(label, url, extra=None, method="GET"):
    params = oauth_params(extra)
    params["oauth_signature"] = sign(method, url, params)
    full = url + "?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(full, timeout=20) as r:
            status, body = r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        status, body = e.code, e.read().decode("utf-8", "replace")
    except Exception as e:  # noqa: BLE001
        status, body = "ERR", f"{type(e).__name__}: {e}"
    body = body.replace(KEY, "<KEY>").replace(SECRET, "<SECRET>")
    print(f"=== {label}\nHTTP {status}\n{body[:400]}\n")


# 1. Two-legged call, exactly the gist's endpoint.
call("two-legged /fantasy/v2/game/nfl",
     "https://fantasysports.yahooapis.com/fantasy/v2/game/nfl")

# 2. Same, JSON format.
call("two-legged /fantasy/v2/game/nfl?format=json",
     "https://fantasysports.yahooapis.com/fantasy/v2/game/nfl",
     extra={"format": "json"})

# 3. OAuth1 three-legged step 1: request token (gists 1 and 2).
call("oauth1 get_request_token",
     "https://api.login.yahoo.com/oauth/v2/get_request_token",
     extra={"oauth_callback": "oob"})
