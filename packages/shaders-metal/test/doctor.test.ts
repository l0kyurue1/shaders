import { describe, expect, test } from 'bun:test';
import { checkTools, REQUIRED_TOOLS } from '../src/doctor.ts';

describe('doctor', () => {
  test('reports all four required tools', async () => {
    expect(REQUIRED_TOOLS).toEqual(['glslang', 'spirv-opt', 'spirv-cross', 'xcrun']);
    const reports = await checkTools();
    expect(reports).toHaveLength(4);
    for (const r of reports) {
      expect(typeof r.found).toBe('boolean');
      if (r.found) expect(r.version).not.toBeNull();
    }
  });
});
