# Stage 1: build the Go server
FROM golang:1.22-alpine AS go-build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /runner .

# Stage 2: build the Julia sysimage
# Using the official Julia image; bakes common packages into a sysimage so
# `using Plots` inside a worker takes ~0.5s instead of ~20s.
FROM julia:1.10 AS julia-sysimage
WORKDIR /sysimage

COPY julia/Project.toml julia/Manifest.toml* ./
RUN julia --project=. -e 'import Pkg; Pkg.instantiate()'

# Add PackageCompiler and the packages we want in the sysimage.
# Extend this list as new recipe categories are added.
RUN julia --project=. -e '
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
'

# Stage 3: runtime image
FROM julia:1.10-slim
WORKDIR /app

COPY --from=go-build /runner ./runner
COPY --from=julia-sysimage /sysimage/sys.so ./sys.so
COPY julia/ ./julia/

# Non-root user for sandboxing
RUN useradd -m -s /bin/sh runner
USER runner

EXPOSE 8080

ENTRYPOINT ["/app/runner", "-sysimage", "/app/sys.so", "-pool", "4", "-timeout", "10"]
