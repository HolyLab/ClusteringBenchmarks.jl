using ClusteringBenchmarks
using Test

@testset "ClusteringBenchmarks.jl" begin
    @testset "metrics" begin
        @test nca([1, 1, 2, 2], [1, 1, 2, 2]) ≈ 1.0
        @test nca([1, 1, 2, 2], [2, 2, 1, 1]) ≈ 1.0
        @test nca([1, 1, 2, 2], [1, 2, 1, 2]) < 0.001

        @test ami([1, 1, 2, 2], [1, 1, 2, 2]) ≈ 1.0
        @test ami([1, 1, 2, 2], [2, 2, 1, 1]) ≈ 1.0
        @test ami([1, 1, 2, 2], [1, 2, 1, 2]) < 0.001

        clust1, clust2 = rand(1:3, 10000), rand(1:3, 10000)
        @test nca(clust1, clust1) ≈ 1
        @test abs(nca(clust1, clust2)) < 0.02

        @test ami(clust1, clust1) ≈ 1
        @test abs(ami(clust1, clust2)) < 0.001
        clust1a = [c == 3 ? rand(3:4) : c for c in clust1]
        @test ami(clust1, clust1a) > 1 - 1/6
        @test abs(ami(clust1a, clust2)) < 0.001

        clustlong = rand(1:3, length(clust1) + 10)
        @test_throws DimensionMismatch nca(clust1, clustlong)
        @test_throws DimensionMismatch ami(clust1, clustlong)
    end

    @testset "Gagolewski" begin
        data, labelsets = load_gagolewski("wut", "x2")
        @test isa(data, AbstractMatrix)
        @test isa(labelsets[1], AbstractVector{<:Integer})
    end
end
