using NonResizableVectors
using Test

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
end

using Aqua: Aqua

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(NonResizableVectors)
end
