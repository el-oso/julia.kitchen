---
title: "Your First Plot"
description: "Draw lines, scatter plots, and histograms in three lines of code"
level: "beginner"
julia_version: "1.12"
weight: 1
categories: ["plotting"]
tags: ["plots", "line", "scatter", "histogram", "basics"]
comments: false
---

`Plots.jl` is Julia's meta-plotting library — it works with multiple backends (GR, PyPlot, Makie) and has a concise, consistent API. A single `using Plots` gives you everything covered here.

> **First run**: `using Plots` triggers compilation the first time (~10 s cold, ~0.5 s warm). Subsequent calls in the same session are instant.

## Line plot

{{< julia >}}
using Plots

x = 0:0.1:2π
y = sin.(x)

plot(x, y; label="sin(x)", xlabel="x", ylabel="y", title="Sine wave", lw=2)
{{< /julia >}}

## Scatter plot

{{< julia >}}
using Plots, Random
Random.seed!(7)

x = randn(50)
y = x .+ 0.5 .* randn(50)

scatter(x, y;
    label  = "data",
    xlabel = "x",
    ylabel = "y + noise",
    title  = "Noisy linear relationship",
    alpha  = 0.7,
    ms     = 5,
)
{{< /julia >}}

## Histogram

{{< julia >}}
using Plots, Random, Statistics
Random.seed!(42)

data = randn(1000)

histogram(data;
    bins   = 30,
    label  = "N(0,1) samples",
    xlabel = "value",
    ylabel = "count",
    title  = "Histogram (n=1000)",
    alpha  = 0.7,
    color  = :steelblue,
)
println("mean=$(round(mean(data), digits=3))  std=$(round(std(data), digits=3))")
{{< /julia >}}

## Multiple series on one plot

{{< julia >}}
using Plots

x = 0:0.05:2π

plot(x, sin.(x); label="sin", lw=2, color=:steelblue)
plot!(x, cos.(x); label="cos", lw=2, color=:crimson)
plot!(x, sin.(x) .* cos.(x); label="sin·cos", lw=2, color=:seagreen, ls=:dash)

xlabel!("x")
title!("Trig functions")
{{< /julia >}}
