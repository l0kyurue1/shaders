import { describe, expect, test, beforeAll } from 'bun:test';
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { InMemoryTransport } from '@modelcontextprotocol/sdk/inMemory.js';
import { buildServer } from '../src/mcp-server.ts';   // export a factory: buildServer(sessionPath?) -> McpServer

async function connect(sessionPath: string) {
  const server = buildServer(sessionPath);
  const [ct, st] = InMemoryTransport.createLinkedPair();
  await server.connect(st);
  const client = new Client({ name: 't', version: '0' });
  await client.connect(ct);
  return client;
}
const parse = (r: any) => JSON.parse(r.content[0].text);

describe('mcp server e2e', () => {
  let sessionPath: string, client: Awaited<ReturnType<typeof connect>>;
  beforeAll(async () => {
    sessionPath = join(await mkdtemp(join(tmpdir(),'mcp-')), 'params.json');
    client = await connect(sessionPath);
  });
  test('list_shaders returns 29', async () => {
    expect(parse(await client.callTool({name:'list_shaders', arguments:{}})).shaders.length).toBe(29);
  });
  test('set_shader then read_params', async () => {
    expect(parse(await client.callTool({name:'set_shader', arguments:{id:'warp'}})).ok).toBe(true);
    expect(parse(await client.callTool({name:'read_params', arguments:{}})).shader).toBe('warp');
  });
  test('set_params clamps and merges', async () => {
    const r = parse(await client.callTool({name:'set_params', arguments:{params:{scale:99}}}));
    expect(r.ok).toBe(true);
    expect(r.params.scale).toBe(4);
    expect(r.clamped[0].key).toBe('scale');
  });
  test('set_params rejects unknown key', async () => {
    const r = await client.callTool({name:'set_params', arguments:{params:{bogus:1}}});
    expect(r.isError).toBe(true);
    expect(parse(r).errors[0].code).toBe('unknown_key');
  });
  test('export_snippet bakes current params', async () => {
    const r = parse(await client.callTool({name:'export_snippet', arguments:{}}));
    expect(r.snippet).toContain('PaperShadersMetal');
  });
});
