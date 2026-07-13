# Domain glossary — Metal/Swift shader toolchain

Terms used by `packages/shaders-metal` (TS build pipeline) and
`packages/shaders-metal-swift` (PaperShadersMetal library + PaperShadersPreview app).
Architecture reviews and refactors use these names; don't invent synonyms.

- **Manifest** — `dist/manifest.json`, the contract artifact between the TS pipeline
  and the Swift runtime. One entry per shader (`ShaderEntry`), each with `ParamEntry`s.
- **Param** — a user-facing shader control described in the manifest (name, kind,
  default, bounds). Kinds: `number | boolean | colors | string`.
- **Uniform** — the GPU-side variable a param maps to (`u_*`). A param without a
  uniform is a **runtime-only param** (e.g. `speed`, `frame`): it drives the host
  clock, never the GPU.
- **Runtime uniforms** — uniforms the host injects every frame, never listed as
  params: `u_time`, `u_resolution`, `u_pixelRatio`, `u_noiseTexture`, `u_image`,
  `u_<texture>AspectRatio`. Single vocabulary: `RuntimeUniforms` (Swift).
- **Session vocabulary** — the typed JSON value shape (`JSONValue`:
  number | bool | string | [string]) shared by manifest defaults, presets, and the
  session file. `SessionCodec` translates it to/from `UniformValue`.
- **Session file** — `session/params.json`, the file-as-protocol seam
  (`SessionStore`): external edits flow in, UI edits flow out.
- **Session adoption** — the mount-time decision of whether the persisted session
  file or the sidebar selection wins (`SessionAdoption`); wrong answers here caused
  the "shader switch bounces back" regression.
- **Preset** — a named param bundle in the manifest, applied through the same
  session-vocabulary path as session-file params.
- **Group** — a param's UI section (Colors | Motion | Transform | Effect),
  owned by the manifest (`paramGroup()` in the TS pipeline); the preview app
  reads it, never derives it. **Category** is the shader-level analogue,
  mirrored from the docs site's sections and guarded by a divergence test.
