import { describe, expect, test } from 'bun:test';
import { mkdtemp, readdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { buildAll } from '../src/build.ts';
import { parseVaryingLocations } from '../src/varyings.ts';

describe('build', () => {
  test('converts the full catalog: 29/29 + vertex + manifest', async () => {
    const dist = await mkdtemp(join(tmpdir(), 'shaders-metal-dist-'));
    const summary = await buildAll(dist);

    expect(summary.failed).toEqual([]); // failure list printed by CLI; must be empty
    expect(summary.total).toBeGreaterThanOrEqual(29);
    expect(summary.succeeded.length).toBe(summary.total);

    expect(await Bun.file(join(dist, 'simplex-noise.metal')).exists()).toBe(true);
    expect(await Bun.file(join(dist, 'vertex.metal')).exists()).toBe(true);
    const manifest = await Bun.file(join(dist, 'manifest.json')).json();
    expect(manifest.version).toBe(1);
    expect(manifest.shaders.length).toBe(summary.total - 1); // vertex has no manifest entry

    // Every fragment varying must sit at the vertex's canonical location for that name,
    // otherwise Metal mislinks vertex→fragment varyings (they're matched by index).
    const canonical = parseVaryingLocations(await Bun.file(join(dist, 'vertex.metal')).text());
    for (const file of await readdir(dist)) {
      if (!file.endsWith('.metal') || file === 'vertex.metal') continue;
      for (const [name, idx] of parseVaryingLocations(await Bun.file(join(dist, file)).text())) {
        expect(canonical.get(name), `${file}: ${name} should match vertex`).toBe(idx);
      }
    }
  }, 600_000);
});
