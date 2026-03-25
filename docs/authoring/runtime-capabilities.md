# Runtime Capabilities Snapshot

Current Prezi-like runtime capabilities in this project:

- Markdown-driven deck authoring (`src/content/example-deck.md`).
- Structured blocks: `layout`, `motion`, `diagram`.
- Diagram rendering modes:
  - `flow` (textual relation lines)
  - `chart` (bar chart with optional animation)
  - `image` (render predefined images from `src/content/example-deck-images/`)
- Chart animation modes: `none`, `grow`, `pulse`.
- Keyboard navigation:
  - `ArrowLeft` -> previous frame
  - `ArrowRight` / `Space` -> next frame
- Viewport fitting:
  - Uses real rendered node dimensions (`offsetWidth`/`offsetHeight`)
  - Uses real visible viewport dimensions (`getBoundingClientRect` +
    `visualViewport`)
  - Keeps active frame fully visible via constrained camera scaling.

Authoring constraints:

- Do not force charts unless explicitly needed.
- Use `type: image` only when you want an image diagram (do not add extra content unless requested).
- Avoid assumption-driven additional sections or alternative representations.
