#!/usr/bin/env julia
# Runs a live PlutoSliderServer for the Pluto notebooks in notebooks/src/.
#
# It runs each notebook, serves the exported HTML, and answers @bind slider
# requests on the same origin — so the embedded notebooks are fully interactive
# (every slider position is recomputed live, at full resolution). The Binder
# "Edit or run" link is disabled (Export_offer_binder = false).
#
# Dev:   PLUTO_PORT=2345 julia --project=notebooks/env notebooks/serve.jl
# Prod:  PLUTO_HOST=0.0.0.0 PLUTO_PORT=2345 julia --project=notebooks/env notebooks/serve.jl
#        (behind TLS — see notebooks/Dockerfile and the deployment notes)

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

using PlutoSliderServer

const SRC_DIR = joinpath(@__DIR__, "src")
const OUT_DIR = joinpath(dirname(@__DIR__), "static", "notebooks")
mkpath(OUT_DIR)

PlutoSliderServer.run_directory(
    SRC_DIR;
    SliderServer_enabled  = true,
    SliderServer_host     = get(ENV, "PLUTO_HOST", "127.0.0.1"),
    SliderServer_port     = parse(Int, get(ENV, "PLUTO_PORT", "2345")),
    # The slider server also serves the static HTML exports, so the iframe can
    # point straight at it and @bind requests stay same-origin.
    SliderServer_serve_static_export_folder = true,
    # broadcasting_demo.jl is a Bonito app, not a Pluto notebook — skip it.
    SliderServer_exclude  = ["broadcasting_demo.jl"],
    Export_enabled        = true,
    Export_offer_binder   = false,   # ← removes the Binder link from exports
    Export_output_dir     = OUT_DIR,
)
