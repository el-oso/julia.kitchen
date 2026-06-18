---
title: "Variables & Types"
description: "How Julia handles variables, type inference, and basic data types"
level: "beginner"
julia_version: "1.10"
weight: 1
categories: ["basics"]
tags: ["variables", "types", "inference"]
comments: false
---

Julia uses dynamic typing with optional type annotations. The compiler infers types at runtime and specializes code for each combination it encounters.

## Assigning variables

No declaration keyword needed — just assign:

{{< julia >}}
x = 42
y = 3.14
name = "Julia"
flag = true

println(x, " ", y, " ", name, " ", flag)
{{< /julia >}}

## Checking types

Use `typeof` to inspect the inferred type:

{{< julia >}}
println(typeof(42))       # Int64
println(typeof(3.14))     # Float64
println(typeof("hello"))  # String
println(typeof(true))     # Bool
{{< /julia >}}

## Type annotations

You can annotate a variable with `::` — Julia will convert or error at assignment:

{{< julia >}}
x::Float64 = 1      # Int literal coerced to Float64
println(x, " :: ", typeof(x))
{{< /julia >}}

## Unicode identifiers

Julia accepts any Unicode identifier, including Greek letters commonly used in math:

{{< julia >}}
α = 0.01
β = 0.99
println("learning rate α = ", α, ", momentum β = ", β)
{{< /julia >}}

## Multiple assignment

{{< julia >}}
a, b, c = 1, 2, 3
println(a, " ", b, " ", c)

# swap without a temp variable
a, b = b, a
println("after swap: a=", a, " b=", b)
{{< /julia >}}
