---
title: "Linear Algebra"
description: "Matrix operations, decompositions, and solvers using Julia's built-in LinearAlgebra"
level: "intermediate"
julia_version: "1.12"
weight: 3
categories: ["numerics"]
tags: ["linear algebra", "matrices", "decompositions", "solvers"]
comments: false
---

Julia's `LinearAlgebra` standard library wraps BLAS/LAPACK under a clean, expressive API. No installation needed.

## Basic matrix operations

{{< julia >}}
using LinearAlgebra

A = [1.0 2.0; 3.0 4.0]
B = [5.0 6.0; 7.0 8.0]

println("A + B =\n", A + B)
println("A * B =\n", A * B)
println("Aᵀ =\n", A')          # transpose (adjoint)
println("det(A) = ", det(A))
println("tr(A)  = ", tr(A))
{{< /julia >}}

## Solving linear systems

`A \ b` solves Ax = b — faster and more numerically stable than computing A⁻¹ explicitly.

{{< julia >}}
using LinearAlgebra

A = [2.0 1.0; 5.0 3.0]
b = [4.0; 7.0]

x = A \ b
println("solution x = ", x)
println("residual  = ", norm(A * x - b))
{{< /julia >}}

## Eigendecomposition

{{< julia >}}
using LinearAlgebra

A = [4.0 1.0; 2.0 3.0]
vals, vecs = eigen(A)

println("eigenvalues:  ", vals)
println("eigenvectors:\n", vecs)

# Verify: A*v = λ*v for each pair
for i in 1:2
    λ, v = vals[i], vecs[:, i]
    println("residual $i: ", norm(A * v - λ * v))
end
{{< /julia >}}

## SVD

{{< julia >}}
using LinearAlgebra

A = [1.0 2.0 3.0;
     4.0 5.0 6.0]

U, S, V = svd(A)

println("singular values: ", S)
println("rank estimate:   ", count(s -> s > 1e-10, S))

# Reconstruct A from SVD
A_rec = U * Diagonal(S) * V'
println("reconstruction error: ", norm(A - A_rec))
{{< /julia >}}

## Cholesky decomposition

For symmetric positive-definite matrices (e.g. covariance matrices):

{{< julia >}}
using LinearAlgebra

# Build a symmetric positive-definite matrix
A = [4.0 2.0; 2.0 3.0]
C = cholesky(A)

println("L =\n", C.L)
println("L*Lᵀ ≈ A: ", C.L * C.L' ≈ A)

# Fast solve via Cholesky
b = [1.0; 2.0]
x = C \ b
println("x = ", x, "  residual = ", norm(A * x - b))
{{< /julia >}}

## Norms

{{< julia >}}
using LinearAlgebra

v = [3.0, 4.0]
println("‖v‖₂ = ", norm(v))         # Euclidean (default)
println("‖v‖₁ = ", norm(v, 1))      # Manhattan
println("‖v‖∞ = ", norm(v, Inf))    # max-norm

A = [1.0 2.0; 3.0 4.0]
println("‖A‖F = ", norm(A))         # Frobenius
println("‖A‖₂ = ", opnorm(A))       # spectral (largest singular value)
{{< /julia >}}
