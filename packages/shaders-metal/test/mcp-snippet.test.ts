import { describe, expect, test } from 'bun:test';
import { loadManifest, findShader } from '../src/mcp/manifest-load.ts';
import { buildSnippet } from '../src/mcp/snippet.ts';

describe('snippet', () => {
  const warp = findShader(loadManifest(), 'warp')!;

  test('bakes params and SPM install into a SwiftUI snippet', () => {
    const s = buildSnippet(warp, { scale: 2.5, shape: 'stripes' });
    expect(s).toContain('2.5'); // number baked verbatim
    expect(s).toContain('stripes'); // enum label as string
    expect(s).toContain('PaperShadersMetal'); // SPM product
    expect(s).toContain('.package('); // SPM install instruction
    expect(s).toContain('warp'); // shader id
  });
});
