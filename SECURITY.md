# Security model — julia.kitchen

The interactive features execute Julia code. This documents what runs untrusted
input, how it's contained, and what is safe to expose publicly.

## The three execution backends

| Backend | Runs visitor input? | Containment | Safe to expose? |
|---|---|---|---|
| **Go runner** (`:8080`) | Yes (Run buttons, slider demos) | Sandboxed — see below | **Yes**, behind the hardened deploy |
| **Bonito editor** (`:8773`) | Yes (editable `y=` formula, `eval`) | None — in-process `eval` | **No** — local/trusted only |
| **Pluto editor** (`:1234`) | Yes (full editable notebook) | None — secrets disabled, single kernel | **No** — local/trusted only |

The read-only Pluto **slider** server (`:2345`) runs the *notebook author's* code,
not visitor input, so it is not in the visitor-input threat model.

## Go runner — how it's contained

Defense in depth (`runner/`):

- **Per-cell isolation**: each cell runs in a fresh anonymous `Module`; shared
  package globals (Plots theme, RNG) are reset before every eval.
- **Environment isolation**: workers get a minimal allowlisted environment
  (`worker.go` `workerEnv()`) — host env vars (API keys, tokens) are **not**
  visible to user code. `JULIA_NUM_THREADS=1`.
- **Output cap**: stdout/stderr are truncated to 32 KB (`MAX_OUTPUT_BYTES`),
  bounding response size/memory.
- **Time + lifecycle limits**: per-exec timeout kills the worker; workers are
  recycled after `-max-uses`; request body capped at 64 KB.
- **Rate limiting**: per-IP (`-rate`, default 5/min).
- **Container** (`runner/docker-compose.yml`): non-root, `cap_drop: ALL`,
  `no-new-privileges`, **read-only root FS** (Julia precompile goes to a tmpfs
  depot layered over the baked read-only depot), tmpfs `/tmp`, memory/CPU/PID
  limits, and an **internal network with no internet egress** — user code can't
  phone home. The edge Caddy proxy terminates TLS and is the only thing that can
  reach the runner.

This is defense in depth, **not a perfect jail**. For stronger isolation run the
runner under gVisor (`runsc`) or per-eval microVMs.

## Bonito / Pluto editors — why they're gated

Both `eval` arbitrary visitor code **with no sandbox, timeout, or rate limit**,
in the server process. They must not face the public internet as-is.

They are gated in the templates: the editable Bonito embed and the
"Launch editable notebook" link render **only** under `hugo server` (local dev)
or when `params.enableLiveEditors = true` is set explicitly. A normal production
build (`hugo --minify`) hides them and shows a placeholder.

To expose them later, they need the same treatment as the Go runner: a
locked-down container (read-only FS, dropped caps, no egress, resource limits)
**plus** auth in front of the Pluto editor (it is single-kernel and not
multi-user-safe — e.g. Cloudflare Access / basic auth), or ephemeral per-session
sandboxes.

## Production checklist

- [ ] Serve the iframed services over **HTTPS** (mixed-content otherwise).
- [ ] Point `JULIA_RUNNER_URL` / `sliderServerURL` at the hardened hosts.
- [ ] Keep `enableLiveEditors` unset/false in the production config.
- [ ] Put the runner behind the Caddy proxy on the internal (egress-blocked) net.
- [ ] Consider gVisor/microVM isolation and a WAF/Cloudflare in front.
