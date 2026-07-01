# julia.kitchen

## Run locally

```bash
/home/el_oso/go/bin/hugo server --port 1313 --bind 0.0.0.0 --disableFastRender
```

Then open http://localhost:1313.

This serves the static site only. Code cells that run against a live Julia
backend (Run buttons, Pluto/Bonito embeds) need the runner/notebook servers
too — see `CLAUDE.md` for those commands.
