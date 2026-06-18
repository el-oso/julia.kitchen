---
title: "Functions"
description: "Defining functions, multiple dispatch, and anonymous functions in Julia"
level: "beginner"
julia_version: "1.10"
weight: 2
categories: ["basics"]
tags: ["functions", "dispatch", "closures"]
comments: false
---

Functions are the core unit of computation in Julia. Julia's killer feature is **multiple dispatch** — a function can have many methods, each specialized on the types of its arguments.

## Basic function definition

{{< julia >}}
function greet(name)
    return "Hello, " * name * "!"
end

println(greet("world"))
{{< /julia >}}

## Short-form (assignment syntax)

For one-liners, Julia has a compact form:

{{< julia >}}
double(x) = 2x
square(x) = x^2

println(double(5), " ", square(5))
{{< /julia >}}

## Multiple dispatch

Define the same function name for different argument types — Julia picks the most specific method at call time:

{{< julia >}}
describe(x::Int)     = "an integer: $x"
describe(x::Float64) = "a float: $x"
describe(x::String)  = "a string: \"$x\""
describe(x)          = "something else: $x"

println(describe(42))
println(describe(3.14))
println(describe("hi"))
println(describe(true))
{{< /julia >}}

## Default and keyword arguments

{{< julia >}}
function power(base, exp=2; verbose=false)
    result = base ^ exp
    verbose && println("$base ^ $exp = $result")
    return result
end

println(power(3))
println(power(2, 10))
power(5, 3, verbose=true)
{{< /julia >}}

## Anonymous functions

Use `->` for lambdas, useful with higher-order functions:

{{< julia >}}
nums = [3, 1, 4, 1, 5, 9, 2, 6]

evens    = filter(x -> x % 2 == 0, nums)
doubled  = map(x -> x * 2, nums)
total    = reduce(+, nums)

println("evens:   ", evens)
println("doubled: ", doubled)
println("sum:     ", total)
{{< /julia >}}
