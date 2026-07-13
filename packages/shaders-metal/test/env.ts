import { existsSync } from 'node:fs';
import { join } from 'node:path';

// The repo-wide `bun test` job runs on Linux, where the Metal toolchain cannot exist.
// Tests gated on these flags run for real in the macOS shaders-metal workflow.
export const hasMetalToolchain = ['glslang', 'spirv-cross', 'xcrun'].every((t) => Bun.which(t) !== null);
export const hasDist = existsSync(join(import.meta.dir, '../dist/manifest.json'));
