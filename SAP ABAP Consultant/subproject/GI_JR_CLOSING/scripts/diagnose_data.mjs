import path from 'node:path';
import { pathToFileURL } from 'node:url';

const userProfile = process.env.USERPROFILE || 'C:\\Users\\User';
const registryPath = path.join(
  userProfile,
  'Documents',
  'Claude',
  'MCP SAP',
  'sap-leader-mcp',
  'src',
  'tool-registry.js'
);

const reg = await import(pathToFileURL(registryPath).href);
const setActiveServer = reg.HANDLERS['set_active_server'];
const callFunction = reg.HANDLERS['call_function'];
await setActiveServer({ server_ref: 'sandbox-new' });

const res = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: [
      { LINE: 'REPORT ZTMP_DIAGNOSE.' },
      { LINE: 'DATA: lv_max TYPE mkpf-budat,' },
      { LINE: '      lv_min TYPE mkpf-budat.' },
      { LINE: 'SELECT MAX( budat ) INTO lv_max FROM mkpf.' },
      { LINE: 'SELECT MIN( budat ) INTO lv_min FROM mkpf.' },
      { LINE: "WRITE: / 'MIN BUDAT:', lv_min." },
      { LINE: "WRITE: / 'MAX BUDAT:', lv_max." }
    ]
  }
});

console.log('Result:', JSON.stringify(res.result, null, 2));
