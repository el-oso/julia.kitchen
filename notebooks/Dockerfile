# Live PlutoSliderServer for julia.kitchen interactive notebooks.
# Build context is the notebooks/ directory.

# Stage 1: build a sysimage so the server starts quickly.
FROM julia:1.12 AS sysimage
WORKDIR /build

# PackageCompiler needs a C compiler.
RUN apt-get update && apt-get install -y --no-install-recommends gcc g++ && rm -rf /var/lib/apt/lists/*

COPY env/ ./env/
COPY build_sysimage.jl ./
RUN julia --project=env -e 'import Pkg; Pkg.instantiate()'
RUN mkdir -p /sysimage && julia --project=env build_sysimage.jl

# Stage 2: runtime image.
FROM julia:1.12
WORKDIR /app

# Plots/GR run headless in the container — no display.
ENV GKSwstype=nul \
    GR_NO_DISPLAY=true \
    PLUTO_HOST=0.0.0.0 \
    PLUTO_PORT=2345

COPY --from=sysimage /sysimage/sys.so ./sys.so
COPY env/ ./env/
COPY src/ ./src/
COPY serve.jl ./serve.jl

# Reuse the package depot from the build stage so notebook deps are present.
COPY --from=sysimage /root/.julia /root/.julia

EXPOSE 2345

# serve.jl activates ./env relative to its own location, so run from /app.
ENTRYPOINT ["julia", "-J", "/app/sys.so", "--project=/app/env", "/app/serve.jl"]
