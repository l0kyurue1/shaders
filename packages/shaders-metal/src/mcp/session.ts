import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';

export type Session = { shader: string; params: Record<string, unknown> };

export function resolveSessionPath(): string {
  return process.env.PAPER_SHADERS_SESSION ?? join(import.meta.dir, '../../../shaders-metal-swift/session/params.json');
}

export function readSession(path: string): Session | null {
  if (!existsSync(path)) return null;
  return JSON.parse(readFileSync(path, 'utf8'));
}

export function writeSession(path: string, s: Session): void {
  mkdirSync(dirname(path), { recursive: true });
  const tmp = path + '.tmp';
  writeFileSync(tmp, JSON.stringify(s, null, 2));
  renameSync(tmp, path);
}
