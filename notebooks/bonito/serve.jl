#!/usr/bin/env julia
# Serves the BonitoBook book (WGLMakie + sliders) over HTTP, headless.
# The book is reactive via a live Julia session — moving a slider recomputes
# in Julia and WGLMakie streams the update over a websocket.
#
# Dev:  BONITO_PORT=8773 julia --project=notebooks/bonito/env notebooks/bonito/serve.jl
# Route: http://<host>:<port>/broadcasting

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

ENV["GKSwstype"] = "nul"          # headless, just in case GR is pulled in
using BonitoBook

const HOST = get(ENV, "BONITO_HOST", "127.0.0.1")
const PORT = parse(Int, get(ENV, "BONITO_PORT", "8773"))

server = BonitoBook.book(
    joinpath(@__DIR__, "broadcasting.md");
    url         = HOST,
    port        = PORT,
    openbrowser = false,
)

println("BonitoBook serving on http://$HOST:$PORT/broadcasting")
flush(stdout)

# book() returns once the route is registered; keep the process alive to serve.
wait(Condition())
