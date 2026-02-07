using NonResizableVectors
using Test

# not public API yet
using NonResizableVectors.VectorBoundsErrors: VectorBoundsError

@testset "NonResizableVectors.jl" begin
    @testset "subtyping" begin
        for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
            @test typ <: AbstractVector
            for elt ∈ (Float32, String)
                @test typ{elt} <: AbstractVector{elt}
            end
        end
    end
    @testset "construction with `undef`" begin
        for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
            for elt ∈ (Float32, String)
                for n ∈ 0:4
                    @test (@inferred typ{elt}(undef, n)) isa typ{elt}
                end
            end
        end
    end
    @testset "`getindex`" begin
        @testset "in-bounds access" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 1:4
                    for i ∈ 1:n
                        @test let v = typ{elt}(undef, n)
                            (@inferred v[i]) isa elt
                        end
                    end
                end
            end
        end
        @testset "out-of-bounds access" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 0:4
                    for i ∈ (-1, 0, n + 1, n + 2)
                        @test_throws VectorBoundsError typ{elt}(undef, n)[i]
                    end
                end
            end
        end
    end
    @testset "`setindex!`" begin
        @testset "in-bounds access" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 1:4
                    for i ∈ 1:n
                        @test let v = typ{elt}(undef, n)
                            (@inferred setindex!(v, 3, i)) === v
                        end
                    end
                end
            end
        end
        @testset "out-of-bounds access" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 0:4
                    for i ∈ (-1, 0, n + 1, n + 2)
                        @test_throws VectorBoundsError typ{elt}(undef, n)[i] = 3
                    end
                end
            end
        end
    end
    @testset "`getindex`, `setindex!` consistency" begin
        for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
            elt = Float32
            for n ∈ 1:4
                @test let v = typ{elt}(undef, n)
                    r = 1:n
                    for i ∈ r
                        v[i] = i * 10
                    end
                    all((i -> v[i] == i * 10), r)
                end
            end
        end
    end
end

using Aqua: Aqua

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(NonResizableVectors)
end
