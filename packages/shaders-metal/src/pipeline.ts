import { join } from 'node:path';
import { prepareForSpirv } from './transform.ts';

export type CompileResult = { id: string; ok: boolean; metalSource: string | null; errors: string[] };

async function run(cmd: string[]): Promise<{ ok: boolean; stderr: string }> {
  const proc = Bun.spawn(cmd, { stdout: 'pipe', stderr: 'pipe' });
  const stderr = await new Response(proc.stderr).text();
  const stdout = await new Response(proc.stdout).text();
  await proc.exited;
  // glslang prints errors to stdout; capture both.
  return { ok: proc.exitCode === 0, stderr: (stderr + stdout).trim() };
}

export async function compileToMetal(
  id: string,
  source: string,
  stage: 'frag' | 'vert',
  workDir: string
): Promise<CompileResult> {
  const glslPath = join(workDir, `${id}.${stage}`);
  const spvPath = `${glslPath}.spv`;
  const metalPath = join(workDir, `${id}.metal`);
  const airPath = join(workDir, `${id}.air`);
  const errors: string[] = [];

  await Bun.write(glslPath, prepareForSpirv(source));

  const steps: [string, string[]][] = [
    ['glslang', ['glslang', '-G', '--auto-map-bindings', '--auto-map-locations', glslPath, '-o', spvPath]],
    ['spirv-cross', ['spirv-cross', '--msl', spvPath, '--output', metalPath]],
    ['metal-validate', ['xcrun', '-sdk', 'macosx', 'metal', '-c', metalPath, '-o', airPath]],
  ];

  for (const [name, cmd] of steps) {
    const { ok, stderr } = await run(cmd);
    if (!ok) {
      errors.push(`[${name}] ${stderr}`);
      return { id, ok: false, metalSource: null, errors };
    }
  }

  return { id, ok: true, metalSource: await Bun.file(metalPath).text(), errors };
}
