#!/usr/bin/env julia
# Live Pluto editor — backs the "Launch editable notebook ↗" links. Unlike the
# PlutoSliderServer embed (read-only, grows to fit), this is the full Pluto
# editor where cells are editable and reactive.
#
# Dev:  PLUTO_EDIT_PORT=1234 julia --project=notebooks/env notebooks/edit.jl
#
# NOTE: secrets are disabled so the site can deep-link into it. That means
# anyone who can reach this port can open/run notebooks — it is a single-kernel,
# local/demo service, NOT multi-user-safe. Do not expose it publicly without
# putting auth in front of it.

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

ENV["GKSwstype"] = "nul"
using Pluto

const HOST = get(ENV, "PLUTO_EDIT_HOST", "127.0.0.1")
const PORT = parse(Int, get(ENV, "PLUTO_EDIT_PORT", "1234"))

Pluto.run(;
    host = HOST,
    port = PORT,
    launch_browser = false,
    require_secret_for_access = false,
    require_secret_for_open_links = false,
    auto_reload_from_file = true,
)
