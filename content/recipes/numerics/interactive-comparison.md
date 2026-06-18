---
title: "Interactive: Three Ways"
description: "The same broadcasting demo built with Pluto, BonitoBook+WGLMakie, and the Go runner — compared"
level: "intermediate"
julia_version: "1.12"
weight: 6
categories: ["numerics"]
tags: ["interactive", "pluto", "bonito", "wglmakie", "comparison"]
comments: false
---

The same interactive demo — `sin.(freq .* x .+ phase)` with two sliders — built
three different ways. Each takes a different path to "drag a slider, see the
plot change," with different tradeoffs in hosting, latency, and how the plot is
rendered.

## 1. Pluto + PlutoSliderServer

A real Pluto notebook served by a live PlutoSliderServer. Moving a slider sends
the bound values to the server, which re-runs the dependent cells and returns
the new state. Plot is a server-rendered GR PNG.

{{< notebook "broadcasting_slider" "Broadcasting — Pluto" >}}

## 2. Bonito + WGLMakie

A Bonito `App` (the same stack BonitoBook is built on, without the notebook
chrome). **Edit the `y =` formula and hit Run** — it's recompiled in Julia and
the plot updates. The slider `.value` observables feed a `map` that recomputes
in Julia; **WGLMakie** renders in the browser with WebGL and streams updates
over a websocket — so panning/zooming the axis is also client-side interactive.

{{< bonitobook "broadcasting" "Broadcasting — Bonito + WGLMakie" >}}

## 3. Go runner

No notebook framework. A slider's `input` event substitutes its value into a
plain Julia snippet, which is POSTed to the Go runner's worker pool; the worker
returns a base64 PNG that swaps into an `<img>`. Same backend as the editable
[Run](/recipes/plotting/first-plot/) cells.

{{< runner-slider >}}

## How they compare

| | Pluto + SliderServer | Bonito + WGLMakie | Go runner |
|---|---|---|---|
| Backend | Live Julia (Pluto) | Live Julia (Bonito) | Go pool of Julia workers |
| Reactivity | Server re-runs cells | Julia observables + WebGL | Re-POST snippet per change |
| Plot rendering | GR PNG (server) | WebGL (browser) | GR PNG (server) |
| Client-only interaction | No | Yes (pan/zoom/rotate) | No |
| State between cells | Yes (notebook) | Yes (session) | No (stateless cells) |
| Hosting | PlutoSliderServer process | Bonito server process | Go binary + workers (already deployed) |
| Authoring | `.jl` Pluto notebook | Bonito `App` (Julia) | Markdown shortcode + snippet |

**Rough take:** the Go runner is the lightest to host (it's already serving the
Run buttons) and best when each interaction is an independent computation.
Bonito + WGLMakie shines when you want true client-side graphics interaction
(3D, pan/zoom) and an ecosystem-first Makie workflow. Pluto is the most familiar
reactive-notebook experience. All three need a live Julia backend for the
*compute* step here — only WGLMakie adds extra interaction without round-tripping
to Julia.

> **Running locally**: this page needs three services up — the Go runner
> (`:8080`), PlutoSliderServer (`:2345`), and the Bonito server (`:8773`). See
> each service's `serve.jl` / run command.
