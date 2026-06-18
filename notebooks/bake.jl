#!/usr/bin/env julia
# Bakes all Bonito apps in notebooks/src/ to static HTML in static/notebooks/.
# Run: julia --project=notebooks/env notebooks/bake.jl

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

src_dir = joinpath(@__DIR__, "src")
out_dir = joinpath(dirname(@__DIR__), "static", "notebooks")
mkpath(out_dir)

scripts = filter(f -> endswith(f, ".jl"), readdir(src_dir; join=true))

for script in scripts
    println("Baking: ", basename(script))
    ENV["BONITO_OUT"] = out_dir
    try
        include(script)
        println("  ✓")
    catch e
        println("  ✗ ", sprint(showerror, e))
    end
end

println("\nDone — output in: ", out_dir)
