# @paper-design/shaders-metal

TypeScript/bun toolchain that converts the web Paper Shaders into Metal
artifacts (`.metal` + `manifest.json`) under `dist/`, plus an MCP server that
lets an agent drive the macOS preview app's shader params.

The artifacts are consumed by
[`packages/shaders-metal-swift`](../shaders-metal-swift) — a Swift runtime
and the **Paper Shaders Metal** macOS app (installable via the curl one-liner
in that README).

```bash
bun run build     # convert all shaders -> dist/ (gitignored, regenerate anywhere)
bun run doctor    # check required toolchain is present
bun test          # run the suite
```

## MCP server + skill

Launch the stdio MCP server:

```bash
bun run mcp
```

Tools it exposes:

- `list_shaders` — list every shader id with its params and presets.
- `set_shader` — switch the active shader (writes `session/params.json`).
- `set_params` — validate/coerce and apply param values to the active shader.
- `read_params` — read the current session shader + params back.
- `export_snippet` — emit a SwiftUI + SPM snippet for a shader + params.

The server writes the shared session file the Swift preview app watches. By
default it targets `packages/shaders-metal-swift/session/params.json`; override
with the `PAPER_SHADERS_SESSION` env var to point at another session file.

Register it with Claude Code:

```bash
claude mcp add paper-shaders-metal -- bun run /Users/yuruei.wan/Documents/Repository/fork/shaders/packages/shaders-metal/src/mcp-server.ts
```

Regenerate the agent skill doc (`.claude/skills/paper-shaders-metal/SKILL.md`,
param semantics for all shaders) after any shader change:

```bash
bun run build && bun run skill
```

## Future direction

A SwiftUI Shader / `[[stitchable]]` export flavor would let developers use a
shader with zero package dependency. Requires moving vertex-stage UV math to
CPU and flattening params to arguments. Effort: L, not started.
