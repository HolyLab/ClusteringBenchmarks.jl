using LibGit2

const datasetsdir = joinpath(dirname(@__DIR__), "datasets")
const gagolewskidir = joinpath(datasetsdir, "gagolewski")

if !isdir(datasetsdir)
    mkdir(datasetsdir)
end
if !isdir(gagolewskidir)
    LibGit2.clone("https://github.com/gagolews/clustering-data-v1.git", gagolewskidir)
end
