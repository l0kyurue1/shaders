import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { loadManifest } from './mcp/manifest-load.ts';
import { resolveSessionPath } from './mcp/session.ts';
import { listShaders, setShader, setParams, readParams, exportSnippet, type ToolCtx } from './mcp/tools.ts';

const text = (result: unknown) => ({ type: 'text' as const, text: JSON.stringify(result) });

export function buildServer(sessionPath?: string): McpServer {
  const ctx: ToolCtx = { manifest: loadManifest(), sessionPath: sessionPath ?? resolveSessionPath() };
  const server = new McpServer({ name: 'paper-shaders-metal', version: '0.0.1' });

  server.registerTool('list_shaders', { description: 'List all available shaders.' }, async () => ({
    content: [text(listShaders(ctx))],
  }));

  server.registerTool(
    'set_shader',
    { description: 'Select the active shader and reset its params to defaults.', inputSchema: { id: z.string() } },
    async ({ id }) => {
      const r = setShader(ctx, id);
      return { content: [text(r)], isError: !r.ok };
    },
  );

  server.registerTool(
    'set_params',
    { description: 'Validate, clamp, and merge params into the active shader session.', inputSchema: { params: z.record(z.string(), z.unknown()) } },
    async ({ params }) => {
      const r = setParams(ctx, params);
      return { content: [text(r)], isError: !r.ok };
    },
  );

  server.registerTool('read_params', { description: 'Read the current shader session.' }, async () => ({
    content: [text(readParams(ctx))],
  }));

  server.registerTool(
    'export_snippet',
    {
      description: 'Export a self-contained SwiftUI snippet with params baked in.',
      inputSchema: { shader: z.string().optional(), params: z.record(z.string(), z.unknown()).optional() },
    },
    async (args) => {
      const r = exportSnippet(ctx, args);
      return { content: [text(r)], isError: !r.ok };
    },
  );

  return server;
}

if (import.meta.main) {
  const server = buildServer();
  await server.connect(new StdioServerTransport());
}
