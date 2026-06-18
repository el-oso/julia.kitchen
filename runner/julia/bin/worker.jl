# Prevent GR (Plots.jl default backend) from trying to open a display window.
# Must be set before `using Plots` runs anywhere in the process.
ENV["GKSwstype"] = "nul"
ENV["GR_NO_DISPLAY"] = "true"

using JuliaRunner
JuliaRunner.serve()
