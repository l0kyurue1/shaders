#!/usr/bin/env bash
set -euo pipefail

# Copies packages/shaders-metal/dist build artifacts (fragment + vertex .metal,
# manifest.json, snippet.swift.tmpl) into the Swift package as a bundled resource,
# so PaperShadersMetal works for downstream SPM consumers with no
# packages/shaders-metal/dist checkout. Re-run after `bun run build` in packages/shaders-metal.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dist="$repo_root/packages/shaders-metal/dist"
dest="$repo_root/packages/shaders-metal-swift/Sources/PaperShadersMetal/Resources/PrecompiledShaders"

if [ ! -f "$dist/manifest.json" ]; then
    echo "error: $dist/manifest.json not found — run 'bun run build' in packages/shaders-metal first" >&2
    exit 1
fi

rm -rf "$dest"
mkdir -p "$dest"
cp "$dist"/*.metal "$dist/manifest.json" "$dist/snippet.swift.tmpl" "$dest/"

echo "Synced $(ls "$dest"/*.metal | wc -l | tr -d ' ') .metal files + manifest.json + snippet.swift.tmpl into $dest"
