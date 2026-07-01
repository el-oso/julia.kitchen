#!/usr/bin/env bash
# Stop servers started by ./start.sh.
set -euo pipefail
cd "$(dirname "$0")"

shopt -s nullglob
for pidfile in log/*.pid; do
  name="$(basename "$pidfile" .pid)"
  pid="$(cat "$pidfile")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "stopped $name (pid $pid)"
  fi
  rm -f "$pidfile"
done
