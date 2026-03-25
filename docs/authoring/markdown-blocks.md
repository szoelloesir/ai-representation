# Markdown Deck Authoring (MVP)

This format is the high-level authoring surface for the Prezi-like MVP.
Users write Markdown with structured fenced blocks. The compiler converts it
into scene graph and camera path data for playback.

## Document shape

- `# <Deck title>` defines the presentation title.
- `## <Frame title>` starts a new frame/step in the presentation path.
- Plain text lines under a frame are rendered as body content.

## Structured blocks

### `layout`

Use this block to place and frame a logical step.

```layout
x: 1100
y: 150
scale: 1.05
rotation: -2
```

- `x`, `y`: camera anchor in canvas coordinates.
- `scale`: zoom level for this frame.
- `rotation`: camera rotation in degrees.

### `motion`

Use this block to define a high-level transition preset.

```motion
preset: panTo
durationMs: 1200
```

- `preset`: one of `focusIn`, `panTo`, `zoomOut`, `revealGroup`.
- `durationMs` (optional): override default transition duration.

### `diagram`

Use this block for diagram-like content without raw runtime structures.

```diagram
title: MVP architecture
AuthorMarkdown -> DeckCompiler
DeckCompiler -> SceneGraph
SceneGraph -> RuntimeViewer
```

- `title` (optional): heading for the diagram block.
- `type` (optional): `flow`, `chart`, or `image`.
- `src` (optional, for `type: image`): image filename to render (e.g. `1.png`).
- `chart` (optional): currently `bar` when `type: chart`.
- `animation` (optional): `none`, `grow`, `pulse`.
- Remaining lines:
  - `flow` mode: free-form diagram text lines.
  - `chart` mode: `Label | value` entries.
  - `image` mode: unused (keep empty).

Example chart block:

```diagram
title: Prompt quality impact
type: chart
chart: bar
animation: grow
SmoothBrain | 25
IdealPrompt | 95
```

Important:

- Do not force charts when they are not needed by the content.
- Prefer `flow` diagrams by default unless the user explicitly asks for chart
  representation.

## Authoring goals

- Avoid low-level scene JSON editing.
- Keep authoring diff-friendly and version-control friendly.
- Let AI draft the Markdown, then refine manually.
