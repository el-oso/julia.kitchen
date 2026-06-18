### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running outside Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Plots = "~1"
PlutoUI = "~0.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = ""

# ╔═╡ cell-001
md"""
# Eigenvectors — Visualised

An **eigenvector** of a matrix **A** is a vector that only *scales* (not rotates) when **A** is applied.

$$\mathbf{A}\mathbf{v} = \lambda\mathbf{v}$$

Use the sliders to build a 2×2 matrix and see its eigenvectors live.
"""

# ╔═╡ cell-slider-a
@bind a11 PlutoUI.Slider(-3.0:0.1:3.0, default=2.0, show_value=true)

# ╔═╡ cell-slider-b
@bind a12 PlutoUI.Slider(-3.0:0.1:3.0, default=1.0, show_value=true)

# ╔═╡ cell-slider-c
@bind a21 PlutoUI.Slider(-3.0:0.1:3.0, default=0.5, show_value=true)

# ╔═╡ cell-slider-d
@bind a22 PlutoUI.Slider(-3.0:0.1:3.0, default=1.0, show_value=true)

# ╔═╡ cell-labels
md"""
**Matrix A** = $\begin{pmatrix} a_{11} & a_{12} \\ a_{21} & a_{22} \end{pmatrix}$

$$\begin{pmatrix} $(a11) & $(a12) \\ $(a21) & $(a22) \end{pmatrix}$$
"""

# ╔═╡ cell-compute
begin
	using LinearAlgebra, Plots

	A = [a11 a12; a21 a22]
	vals, vecs = eigen(A)

	# Show result
	md"""
	**Eigenvalues**: λ₁ = $(round(real(vals[1]), digits=3)),  λ₂ = $(round(real(vals[2]), digits=3))
	"""
end

# ╔═╡ cell-plot
begin
	p = plot(
		xlims=(-3, 3), ylims=(-3, 3),
		aspect_ratio=:equal,
		title="Unit circle and eigenvectors",
		legend=:topright,
		size=(500, 500)
	)

	# Unit circle
	θ = range(0, 2π, length=200)
	xs, ys = cos.(θ), sin.(θ)

	# Apply A to the unit circle
	pts = A * [xs'; ys']
	plot!(p, xs, ys, label="unit circle", color=:lightgray, lw=2)
	plot!(p, pts[1, :], pts[2, :], label="A(unit circle)", color=:steelblue, lw=2)

	# Eigenvectors
	colors = [:red, :orange]
	for i in 1:min(2, length(vals))
		λ = real(vals[i])
		v = real(vecs[:, i])
		v = v / norm(v)
		quiver!(p, [0], [0], quiver=([v[1]*λ], [v[2]*λ]),
				color=colors[i], lw=3, label="λ$i=$(round(λ, digits=2))")
	end

	hline!(p, [0], color=:black, lw=0.5, label=nothing)
	vline!(p, [0], color=:black, lw=0.5, label=nothing)
	p
end

# ╔═╡ cell-explainer
md"""
## What you're seeing

- **Gray ellipse**: where the unit circle lands after applying **A**
- **Arrows**: the eigenvectors, scaled by their eigenvalues λ
- Eigenvectors point in directions that **A** only stretches or flips — they don't rotate

Try setting **A** = identity (a₁₁=1, a₁₂=0, a₂₁=0, a₂₂=1): every direction is an eigenvector (λ=1).
"""

# ╔═╡ 00000000-0000-0000-0000-000000000000
PlutoUI.TableOfContents()
