# Stage 1: build the Go server
FROM golang:1.25-alpine AS go-build
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

# PackageCompiler requires a C compiler
RUN apt-get update && apt-get install -y --no-install-recommends gcc g++ && rm -rf /var/lib/apt/lists/*

# Copy the full JuliaRunner package (Pkg.instantiate needs the source)
COPY julia/ ./julia/
COPY build_sysimage.jl ./

# Instantiate the Julia environment (downloads registered deps)
RUN julia --project=julia -e 'import Pkg; Pkg.instantiate()'

# Add PackageCompiler and bake common packages into a sysimage.
# Extend build_sysimage.jl as new recipe categories are added.
RUN julia --project=julia build_sysimage.jl

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
