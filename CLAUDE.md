# CLAUDE.md — julia.kitchen

Working notes for Claude. Keep this current when architecture or conventions change.

## What this is

A Julia tutorial site (à la the Rust Book) with runnable, interactive code
examples. Domain `julia.kitchen` is owned; no host yet (develop locally).
Static site is built with Hugo; interactivity is provided by live Julia
backends. See `Julia.kitchen.md` (in the parent dir) for the requirements.

## Toolchain

- **Julia 1.12** (latest stable), managed by **juliaup** — `julia` resolves to the
  `release` channel. Always target latest stable; do not pin to 1.10.
- **Hugo** binary at `/home/el_oso/go/bin/hugo` (not always on PATH).
- **Go 1.25** for the runner.

## Architecture: one static site + three live interactive backends

The site is static HTML. Interactivity comes from three independent services —
**all three are intentionally kept; they cover different use cases** (user
confirmed). Pick by use case; don't assume one replaces the others.

| Backend | Port | Use case | Hugo shortcode |
|---|---|---|---|
| **Go runner** | 8080 | Stateless "run snippet → return PNG"; cheapest (also powers the Run buttons) | `{{< runner-slider >}}`, `{{< julia >}}` |
| **BonitoBook + WGLMakie** | 8773 | Client-side WebGL graphics interaction (3D/pan/zoom); Makie workflow | `{{< bonitobook "name" >}}` |
| **Pluto + PlutoSliderServer** | 2345 | Familiar reactive notebook; multi-cell state | `{{< notebook "name" >}}` |

All three need a live Julia process for the *compute* step. See
`content/recipes/numerics/interactive-comparison.md` for the side-by-side.

## Running it locally

```bash
# Hugo dev server
/home/el_oso/go/bin/hugo server --port 1313 --bind 0.0.0.0 --disableFastRender

# Go runner (rate 0 = no per-IP limit, for dev). Prod default is 5 req/min.
cd runner && go build -o runner_bin . && \
  ./runner_bin -pool 2 -rate 0 -script ./julia/bin/worker.jl

# Pluto slider server — read-only embeds, grow-to-fit (first run is slow)
PLUTO_PORT=2345 julia --project=notebooks/env notebooks/serve.jl

# Bonito server — compact App, editable y-formula + WGLMakie
BONITO_PORT=8773 julia --project=notebooks/bonito/env notebooks/bonito/serve.jl

# Live Pluto editor — backs the "Launch editable notebook" links (single-kernel,
# secrets disabled → local/demo only, NOT multi-user-safe)
PLUTO_EDIT_PORT=1234 julia --project=notebooks/env notebooks/edit.jl
```

Health checks: `curl localhost:8080/health`, `curl -sI localhost:2345/`,
`curl -sI localhost:8773/broadcasting`, `curl -sI localhost:1234/`.

The runner/Pluto/Bonito server URLs are configurable via `window.JULIA_RUNNER_URL`
and Hugo params `sliderServerURL` / `bonitoServerURL` (dev defaults are localhost).
**In production these two iframe URLs must be HTTPS** or the browser blocks them
as mixed content.

## Validating recipes (regression guard)

Every `{{< julia >}}` block must run without error.

```bash
# All recipes (CI mode)
GKSwstype=nul julia --project=ci ci/run_examples.jl
# Just specific files (fast; used by the pre-push hook)
GKSwstype=nul julia --project=ci ci/run_examples.jl content/recipes/basics/variables.md
```

- CI (`.github/workflows/ci.yml`) runs this on every push/PR (jobs: validate, go, docker, build).
- A tracked **pre-push hook** runs it on changed recipes. Activate with
  `git config core.hooksPath .githooks` (already set in this clone).

## Conventions / gotchas

- **Code cells are a single editable panel**: a transparent `<textarea class="julia-editor">`
  overlaid on a highlighted `<pre class="julia-highlight">`, synced in `runner.js`.
  `runner.js` owns all highlighting (don't re-add an inline hljs loop in baseof).
- **Assets are fingerprinted** via Hugo's pipeline (`resources.Get | minify | fingerprint`).
  Put JS/CSS in `themes/julia-kitchen/assets/`, not `static/` — `static/` has no cache-busting.
- **No Binder links anywhere.** PlutoSliderServer runs with `Export_offer_binder=false`.
- **Plots run headless**: `GKSwstype=nul` + `GR_NO_DISPLAY=true` set before Julia
  starts (worker.jl, CI env). Never spawn a GR/Qt window.
- **Plot capture**: the runner auto-captures the current Plots figure as a base64
  PNG only when a cell produced a *new* figure (objectid snapshot before/after) —
  prevents stale plots leaking onto non-plot cells on shared workers.
- **Worker isolation**: each cell runs in a fresh `Module`; shared package globals
  (Plots theme, RNG) are reset before each eval so state can't bleed between users.
- **Julia stdlibs get NO `[compat]` bound** (they track the Julia version) — a
  `Base64 = "1.11.0"` bound once broke the Docker build on a different Julia.
- **Manifests are gitignored** (`runner/julia`, notebook envs); Docker resolves fresh.

## Git

- End commit messages with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- **Do not push to `main`** — it's a soft block; the user pushes. Commit freely.

## Content

- Sources in `CONTENT_SOURCES.md` (paraphrase, never copy verbatim).
- New recipes: copy `RECIPE_TEMPLATE.md` → `content/recipes/<section>/<slug>.md`;
  `julia_version: "1.12"`; each `{{< julia >}}` block must be self-contained and pass CI.
- Sections: basics/, numerics/, plotting/.

## Search (Pagefind)

- Recipe search is built with **Pagefind**. The nav has a search box → `/search/`
  (layout `_default/search.html`, content `content/search.md`); `?q=` deep-links
  prefill the query.
- Index scope: recipe single pages carry `data-pagefind-body`; interactive
  widgets (editor textarea, output, embeds) carry `data-pagefind-ignore`. The
  visible highlighted code stays indexed.
- **The index is generated by Pagefind over the BUILT site**, so search does NOT
  work under `hugo server` — build first: `./build.sh` (runs `hugo --minify`
  then `npx pagefind --site public`), then serve `public/`. CI does this in the
  build job. The generated `public/pagefind/` is a build artifact (gitignored).
