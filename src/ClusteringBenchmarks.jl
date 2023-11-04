module ClusteringBenchmarks

using DelimitedFiles
using GZip
using OffsetArrays
using Combinatorics
using SpecialFunctions

export load_gagolewski, nca, ami, contingency_matrix

const datasetsdir = joinpath(dirname(@__DIR__), "datasets")

include("gagolewski.jl")
include("metrics.jl")

end
