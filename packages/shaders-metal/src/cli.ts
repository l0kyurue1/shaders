import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { checkTools } from './doctor.ts';
import { buildAll } from './build.ts';
import { loadManifest, findShader } from './mcp/manifest-load.ts';
import { renderSkill } from './mcp/skill.ts';
import { buildSnippet } from './mcp/snippet.ts';

const command = process.argv[2];

if (command === 'doctor') {
  const reports = await checkTools();
  for (const r of reports) {
    console.log(`${r.found ? 'ok  ' : 'MISS'} ${r.tool.padEnd(12)} ${r.version ?? '(not found)'}`);
  }
  process.exit(reports.every((r) => r.found) ? 0 : 1);
} else if (command === 'build') {
  const missing = (await checkTools()).filter((r) => !r.found);
  if (missing.length > 0) {
    console.error(`Missing tools: ${missing.map((r) => r.tool).join(', ')}. Run \`bun run doctor\`.`);
    process.exit(1);
  }
  const dist = join(import.meta.dir, '../dist');
  let summary;
  try {
    summary = await buildAll(dist);
  } catch (err) {
    console.error(`build crashed: ${err instanceof Error ? err.message : String(err)}`);
    process.exit(1);
  }
  console.log(`\n${summary.succeeded.length}/${summary.total} shaders converted -> ${dist}`);
  for (const f of summary.failed) {
    console.error(`\nFAIL ${f.id}`);
    for (const e of f.errors) console.error(`  ${e}`);
  }
  process.exit(summary.failed.length === 0 ? 0 : 1);
} else if (command === 'skill') {
  const outFlag = process.argv.indexOf('--out');
  const out =
    outFlag !== -1
      ? process.argv[outFlag + 1]
      : join(import.meta.dir, '../../../.claude/skills/paper-shaders-metal/SKILL.md');
  const frontmatter =
    '---\n' +
    'name: paper-shaders-metal\n' +
    'description: Param semantics for the 29 Paper Shaders Metal shaders — drives the preview app via the MCP tools set_shader/set_params.\n' +
    '---\n\n';
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, frontmatter + renderSkill(loadManifest()));
  console.log(`wrote ${out}`);
  process.exit(0);
} else if (command === 'typecheck-snippet') {
  // Guards snippet.ts's API-shape claims (see its docstring) against real Swift API drift:
  // emit one representative generated snippet and typecheck it against the built module.
  const warp = findShader(loadManifest(), 'warp');
  if (!warp) {
    console.error("shader 'warp' not found in manifest — run `bun run build` first");
    process.exit(1);
  }
  const snippet = buildSnippet(warp, { scale: 2.5, shape: 'stripes' });
  const tmpFile = join(mkdtempSync(join(tmpdir(), 'paper-shaders-snippet-')), 'WarpPreview.swift');
  writeFileSync(tmpFile, snippet);

  const buildDir = join(import.meta.dir, '../../shaders-metal-swift/.build/debug');
  const sdk = (await Bun.$`xcrun --sdk macosx --show-sdk-path`.text()).trim();
  const proc = Bun.spawn(
    ['xcrun', 'swiftc', '-typecheck', tmpFile, '-I', buildDir, '-sdk', sdk, '-target', 'arm64-apple-macos14'],
    { stdout: 'inherit', stderr: 'inherit' }
  );
  process.exit(await proc.exited);
} else {
  console.error('Usage: bun run src/cli.ts <doctor|build|skill|typecheck-snippet>');
  process.exit(1);
}
