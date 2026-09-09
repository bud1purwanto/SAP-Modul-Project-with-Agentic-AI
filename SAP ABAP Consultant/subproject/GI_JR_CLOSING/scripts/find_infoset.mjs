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
      { LINE: 'REPORT ZTMP_FIND_ISET.' },
      { LINE: 'DATA: lv_iset TYPE aqs_isname VALUE \'ORDER_MOVEMENT\',' },
      { LINE: '      ls_head TYPE rsaqhead,' },
      { LINE: '      lt_db   TYPE STANDARD TABLE OF rsaqdb,' },
      { LINE: '      ls_db   TYPE rsaqdb.' },
      { LINE: 'CALL FUNCTION \'RSAQ_READ_INFOSET\'' },
      { LINE: '  EXPORTING' },
      { LINE: '    i_iset  = lv_iset' },
      { LINE: '  IMPORTING' },
      { LINE: '    o_head  = ls_head' },
      { LINE: '  TABLES' },
      { LINE: '    o_db    = lt_db' },
      { LINE: '  EXCEPTIONS' },
      { LINE: '    OTHERS  = 1.' },
      { LINE: 'WRITE: / \'SUBRC:\', sy-subrc, \'HEAD:\', ls_head-name, ls_head-text.' },
      { LINE: 'LOOP AT lt_db INTO ls_db.' },
      { LINE: '  WRITE: / ls_db-dbtab, ls_db-text.' },
      { LINE: 'ENDLOOP.' }
    ]
  }
});
console.log(JSON.stringify(res.result?.WRITES, null, 2));
