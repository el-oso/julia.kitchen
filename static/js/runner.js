const RUNNER_URL = window.JULIA_RUNNER_URL || "http://localhost:8080";

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".julia-cell").forEach(initCell);
});

function initCell(cell) {
  const viewEl    = cell.querySelector(".julia-view");
  const editorEl  = cell.querySelector(".julia-editor");
  const outputEl  = cell.querySelector(".julia-output");
  const stdoutEl  = outputEl.querySelector(".stdout");
  const stderrEl  = outputEl.querySelector(".stderr");
  const runBtn    = cell.querySelector(".run-btn");
  const editBtn   = cell.querySelector(".edit-btn");
  const resetBtn  = cell.querySelector(".reset-btn");

  const original = editorEl.value;

  function enterEditMode() {
    viewEl.hidden   = true;
    editorEl.hidden = false;
    editorEl.focus();
    editBtn.textContent = "✓ Done";
  }

  function leaveEditMode() {
    // Update the highlighted view to reflect edits, then re-highlight
    const codeEl = viewEl.querySelector("code");
    codeEl.textContent = editorEl.value;
    if (window.hljs) window.hljs.highlightElement(codeEl);
    editorEl.hidden = false;  // keep textarea in DOM for value reads
    viewEl.hidden   = false;
    editorEl.hidden = true;
    editBtn.textContent = "✎ Edit";
  }

  editBtn.addEventListener("click", () => {
    if (!editorEl.hidden) {
      leaveEditMode();
    } else {
      enterEditMode();
    }
  });

  // Clicking the highlighted view also enters edit mode
  viewEl.addEventListener("click", enterEditMode);

  // ── Keyboard handling in the textarea ────────────────────────────────────
  editorEl.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
      e.preventDefault();
      leaveEditMode();
      runBtn.click();
      return;
    }
    if (e.key === "Tab") {
      e.preventDefault();
      const s = editorEl.selectionStart;
      const v = editorEl.value;
      editorEl.value = v.slice(0, s) + "    " + v.slice(editorEl.selectionEnd);
      editorEl.selectionStart = editorEl.selectionEnd = s + 4;
    }
    if (e.key === "Escape") {
      leaveEditMode();
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

    // If in edit mode, leave it so the user sees output clearly
    if (!editorEl.hidden) leaveEditMode();

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
      if (data.stdout || data.stderr) outputEl.hidden = false;

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
    const codeEl = viewEl.querySelector("code");
    codeEl.textContent = original;
    if (window.hljs) window.hljs.highlightElement(codeEl);
    if (!editorEl.hidden) leaveEditMode();
    outputEl.hidden = true;
    stdoutEl.textContent = "";
    stderrEl.textContent = "";
  });
}
