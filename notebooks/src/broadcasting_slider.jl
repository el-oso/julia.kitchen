### A Pluto.jl notebook ###
# v1.0.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ a93a59d8-6b36-11f1-a0a5-8d7d98e19e56
md"""
# Broadcasting: Interactive Explorer

Julia's dot broadcast applies any function **element-wise**.

Try the sliders below to see how `sin.(freq .* x .+ phase)` changes:
- **frequency** — how many cycles in [0, 2π]
- **phase** — horizontal shift
"""

# ╔═╡ a93a5a16-6b36-11f1-9189-97f1529b5098
using PlutoUI, Plots

# ╔═╡ a93a5a1e-6b36-11f1-a3b4-810aa0618b5a
@bind freq Slider(0.5:0.5:5.0, default=1.0, show_value=true)

# ╔═╡ a93a5a1e-6b36-11f1-a8e5-1bb606036a8a
@bind phase Slider(0.0:0.1:2π, default=0.0, show_value=true)

# ╔═╡ a93a5a28-6b36-11f1-8640-b572fcf663e3
begin
    x = LinRange(0, 2π, 300)
    y = sin.(freq .* x .+ phase)
    plot(x, y;
        label  = "sin.($(round(freq, digits=1)) .* x .+ $(round(phase, digits=2)))",
        xlabel = "x",
        ylabel = "y",
        ylims  = (-1.2, 1.2),
        lw     = 2,
        color  = :steelblue,
        title  = "Broadcasting demo",
        size   = (680, 280),
    )
end

# ╔═╡ a93a5a28-6b36-11f1-ac63-fbfededdb231
md"""
## Key idea

```julia
y = sin.(freq .* x .+ phase)
```

The dot `.` before `sin`, `.*`, and `.+` broadcasts each operation across every element of `x` in a single fused loop — no explicit `for`, no temporaries.
"""

# ╔═╡ Cell order:
# ╠═a93a59d8-6b36-11f1-a0a5-8d7d98e19e56
# ╠═a93a5a16-6b36-11f1-9189-97f1529b5098
# ╠═a93a5a1e-6b36-11f1-a3b4-810aa0618b5a
# ╠═a93a5a1e-6b36-11f1-a8e5-1bb606036a8a
# ╠═a93a5a28-6b36-11f1-8640-b572fcf663e3
# ╠═a93a5a28-6b36-11f1-ac63-fbfededdb231
