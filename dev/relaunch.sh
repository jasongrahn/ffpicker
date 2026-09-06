#!/usr/bin/env bash
#
# Relaunch the draft app on a clean Pick Log, for inspecting board/run-guide
# changes. Every relaunch during development has to start from an empty log,
# or leftover picks from the last look silently skew need counts and
# picks-until-turn -- the two inputs the whole run guide is built on.
#
#   dev/relaunch.sh              # empty log, app opens on the setup form
#   dev/relaunch.sh --slot 5     # log pre-seeded as a started 10-team draft
#                                # at slot 5, app opens straight on the board
#   dev/relaunch.sh --force      # wipe even when data/DRAFT_IS_LIVE exists
#   dev/relaunch.sh --no-wipe    # restart the server, keep the log as-is
#
# SAFETY. Wiping is the normal QA path and is never questioned. Two mechanisms
# instead, neither of which fires during development:
#
#   * the current log is always archived to dev/pick_log_archive/ first,
#     timestamped, whatever else happens. This is the real net -- it is
#     lossless, so a mistaken wipe costs one copy command to undo.
#   * if data/DRAFT_IS_LIVE exists, wiping is refused without --force.
#
# The marker is deliberate rather than inferred. An earlier version guessed
# from pick count -- more than 10 picks meant "probably the real draft" -- and
# immediately blocked a routine 16-pick QA run. Pick count cannot tell a long
# QA session from a live draft, because they look identical. `touch
# data/DRAFT_IS_LIVE` on draft night, delete it afterwards.

set -euo pipefail

PORT=7645

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log_path="$root/data/pick_log.jsonl"
archive_dir="$root/dev/pick_log_archive"
app_log="/tmp/ffdraft_app.log"

slot=""
force=0
wipe=1

while [ $# -gt 0 ]; do
  case "$1" in
    --slot)     slot="${2:?--slot needs a number}"; shift 2 ;;
    --force)    force=1; shift ;;
    --no-wipe)  wipe=0; shift ;;
    -h|--help)  sed -n '2,28p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)          echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# --- archive whatever is there now, before anything else ------------------
mkdir -p "$archive_dir"
if [ -s "$log_path" ]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  cp "$log_path" "$archive_dir/pick_log-$stamp.jsonl"
  echo "archived current log -> dev/pick_log_archive/pick_log-$stamp.jsonl"
fi

# --- refuse only when explicitly told the draft is live -------------------
if [ "$wipe" -eq 1 ] && [ -e "$root/data/DRAFT_IS_LIVE" ] && [ "$force" -eq 0 ]; then
  cat >&2 <<EOF

REFUSING TO WIPE. data/DRAFT_IS_LIVE exists, so this log is the real draft.

A copy is safe in dev/pick_log_archive/ either way. To wipe anyway, re-run
with --force. When the draft is over, delete data/DRAFT_IS_LIVE.

EOF
  exit 1
fi

# --- stop the running server ---------------------------------------------
# plain `pkill -f runApp` does not kill it; port lookup does.
if lsof -ti ":$PORT" >/dev/null 2>&1; then
  lsof -ti ":$PORT" | xargs kill -9
  echo "stopped app on port $PORT"
fi

# --- reset the log --------------------------------------------------------
if [ "$wipe" -eq 1 ]; then
  if [ -n "$slot" ]; then
    # Seed a started draft so the app skips the setup form. my_slot drives
    # picks_until_turn, which drives every "survives / TAKE NOW" call in the
    # run guide -- so inspecting the guide at all requires a slot.
    printf '{"type":"draft_started","teams":10,"my_team":"JGrahnasaurs","my_slot":%s}\n' \
      "$slot" > "$log_path"
    echo "pick log reset: started 10-team draft, slot $slot"
  else
    : > "$log_path"
    echo "pick log reset: empty (app will show the setup form)"
  fi
else
  echo "pick log left as-is (--no-wipe)"
fi

# --- launch --------------------------------------------------------------
cd "$root"
(nohup Rscript -e "shiny::runApp('inst/app', port = $PORT, launch.browser = FALSE)" \
  > "$app_log" 2>&1 & disown)

# Wait for the port to actually accept connections rather than printing a URL
# that 404s for another few seconds.
for _ in $(seq 1 40); do
  if lsof -ti ":$PORT" >/dev/null 2>&1; then
    echo "app ready -> http://127.0.0.1:$PORT"
    exit 0
  fi
  sleep 0.5
done

echo "app did not come up within 20s; last lines of $app_log:" >&2
tail -20 "$app_log" >&2
exit 1
