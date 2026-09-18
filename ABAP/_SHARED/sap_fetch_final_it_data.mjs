import { serverManager } from 'file:///C:/Users/Lenovo/Documents/Claude/MCP%20SAP/sap-leader-mcp/src/server-manager.js';
import { read_program } from 'file:///C:/Users/Lenovo/Documents/Claude/MCP%20SAP/sap-leader-mcp/src/tools/abap-tools.js';

await serverManager.loadConfig();
await serverManager.setActiveServer('dev');
const result = await read_program({ program_name: 'ZQMI_COA_F01' });
const lines = result.source.split('\n');
console.log(JSON.stringify(lines.slice(495, 725).map((text, index) => ({
  line: index + 496, text
})), null, 2));
