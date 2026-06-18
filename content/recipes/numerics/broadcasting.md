---
title: "Broadcasting"
description: "Apply any function element-wise to arrays of any shape with the dot syntax"
level: "beginner"
julia_version: "1.12"
weight: 2
categories: ["numerics"]
tags: ["broadcasting", "dot syntax", "vectorisation", "fusion"]
comments: false
---

Broadcasting lets you apply any function element-wise across arrays — or mix arrays with scalars — using a single dot `.`. Julia fuses chains of dot calls into a single loop with no temporaries.

## The dot operator

{{< julia >}}
v = [1.0, 4.0, 9.0, 16.0]

println(sqrt.(v))          # element-wise sqrt
println(v .^ 2)            # element-wise square
println(v .+ 10)           # add scalar to every element
{{< /julia >}}

## Broadcasting works with any function

{{< julia >}}
clamp_pos(x) = max(0.0, x)

data = [-2.0, -1.0, 0.0, 1.0, 2.0]
println(clamp_pos.(data))
println(round.(data .* 1.7, digits=2))
{{< /julia >}}

## Array × array broadcasting

Arrays are broadcast against each other if their shapes are compatible — dimensions of size 1 expand to match.

{{< julia >}}
row = [1 2 3]       # 1×3
col = [10; 20; 30]  # 3×1

# outer product via broadcasting
result = row .+ col   # 3×3 matrix
println(result)
{{< /julia >}}

## Dot-call fusion

Julia compiles a chain of dots into a single pass — no intermediate arrays.

{{< julia >}}
x = collect(0.0:0.1:1.0)

# This entire expression is one fused loop:
y = sin.(x) .^ 2 .+ cos.(x) .^ 2

# sin²+cos² = 1 everywhere (Pythagorean identity)
println("max deviation from 1: ", maximum(abs.(y .- 1.0)))
{{< /julia >}}

## In-place broadcasting with `.=`

{{< julia >}}
v = zeros(5)
v .= 1:5         # fill in-place, no allocation
println(v)

v .*= 2          # multiply every element by 2 in-place
println(v)
{{< /julia >}}

## @. macro — dot everything

Prefix with `@.` to add a dot to every function call and operator in an expression.
Use it with plain scalar constants or scalar-returning variables — not with functions
like `norm(x)` that should stay scalar, since `@.` would turn them into `norm.(x)`.

{{< julia >}}
x = [1.0, 2.0, 3.0]
scale = 2.5

# without @.
y1 = sin.(x) .+ cos.(x) .* scale

# with @. — scale is a scalar variable, not a function call, so it is unaffected
y2 = @. sin(x) + cos(x) * scale

println(y1 ≈ y2 ? "identical ✓" : "different")
println(y1)
{{< /julia >}}
