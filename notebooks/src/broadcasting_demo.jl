using WGLMakie, Bonito

function build_app()
    app = App() do session
        # Slider: frequency
        freq_slider = Slider(0.5:0.1:5.0)
        # Slider: phase
        phase_slider = Slider(0.0:0.1:2π)

        fig = Figure(size=(680, 320))
        ax  = Axis(fig[1, 1],
            title  = "Broadcasting sin over a vector — y = sin.(freq .* x .+ phase)",
            xlabel = "x",
            ylabel = "y",
        )
        xlims!(ax, 0, 2π)
        ylims!(ax, -1.5, 1.5)

        x = LinRange(0, 2π, 400)

        # Reactive line: updates whenever sliders change
        y = lift(freq_slider.value, phase_slider.value) do freq, phase
            sin.(freq .* x .+ phase)
        end

        lines!(ax, x, y, color=:dodgerblue, linewidth=3)

        DOM.div(
            DOM.h3("Interactive Broadcasting Demo"),
            DOM.p("Frequency: ", freq_slider, " ", @lift(string(round($freq_slider.value[], digits=1)))),
            DOM.p("Phase:     ", phase_slider, " ", @lift(string(round($phase_slider.value[], digits=2)))),
            fig,
        )
    end
    return app
end

# Export to static HTML when run as a script
if abspath(PROGRAM_FILE) == @__FILE__
    outdir = get(ENV, "BONITO_OUT", joinpath(@__DIR__, "..", "..", "static", "notebooks"))
    mkpath(outdir)
    outfile = joinpath(outdir, "broadcasting_demo.html")
    app = build_app()
    export_static(outfile, app)
    println("Exported → ", outfile)
end
