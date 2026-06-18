---
title: "Types & Structs"
description: "Defining custom types, abstract types, and the Julia type hierarchy"
level: "beginner"
julia_version: "1.10"
weight: 3
categories: ["basics"]
tags: ["types", "structs", "abstract", "dispatch"]
comments: false
---

Julia's type system is the foundation of its performance and expressiveness. You define your own types as `struct` — the compiler generates specialized code for each concrete type.

## Concrete structs

{{< julia >}}
struct Point
    x::Float64
    y::Float64
end

p = Point(3.0, 4.0)
println("x=", p.x, " y=", p.y)
{{< /julia >}}

## Mutable structs

By default structs are immutable (faster). Use `mutable struct` when fields need to change:

{{< julia >}}
mutable struct Counter
    count::Int
end

c = Counter(0)
c.count += 1
c.count += 1
println("count: ", c.count)
{{< /julia >}}

## Abstract types

Abstract types define a hierarchy — they have no fields, only concrete subtypes can be instantiated:

{{< julia >}}
abstract type Shape end

struct Circle <: Shape
    radius::Float64
end

struct Rectangle <: Shape
    width::Float64
    height::Float64
end

area(s::Circle)    = π * s.radius^2
area(s::Rectangle) = s.width * s.height

shapes = [Circle(3.0), Rectangle(4.0, 5.0), Circle(1.0)]

for s in shapes
    println(typeof(s), " → area = ", round(area(s), digits=3))
end
{{< /julia >}}

## Parametric types

Types can be parameterized — like generics in other languages:

{{< julia >}}
struct Box{T}
    value::T
end

int_box    = Box(42)
float_box  = Box(3.14)
string_box = Box("hello")

println(int_box.value,    " :: ", typeof(int_box))
println(float_box.value,  " :: ", typeof(float_box))
println(string_box.value, " :: ", typeof(string_box))
{{< /julia >}}
