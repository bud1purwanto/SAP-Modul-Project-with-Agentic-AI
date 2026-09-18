import fs from 'fs';
import { execSync } from 'child_process';

const source = fs.readFileSync('src/ZPPI_COHVPI.abap', 'utf8');
const lines = source.split('\n');
const it_source = lines.map(line => ({ LINE: line }));

// Kita akan tulis ke JSON sementara dan memanggil MCP server via terminal
fs.writeFileSync('temp_payload.json', JSON.stringify({
  function_name: 'Z_RFC_PROGRAM_UPDATE',
  parameters: {
    IV_PROGRAM_NAME: 'ZPPI_COHVPI',
    IV_PACKAGE: '$TMP',
    IV_CORRNUMBER: ' ',
    IT_SOURCE: it_source
  }
}));

console.log("Payload ready. Gunakan mcp__MCP_SAP__call_function");
