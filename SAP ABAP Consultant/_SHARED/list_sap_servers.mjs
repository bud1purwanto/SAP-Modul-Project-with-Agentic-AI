import { HANDLERS } from 'file:///C:/Users/Lenovo/Documents/Claude/MCP%20SAP/sap-leader-mcp/src/tool-registry.js';

const servers = await HANDLERS.list_servers({});
console.log(JSON.stringify(servers, null, 2));
