import { pathToFileURL } from 'node:url';

import path from 'node:path';

const userProfile = process.env.USERPROFILE || 'C:\\Users\\User';
const registryPath =
  path.join(userProfile, 'Documents', 'Claude', 'MCP SAP', 'sap-leader-mcp', 'src', 'tool-registry.js');

const toolName = process.argv[2];
const rawArguments = process.argv[3] || '{}';

if (!toolName) {
  throw new Error('Tool name is required.');
}

const registry = await import(pathToFileURL(registryPath).href);
const handler = registry.HANDLERS[toolName];

if (!handler) {
  throw new Error(`Unknown SAP MCP tool: ${toolName}`);
}

let toolArguments;

if (toolName === 'set_active_server' && rawArguments.charAt(0) !== '{') {
  toolArguments = { server_ref: rawArguments };
} else {
  toolArguments = JSON.parse(rawArguments);
}

const result = await handler(toolArguments);
process.stdout.write(JSON.stringify(result, null, 2));
