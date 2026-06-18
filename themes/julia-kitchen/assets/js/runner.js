const RUNNER_URL = window.JULIA_RUNNER_URL || "http://localhost:8080";

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".julia-cell").forEach(initCell);
});

function initCell(cell) {
  const editorEl  = cell.querySelector(".julia-editor");
  const highlight = cell.querySelector(".julia-highlight");
  const codeEl    = highlight.querySelector("code");
  const outputEl  = cell.querySelector(".julia-output");
  const stdoutEl  = outputEl.querySelector(".stdout");
  const stderrEl  = outputEl.querySelector(".stderr");
  const plotEl    = outputEl.querySelector(".plot-output");
  const plotImg   = outputEl.querySelector(".plot-img");
  const runBtn    = cell.querySelector(".run-btn");
  const resetBtn  = cell.querySelector(".reset-btn");

  const original = editorEl.value;

  // Re-render the highlighted layer from the textarea's current value and keep
  // the two boxes scroll-aligned. A trailing newline needs a padding space or
  // the last (empty) line wouldn't render in the <pre>.
  function syncHighlight() {
    let src = editorEl.value;
    if (src.endsWith("\n")) src += " ";
    codeEl.textContent = src;
    if (window.hljs) {
      codeEl.removeAttribute("data-highlighted");
      codeEl.className = "language-julia";
      window.hljs.highlightElement(codeEl);
    }
    highlight.scrollTop  = editorEl.scrollTop;
    highlight.scrollLeft = editorEl.scrollLeft;
  }

  editorEl.addEventListener("input", syncHighlight);
  editorEl.addEventListener("scroll", () => {
    highlight.scrollTop  = editorEl.scrollTop;
    highlight.scrollLeft = editorEl.scrollLeft;
  });

  editorEl.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
      e.preventDefault();
      runBtn.click();
      return;
    }
    if (e.key === "Tab") {
      e.preventDefault();
      const s = editorEl.selectionStart;
      const v = editorEl.value;
      editorEl.value = v.slice(0, s) + "    " + v.slice(editorEl.selectionEnd);
      editorEl.selectionStart = editorEl.selectionEnd = s + 4;
      syncHighlight();
    }
  });

  // ── Run ───────────────────────────────────────────────────────────────────
  runBtn.addEventListener("click", async () => {
    if (runBtn.disabled) return;

    const code = editorEl.value;

    runBtn.disabled = true;
    runBtn.textContent = "⟳ Running…";
    outputEl.hidden = true;
    stdoutEl.textContent = "";
    stderrEl.textContent = "";
    plotEl.hidden = true;
    plotImg.src = "";

    try {
      const res  = await fetch(`${RUNNER_URL}/api/run`, {
        method:  "POST",
        headers: { "Content-Type": "application/json" },
        body:    JSON.stringify({ code }),
      });

      const data = await res.json();

      if (!res.ok) {
        stderrEl.textContent = data.error || `Server error ${res.status}`;
        outputEl.hidden = false;
        return;
      }

      stdoutEl.textContent = data.stdout || "";
      stderrEl.textContent = data.stderr || "";
      if (data.image_data) {
        plotImg.src = data.image_data;
        plotEl.hidden = false;
      }
      if (data.stdout || data.stderr || data.image_data) outputEl.hidden = false;

    } catch (err) {
      stderrEl.textContent =
        `Connection error: ${err.message}\n` +
        `Is the Julia runner running at ${RUNNER_URL}?`;
      outputEl.hidden = false;
    } finally {
      runBtn.disabled = false;
      runBtn.textContent = "▶ Run";
    }
  });

  // ── Reset ─────────────────────────────────────────────────────────────────
  resetBtn.addEventListener("click", () => {
    editorEl.value = original;
    syncHighlight();
    outputEl.hidden = true;
    stdoutEl.textContent = "";
    stderrEl.textContent = "";
    plotEl.hidden = true;
    plotImg.src = "";
  });

  // Initial highlight.
  syncHighlight();
}
