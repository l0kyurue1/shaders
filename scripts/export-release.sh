#!/usr/bin/env bash
set -euo pipefail

# Mirrors the Swift package into the standalone release repo
# (github.com/l0kyurue1/paper-shaders-metal). Development happens here in the
# monorepo; the mirrored set (Package.swift, Sources/, Tests/) is generated and
# must never be hand-edited in the release repo. Release-repo-specific files
# (README, LICENSE, NOTICE, scripts/, workflows, assets) live there and are
# left untouched by this script.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
release="${RELEASE_REPO:-$repo_root/../../paper-shaders-metal}"
pkg="$repo_root/packages/shaders-metal-swift"

if [ ! -d "$release/.git" ]; then
    echo "error: release repo not found at $release — clone it or set RELEASE_REPO" >&2
    exit 1
fi

"$repo_root/scripts/sync-dist.sh"

rsync -a --delete "$pkg/Sources/" "$release/Sources/"
rsync -a --delete "$pkg/Tests/" "$release/Tests/"
cp "$pkg/Package.swift" "$release/Package.swift"
git -C "$repo_root" rev-parse HEAD > "$release/GENERATED_FROM"

echo "Exported to $release (source $(git -C "$repo_root" rev-parse --short HEAD))"
echo "Next: cd $release && swift test, then commit + tag vX.Y.Z + push"
