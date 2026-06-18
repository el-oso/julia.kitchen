---
title: "Subplots and Layouts"
description: "Arrange multiple plots side-by-side or in a grid with the layout keyword"
level: "beginner"
julia_version: "1.10"
weight: 2
categories: ["plotting"]
tags: ["plots", "subplots", "layout", "grid"]
comments: false
---

Plots.jl composes multiple panels with a single `layout` argument — no figure/axes management needed.

## Side by side

{{< julia >}}
using Plots

x = 0:0.05:2π

p1 = plot(x, sin.(x);  title="sin(x)", label=nothing, color=:steelblue)
p2 = plot(x, cos.(x);  title="cos(x)", label=nothing, color=:crimson)

plot(p1, p2; layout=(1,2), size=(700, 280))
savefig("/tmp/side_by_side.png")
println("Saved to /tmp/side_by_side.png")
{{< /julia >}}

## 2×2 grid

{{< julia >}}
using Plots, Random
Random.seed!(1)

p1 = histogram(randn(500);  title="Normal",    bins=20, label=nothing)
p2 = histogram(rand(500);   title="Uniform",   bins=20, label=nothing)
p3 = histogram(randexp(500);title="Exponential",bins=20, label=nothing)
p4 = histogram(abs.(randn(500)); title="|Normal|", bins=20, label=nothing)

plot(p1, p2, p3, p4; layout=(2,2), size=(700, 500))
savefig("/tmp/grid.png")
println("Saved to /tmp/grid.png")
{{< /julia >}}

## Shared axis

{{< julia >}}
using Plots

x = 1:20
y1 = cumsum(randn(20))
y2 = cumsum(randn(20))

plot(x, [y1 y2];
    layout    = (2, 1),
    label     = ["series A" "series B"],
    xlabel    = ["" "time"],
    ylabel    = ["value" "value"],
    link      = :x,
    size      = (650, 400),
)
savefig("/tmp/shared_axis.png")
println("Saved to /tmp/shared_axis.png")
{{< /julia >}}

## Inset (plot-within-plot)

{{< julia >}}
using Plots

x = 0:0.01:2π
y = sin.(x)

main = plot(x, y; label="sin(x)", lw=2, title="Full range")
inset_plot = plot(x[1:30], y[1:30]; label=nothing, lw=2, color=:crimson, title="Zoom")

plot(main; inset=(1, bbox(0.55, 0.05, 0.4, 0.4)))
plot!(inset_plot; subplot=2)
savefig("/tmp/inset.png")
println("Saved to /tmp/inset.png")
{{< /julia >}}
