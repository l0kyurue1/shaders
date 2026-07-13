export type ToolReport = { tool: string; found: boolean; version: string | null };

export const REQUIRED_TOOLS = ['glslang', 'spirv-opt', 'spirv-cross', 'xcrun'];

const VERSION_ARGS: Record<string, string[]> = {
  glslang: ['--version'],
  'spirv-opt': ['--version'],
  'spirv-cross': ['--revision'],
  xcrun: ['-sdk', 'macosx', 'metal', '--version'],
};

export async function checkTools(): Promise<ToolReport[]> {
  return Promise.all(
    REQUIRED_TOOLS.map(async (tool) => {
      try {
        const proc = Bun.spawn([tool, ...VERSION_ARGS[tool]], { stdout: 'pipe', stderr: 'pipe' });
        const out = await new Response(proc.stdout).text();
        const err = await new Response(proc.stderr).text();
        await proc.exited;
        const version = (out + err).trim().split('\n')[0] || null;
        return { tool, found: proc.exitCode === 0, version };
      } catch {
        return { tool, found: false, version: null };
      }
    })
  );
}
