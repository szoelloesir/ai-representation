# OpenViking Sync Note

Date: 2026-03-24
Status: Pending MCP availability

OpenViking MCP server was in an error state during this update window, so this
project-side note captures context intended for OV persistence when MCP is
healthy again.

## Context to persist

- Runtime now supports structured diagram rendering with optional charts and
  animations.
- Frame layout logic uses vertical stacking to reduce node overlap.
- Camera fitting uses real rendered node dimensions and real viewport size.
- Explicit rule added: avoid assumption-driven additions unless user requests
  them.
- Prompt logging policy supports placeholder entries for very large input
  payloads to avoid duplicating wall-of-text content.
