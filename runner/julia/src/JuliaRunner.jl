module JuliaRunner

using JSON
using TypeContracts

# ── Result type ────────────────────────────────────────────────────────────────

struct EvalResult
    stdout::String
    stderr::String
    elapsed_ms::Float64
end

# ── Evaluator interface ────────────────────────────────────────────────────────

@contract AbstractEvaluator "Executes Julia code and returns stdout/stderr/timing." begin
    eval_code(::Self, ::AbstractString)::EvalResult
end

# ── SandboxEvaluator ───────────────────────────────────────────────────────────

"""
Evaluates code in a fresh anonymous Module per request.
Captures stdout/stderr via OS-level fd redirect to temp files — synchronous
and reliable across Julia versions (avoids libuv async pipe close timing bugs).
"""
struct SandboxEvaluator <: AbstractEvaluator end

function eval_code(::SandboxEvaluator, code::AbstractString)::EvalResult
    mod = Module(gensym("Cell"))

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

    seek(out_io, 0)
    seek(err_io, 0)
    out_str = read(out_io, String)
    err_str = read(err_io, String)

    close(out_io)
    close(err_io)
    rm(out_path; force=true)
    rm(err_path; force=true)

    if !isempty(caught)
        err_str = isempty(err_str) ? caught : err_str * "\n" * caught
    end

    EvalResult(out_str, err_str, elapsed_ms)
end

# ── Worker serve loop ──────────────────────────────────────────────────────────

"""
    serve(evaluator; proto_in, proto_out)

Read newline-delimited JSON requests from `proto_in`, evaluate each with
`evaluator`, and write JSON responses to `proto_out`.

Protocol:
  <- {"id": "<id>", "code": "<julia source>"}
  -> {"id": "<id>", "stdout": "...", "stderr": "...", "elapsed_ms": 123.4}
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
            EvalResult("", sprint(showerror, e), 0.0)
        end

        resp = JSON.json(Dict(
            "id"         => req["id"],
            "stdout"     => result.stdout,
            "stderr"     => result.stderr,
            "elapsed_ms" => result.elapsed_ms,
        ))

        println(proto_out, resp)
        flush(proto_out)
    end

    return nothing
end

end # module JuliaRunner
