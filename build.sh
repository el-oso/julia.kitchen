#!/usr/bin/env bash
# Production build: render the static site, then generate the Pagefind search
# index over the output. Serve ./public after this (Pagefind needs the built
# site; the index does not exist under `hugo server`).
#
# Usage: ./build.sh
set -euo pipefail

cd "$(dirname "$0")"

# hugo may live in ~/go/bin locally (it's on PATH in CI).
command -v hugo >/dev/null 2>&1 || export PATH="$HOME/go/bin:$PATH"

hugo --minify

# Pagefind indexes the built HTML and writes public/pagefind/.
npx -y pagefind@latest --site public

echo "Built site + search index in ./public  (try: npx -y serve public)"
