import { spawn } from 'child_process';
import fs from 'fs';

// Node.js script untuk memotong limit payload di tool python,
// kita gunakan twozero MCP client langsung (atau jq trick) jika tersedia.
// Tapi karena MCP SAP ini berjalan via stdio/sse, 
// kita panggil hermes mcp CLI dengan cara streaming.

const payloadPath = 'temp_payload.json';
console.log("Mencoba kirim lewat hermes call_function via file arg...");
