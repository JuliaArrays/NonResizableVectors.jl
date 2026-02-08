using NonResizableVectors
using Test

# not public API yet
using NonResizableVectors.LightBoundsErrors: LightBoundsError

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
    @testset "`IndexStyle`" begin
        for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
            @test (@inferred IndexStyle(typ)) === IndexLinear()
            for elt ∈ (Float32, String)
                @test (@inferred IndexStyle(typ{elt})) === IndexLinear()
            end
        end
    end
    @testset "`size`" begin
        for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
            for elt ∈ (Float32, String)
                for n ∈ 0:4
                    @test (@inferred size(typ{elt}(undef, n))) === (n,)
                end
            end
        end
    end
    @testset "`checkbounds`" begin
        @testset "predicate version" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 0:4
                    for i ∈ (-1):(5)
                        @test (@inferred checkbounds(Bool, typ{elt}(undef, n), i)) === (1 ≤ i ≤ n)
                    end
                end
            end
        end
        @testset "conditionally-throwing version" begin
            for typ ∈ (MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut)
                elt = Float32
                for n ∈ 0:4
                    if checkbounds(Bool, typ{elt}(undef, n))
                        @test (@inferred checkbounds(typ{elt}(undef, n))) === nothing
                    else
                        @test_throws LightBoundsError checkbounds(typ{elt}(undef, n))
                        @test_throws ["LightBoundsError: ", "`collection[]`", "`typeof(collection) == $(typeof(typ{elt}(undef, n)))`", "`axes(collection) == $(axes(typ{elt}(undef, n)))`"] checkbounds(typ{elt}(undef, n))
                    end
                    for i ∈ (-1):(5)
                        if checkbounds(Bool, typ{elt}(undef, n), i)
                            @test (@inferred checkbounds(typ{elt}(undef, n), i)) === nothing
                        else
                            @test_throws LightBoundsError checkbounds(typ{elt}(undef, n), i)
                            @test_throws ["LightBoundsError: ", "`collection[$i]`", "`typeof(collection) == $(typeof(typ{elt}(undef, n)))`", "`axes(collection) == $(axes(typ{elt}(undef, n)))`"] checkbounds(typ{elt}(undef, n), i)
                        end
                        for j ∈ (-1):5
                            if checkbounds(Bool, typ{elt}(undef, n), i, j)
                                @test (@inferred checkbounds(typ{elt}(undef, n), i, j)) === nothing
                            else
                                @test_throws LightBoundsError checkbounds(typ{elt}(undef, n), i, j)
                                @test_throws ["LightBoundsError: ", "`collection[$i, $j]`", "`typeof(collection) == $(typeof(typ{elt}(undef, n)))`", "`axes(collection) == $(axes(typ{elt}(undef, n)))`"] checkbounds(typ{elt}(undef, n), i, j)
                            end
                        end
                    end
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
                        @test_throws LightBoundsError typ{elt}(undef, n)[i]
                        @test_throws ["LightBoundsError: ", "`collection[$i]`", "`typeof(collection) == $(typeof(typ{elt}(undef, n)))`", "`axes(collection) == $(axes(typ{elt}(undef, n)))`"] typ{elt}(undef, n)[i]
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
                        @test_throws LightBoundsError typ{elt}(undef, n)[i] = 3
                        @test_throws ["LightBoundsError: ", "`collection[$i]`", "`typeof(collection) == $(typeof(typ{elt}(undef, n)))`", "`axes(collection) == $(axes(typ{elt}(undef, n)))`"] typ{elt}(undef, n)[i] = 3
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
