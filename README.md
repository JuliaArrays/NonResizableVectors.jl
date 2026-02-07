# NonResizableVectors

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaArrays.github.io/NonResizableVectors.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaArrays.github.io/NonResizableVectors.jl/dev/)
[![Build Status](https://github.com/JuliaArrays/NonResizableVectors.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaArrays/NonResizableVectors.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaArrays/NonResizableVectors.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaArrays/NonResizableVectors.jl)
[![Package version](https://juliahub.com/docs/General/NonResizableVectors/stable/version.svg)](https://juliahub.com/ui/Packages/General/NonResizableVectors)
[![Package dependencies](https://juliahub.com/docs/General/NonResizableVectors/stable/deps.svg)](https://juliahub.com/ui/Packages/General/NonResizableVectors?t=2)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/N/NonResizableVectors.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/N/NonResizableVectors.html)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Several simple subtypes of `AbstractVector` that just wrap `Memory` or `MemoryRef`.

One of the main differences between these types and `Memory` is that the types defined in this package are supposed to never throw `BoundsError`. This is beneficial because throwing `BoundsError` escapes the `AbstractArray` value, making it impossible to eliminate the underlying allocation.

Comparison with FixedSizeArrays.jl: the two packages are very similar, here are some differences:

* This package only supports `AbstractVector`. This makes the types defined here cheaper, as there is no need to store the `AbstractArray` shape. It also simplifies the implementation.

* This package supports some variations not supported by FixedSizeArrays.jl: a `MemoryRef` may be stored instead of directly storing a `Memory`. TODO: investigate whether this allows performance improvements.

* The type parameters are executed differently, leading to a simpler implementation.

In the future, it might make sense to extend FixedSizeArrays.jl so it would allow being based on the types defined here, instead of accepting only `Memory` as the parent type.
