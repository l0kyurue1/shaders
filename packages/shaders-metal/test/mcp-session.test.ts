import { describe, expect, test } from 'bun:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { readSession, writeSession, type Session } from '../src/mcp/session.ts';

describe('session IO', () => {
  test('round-trips and creates parent dir', async () => {
    const dir = await mkdtemp(join(tmpdir(), 'sess-'));
    const p = join(dir, 'nested', 'params.json');
    const s: Session = { shader: 'warp', params: { scale: 1.5, fit: 'contain' } };
    writeSession(p, s);
    expect(readSession(p)).toEqual(s);
    await rm(dir, { recursive: true, force: true });
  });
  test('missing file -> null', () => {
    expect(readSession('/no/such/params.json')).toBeNull();
  });
});
