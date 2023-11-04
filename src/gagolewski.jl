const gagolewskidir = joinpath(datasetsdir, "gagolewski")

"""
    data, labelsets = load_gagolewski(battery, dataset)

Load a dataset from the Gagolewski collection of data sets. `data` is a `d × N` matrix of `Float64` values,
where `d` is the dimensionality of the data set and `N` is the number of observations. `labelsets` is a vector
of label-vectors (for each label-vector `label = labelsets[i]`, `label[j]` is the cluster number assigned to
the `j`th data point). Most data sets have a single label-vector, but some provide multiple label sets.
Typically the first is the one provided by the original creator of the data set, and is the recommended choice
for benchmarking.

# Examples

```julia
using ClusteringBenchmarks
data, labelsets = load_gagolewski("wut", "x2")
```
"""
function load_gagolewski(battery, dataset)
    basename = joinpath(gagolewskidir, battery, dataset)
    datafile = basename * ".data.gz"
    isfile(datafile) || error("no such file: $datafile")
    data = Matrix(gzopen(datafile) do f
        readdlm(f, Float64)'
    end)
    labels = Vector{Int}[]
    i = 0
    while true
        labelfile = basename * ".labels$i.gz"
        if !isfile(labelfile)
            break
        end
        push!(labels, gzopen(labelfile) do f
            vec(readdlm(f, Int))
        end)
        i += 1
    end
    isempty(labels) && error("no label files found for $basename")
    return data, labels
end
