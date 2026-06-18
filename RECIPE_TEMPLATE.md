# Recipe Template

Copy this file to `content/recipes/<section>/<slug>.md` and fill in every field.
All code blocks must pass `julia ci/run_examples.jl` before a PR will be accepted.

---

```markdown
---
title: "Short, noun-phrase title"           # e.g. "Sorting Arrays"
description: "One sentence, 10-15 words"   # shown in listings and meta
level: "beginner"                           # beginner | intermediate | advanced
julia_version: "1.10"                      # minimum Julia version for the recipe
weight: 10                                  # controls order within section (lower = first)
categories: ["numerics"]                    # pick one: basics | numerics | plotting | data | packages
tags: ["sorting", "arrays"]                # 2-5 keywords, lowercase
comments: false                            # set true once GitHub repo is wired to Giscus
---

One or two sentences explaining WHAT this recipe covers and WHEN you'd reach for it.
No need to explain syntax — the runnable cells below do that.

## Section heading

Brief prose (1-4 sentences). Explain the WHY, not just the what.

{{< julia >}}
# Working, minimal code that demonstrates the concept.
# println so readers see output without running.
x = [3, 1, 4, 1, 5, 9]
println(sort(x))         # [1, 1, 3, 4, 5, 9]
println(sort(x; rev=true))  # [9, 5, 4, 3, 1, 1]
{{< /julia >}}

## Another section

Each `{{< julia >}}` block is independent — don't assume variables from previous blocks.

{{< julia >}}
v = [5, 2, 8, 1]
i = sortperm(v)          # indices that would sort v
println(i)               # [4, 2, 1, 3]
println(v[i])            # sorted: [1, 2, 5, 8]
{{< /julia >}}
```

---

## Checklist

Before opening a PR:

- [ ] All `{{< julia >}}` blocks run without error (`julia ci/run_examples.jl`)
- [ ] Each block is self-contained (no shared state between blocks)
- [ ] `julia_version` is set to the minimum version required
- [ ] Title is a short noun phrase, not a sentence
- [ ] Description is ≤ 15 words
- [ ] `level` reflects the assumed knowledge, not the topic difficulty
- [ ] `categories` picks exactly one from the list above
- [ ] 2-5 `tags`, all lowercase
- [ ] No copied text from external sources (paraphrase and credit in PR description)
