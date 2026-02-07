using NonResizableVectors
using Test
using Aqua

@testset "NonResizableVectors.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(NonResizableVectors)
    end
    # Write your tests here.
end
