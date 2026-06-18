---
title: "Plot Customisation"
description: "Colours, markers, line styles, fonts, themes, and annotations"
level: "beginner"
julia_version: "1.12"
weight: 3
categories: ["plotting"]
tags: ["plots", "styling", "themes", "annotations", "colours"]
comments: false
---

Plots.jl accepts keyword arguments for virtually every visual property.

## Line styles and markers

{{< julia >}}
using Plots

x = 1:10

plot(x, x;         lw=3, ls=:solid,   marker=:circle,  label="solid/circle")
plot!(x, x .+ 3;  lw=2, ls=:dash,    marker=:square,  label="dashed/square")
plot!(x, x .+ 6;  lw=2, ls=:dot,     marker=:diamond, label="dotted/diamond")
plot!(x, x .+ 9;  lw=2, ls=:dashdot, marker=:star5,   label="dashdot/star")

title!("Line and marker styles")
{{< /julia >}}

## Colours

Named colours, hex codes, and RGB all work:

{{< julia >}}
using Plots

x = 1:5
bar(x, x .^ 2;
    color  = [:steelblue, :crimson, :seagreen, "#ff7f0e", RGB(0.5, 0.1, 0.8)],
    label  = nothing,
    title  = "Five ways to specify colour",
    xlabel = "x",
    ylabel = "x²",
)
{{< /julia >}}

## Themes

{{< julia >}}
using Plots

x = 0:0.05:2π

# Show four themes side by side
plots = map([:default, :dark, :ggplot2, :gruvbox_dark]) do t
    theme(t)
    plot(x, sin.(x); label="sin(x)", title="theme :$t", lw=2)
end
theme(:default)

plot(plots...; layout=(2,2), size=(700, 500))
{{< /julia >}}

## Annotations

{{< julia >}}
using Plots

x = 0:0.1:2π
y = sin.(x)

idx_max = argmax(y)

plot(x, y; lw=2, label="sin(x)", xlabel="x", ylabel="y")

scatter!([x[idx_max]], [y[idx_max]];
    label=nothing, markersize=8, markercolor=:crimson)

annotate!(x[idx_max] + 0.3, y[idx_max] - 0.15,
    text("peak at x=$(round(x[idx_max], digits=2))", 9, :left))

hline!([0]; ls=:dash, color=:gray, label=nothing)
title!("Annotated sine")
{{< /julia >}}

## Font and axis control

{{< julia >}}
using Plots

plot(1:5, (1:5).^2;
    title         = "Quadratic",
    titlefontsize = 14,
    xlabel        = "n",
    ylabel        = "n²",
    guidefontsize = 12,
    tickfontsize  = 10,
    xticks        = 1:5,
    yticks        = 0:5:25,
    ylims         = (0, 27),
    grid          = true,
    gridstyle     = :dot,
    lw            = 2,
    label         = "n²",
)
{{< /julia >}}
