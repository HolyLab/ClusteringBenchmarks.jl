using ClusteringBenchmarks
using Documenter

DocMeta.setdocmeta!(ClusteringBenchmarks, :DocTestSetup, :(using ClusteringBenchmarks); recursive=true)

makedocs(;
    modules=[ClusteringBenchmarks],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/HolyLab/ClusteringBenchmarks.jl/blob/{commit}{path}#{line}",
    sitename="ClusteringBenchmarks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://HolyLab.github.io/ClusteringBenchmarks.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/HolyLab/ClusteringBenchmarks.jl",
    devbranch="main",
)
