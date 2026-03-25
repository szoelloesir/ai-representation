# MVP Baseline Decisions

Date: 2026-03-23
Status: Accepted
Source: User decision capture in chat

## Product Direction

- Audience: Other users, presented by project owner.
- MVP format: Slides with zoom transitions first.
- Future extension: Add free-form canvas zoom later.

## Scope Decisions

- Editor UI: Not needed for MVP.
- AI role in MVP: Both content generation and layout generation.
- Storage: Local files only.
- Authentication: No login for now.
- Architecture/runtime: Frontend-only React + Vite (no backend for now).

## Success Criteria (MVP)

- Presentation includes all required slides.
- Includes one small "gimmick" feature.
- End result is presentable.

## Known Open Items

- Gimmick feature is intentionally undecided.
- Planned adjacent tool context:
  - User is developing a separate tool with OpenViking underneath.
  - The presentation should be able to show context data, tools, and related information.
  - It should also demonstrate how those change when a new task is given.

## Sequencing Decision

1. Keep and remember this baseline now.
2. User completes the context/tooling work first.
3. Then define architecture in detail.
4. Then start implementation.

## Constraints To Preserve

- Avoid assumptions beyond explicit decisions above.
- Validate unclear requirements before implementation.

## Addendum (2026-03-24): Authoring Surface Clarification

- "No editor UI for MVP" means no full drag-and-drop visual editor in this phase.
- MVP still supports richer slide creation through a higher-level authoring format.
- Authoring format for MVP is Markdown with structured blocks (`layout`, `motion`,
  `diagram`) compiled into runtime scene/camera artifacts.
- Raw JSON editing is treated as an implementation detail, not the primary user
  authoring experience.
