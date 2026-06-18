import Pkg
Pkg.add("PackageCompiler")
using PackageCompiler

# Bake the slider-server stack into a sysimage so the service starts fast in the
# container (PlutoSliderServer + Pluto pull in a lot of code to precompile).
create_sysimage(
    [:PlutoSliderServer, :Pluto, :PlutoUI, :Plots],
    sysimage_path = "/sysimage/sys.so",
    project = "env",
)
