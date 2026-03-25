# Compiler Contract (MVP)

The compiler turns Markdown deck content into two runtime artifacts:

- `SceneNode[]` (what to render on canvas)
- `CameraFrame[]` (how the camera moves between frames)

## Internal model

The runtime contract is implemented in `src/presentation/types.ts`.

### `SceneNode`

- `id`: stable node identifier.
- `frameId`: frame membership key.
- `type`: `title | text | diagram`.
- `x`, `y`: absolute canvas placement.
- `width`: layout width hint for rendering.
- `height`: estimated layout height (used before runtime measurement).
- `content`: display content.
- `diagram` (optional): structured diagram payload for `flow`/`chart` rendering.

### `CameraFrame`

- `frameId`: target frame.
- `x`, `y`: camera focus position.
- `scale`: zoom.
- `rotation`: view rotation.
- `transition`: `{ durationMs, easing }`.

### `CompiledDeck`

- `title`: deck title.
- `nodes`: flattened render list.
- `cameraPath`: ordered transition path.

## Defaults and mapping rules

- Frames without explicit `layout` use compiler grid placement.
- Frames without `motion` default to `panTo`.
- `motion.preset` maps to transition defaults in
  `src/presentation/presets.ts`.
- `motion.durationMs` overrides preset duration only.
- Frame nodes are vertically stacked (`title` -> `text` -> `diagram`) using
  estimated heights and gaps to avoid overlap.
- Runtime camera fit uses rendered DOM sizes and actual viewport dimensions to
  keep active frame content fully visible.

## Validation posture (MVP)

- Unknown `motion.preset` falls back to `panTo`.
- Missing deck title defaults to `Untitled deck`.
- Missing frame content still produces a title node and camera frame.
- Unknown diagram metadata is ignored; parser falls back to plain flow lines.
