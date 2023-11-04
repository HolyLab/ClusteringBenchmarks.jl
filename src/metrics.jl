"""
    score = nca(refclust, clust)
    score = nca(C)

Compute the Normalised Clustering Accuracy (NCA) of a clustering `clust` with respect to the "ground truth" `refclust`.
Alternatively supply the confusion matrix `C` (see [`confusion_matrix`](@ref)).

!!! note
    The NCA assumes hard-clustering and requires that the number of clusters in `refclust` and `clust`
    be the same (`C` must be square). It scales poorly when there are many (>20) clusters.

Implements Eq 35 in:
    Gagolewski, M. (2023). Normalised clustering accuracy: An asymmetric external cluster validity measure (preprint).
    URL: https://arxiv.org/pdf/2209.02935.pdf, DOI: 10.48550/arXiv.2209.02935
"""
function nca(C::AbstractMatrix{Int})
    ax1, ax2 = axes(C)
    k = length(ax1)
    length(ax2) == k || throw(DimensionMismatch("C must be square"))
    k > 1 || return 0.0
    ncamax = 0.0
    c = sum(C, dims=2)
    for perm in permutations(ax1)
        nca = 0.0
        for (i, j) in zip(perm, ax2)
            nca += C[i, j] / c[i]
        end
        nca = (nca - 1) / (k - 1)
        ncamax = max(ncamax, nca)
    end
    return ncamax
end

nca(refclust::AbstractVector{<:Integer}, clust::AbstractVector{<:Integer}) = nca(confusion_matrix(refclust, clust))

"""
    score = ami(refclust, clust)
    score = ami(C)

Compute the Adjusted Mutual Information (AMI) of a clustering `clust` with respect to the "ground truth" `refclust`.
Alternatively supply the confusion matrix `C` (see [`confusion_matrix`](@ref)).

!!! note
    AMI assumes hard-clustering.

Implements Eq. 24a in:
    Vinh, N.X., Epps, J. and Bailey, J., 2009. Information theoretic measures for clusterings comparison: is a correction
    for chance necessary?. In Proceedings of the 26th annual international conference on machine learning (pp. 1073-1080).
"""
function ami(C::AbstractMatrix{Int})
    entropy(v) = -sum(x * log(x) for x in v if !iszero(x))

    ax1, ax2 = axes(C)
    N = sum(C)
    N > 1 || return 0.0
    mi = emi = 0.0
    a = sum(C, dims=2)
    b = sum(C, dims=1)
    for i in ax1
        ai = a[i]
        for j in ax2
            cij = C[i, j]
            cij > 0 || continue
            bj = b[j]
            mi += (cij / N) * log((N * cij) / (ai * bj))
            for k in max(ai + bj - N, 1) : min(ai, bj)
                f = exp(logfactorial(ai) + logfactorial(bj) + logfactorial(N - ai) + logfactorial(N - bj) - logfactorial(k) - logfactorial(ai - k) - logfactorial(bj - k) - logfactorial(N - ai - bj + k) - logfactorial(N))
                emi += (k / N) * log((N * k) / (ai * bj)) * f
            end
        end
    end
    return (mi - emi) / (sqrt(entropy(a / N) * entropy(b / N)) - emi)
end
ami(refclust::AbstractVector{<:Integer}, clust::AbstractVector{<:Integer}) = ami(confusion_matrix(refclust, clust))

"""
    C = confusion_matrix(refclust, clust)

Compute the confusion matrix of a clustering `clust` with respect to the "ground truth" `refclust`.
Both `refclust` and `clust` are vectors of cluster labels (integers).

`C[i, j]` is the number of objects that are in cluster `i` in `refclust` and in cluster `j` in `clust`.
"""
function confusion_matrix(refclust::AbstractVector{<:Integer}, clust::AbstractVector{<:Integer})
    length(refclust) == length(clust) || throw(DimensionMismatch("refclust and clust must have the same length"))

    e1, e2 = extrema(refclust), extrema(clust)
    ax1, ax2 = e1[1] : e1[2], e2[1] : e2[2]
    C = zeros(Int, ax1, ax2)
    for (i, j) in zip(refclust, clust)
        C[i, j] += 1
    end
    return C
end

# Wanted: something like AMI for soft clustering
