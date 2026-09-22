# Godot development environment

Verified on 2026-09-21 on this Apple Silicon Mac.

## Installed and exercised

| Component | Version / location | Verification |
| --- | --- | --- |
| Godot standard edition | `4.7.2.stable.official.ed1daf0bf` at `/Applications/Godot.app` | Native version check, headless version check, archive SHA-256, macOS signature verification |
| Export templates | `4.7.2.stable`, macOS and Web | Official archive SHA-256 verified; templates installed under the user's Godot support directory |
| Node.js | `v24.14.1` | Runs and builds the MCP server |
| Godot MCP | Coding-Solo source revision `1209744fad78f3998f98c7394fd0f6ef50da5281` | Six protocol/tool checks, including real Godot scene creation |
| MCP TypeScript SDK | `1.30.0`, exact dependency in lockfile | Server builds; stdio negotiation and calls pass |
| Godot GDScript Patterns skill | wshobson/agents revision `4236bb91f8395b0435f1d8b8baf9e8e4c69a8620` | Skill and both referenced documents inspected; MIT license retained |

The official macOS download page listed **4.7.2**, released August 18, 2026. The standard edition is sufficient for GDScript; a .NET SDK is unnecessary. Godot is a self-contained application. [Official macOS download](https://godotengine.org/download/macos/)

The downloaded `Godot_v4.7.2-stable_macos.universal.zip` has SHA-256 `c58a24e31d720be9d62f60cb5627c4e695fb72f21b0cfe1bc9ccaa9a3b3ba63e`, matching the asset digest returned by the release API. `codesign --verify --deep --strict /Applications/Godot.app` passed. [Official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable), [release metadata](https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable)

Homebrew was initially unavailable because this machine's Xcode license had not been accepted. Installation used the official standalone archive instead. No Xcode settings, license acceptance, shell profiles, or global MCP configuration were changed.

macOS and Web export templates are installed in `/Users/twoedge/Library/Application Support/Godot/export_templates/4.7.2.stable/` (207 MB). The official `Godot_v4.7.2-stable_export_templates.tpz` archive matched SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` before extraction. Only the useful macOS/Web templates, version marker, and ICU data were installed; other platforms can be installed later from the same official archive. The large downloaded archives were removed after verification and installation. [Official release assets](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)

## Run and inspect the game

Run these commands from the repository root:

```sh
./tools/godot --version
./tools/godot --editor --path .
./tools/godot --path .
./tools/godot --headless --path . --import
./tools/godot --headless --path . --quit-after 30
```

`tools/godot` first honors `GODOT_PATH`, then the installed macOS application, then a `godot` executable on `PATH`. Other computers can set `GODOT_PATH` to their engine executable. Headless import checks resources and scripts without opening an editor window. Godot's command-line reference documents `--headless`, `--path`, `--import`, `--script`, and export commands. [Official CLI documentation](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)

For an individual script without project dependencies:

```sh
./tools/godot --headless --path . --check-only --script res://scripts/example.gd
```

Use the actual project smoke tests to validate scripts with singletons, imported resources, or scene dependencies; standalone parsing does not exercise those relationships.

## Package native and browser builds

The checked-in `export_presets.cfg` provides `macOS` and `Web` presets. Rebuild both with:

```sh
./tools/package.sh
```

Or pass `macos` or `web` to rebuild one target. The output locations are:

- `exports/macos/Last Call in Lost Wages.app`
- `exports/Last Call in Lost Wages-macOS.zip`
- `exports/web/index.html`, with its required JS, WASM, and PCK siblings
- `exports/Last Call in Lost Wages-Web.zip`, a browser-build archive with `index.html` at its root

The native preset is universal arm64/x86_64 and uses Godot's built-in **ad-hoc** signature for local execution. It uses no Developer ID credentials and is not notarized or App Store signed. The browser preset uses the Compatibility renderer configured by the game, disables threads and extensions, and requires no cross-origin isolation workaround. This follows Godot's single-thread Web export guidance. [macOS exports](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html), [Web exports](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

`tools/package.sh` imports the project, exports the requested targets, packages the app in a zip, then runs `tools/verify-exports.mjs`. The verifier reads the actual PCK directory, checks game assets/music/font-license inclusion, and rejects research screenshots, development tools, docs, tests, the supplied walkthrough snippet, and raw GDScript source. Its JSON report and per-file resource inventory appear in `exports/export-verification-*.json`. The parser follows the engine's [PCK reader](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/file_access_pack.cpp).

Native exports also run `tools/smoke-native.mjs`: it verifies the ad-hoc bundle signature and executes the **exported app binary** headlessly for 30 frames, rejecting errors in its output. The result is recorded in `exports/native-smoke-result.json`. Browser rendering and interaction are inspected separately.

The final build completed on September 21, 2026 local time, including the final shop and blackjack hotspot/description corrections. Both packs contain 53 runtime resources, all 13 background textures/imports, all 3 fonts and their licenses, music, and compiled casino code. Both have SHA-256 `398eddee7fc6582d64f4202a6d2244027ccd43293bcb648a611d2648778b98ff`. The export log contains no errors or warnings; the exported native app passes its signature and 30-frame runtime checks with no errors. Both zip archives pass decompression integrity checks and exclude AppleDouble metadata.

Final artifact sizes: macOS zip **91,076,560 bytes**; universal app bundle **201,767,297 bytes** summed file sizes; Web zip **40,614,489 bytes**; unpacked Web directory **70,354,991 bytes**. Exact archive hashes and paths are recorded in `exports/build-artifacts.json`, regenerated automatically by `tools/build-manifest.mjs` at the end of packaging. The Web preview remains available on loopback port 8766 during the development session.

Serve the exported browser build locally:

```sh
node tools/serve-web.mjs
```

Open `http://127.0.0.1:8766`. This server only serves the Web export directory on loopback and provides the WASM MIME type. Opening the HTML through `file://` is not supported. Browser audio may require the first click; browser save persistence depends on allowed site storage. [Godot Web limitations](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

## Project-local MCP setup

The reviewed, inspectable server source lives in `tools/godot-mcp/`. Its upstream MIT license is retained. Changes to dependencies, ESM project-name reading, `.gdignore` handling, and opt-in debug output are recorded in `tools/godot-mcp/LOCAL-CHANGES.md`.

Rebuild the exact dependency tree and exercise the connection:

```sh
./tools/setup-mcp.sh
node tools/mcp-smoke.mjs
codex mcp get godot --json
```

The smoke test negotiates MCP over **stdio**, lists all **14 tools**, retrieves the engine version, discovers a fixture project, reads its actual configured name, creates a `Node2D` scene with Godot, and adds a `Label` whose saved text is checked on disk. It deletes its own fixture afterward. All six checks passed. The final dependency audit reported **zero vulnerabilities**. This is a dependency-advisory check and focused source review, not a comprehensive security certification.

The project includes both:

- `.codex/config.toml`: Codex project-scoped configuration. `codex mcp get godot --json` confirmed it is enabled and resolves to the local server.
- `.mcp.json`: equivalent generic JSON configuration for compatible MCP clients.

Both configurations use the current machine's absolute Node/server/engine paths so GUI clients do not depend on an interactive shell's Node initialization. Update these three paths if the repository moves or another computer opens it. A new/restarted MCP session loads the configuration; the current coding session also exercised the server directly through its SDK client. Codex supports project-scoped MCP tables in trusted projects. [Official OpenAI MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)

The server exposes editor launch, project run/stop/debug output, version/project inspection, scene creation/editing, sprite loading, MeshLibrary export, scene saving, and UID tools. It does **not** provide a full live editor debugger, screen capture, or automated mouse input; use the installed engine and computer-use tools for visual inspection. [Upstream server documentation](https://github.com/Coding-Solo/godot-mcp)

MCP is local stdio, with no network listener configured. It runs with the caller's file/process permissions; project-scoped registration is not a filesystem sandbox. `tools/.gdignore` excludes development tooling and test fixtures from Godot's resource scan. Package caches, dependencies, and compiled server output are ignored by Git.

## MCP candidates researched

| Server | Findings and decision |
| --- | --- |
| [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | Chosen: 5,775 stars at inspection, compact 14-tool scope, inspectable TypeScript plus headless GDScript, MIT. No editor addon or network listener needed. Upstream dependency age was addressed locally and verified. |
| [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) | Richer runtime/editor tool surface and Godot 4.7 support advertised by the author. Its 157-tool surface and runtime code execution exceed this game's immediate needs. Not installed. |
| [Fulviuus/godot-mcp](https://github.com/Fulviuus/godot-mcp) | Advertises version-specific docs, headless exports, runtime screenshots/control, optional HTTP, and a Tauri manager. More moving parts than needed here. Not installed. |
| [sterion66/godot-mcp-server](https://github.com/sterion66/godot-mcp-server) | Python/FastMCP alternative with a workspace-root restriction and explicit execution flag; relevant if stricter tool-level path controls are required. Not installed. |

Source inspection of the selected server confirmed engine calls use `spawn` or `execFile` with argument arrays, rather than shell interpolation. The source did not use its bundled Axios dependency, which was removed. The upstream SDK dependency was updated from 0.6.0 to 1.30.0; the local server then built and passed real protocol tests. These are observations about the pinned local source, not assumptions about future upstream versions.

## Godot skills researched

The find-skills workflow checked the [skills.sh directory](https://skills.sh/) and ran `npx --yes skills find godot`. Repository stars were checked through each author's GitHub API, and the chosen skill's complete text and references were read before installation.

| Candidate | Discovery snapshot | Result |
| --- | --- | --- |
| [wshobson/agents — godot-gdscript-patterns](https://skills.sh/wshobson/agents/godot-gdscript-patterns) | 15.6K installs; source repository 39,854 stars | Installed under `.agents/skills/godot-gdscript-patterns/` at a fixed revision, with source attribution and license. |
| [thedivergentai/gd-agentic-skills — godot-master](https://skills.sh/thedivergentai/gd-agentic-skills/godot-master) | 3.8K installs; source repository 737 stars | Found; not installed. |
| [gamedev-skills — godot-ui-control](https://skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-ui-control) | 3K installs; source repository 1,089 stars | Found; not installed. |
| [zate/cc-godot — godot-development](https://skills.sh/zate/cc-godot/godot-development) | 1.4K installs | Found; not installed. |

The installed skill covers typed GDScript, signals, scene/state organization, resource data, UI-independent state, persistence, and performance. It is **community guidance**, not an official Godot standard. Example code needs validation against the current engine: its encrypted-save placeholder is not a secret-management solution, and the generic `Node` pooling example assumes visual properties not available on every Node. We use the architecture guidance selectively and validate the game's actual behavior. [Pinned skill source](https://github.com/wshobson/agents/tree/4236bb91f8395b0435f1d8b8baf9e8e4c69a8620/plugins/game-development/skills/godot-gdscript-patterns)

Further primary references for implementation:

- [GDScript basics](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [Control class and GUI input](https://docs.godotengine.org/en/stable/classes/class_control.html)
- [Using signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Saving games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)
- [Exporting for macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
