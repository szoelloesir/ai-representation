# Worker A Result — Technical Specification: ai-representation Presentation Site

**Role**: Software Architect
**Task assigned**: 2026-03-22
**Priority**: High

---

## (a) Recommended Tech Stack with Justification

### Decision: React + CSS Transforms + Framer Motion + Vite + Tailwind

| Layer | Choice | Rationale |
|---|---|---|
| Framework | React 18 | Widest team familiarity across dev/QA/DevOps; strong ecosystem |
| Canvas engine | CSS 2D transforms (`translate` + `scale`) | No WebGL overhead; fully inspectable in DevTools; maintainable by any frontend dev |
| Animation | Framer Motion | Declarative zoom/pan transitions; works natively with React; avoids imperative GSAP complexity |
| Styling | Tailwind CSS | Readable by non-frontend team members; consistent design tokens without a bespoke system |
| Build | Vite | Fast cold starts; simple config; works out-of-the-box for static output |
| Build log delivery | Static JSON file + polling (upgradeable to SSE) | No server required for MVP; agents append to file; site fetches on interval |
| Documentation rendering | `react-markdown` | Renders existing `.md` files from the repo without a CMS |
| Deployment | Static hosting (GitHub Pages / Netlify / Vercel) | Zero ops burden; deployable by any team member |

**Trade-offs named:**
- CSS transforms over PixiJS/Konva: gives up GPU-accelerated rendering; gains full DOM accessibility and debuggability.
- Static JSON over WebSockets: gives up true real-time push; gains zero infrastructure cost. Upgrade path is clear if needed.
- React over Svelte/Vue: gives up smaller bundle; gains the broadest cross-role familiarity.

---

## (b) Component Structure / Canvas Architecture

```
App
├── CanvasStage          # Outer viewport — clips overflow, captures pan/zoom gestures
│   └── CanvasWorld      # Infinite 2D plane — transformed via CSS translate + scale
│       ├── CanvasNode (x, y, width, height, sectionId)   × N
│       │   └── <SectionContent />                         # injected by sectionId
│       └── CanvasEdge   # Optional connector lines between nodes
├── NavBar               # Section titles, prev/next arrows, progress indicator
├── ZoomControls         # +/- buttons, reset, fit-to-screen
└── BuildLogDrawer       # Slide-in panel (or dedicated node) for live log
```

### Canvas coordinate system
- World space: arbitrary pixel coordinates (e.g. node 1 at `{x:0, y:0}`, node 2 at `{x:2400, y:0}`)
- Viewport transform: `transform: translate(${panX}px, ${panY}px) scale(${zoom})`
- Navigation animates `panX/panY/zoom` to frame a target node using Framer Motion `animate`
- Touch/trackpad: `onWheel` for zoom, pointer events for drag-pan

### Section content components
Each `CanvasNode` receives a `sectionId` and renders one of:

| sectionId | Component |
|---|---|
| `intro` | `SectionIntro` |
| `llms` | `SectionLLMs` |
| `multiagent` | `SectionMultiAgent` |
| `buildlog` | `SectionBuildLog` |
| `processdocs` | `SectionProcessDocs` |

---

## (c) Build-Log Data Format Schema

File location: `public/data/build-log.json` (static, appended by orchestrator)

```json
{
  "schema_version": "1.0",
  "project": "ai-representation",
  "entries": [
    {
      "id": "ulid-or-uuid",
      "timestamp": "2026-03-22T14:05:00Z",
      "event_type": "task_assigned | task_started | task_completed | handoff_written | error",
      "agent": "orchestrator | worker-a | worker-b",
      "role": "engineering-software-architect | null",
      "summary": "Human-readable one-liner describing what happened",
      "detail": {
        "input_file": "context/tasks/worker-A-current.json",
        "output_file": "context/handoffs/worker-A-result.md",
        "duration_ms": 18400,
        "task_excerpt": "Design technical specification for..."
      }
    }
  ]
}
```

**Event type semantics:**
- `task_assigned` — orchestrator writes a task JSON for a worker
- `task_started` — worker reads task and begins execution
- `task_completed` — worker writes result and done signal
- `handoff_written` — orchestrator acknowledges and reads result
- `error` — any agent failure with message in `detail`

**Append strategy**: Orchestrator and workers append new entries to the `entries` array. The site fetches and diffs by `id` to show only new items without full re-render.

---

## (d) Section/Node Layout on the Canvas

Linear horizontal path. Each node is `1600px × 900px` (16:9). Gap between nodes: `400px`.

```
World X →

[0, 0]              [2000, 0]           [4000, 0]           [6000, 0]           [8000, 0]
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  1. INTRO    │───▶│  2. LLMs     │───▶│  3. AGENTS   │───▶│  4. BUILD    │───▶│  5. PROCESS  │
│              │    │              │    │              │    │     LOG      │    │    DOCS      │
│ What is      │    │ What are     │    │ Orchestrator │    │              │    │              │
│ ai-represent │    │ large lang.  │    │ + Workers    │    │ Live feed of │    │ How this was │
│ -ation?      │    │ models?      │    │ pattern      │    │ agent tasks  │    │ built        │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

**Node detail:**

| # | Title | Key content |
|---|---|---|
| 1 | What is this project? | Project pitch, goals, meta-narrative (built by the system it describes) |
| 2 | What are LLMs? | Conceptual diagram: tokens → attention → generation; analogy-first for non-engineers |
| 3 | Multi-Agent Pattern | Orchestrator + worker-A + worker-B diagram; task contract (read → work → write) |
| 4 | Live Build Log | Auto-polling log viewer; filterable by agent/event type; newest-first |
| 5 | Process Documentation | Rendered Markdown from repo (ADRs, handoffs, setup); linked to actual files |

**Navigation UX:**
- Keyboard: `←` / `→` arrows move between nodes
- Click node title in NavBar to jump
- Scroll/pinch zooms in place
- "Fit all" button zooms out to show full canvas overview (Prezi-style reveal)

---

## (e) Build Log and Docs — Storage and Rendering

### Build Log

**Write path (agents → file):**
```
Orchestrator / Worker
       │
       ▼
public/data/build-log.json   ← append new entry (jq / Node script / PowerShell)
```

A small append helper (`scripts/log-event.js` or `.ps1`) accepts CLI args and appends to the JSON array atomically (read → push → write with file lock or tmp-rename).

**Read path (site → user):**
```
Browser
  │  polls every 5s
  ▼
GET /data/build-log.json
  │
  ▼
SectionBuildLog component
  │  diffs by entry id, appends new rows
  ▼
BuildLogEntry (timestamp | agent badge | event type | summary)
```

Upgrade path: replace polling with `EventSource` (SSE) from a lightweight Node/Deno server when true real-time is needed.

### Process Documentation

**Storage**: Markdown files committed to the repo under `docs/` (ADRs, handoffs, meeting notes).

**Rendering:**
```
/docs/*.md  (static files in public/)
      │
      ▼
fetch() in SectionProcessDocs
      │
      ▼
react-markdown with syntax highlighting (rehype-highlight)
      │
      ▼
Rendered in canvas node with scroll within the node frame
```

A `docs/index.json` manifest lists available docs with title + filename so the section can render a navigation list without directory listing.

---

## ADR Summary

### ADR-001: CSS transforms over a canvas/WebGL engine
**Status**: Proposed
**Context**: Need smooth zoom/pan for a 2D spatial presentation.
**Decision**: Use CSS `transform: translate + scale` with Framer Motion.
**Consequences**: Easier: DOM accessibility, DevTools debugging, no build complexity. Harder: Performance ceiling at very large canvases (mitigated by keeping node count ≤ 10).

### ADR-002: Static JSON build log over a database
**Status**: Proposed
**Context**: Build log must persist agent events without requiring a server.
**Decision**: Append-only JSON file in `public/data/`.
**Consequences**: Easier: zero infrastructure, works locally and on any static host. Harder: No concurrent write safety at scale (acceptable for single-orchestrator setup).

### ADR-003: Markdown files for process documentation
**Status**: Proposed
**Context**: Documentation lives in the repo; mixed team needs to contribute without a CMS.
**Decision**: Commit `.md` files to `docs/`; render with `react-markdown` at runtime.
**Consequences**: Easier: docs are version-controlled alongside code; any team member can edit. Harder: No rich WYSIWYG editor (acceptable trade-off for maintainability).

---

*Result written by Worker A (role: Software Architect) — 2026-03-22*
