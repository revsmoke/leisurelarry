# Local Godot MCP integration

Upstream: https://github.com/Coding-Solo/godot-mcp

Pinned source: `1209744fad78f3998f98c7394fd0f6ef50da5281` (2026-04-16).
Upstream package version: `0.1.1` (the upstream protocol reports `0.1.0`).
License: MIT; see `LICENSE`.

Local changes, 2026-09-21:

- Pin `@modelcontextprotocol/sdk` to 1.30.0; upstream 0.6.0 has a published advisory.
- Remove unused `axios` and its dependency subtree. Source inspection found no imports or calls.
- Regenerate and retain `package-lock.json`. The installed dependency tree passes `npm audit --omit=dev` with zero advisories at setup time.
- Replace the ESM-incompatible `require('fs')` call with an explicit `readFileSync` import so project names are read correctly.
- Honor `.gdignore` when counting project files, avoiding tooling dependencies and fixture projects.
- Gate Godot operation debug output behind `GODOT_DEBUG=true`; upstream enabled it unconditionally and printed environment/path diagnostics.

`node ../mcp-smoke.mjs` verifies real stdio negotiation and Godot-backed tools using an isolated fixture. Source remains inspectable and rebuildable with `../setup-mcp.sh`.

The server runs locally over stdio. It is development tooling with the calling user's file and process permissions; project-scoped configuration is not a filesystem sandbox. No HTTP listener is configured.
