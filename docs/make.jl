using NonResizableVectors
using Documenter

DocMeta.setdocmeta!(NonResizableVectors, :DocTestSetup, :(using NonResizableVectors); recursive=true)

makedocs(;
    modules=[NonResizableVectors],
    authors="Neven Sajko <s@purelymail.com> and contributors",
    sitename="NonResizableVectors.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaArrays.github.io/NonResizableVectors.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaArrays/NonResizableVectors.jl",
    devbranch="main",
)
