import { mkdtemp, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { extractShaders, extractVertexShader } from './extract.ts';
import { compileToMetal } from './pipeline.ts';
import { buildManifest } from './manifest.ts';
import { parseVaryingLocations, remapFragmentVaryings } from './varyings.ts';
import { renameParamsArg } from './rename-params.ts';
import { shortenFloatLiterals } from './shorten-floats.ts';

export type BuildSummary = {
  total: number;
  succeeded: string[];
  failed: { id: string; errors: string[] }[];
};

export async function buildAll(distDir: string): Promise<BuildSummary> {
  await rm(distDir, { recursive: true, force: true });
  await mkdir(distDir, { recursive: true });
  const workDir = await mkdtemp(join(tmpdir(), 'shaders-metal-work-'));
  const shaders = await extractShaders();

  // Vertex first: its stage_out gives the canonical varying name→location map that
  // every fragment must be renumbered against (Metal links varyings by index).
  const vertexJob = { id: 'vertex', source: await extractVertexShader(), stage: 'vert' as const };
  const fragJobs = shaders.map((s) => ({ ...s, stage: 'frag' as const }));

  const summary: BuildSummary = { total: fragJobs.length + 1, succeeded: [], failed: [] };
  let canonical: Map<string, number> | null = null;

  for (const job of [vertexJob, ...fragJobs]) {
    try {
      const result = await compileToMetal(job.id, job.source, job.stage, workDir);
      if (result.ok && result.metalSource) {
        let metalSource = result.metalSource;
        if (job.stage === 'vert') {
          canonical = parseVaryingLocations(metalSource);
        } else if (canonical) {
          metalSource = remapFragmentVaryings(metalSource, canonical);
        }
        metalSource = renameParamsArg(metalSource);
        metalSource = shortenFloatLiterals(metalSource);
        await Bun.write(join(distDir, `${job.id}.metal`), metalSource);
        summary.succeeded.push(job.id);
      } else {
        summary.failed.push({ id: job.id, errors: result.errors });
      }
    } catch (err) {
      summary.failed.push({
        id: job.id,
        errors: [`[unexpected] ${err instanceof Error ? err.message : String(err)}`],
      });
    }
  }

  const manifestShaders = [];
  for (const s of shaders) {
    if (!summary.succeeded.includes(s.id)) continue;
    try {
      const single = await buildManifest([s.id]);
      manifestShaders.push(...single.shaders);
    } catch (err) {
      summary.succeeded.splice(summary.succeeded.indexOf(s.id), 1);
      summary.failed.push({
        id: s.id,
        errors: [`[manifest] ${err instanceof Error ? err.message : String(err)}`],
      });
    }
  }
  await Bun.write(join(distDir, 'manifest.json'), JSON.stringify({ version: 1, shaders: manifestShaders }, null, 2));
  await rm(workDir, { recursive: true, force: true });
  return summary;
}
