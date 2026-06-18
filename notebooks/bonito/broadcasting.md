# Broadcasting — BonitoBook + WGLMakie

Julia's dot broadcast applies a function element-wise. Drag the sliders: the `freq.value` / `phase.value` observables feed a `map` that recomputes `sin.(freq .* x .+ phase)` in **Julia**, and WGLMakie streams the updated line to the browser over a websocket.

```julia (editor=true, logging=false, output=true)
using WGLMakie, Bonito

freq  = Components.Slider(0.5:0.5:5.0)
phase = Components.Slider(0.0:0.1:2π)

x = LinRange(0, 2π, 300)

# map over the slider observables → recomputed in Julia on every change
ys = map(freq.value, phase.value) do f, p
    sin.(f .* x .+ p)
end

fig, ax, _ = lines(x, ys; color = :steelblue, linewidth = 3, figure = (; size = (680, 300)))
ax.title = "Broadcasting (BonitoBook + WGLMakie)"
ax.xlabel = "x"; ax.ylabel = "y"
ylims!(ax, -1.2, 1.2)

DOM.div(
    DOM.div("frequency: ", freq),
    DOM.div("phase: ", phase),
    fig,
)
```
