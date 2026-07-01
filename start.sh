#!/usr/bin/env bash
# Start all local dev servers: Hugo, Go runner, Pluto slider, Bonito, live
# Pluto editor. Logs go to ./log/<name>.log, PIDs to ./log/<name>.pid.
#
# Usage: ./start.sh        # start everything
#        ./stop.sh         # stop everything
set -euo pipefail
cd "$(dirname "$0")"

command -v hugo >/dev/null 2>&1 || export PATH="$HOME/go/bin:$PATH"

mkdir -p log

start() {
  local name="$1"; shift
  local pidfile="log/$name.pid"
  if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    echo "$name already running (pid $(cat "$pidfile"))"
    return
  fi
  nohup "$@" > "log/$name.log" 2>&1 &
  echo $! > "$pidfile"
  echo "started $name (pid $!) -> log/$name.log"
}

# Wait for a server to answer before starting the next one. Julia backends
# (Pluto/Bonito) precompile heavy package stacks on first run; starting them
# concurrently makes them fight for RAM and swap instead of finishing sooner.
wait_healthy() {
  local name="$1" url="$2" timeout="${3:-600}" waited=0
  until curl -s --max-time 2 -o /dev/null "$url"; do
    sleep 5; waited=$((waited + 5))
    if (( waited >= timeout )); then
      echo "$name: still not responding after ${timeout}s, moving on (see log/$name.log)"
      return
    fi
  done
  echo "$name: ready after ${waited}s"
}

start hugo hugo server --port 1313 --bind 0.0.0.0 --disableFastRender

(cd runner && go build -o runner_bin .)
start runner ./runner/runner_bin -pool 2 -rate 0 -script ./runner/julia/bin/worker.jl
wait_healthy runner http://localhost:8080/health 60

start pluto env PLUTO_PORT=2345 julia --project=notebooks/env notebooks/serve.jl
wait_healthy pluto http://localhost:2345/

start bonito env BONITO_PORT=8773 julia --project=notebooks/bonito/env notebooks/bonito/serve.jl
wait_healthy bonito http://localhost:8773/broadcasting

start pluto-edit env PLUTO_EDIT_PORT=1234 julia --project=notebooks/env notebooks/edit.jl
wait_healthy pluto-edit http://localhost:1234/

cat <<'EOF'

All servers launching (Pluto/Bonito take a while to precompile on first run).
Health checks:
  curl localhost:1313/                  # Hugo
  curl localhost:8080/health            # Go runner
  curl -sI localhost:2345/              # Pluto slider server
  curl -sI localhost:8773/broadcasting  # Bonito
  curl -sI localhost:1234/              # live Pluto editor
Tail a log:      tail -f log/pluto.log
Stop everything: ./stop.sh
EOF
