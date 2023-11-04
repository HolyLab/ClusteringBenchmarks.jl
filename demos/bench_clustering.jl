# Load GLMakie or CairoMakie externally

using Clustering
using ClusteringBenchmarks
using Statistics
using Distances
using DataFrames
using Glob
using ProgressMeter

nclust(refclust) = length(unique(refclust))

gdatasets = [
    # ("wut", "*"),
    ("sipu", "*"),
    ("fcps", "*"),
    # ("graves", "*"),
    ("other", "*"),
    ("uci", "*"),
]

function gexpandstar(battery)
    fls = glob(relpath(joinpath(ClusteringBenchmarks.gagolewskidir, battery, "*.data.gz"), @__DIR__))
    return [basename(f)[begin:end-8] for f in fls]
end

datasets = Tuple{String, String}[]
for (battery, pattern) in gdatasets
    for dataset in gexpandstar(battery)
        push!(datasets, (battery, dataset))
    end
end

evaluate_kmeans(X, refclust) = ami(refclust, kmeans(X, nclust(refclust)).assignments)
evaluate_kmedoids(X, refclust) = size(X, 2) < 3000 ? ami(refclust, kmedoids(pairwise(Euclidean(), X), nclust(refclust)).assignments) : missing
evaluate_hclust(X, refclust) = size(X, 2) < 3000 ? ami(refclust, cutree(hclust(pairwise(Euclidean(), X)); k=nclust(refclust))) : missing
evaluate_affprop(X, refclust) = size(X, 2) < 3000 ? ami(refclust, affinityprop(-pairwise(Euclidean(), X)).assignments) : missing
function evaluate_dbscan(X, refclust)
    size(X, 2) < 3000 || return missing
    D = pairwise(Euclidean(), X)
    nn = 2*size(X,1)
    N = size(X, 2)
    dn = [quantile(col, nn/N) for col in eachcol(D)]
    ami(refclust, dbscan(D, mean(dn); metric=nothing, min_neighbors=nn).assignments)
end

dspairs = [battery * "/" * dataset => Union{Float64,Missing}[] for (battery, dataset) in datasets]
pushfirst!(dspairs, "Algorithm" => String[])
df = DataFrame(dspairs)
@showprogress desc="Algorithm" for (f, name) in ((evaluate_kmeans, "kmeans"), (evaluate_kmedoids, "kmedoids"), (evaluate_hclust, "hclust"), (evaluate_affprop, "affprop"), (evaluate_dbscan, "dbscan"))
    push!(df, (Algorithm = name,), cols=:subset)
    i = 1
    @showprogress desc="Dataset " offset=1 for (battery, dataset) in datasets
        try
            data, labelsets = load_gagolewski(battery, dataset)
            refclust = labelsets[1]
            df[end, i+=1] = f(data, refclust)
        catch
            @warn "Error on $battery/$dataset: $err"
            rethrow()
        end
    end
end

function forviolin(df)
    x = Int[]
    y = Float64[]
    for (i, row) in enumerate(eachrow(df))
        for (j, val) in enumerate(row)
            if j == 1
                continue
            end
            (ismissing(val) || isnan(val)) && continue
            push!(x, i)
            push!(y, val)
        end
    end
    return x, y, convert(Vector{String}, df.Algorithm)
end

x, y, algs = forviolin(df)
fig = Figure()
ax = Axis(fig[1, 1]; xticks=(1:length(algs), algs))
violin!(ax, x, y; datalimits=(minimum(y), 1))
