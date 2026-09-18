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

const registry = await import(pathToFileURL(registryPath).href);
const setActiveServer = registry.HANDLERS['set_active_server'];
const callFunction = registry.HANDLERS['call_function'];

console.log('1. Setting active server to sandbox-new (TRS)...');
await setActiveServer({ server_ref: 'sandbox-new' });

console.log('2. Deleting PRODLINE from ZMAP_TYPE...');
const progLines = [
  { LINE: 'REPORT ZTMP_DEL.' },
  { LINE: 'DELETE FROM zmap_type' },
  { LINE: "  WHERE prog = 'ZPPR_GI_JR_CLOSING'" },
  { LINE: "    AND type = 'PRODLINE'." },
  { LINE: 'COMMIT WORK AND WAIT.' },
  { LINE: "WRITE: / 'DELETED:', sy-dbcnt." }
];

const runRes = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: progLines
  }
});

console.log('Delete result:', JSON.stringify(runRes, null, 2));

console.log('3. Checking remaining records in ZMAP_TYPE...');
const checkLines = [
  { LINE: 'REPORT ZTMP_CHK.' },
  { LINE: 'DATA: lt_map TYPE STANDARD TABLE OF zmap_type,' },
  { LINE: '      ls_map TYPE zmap_type.' },
  { LINE: 'SELECT * INTO TABLE lt_map FROM zmap_type' },
  { LINE: "  WHERE prog = 'ZPPR_GI_JR_CLOSING'." },
  { LINE: "WRITE: / 'TOTAL ROWS:', sy-dbcnt." },
  { LINE: 'LOOP AT lt_map INTO ls_map.' },
  { LINE: "  WRITE: / ls_map-type, ls_map-opt, ls_map-value, ls_map-text1." },
  { LINE: 'ENDLOOP.' }
];

const chkRes = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: checkLines
  }
});

console.log('Check result:', JSON.stringify(chkRes, null, 2));
