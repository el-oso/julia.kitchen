#!/usr/bin/env julia
# Serves a compact Bonito + WGLMakie demo: the source code, two sliders, and a
# live WGLMakie figure. Reactive via a live Julia session — moving a slider
# recomputes in Julia and WGLMakie streams the update over a websocket.
#
# It is a plain Bonito App (no notebook chrome) so the embed sizes to its
# content and reports its height to the parent page (no inner scrollbar).
#
# Dev:  BONITO_PORT=8773 julia --project=notebooks/bonito/env notebooks/bonito/serve.jl
# Route: http://<host>:<port>/broadcasting

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

ENV["GKSwstype"] = "nul"
using Bonito, WGLMakie

const HOST = get(ENV, "BONITO_HOST", "127.0.0.1")
const PORT = parse(Int, get(ENV, "BONITO_PORT", "8773"))

# The exact code shown to the reader (kept in sync with what runs below).
const SOURCE = """using Bonito, WGLMakie

freq  = Slider(0.5:0.5:5.0)
phase = Slider(0.0:0.1:2π)

x = LinRange(0, 2π, 300)

# map over the slider observables → recomputed in Julia on every change
ys = map(freq.value, phase.value) do f, p
    sin.(f .* x .+ p)
end

fig, ax, _ = lines(x, ys; color=:steelblue, linewidth=3)
ylims!(ax, -1.2, 1.2)"""

app = App() do
    freq  = Slider(0.5:0.5:5.0)
    phase = Slider(0.0:0.1:2π)

    x = LinRange(0, 2π, 300)
    ys = map(freq.value, phase.value) do f, p
        sin.(f .* x .+ p)
    end

    fig, ax, _ = lines(x, ys; color = :steelblue, linewidth = 3,
                       figure = (; size = (680, 300)))
    ax.title = "Broadcasting (Bonito + WGLMakie)"
    ax.xlabel = "x"; ax.ylabel = "y"
    ylims!(ax, -1.2, 1.2)

    # Page-level CSS: let the body size to content so the embed can auto-grow.
    css = DOM.style("""
        html, body { margin: 0; height: auto; overflow: hidden;
                     background: #fafafa; font-family: system-ui, sans-serif; }
        .bk-code { background: #272822; color: #f8f8f2; padding: 1rem;
                   border-radius: 6px; font: 0.8rem/1.5 monospace;
                   white-space: pre; overflow-x: auto; margin: 0 0 0.75rem; }
        .bk-controls { display: flex; gap: 1.5rem; flex-wrap: wrap;
                       margin-bottom: 0.5rem; font: 0.85rem monospace; color: #444; }
    """)

    # Report our content height to the embedding page so it can size the iframe.
    resize = js"""
    (function () {
        const report = () => parent.postMessage(
            { type: "embed-height", height: Math.ceil(document.body.scrollHeight) }, "*");
        if (window.ResizeObserver) new ResizeObserver(report).observe(document.body);
        window.addEventListener("load", report);
        setTimeout(report, 300); setTimeout(report, 1200); setTimeout(report, 3000);
    })()
    """

    return DOM.div(css,
        DOM.pre(DOM.code(SOURCE); class = "bk-code"),
        DOM.div(DOM.div("frequency: ", freq), DOM.div("phase: ", phase); class = "bk-controls"),
        fig,
        resize;
        style = "padding: 1rem; max-width: 720px;",
    )
end

server = Server(HOST, PORT)
route!(server, "/broadcasting" => app)

println("Bonito serving on http://$HOST:$PORT/broadcasting")
flush(stdout)
wait(Condition())
