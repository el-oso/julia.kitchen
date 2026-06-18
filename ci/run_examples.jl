"""
Parses all .md files under content/, extracts {{< julia >}} shortcode blocks,
and executes each one in a fresh Module. Exits non-zero if any block fails.
"""

using Logging

const CONTENT_DIR = joinpath(@__DIR__, "..", "content")
const SHORTCODE_RE = r"\{\{<\s*julia\s*>\}\}(.*?)\{\{<\s*/julia\s*>\}\}"s

struct ExampleResult
    file::String
    index::Int
    code::String
    passed::Bool
    error::Union{Nothing, String}
    elapsed::Float64
end

function extract_blocks(path::String)
    src = read(path, String)
    [String(m.captures[1]) for m in eachmatch(SHORTCODE_RE, src)]
end

function run_block(code::AbstractString, file::AbstractString, idx::Int)::ExampleResult
    mod = Module(gensym("Recipe"))
    t0 = time()
    try
        include_string(mod, code, "$file:block$idx")
        return ExampleResult(file, idx, code, true, nothing, time() - t0)
    catch e
        return ExampleResult(file, idx, code, false, sprint(showerror, e), time() - t0)
    end
end

function main()
    md_files = String[]
    for (root, _, files) in walkdir(CONTENT_DIR)
        for f in files
            endswith(f, ".md") && push!(md_files, joinpath(root, f))
        end
    end

    results = ExampleResult[]
    for path in sort(md_files)
        blocks = extract_blocks(path)
        isempty(blocks) && continue
        rel = relpath(path, dirname(CONTENT_DIR))
        for (i, code) in enumerate(blocks)
            print("  testing $rel block $i … ")
            r = run_block(strip(code), rel, i)
            push!(results, r)
            println(r.passed ? "✓ ($(round(r.elapsed*1000, digits=0))ms)" : "✗")
            r.passed || println(stderr, "    ERROR: ", r.error)
        end
    end

    n_pass = count(r -> r.passed, results)
    n_fail = count(r -> !r.passed, results)
    println("\n$(length(results)) blocks: $n_pass passed, $n_fail failed")

    if n_fail > 0
        println(stderr, "\nFailed blocks:")
        for r in filter(r -> !r.passed, results)
            println(stderr, "  $(r.file) block $(r.index): $(r.error)")
        end
        exit(1)
    end
end

main()
