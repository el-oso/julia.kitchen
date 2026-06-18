---
title: "Statistics"
description: "Descriptive statistics, distributions, and random sampling with Julia's standard library"
level: "beginner"
julia_version: "1.10"
weight: 4
categories: ["numerics"]
tags: ["statistics", "distributions", "random", "sampling"]
comments: false
---

Julia's `Statistics` standard library covers the essentials. For distributions and hypothesis tests, `Distributions.jl` (not covered here) extends this further.

## Descriptive statistics

{{< julia >}}
using Statistics

data = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]

println("mean:   ", mean(data))
println("median: ", median(data))
println("std:    ", round(std(data), digits=4))
println("var:    ", round(var(data), digits=4))
println("min:    ", minimum(data))
println("max:    ", maximum(data))
{{< /julia >}}

## Quantiles and percentiles

{{< julia >}}
using Statistics

data = Float64.(1:100)

println("Q1  (25th): ", quantile(data, 0.25))
println("Q2  (50th): ", quantile(data, 0.50))
println("Q3  (75th): ", quantile(data, 0.75))
println("IQR:        ", quantile(data, 0.75) - quantile(data, 0.25))
{{< /julia >}}

## Covariance and correlation

{{< julia >}}
using Statistics

x = [1.0, 2.0, 3.0, 4.0, 5.0]
y = [2.1, 3.9, 6.2, 7.8, 10.1]

println("cov:  ", round(cov(x, y), digits=4))
println("corr: ", round(cor(x, y), digits=4))

# Covariance matrix of a dataset
X = [x y]    # 5×2 matrix
println("covariance matrix:\n", round.(cov(X), digits=3))
{{< /julia >}}

## Random numbers and sampling

{{< julia >}}
using Random
Random.seed!(42)   # reproducible results

println("uniform [0,1]:      ", round.(rand(5), digits=3))
println("normal(0,1):        ", round.(randn(5), digits=3))
println("integers [1,10]:    ", rand(1:10, 5))
println("random permutation: ", randperm(6))

# Sample without replacement: shuffle then take first k
pool = ["a", "b", "c", "d", "e"]
println("sample 3:           ", shuffle(pool)[1:3])
{{< /julia >}}

## Column-wise operations on matrices

{{< julia >}}
using Statistics

M = [1.0 2.0 3.0;
     4.0 5.0 6.0;
     7.0 8.0 9.0]

println("column means: ", mean(M, dims=1))   # 1×3
println("row means:    ", mean(M, dims=2))   # 3×1
println("column stds:  ", round.(std(M, dims=1), digits=3))
{{< /julia >}}
