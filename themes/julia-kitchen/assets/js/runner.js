const RUNNER_URL = window.JULIA_RUNNER_URL || "http://localhost:8080";

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".julia-cell").forEach(initCell);
  document.querySelectorAll(".runner-slider").forEach(initSliderDemo);
});

// Auto-size embedded notebook iframes (Pluto / Bonito). They're cross-origin,
// so the iframe content reports its own height via postMessage; we match the
// message to its iframe and set the height — no inner scrollbar, grows to fit.
// Guard against a feedback loop: setting the height changes the iframe's own
// measured height, which echoes back as a new report. Ignore reports within a
// tolerance of the height we last applied, and never add padding (which would
// ratchet the height up on every echo).
const _embedHeights = new WeakMap();
window.addEventListener("message", (e) => {
  const d = e.data;
  if (!d || d.type !== "embed-height" || typeof d.height !== "number") return;
  document.querySelectorAll(".notebook-embed iframe").forEach((frame) => {
    if (frame.contentWindow !== e.source) return;
    const applied = _embedHeights.get(frame) || 0;
    if (Math.abs(d.height - applied) <= 8) return;   // echo / jitter → ignore
    _embedHeights.set(frame, d.height);
    frame.style.height = d.height + "px";
  });
});

// Slider-driven demo: re-run a parameterized code template through the Go
// runner on each slider change (debounced) and show the returned plot PNG.
function initSliderDemo(root) {
  const codeTpl  = root.querySelector(".rs-code").value;
  const freqEl   = root.querySelector(".rs-freq");
  const phaseEl  = root.querySelector(".rs-phase");
  const freqVal  = root.querySelector(".rs-freq-val");
  const phaseVal = root.querySelector(".rs-phase-val");
  const imgEl    = root.querySelector(".rs-img");
  const statusEl = root.querySelector(".rs-status");

  let timer = null;
  let inFlight = false;
  let pending = false;

  async function render() {
    if (inFlight) { pending = true; return; }
    inFlight = true;
    const t0 = performance.now();
    const code = codeTpl
      .replaceAll("__FREQ__", freqEl.value)
      .replaceAll("__PHASE__", phaseEl.value);
    try {
      const res = await fetch(`${RUNNER_URL}/api/run`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code }),
      });
      const data = await res.json();
      if (!res.ok) {
        statusEl.textContent = data.error || `Server error ${res.status}`;
      } else if (data.image_data) {
        imgEl.src = data.image_data;
        imgEl.hidden = false;
        const ms = Math.round(performance.now() - t0);
        statusEl.textContent = `rendered in ${ms} ms (server ${Math.round(data.elapsed_ms)} ms)`;
      } else {
        statusEl.textContent = data.stderr || "no plot returned";
      }
    } catch (err) {
      statusEl.textContent = `runner unreachable at ${RUNNER_URL}`;
    } finally {
      inFlight = false;
      if (pending) { pending = false; render(); }
    }
  }

  function onInput() {
    freqVal.textContent  = parseFloat(freqEl.value).toFixed(1);
    phaseVal.textContent = parseFloat(phaseEl.value).toFixed(1);
    clearTimeout(timer);
    timer = setTimeout(render, 120);   // debounce rapid drags
  }

  freqEl.addEventListener("input", onInput);
  phaseEl.addEventListener("input", onInput);

  // Initial render.
  render();
}

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
