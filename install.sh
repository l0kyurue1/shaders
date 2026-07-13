#!/usr/bin/env bash
set -euo pipefail

# Install (or update) "Paper Shaders Metal.app" from the latest GitHub release.
#   curl -fsSL https://raw.githubusercontent.com/l0kyurue1/shaders/main/install.sh | bash
# Uninstall:
#   ... | bash -s -- --uninstall
# curl-downloaded zips carry no quarantine xattr, so the ad-hoc-signed app
# launches without Gatekeeper friction.

REPO="l0kyurue1/shaders"
APP="Paper Shaders Metal.app"

if [ "${1:-}" = "--uninstall" ]; then
  removed=0
  for dir in "$HOME/Applications" "/Applications"; do
    if [ -d "$dir/$APP" ]; then
      rm -rf "$dir/$APP"
      echo "Removed $dir/$APP"
      removed=1
    fi
  done
  [ "$removed" = 1 ] || echo "$APP not found — nothing to remove."
  exit 0
fi

dest="$HOME/Applications"
mkdir -p "$dest" 2>/dev/null || dest="/Applications"

url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases" |
  grep -o '"browser_download_url": *"[^"]*/PaperShadersMetal-[^"]*\.zip"' |
  head -1 | sed 's/.*"\(https[^"]*\)"$/\1/')
if [ -z "$url" ]; then
  echo "No Paper Shaders Metal release found in $REPO" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "Downloading ${url##*/} ..."
curl -fSL --progress-bar "$url" -o "$tmp/app.zip"

rm -rf "$dest/$APP"
ditto -x -k "$tmp/app.zip" "$dest"
echo "Installed $dest/$APP"
echo "Launch it with: open \"$dest/$APP\""
