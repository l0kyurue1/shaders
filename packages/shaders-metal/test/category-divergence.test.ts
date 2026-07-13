import { describe, expect, test } from 'bun:test';
import { join } from 'node:path';
import { CATEGORY } from '../src/manifest.ts';

const HOME_THUMBNAILS = join(import.meta.dir, '../../../docs/src/app/home-thumbnails.ts');

/** Extracts { shaderId: sectionName } from docs/src/app/home-thumbnails.ts by scanning
 *  for `name: '<Section>', shaders: [` headers and collecting `url: '/<id>'` lines until
 *  the next section header. Deliberately does not import the docs app (different tsconfig/deps). */
function parseHomeSections(source: string): Record<string, string> {
  const headerRe = /\n {2}\{\n {4}name: '([^']+)',\n {4}shaders: \[/g;
  const headers: { name: string; index: number }[] = [];
  for (const m of source.matchAll(headerRe)) headers.push({ name: m[1], index: m.index! });

  const result: Record<string, string> = {};
  headers.forEach((h, i) => {
    const end = i + 1 < headers.length ? headers[i + 1].index : source.length;
    const body = source.slice(h.index, end);
    for (const urlMatch of body.matchAll(/url: '\/([^']+)'/g)) {
      result[urlMatch[1]] = h.name;
    }
  });
  return result;
}

describe('CATEGORY vs docs/src/app/home-thumbnails.ts', () => {
  test('manifest.ts CATEGORY matches the docs home page section membership', async () => {
    const source = await Bun.file(HOME_THUMBNAILS).text();
    const homeSections = parseHomeSections(source);
    expect(Object.keys(homeSections).length).toBeGreaterThan(0); // parser sanity check

    const drifted: string[] = [];
    for (const [id, section] of Object.entries(homeSections)) {
      // Docs' "Effects" section is CATEGORY's implicit fallback — not a dict entry.
      const expected = section === 'Effects' ? undefined : section;
      const actual = CATEGORY[id];
      if (actual !== expected) drifted.push(`${id}: docs says "${section}", CATEGORY has ${JSON.stringify(actual)}`);
    }
    for (const id of Object.keys(CATEGORY)) {
      if (!(id in homeSections)) drifted.push(`${id}: in CATEGORY but not found on the docs home page`);
    }

    expect(drifted, `CATEGORY has drifted from docs/src/app/home-thumbnails.ts:\n${drifted.join('\n')}`).toEqual([]);
  });
});
