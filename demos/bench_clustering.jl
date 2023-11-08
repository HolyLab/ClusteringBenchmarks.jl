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

# Algorithms that require "hints" from the reference clustering (except for evaluation)
evaluate_kmeans(X, refclust) = ami(refclust, kmeans(X, nclust(refclust)).assignments)
evaluate_kmedoids(X, refclust) = size(X, 2) < 3000 ? ami(refclust, kmedoids(pairwise(Euclidean(), X), nclust(refclust)).assignments) : missing
evaluate_hclust(X, refclust) = size(X, 2) < 3000 ? ami(refclust, cutree(hclust(pairwise(Euclidean(), X)); k=nclust(refclust))) : missing

# Algorithms that work without reference to the reference clustering (except for evaluation)
function evaluate_hclust_auto(X, refclust)
    size(X, 2) < 3000 || return missing
    hc = hclust(pairwise(Euclidean(), X))
    # Split at the largest gap in the dendrogram
    idx = argmax(diff(hc.heights))
    return ami(refclust, cutree(hc; h=mean(hc.heights[idx:idx+1])))
end
evaluate_affprop(X, refclust) = size(X, 2) < 3000 ? ami(refclust, affinityprop(-pairwise(Euclidean(), X)).assignments) : missing
function evaluate_dbscan(X, refclust)
    size(X, 2) < 3000 || return missing
    D = pairwise(Euclidean(), X)
    nn = 2*size(X,1)
    N = size(X, 2)
    dn = [quantile(col, nn/N) for col in eachcol(D)]
    ami(refclust, dbscan(D, mean(dn); metric=nothing, min_neighbors=nn).assignments)
end

function add_algorithm!(df::DataFrame, f, name, datasets)
    push!(df, (Algorithm = name,), cols=:subset)
    i = 1
    @showprogress desc="Dataset " offset=1 for (battery, dataset) in datasets
        try
            data, labelsets = load_gagolewski(battery, dataset)
            refclust = labelsets[1]
            df[end, i+=1] = f(data, refclust)
        catch
            @warn "Error with $name on $battery/$dataset: $err"
            rethrow()
        end
    end
    return df
end

dspairs = [battery * "/" * dataset => Union{Float64,Missing}[] for (battery, dataset) in datasets]
pushfirst!(dspairs, "Algorithm" => String[])
df = DataFrame(dspairs)
@showprogress desc="Algorithm" for (f, name) in ((evaluate_kmeans, "kmeans"),
                                                 (evaluate_kmedoids, "kmedoids"),
                                                 (evaluate_hclust, "hclust"),
                                                 (evaluate_hclust_auto, "hclust*"),
                                                 (evaluate_affprop, "affprop*"),
                                                 (evaluate_dbscan, "dbscan*"))
    add_algorithm!(df, f, name, datasets)
end

# Compute the number of benchmarks run with each algorithm
notmissing(x) = !(ismissing(x) | isnan(x))
nbenchmarks = DataFrame(Algorithm = df.Algorithm, Count = vec(sum(notmissing, Matrix(df[:,2:end]); dims=2)))

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
ax = Axis(fig[1, 1]; xticks=(1:length(algs), algs), ylabel="AMI score")
violin!(ax, x, y; datalimits=(minimum(y), 1))
