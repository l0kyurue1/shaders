import type { Manifest, ParamEntry } from '../manifest.ts';

function paramLine(p: ParamEntry): string {
  const notes: string[] = [p.kind];
  if (p.options) notes.push(`options: ${Object.keys(p.options).join('/')}`);
  else if (p.min !== null && p.max !== null) notes.push(`range ${p.min}–${p.max}`);
  else if (p.min !== null) notes.push(`min ${p.min}`);
  else if (p.max !== null) notes.push(`max ${p.max}`);

  const desc =
    p.uniform === null
      ? (p.description ?? 'host-driven motion (not UBO-packed)')
      : (p.description ?? '');
  return `- \`${p.name}\` (${notes.join(', ')})${desc ? ` — ${desc}` : ''}`;
}

export function renderSkill(m: Manifest): string {
  const out: string[] = [
    '# Paper Shaders (Metal) — param reference',
    '',
    'Drive the preview app in two steps:',
    '',
    '1. `set_shader` with a shader `id` (the backticked id in each heading below).',
    '2. `set_params` with a name-keyed object, e.g. `{ "softness": 0.8 }`.',
    '',
    'Params are keyed by **name**, not uniform slot. Enum values are the **option label string** (e.g. `"shape": "stripes"`), single colors are hex strings (`"#rrggbbaa"`), `colors` is an array of hex strings. `speed` and `frame` are host-driven motion params.',
    '',
  ];

  for (const s of m.shaders) {
    out.push(`## ${s.name} (\`${s.id}\`, ${s.category})`, '');
    for (const p of s.params) out.push(paramLine(p));
    out.push('');
  }

  out.push(
    '## Common intents → param',
    '',
    '- softer / smoother gradient → `softness`',
    '- bigger / zoom → `scale`',
    '- slower / faster motion → `speed`',
    '- rotate → `rotation`',
    '- more distortion → `distortion` / `swirl`',
    ''
  );

  return out.join('\n');
}
