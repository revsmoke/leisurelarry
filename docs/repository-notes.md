# Repository setup

The project's origin is [revsmoke/leisurelarry](https://github.com/revsmoke/leisurelarry), with `main` as the working branch. The GitHub repository was empty when this checkout was initialized on September 21, 2026.

Version control includes the Godot project and source, original game assets, font licenses, research references, walkthrough notes, test code, browser test evidence, development scripts, project skills, and dependency lockfiles. Godot import settings (`*.import`) and resource identifiers (`*.uid`) are retained; Godot's generated `.godot/` cache is excluded.

The reviewed Godot MCP source in `tools/godot-mcp/` is intentionally vendored because it contains local fixes documented in its `LOCAL-CHANGES.md`. Its upstream MIT license and package lockfile are retained. Recreate its dependencies and build output with `./tools/setup-mcp.sh`.

`.env` and other local environment files, credential files, installed dependencies, caches, logs, downloaded tooling, and generated game exports are ignored. Keep API keys in a local `.env`; never commit real key values. The MCP configurations currently contain this Mac's absolute development paths and need adjustment on another machine, as documented in [tooling.md](tooling.md).

Release binaries are generated with `./tools/package.sh all` and deliberately remain outside Git history. The working assets and evidence fit ordinary Git; no Git LFS requirement was needed at initialization.
