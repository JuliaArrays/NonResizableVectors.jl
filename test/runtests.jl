using NonResizableVectors
using Test

@testset "NonResizableVectors.jl" begin
    # Write your tests here.
end

using Aqua: Aqua

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(NonResizableVectors)
end
