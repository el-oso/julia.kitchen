module JuliaRunner

using JSON
using TypeContracts
using Base64
using Random

# ── Result type ────────────────────────────────────────────────────────────────

struct EvalResult
    stdout::String
    stderr::String
    elapsed_ms::Float64
    image_data::String   # "data:image/png;base64,..." or ""
end

# ── Evaluator interface ────────────────────────────────────────────────────────

@contract AbstractEvaluator "Executes Julia code and returns stdout/stderr/timing." begin
    eval_code(::Self, ::AbstractString)::EvalResult
end

# ── Plot capture ───────────────────────────────────────────────────────────────

# Plots.jl UUID — checked without importing Plots so the runner stays lightweight.
const _PLOTS_UUID = Base.UUID("91a5bcdd-55d7-5caf-9e0b-520d859cae80")

# Returns the loaded Plots module, or nothing if it hasn't been imported yet.
function _plots_module()
    get(Base.loaded_modules, Base.PkgId(_PLOTS_UUID, "Plots"), nothing)
end

# Identity of the current Plots figure, or `nothing` if Plots isn't loaded /
# there's no current plot. Used to detect whether a cell actually produced a
# *new* plot — workers are long-lived and shared, so `Plots.current()` would
# otherwise return a stale figure left over from an earlier plotting cell.
function _current_plot_id(plots)::Union{UInt,Nothing}
    plots === nothing && return nothing
    try
        fig = Base.invokelatest(plots.current)
        fig === nothing && return nothing
        return objectid(fig)
    catch
        return nothing
    end
end

# Render the current Plots figure to a base64 PNG data URI.
function _capture_plot(plots)::String
    plots === nothing && return ""
    try
        fig = Base.invokelatest(plots.current)
        fig === nothing && return ""
        path = tempname() * ".png"
        Base.invokelatest(plots.savefig, fig, path)
        data = base64encode(read(path))
        rm(path; force=true)
        return "data:image/png;base64," * data
    catch
        return ""
    end
end

# ── Shared-state reset ───────────────────────────────────────────────────────

# Each cell runs in a fresh Module, so user *variables* never leak between
# requests. But loaded packages keep their own global state on a long-lived
# worker — e.g. Plots' active theme, or the default global RNG — which would
# otherwise bleed from one user into the next request on the same worker.
# Reset the known shared globals before each cell so everyone starts clean.
function _reset_shared_state!()
    # Reseed the default global RNG from system entropy. A cell that doesn't set
    # its own seed is then unaffected by the previous cell's random draws;
    # cells that call `Random.seed!(n)` themselves still override this.
    Random.seed!()

    # Reset Plots' active theme to the default (only if Plots is loaded). This
    # undoes a previous cell's `theme(:dark)` etc.
    plots = _plots_module()
    if plots !== nothing
        try
            Base.invokelatest(plots.theme, :default)
        catch
            # Older/newer Plots without `theme` — ignore.
        end
    end
    return nothing
end

# ── Output cap ───────────────────────────────────────────────────────────────

# Hard limit on captured stdout/stderr returned per cell. Bounds the response
# size and memory regardless of how much a cell prints (a runaway loop is also
# stopped by the execution timeout and the worker getting recycled).
const MAX_OUTPUT_BYTES = 32_000

function _read_capped(io::IO)::String
    seek(io, 0)
    data = read(io, MAX_OUTPUT_BYTES + 1)
    length(data) <= MAX_OUTPUT_BYTES && return String(data)
    # Trim back to the last valid UTF-8 boundary so the result stays encodable.
    n = MAX_OUTPUT_BYTES
    while n > 0 && !isvalid(String(@view data[1:n]))
        n -= 1
    end
    return String(@view data[1:n]) * "\n… [output truncated]"
end

# ── SandboxEvaluator ───────────────────────────────────────────────────────────

"""
Evaluates code in a fresh anonymous Module per request.
Captures stdout/stderr via OS-level fd redirect to temp files — synchronous
and reliable across Julia versions (avoids libuv async pipe close timing bugs).
After eval, auto-captures any Plots.jl figure as a base64 PNG.
"""
struct SandboxEvaluator <: AbstractEvaluator end

function eval_code(::SandboxEvaluator, code::AbstractString)::EvalResult
    mod = Module(gensym("Cell"))

    # Reset shared package globals (theme, RNG) so leftover state from a
    # previous user on this worker can't bleed into this cell.
    _reset_shared_state!()

    # Snapshot the current plot identity before running so we can tell whether
    # this cell produced a new figure (vs. a stale one from an earlier cell on
    # this long-lived worker).
    plots_before = _plots_module()
    plot_id_before = _current_plot_id(plots_before)

    orig_out = Base.stdout
    orig_err = Base.stderr

    out_path, out_io = mktemp()
    err_path, err_io = mktemp()

    redirect_stdout(out_io)
    redirect_stderr(err_io)

    t0 = time()
    caught = ""
    try
        include_string(mod, String(code), "cell")
    catch e
        caught = sprint(showerror, e)
    end
    elapsed_ms = (time() - t0) * 1000.0

    flush(Base.stdout)
    flush(Base.stderr)
    redirect_stdout(orig_out)
    redirect_stderr(orig_err)

    out_str = _read_capped(out_io)
    err_str = _read_capped(err_io)

    close(out_io)
    close(err_io)
    rm(out_path; force=true)
    rm(err_path; force=true)

    if !isempty(caught)
        err_str = isempty(err_str) ? caught : err_str * "\n" * caught
    end

    # Only emit an image if this cell produced a new/changed figure. Plots may
    # have been loaded *during* this cell (plots_before === nothing), so re-fetch.
    image_data = ""
    if isempty(caught)
        plots_after = _plots_module()
        plot_id_after = _current_plot_id(plots_after)
        if plot_id_after !== nothing && plot_id_after != plot_id_before
            image_data = _capture_plot(plots_after)
        end
    end

    EvalResult(out_str, err_str, elapsed_ms, image_data)
end

# ── Worker serve loop ──────────────────────────────────────────────────────────

"""
    serve(evaluator; proto_in, proto_out)

Read newline-delimited JSON requests from `proto_in`, evaluate each with
`evaluator`, and write JSON responses to `proto_out`.

Protocol:
  <- {"id": "<id>", "code": "<julia source>"}
  -> {"id": "<id>", "stdout": "...", "stderr": "...", "elapsed_ms": 123.4, "image_data": "..."}
"""
function serve(
    evaluator::AbstractEvaluator = SandboxEvaluator();
    proto_in::IO  = Base.stdin,
    proto_out::IO = Base.stdout,
)::Nothing
    println(proto_out, "READY")
    flush(proto_out)

    for line in eachline(proto_in)
        isempty(strip(line)) && continue

        req = try
            JSON.parse(line)
        catch
            continue
        end

        result = try
            eval_code(evaluator, req["code"])
        catch e
            EvalResult("", sprint(showerror, e), 0.0, "")
        end

        resp = JSON.json(Dict(
            "id"         => req["id"],
            "stdout"     => result.stdout,
            "stderr"     => result.stderr,
            "elapsed_ms" => result.elapsed_ms,
            "image_data" => result.image_data,
        ))

        println(proto_out, resp)
        flush(proto_out)
    end

    return nothing
end

end # module JuliaRunner
