# Slide Placement Guide (Prezi-like Canvas)

This guide helps you place frames on the canvas so camera fitting and transitions look stable.

## Coordinate System

- `layout.x` / `layout.y` are canvas coordinates (world space).
- The runtime places three cards per frame vertically (title -> text -> diagram).
- Navigation computes camera translation/zoom to keep the *active frame* fully visible.

## Grouping Strategy

1. Define logical groups (e.g., “intro + first visual sequence”, “method explanation”, “tools/demo”).
2. Put groups in separated regions of the canvas so non-active frames do not visually bleed into the viewport.
3. Within a group, keep consecutive frames relatively close so motion feels coherent.

## Spacing Rules

- Use a larger gap between groups than between frames within the same group.
- If you see other frames “leaking” into the viewport, increase the inter-group spacing (x/y distance).

## Mixing Movement Directions

- If the deck order is linear, you can still mix camera movement by varying `x` and `y` offsets between neighboring frames.
- Suggested approach:
  - Keep frame N and frame N+1 close in the *same cluster*,
  - but place frame N+2 with a different preferred direction (e.g., down-right after up-right).

## Practical Checklist

- Do you want the next 3 frames to be “one visual sequence”? Cluster them tightly.
- Are you expecting a visual-only frame (like `diagram type: image`)? Keep captions short to reduce fit-zoom-out.
- Need a stable fit? Ensure the frame’s body text is short enough that the active frame bounds don’t force heavy zoom-out.

