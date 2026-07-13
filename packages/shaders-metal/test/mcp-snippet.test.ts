import { describe, expect, test } from 'bun:test';
import { loadManifest, findShader } from '../src/mcp/manifest-load.ts';
import { buildSnippet } from '../src/mcp/snippet.ts';
import { hasDist } from './env.ts';

describe.skipIf(!hasDist)('snippet', () => {
  const warp = hasDist ? findShader(loadManifest(), 'warp')! : (null as any);

  test('bakes params and SPM install into a SwiftUI snippet', () => {
    const s = buildSnippet(warp, { scale: 2.5, shape: 'stripes' });
    expect(s).toContain('2.5'); // number baked verbatim
    expect(s).toContain('stripes'); // enum label as string
    expect(s).toContain('PaperShadersMetal'); // SPM product
    expect(s).toContain('.package('); // SPM install instruction
    expect(s).toContain('warp'); // shader id
  });
});
