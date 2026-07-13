import type { Manifest } from '../manifest.ts';
import { findShader } from './manifest-load.ts';
import { readSession, writeSession, type Session } from './session.ts';
import { validateAndCoerceParams, defaultParamsFor, type Clamp, type ValidateError } from './validate.ts';
import { buildSnippet } from './snippet.ts';

export type ToolCtx = { manifest: Manifest; sessionPath: string };

export function listShaders(ctx: ToolCtx): {
  shaders: { id: string; name: string; category: string; params: number }[];
} {
  return {
    shaders: ctx.manifest.shaders.map((s) => ({
      id: s.id,
      name: s.name,
      category: s.category,
      params: s.params.length,
    })),
  };
}

export function setShader(ctx: ToolCtx, id: string): { ok: boolean; shader?: string; error?: string } {
  const shader = findShader(ctx.manifest, id);
  if (!shader) return { ok: false, error: `unknown shader: ${id}` };
  writeSession(ctx.sessionPath, { shader: id, params: defaultParamsFor(shader) });
  return { ok: true, shader: id };
}

export function setParams(
  ctx: ToolCtx,
  params: Record<string, unknown>,
): { ok: boolean; shader?: string; params?: Record<string, unknown>; clamped?: Clamp[]; errors?: ValidateError[]; error?: string } {
  const current = readSession(ctx.sessionPath);
  if (!current || !current.shader) {
    return { ok: false, error: 'no shader selected; call set_shader first' };
  }
  const shader = findShader(ctx.manifest, current.shader);
  if (!shader) return { ok: false, error: `unknown shader: ${current.shader}` };

  const result = validateAndCoerceParams(shader, params);
  if (!result.ok) {
    return { ok: false, errors: result.errors, clamped: result.clamped };
  }
  const merged = { ...current.params, ...result.params };
  writeSession(ctx.sessionPath, { shader: current.shader, params: merged });
  return { ok: true, shader: current.shader, params: merged, clamped: result.clamped };
}

export function readParams(ctx: ToolCtx): Session | { error: string } {
  return readSession(ctx.sessionPath) ?? { error: 'no session yet' };
}

export function exportSnippet(
  ctx: ToolCtx,
  override?: { shader?: string; params?: Record<string, unknown> },
): { ok: boolean; snippet?: string; error?: string } {
  const current = readSession(ctx.sessionPath);
  const shaderId = override?.shader ?? current?.shader;
  if (!shaderId) return { ok: false, error: 'no shader selected; call set_shader first' };
  const shader = findShader(ctx.manifest, shaderId);
  if (!shader) return { ok: false, error: `unknown shader: ${shaderId}` };
  const params = override?.params ?? (override?.shader ? {} : (current?.params ?? {}));
  return { ok: true, snippet: buildSnippet(shader, params) };
}
