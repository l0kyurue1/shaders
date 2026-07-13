import type { ParamEntry, ShaderEntry } from '../manifest.ts';

export type ValidateError = {
  key: string;
  code: 'unknown_key' | 'wrong_type' | 'bad_enum' | 'bad_color' | 'too_many_colors';
  message: string;
  valid?: string[];
};
export type Clamp = { key: string; from: number; to: number; bound: 'min' | 'max' };
export type ValidateResult = {
  ok: boolean;
  params: Record<string, unknown>;
  clamped: Clamp[];
  errors: ValidateError[];
};

const HEX = /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

export function validateAndCoerceParams(shader: ShaderEntry, input: Record<string, unknown>): ValidateResult {
  const byName = new Map(shader.params.map((p) => [p.name, p]));
  const params: Record<string, unknown> = {};
  const clamped: Clamp[] = [];
  const errors: ValidateError[] = [];

  for (const [key, value] of Object.entries(input)) {
    const param = byName.get(key);
    if (!param) {
      errors.push({
        key,
        code: 'unknown_key',
        message: `unknown param "${key}"`,
        valid: shader.params.map((p) => p.name),
      });
      continue;
    }
    const coerced = coerce(param, key, value, clamped, errors);
    if (coerced !== SKIP) params[key] = coerced;
  }

  return { ok: errors.length === 0, params, clamped, errors };
}

const SKIP = Symbol('skip');

function coerce(
  param: ParamEntry,
  key: string,
  value: unknown,
  clamped: Clamp[],
  errors: ValidateError[],
): unknown {
  switch (param.kind) {
    case 'number': {
      if (typeof value !== 'number') {
        errors.push({ key, code: 'wrong_type', message: `${key} must be a number` });
        return SKIP;
      }
      let v = value;
      if (param.min != null && v < param.min) {
        clamped.push({ key, from: v, to: param.min, bound: 'min' });
        v = param.min;
      } else if (param.max != null && v > param.max) {
        clamped.push({ key, from: v, to: param.max, bound: 'max' });
        v = param.max;
      }
      return v;
    }
    case 'boolean': {
      if (typeof value !== 'boolean') {
        errors.push({ key, code: 'wrong_type', message: `${key} must be a boolean` });
        return SKIP;
      }
      return value;
    }
    case 'string': {
      if (param.options === null) {
        if (typeof value !== 'string' || !HEX.test(value)) {
          errors.push({ key, code: 'bad_color', message: `${key} must be a hex color like #rrggbb[aa]` });
          return SKIP;
        }
        return value;
      }
      const valid = Object.keys(param.options);
      if (typeof value !== 'string' || !valid.includes(value)) {
        errors.push({ key, code: 'bad_enum', message: `${key} must be one of ${valid.join(', ')}`, valid });
        return SKIP;
      }
      return value;
    }
    case 'colors': {
      if (!Array.isArray(value) || !value.every((c) => typeof c === 'string' && HEX.test(c))) {
        errors.push({ key, code: 'bad_color', message: `${key} must be an array of hex colors` });
        return SKIP;
      }
      if (param.maxCount != null && value.length > param.maxCount) {
        errors.push({
          key,
          code: 'too_many_colors',
          message: `${key} accepts at most ${param.maxCount} colors`,
        });
        return SKIP;
      }
      return value;
    }
  }
}

export function defaultParamsFor(shader: ShaderEntry): Record<string, unknown> {
  const preset = shader.presets.find((p) => p.name === 'Default');
  if (preset?.params) return { ...preset.params };
  return Object.fromEntries(shader.params.map((p) => [p.name, p.default]));
}
