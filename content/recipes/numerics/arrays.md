---
title: "Arrays"
description: "Creating, indexing, and slicing Julia arrays — 1-based, column-major, and fast"
level: "beginner"
julia_version: "1.10"
weight: 1
categories: ["numerics"]
tags: ["arrays", "indexing", "slicing", "comprehensions"]
comments: false
---

Julia arrays are 1-indexed, column-major (like MATLAB/Fortran), and designed for high-performance numerical work.

## Creating arrays

{{< julia >}}
# Row vector (1×N matrix)
v = [1, 2, 3, 4, 5]
println("vector: ", v, " size=", size(v))

# 2D matrix (rows separated by ;)
M = [1 2 3;
     4 5 6;
     7 8 9]
println("matrix:\n", M)
{{< /julia >}}

## Ranges and linspace

{{< julia >}}
r = 1:5               # lazy range
v = collect(r)        # materialise to Vector
s = range(0, 1, length=6)   # like linspace

println("range:   ", v)
println("linspace: ", collect(s))
{{< /julia >}}

## Indexing — 1-based

{{< julia >}}
v = [10, 20, 30, 40, 50]

println("first:  ", v[1])
println("last:   ", v[end])
println("slice:  ", v[2:4])
println("stride: ", v[1:2:end])   # every other element
{{< /julia >}}

## Array comprehensions

{{< julia >}}
squares = [x^2 for x in 1:8]
evens   = [x for x in 1:20 if x % 2 == 0]
matrix  = [i * j for i in 1:3, j in 1:3]

println("squares: ", squares)
println("evens:   ", evens)
println("matrix:\n", matrix)
{{< /julia >}}

## Common constructors

{{< julia >}}
println(zeros(3))           # [0.0, 0.0, 0.0]
println(ones(2, 3))         # 2×3 matrix of 1.0
println(fill(7, 4))         # [7, 7, 7, 7]
println(rand(3))            # 3 uniform random numbers (0,1)
println(trues(3))           # [true, true, true]
{{< /julia >}}

## Mutation and copy

{{< julia >}}
a = [1, 2, 3]
b = a           # b is an alias — same memory!
b[1] = 99
println("a after b[1]=99: ", a)   # a is also changed

c = copy(a)     # independent copy
c[1] = 0
println("a after c[1]=0: ", a)    # a unchanged
{{< /julia >}}

## Stack, concatenate

{{< julia >}}
x = [1, 2, 3]
y = [4, 5, 6]

println("vcat: ", vcat(x, y))        # vertical (append)
println("[x;y]: ", [x; y])           # same
println("hcat:\n", hcat(x, y))       # side by side → 3×2 matrix
{{< /julia >}}
