#!/usr/bin/env bash
set -euo pipefail

# Build a distributable "Paper Shaders Metal.app" + zip (universal, ad-hoc signed).
# Usage: scripts/make-app-bundle.sh [version] [outdir]

version="${1:-0.0.0-dev}"
outdir="${2:-dist-app}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
pkg="$repo_root/packages/shaders-metal-swift"

cd "$pkg"
swift build -c release --arch arm64 --arch x86_64 --product PaperShadersPreview
products="$(swift build -c release --arch arm64 --arch x86_64 --product PaperShadersPreview --show-bin-path)"

app="$repo_root/$outdir/Paper Shaders Metal.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

cp "$products/PaperShadersPreview" "$app/Contents/MacOS/"
cp -R "$products"/PaperShadersMetal_*.bundle "$app/Contents/Resources/"
cp -R "$repo_root/packages/shaders-metal/dist" "$app/Contents/Resources/dist"
cp "$pkg/Sources/PaperShadersPreview/Resources/AppIcon.icns" "$app/Contents/Resources/"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>PaperShadersPreview</string>
    <key>CFBundleIdentifier</key><string>dev.yuruei.PaperShadersMetal</string>
    <key>CFBundleName</key><string>Paper Shaders Metal</string>
    <key>CFBundleDisplayName</key><string>Paper Shaders Metal</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${version}</string>
    <key>CFBundleVersion</key><string>${version}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$app"

zip="$repo_root/$outdir/PaperShadersMetal-${version}.zip"
rm -f "$zip"
ditto -c -k --keepParent "$app" "$zip"
echo "Built: $app"
echo "Zip:   $zip"
