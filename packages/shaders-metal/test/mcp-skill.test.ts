import { expect, test } from 'bun:test';
import { loadManifest } from '../src/mcp/manifest-load.ts';
import { renderSkill } from '../src/mcp/skill.ts';

test('renderSkill covers all shaders with enum options and numeric ranges', () => {
  const m = loadManifest();
  const md = renderSkill(m);

  expect(m.shaders.length).toBe(29);
  for (const s of m.shaders) expect(md).toContain(s.id);

  // warp's `shape` enum options
  expect(md).toContain('checks');
  expect(md).toContain('stripes');

  // a numeric range value (warp `scale` min)
  expect(md).toContain('0.01');

  // a param description substring
  expect(md).toContain('Color transition sharpness');
});
