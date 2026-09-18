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

await setActiveServer({ server_ref: 'sandbox-new' });

const res = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: [
      { LINE: 'REPORT ZTMP_TEST_SUBMIT.' },
      { LINE: 'RANGES: r_werks FOR mseg-werks,' },
      { LINE: '        r_budat FOR mkpf-budat.' },
      { LINE: "r_werks-sign = 'I'. r_werks-option = 'EQ'. r_werks-low = '2000'." },
      { LINE: 'APPEND r_werks.' },
      { LINE: "r_budat-sign = 'I'. r_budat-option = 'BT'." },
      { LINE: "r_budat-low = '20240101'. r_budat-high = '20240110'." },
      { LINE: 'APPEND r_budat.' },
      { LINE: "SUBMIT zppr_gi_jr_closing" },
      { LINE: "  WITH p_rpt = 'X'" },
      { LINE: "  WITH r_no261 = 'X'" },
      { LINE: "  WITH s_werks IN r_werks" },
      { LINE: "  WITH s_budat IN r_budat" },
      { LINE: '  AND RETURN.' },
      { LINE: "WRITE: / 'SUBMIT_SUCCESS, SY-SUBRC =', sy-subrc." }
    ]
  }
});

console.log('Test Result:', JSON.stringify(res.result, null, 2));
