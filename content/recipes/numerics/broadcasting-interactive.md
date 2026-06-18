---
title: "Broadcasting — Interactive"
description: "Explore how frequency and phase transform sin waves with live sliders"
level: "beginner"
julia_version: "1.12"
weight: 5
categories: ["numerics"]
tags: ["broadcasting", "interactive", "pluto", "visualisation"]
comments: false
---

This is an interactive Pluto notebook exploring the broadcasting dot-syntax with a live plot. Use the sliders to change the frequency and phase of a sine wave and see the `sin.(freq .* x .+ phase)` expression update in real time.

<div class="notebook-embed">
  <iframe
    src="/notebooks/broadcasting_slider.html"
    title="Broadcasting interactive demo"
    loading="lazy"
    sandbox="allow-scripts allow-same-origin">
  </iframe>
</div>

## What's happening under the hood

The notebook uses `@bind` from **PlutoUI.jl** to connect HTML sliders to Julia variables. Every time a slider moves, Pluto re-evaluates all cells that depend on it.

The key expression is:

```julia
y = sin.(freq .* x .+ phase)
```

The dots broadcast across all 300 elements of `x` in a single fused loop. No explicit `for`, no temporary arrays. See the [Broadcasting recipe](/recipes/numerics/broadcasting/) for the full story.

> **Pre-baked export**: This notebook is exported statically with [PlutoSliderServer.jl](https://github.com/JuliaPluto/PlutoSliderServer.jl) — every slider position is pre-computed and bundled as JSON. No live Julia server required.
