#!/usr/bin/env julia
# Serves a compact, EDITABLE Bonito + WGLMakie demo: the boilerplate is shown
# read-only, the y-formula is editable, and a Run button recompiles it. The
# figure is reactive to both the sliders and the edited formula — it stays put
# and only its data Observable is swapped (a robust Makie pattern).
#
# Dev:  BONITO_PORT=8773 julia --project=notebooks/bonito/env notebooks/bonito/serve.jl
# Route: http://<host>:<port>/broadcasting
#
# NOTE: the edited formula is eval'd in this server process — there is no
# sandbox/timeout here (unlike the Go runner). Fine for a local/demo service;
# do not expose this to untrusted users without sandboxing.

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))

ENV["GKSwstype"] = "nul"
using Bonito, WGLMakie

const HOST = get(ENV, "BONITO_HOST", "127.0.0.1")
const PORT = parse(Int, get(ENV, "BONITO_PORT", "8773"))

const DEFAULT_FORMULA = "sin.(freq .* x .+ phase)"

const CONTEXT = """using Bonito, WGLMakie

freq  = Slider(0.5:0.5:5.0)
phase = Slider(0.0:0.1:2π)
x = LinRange(0, 2π, 300)

# ── editable below ──  y recomputes on every slider move and on Run
y = """

# Compile a formula string into (freq, phase, x) -> y.
compile_formula(src::AbstractString) =
    eval(Meta.parse("(freq, phase, x) -> " * strip(src)))

app = App() do
    freq  = Slider(0.5:0.5:5.0)
    phase = Slider(0.0:0.1:2π)
    x = LinRange(0, 2π, 300)

    editor = CodeEditor("julia"; initial_source = DEFAULT_FORMULA, height = 40)
    run_btn = Button("▶ Run")
    status  = Observable("")

    # Observable holding the currently-compiled formula function.
    fn = Observable{Any}(compile_formula(DEFAULT_FORMULA))

    on(run_btn.value) do _
        try
            fn[] = compile_formula(editor.onchange[])
            status[] = "✓ ran"
        catch e
            status[] = sprint(showerror, e)
        end
    end

    # Recompute y whenever the formula or a slider changes. invokelatest handles
    # the world-age gap from eval'ing a new function at runtime.
    ys = map(fn, freq.value, phase.value) do f, fr, ph
        try
            Base.invokelatest(f, fr, ph, x)
        catch e
            status[] = sprint(showerror, e)
            zeros(length(x))
        end
    end

    fig, ax, _ = lines(x, ys; color = :steelblue, linewidth = 3,
                       figure = (; size = (680, 300)))
    ax.title = "Broadcasting (Bonito + WGLMakie, editable)"
    ax.xlabel = "x"; ax.ylabel = "y"
    ylims!(ax, -1.2, 1.2)

    css = DOM.style("""
        html, body { margin: 0; height: auto; overflow: hidden;
                     background: #fafafa; font-family: system-ui, sans-serif; }
        .bk-code { background: #272822; color: #f8f8f2; padding: 1rem 1rem 0.5rem;
                   border-radius: 6px 6px 0 0; font: 0.8rem/1.5 monospace;
                   white-space: pre; overflow-x: auto; margin: 0; }
        .bk-editwrap { background: #1e1e1e; border-radius: 0 0 6px 6px;
                       padding: 0.25rem 1rem 0.75rem; margin: 0 0 0.5rem;
                       border-top: 2px solid #4063d8; }
        .bk-runrow { display: flex; align-items: center; gap: 0.75rem;
                     font: 0.8rem monospace; color: #888; margin-bottom: 0.6rem; }
        .bk-controls { display: flex; gap: 1.5rem; flex-wrap: wrap;
                       margin-bottom: 0.5rem; font: 0.85rem monospace; color: #444; }
    """)

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
        DOM.pre(DOM.code(CONTEXT); class = "bk-code"),
        DOM.div(editor; class = "bk-editwrap"),
        DOM.div(run_btn, DOM.span(status); class = "bk-runrow"),
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
