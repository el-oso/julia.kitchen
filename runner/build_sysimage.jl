import Pkg
Pkg.add([
    "PackageCompiler",
    "Plots",
    "StatsPlots",
    "DataFrames",
    "Statistics",
    "LinearAlgebra",
    "StatsBase",
])
using PackageCompiler
create_sysimage(
    [:JSON, :Plots, :StatsPlots, :DataFrames, :Statistics, :LinearAlgebra, :StatsBase],
    sysimage_path = "/sysimage/sys.so",
    project = ".",
)
