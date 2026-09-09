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
      { LINE: 'REPORT ZTMP_TEST_LIVE.' },
      { LINE: 'DATA: lt_list TYPE STANDARD TABLE OF abaplist.' },
      { LINE: 'RANGES: r_werks FOR mseg-werks,' },
      { LINE: '        r_budat FOR mkpf-budat.' },
      { LINE: "r_werks-sign = 'I'. r_werks-option = 'EQ'. r_werks-low = '2000'." },
      { LINE: 'APPEND r_werks.' },
      { LINE: "r_budat-sign = 'I'. r_budat-option = 'BT'." },
      { LINE: "r_budat-low = '20240101'. r_budat-high = '20241231'." },
      { LINE: 'APPEND r_budat.' },
      { LINE: 'SUBMIT zppr_gi_jr_closing' },
      { LINE: "  WITH p_rpt = 'X'" },
      { LINE: "  WITH r_all = 'X'" },
      { LINE: '  WITH s_werks IN r_werks' },
      { LINE: '  WITH s_budat IN r_budat' },
      { LINE: '  EXPORTING LIST TO MEMORY' },
      { LINE: '  AND RETURN.' },
      { LINE: "WRITE: / 'SUBMIT DONE. SY-SUBRC =', sy-subrc." },
      { LINE: 'CALL FUNCTION \'LIST_FROM_MEMORY\'' },
      { LINE: '  TABLES' },
      { LINE: '    listobject = lt_list' },
      { LINE: '  EXCEPTIONS' },
      { LINE: '    not_found  = 1' },
      { LINE: '    OTHERS     = 2.' },
      { LINE: "WRITE: / 'LIST_FROM_MEMORY SUBRC =', sy-subrc." },
      { LINE: 'DATA: lt_asci TYPE STANDARD TABLE OF char255,' },
      { LINE: '      ls_asci TYPE char255.' },
      { LINE: 'CALL FUNCTION \'LIST_TO_ASCI\'' },
      { LINE: '  TABLES' },
      { LINE: '    listasci   = lt_asci' },
      { LINE: '    listobject = lt_list.' },
      { LINE: 'WRITE: / \'ASCII ROWS:\', sy-dbcnt.' },
      { LINE: 'DATA: lv_c TYPE i.' },
      { LINE: 'LOOP AT lt_asci INTO ls_asci.' },
      { LINE: '  lv_c = lv_c + 1.' },
      { LINE: '  IF lv_c > 10. EXIT. ENDIF.' },
      { LINE: '  WRITE: / ls_asci(70).' },
      { LINE: 'ENDLOOP.' }
    ]
  }
});

console.log('Result:', JSON.stringify(res.result?.WRITES, null, 2));
if (res.result?.ERRORMESSAGE) {
  console.log('Error:', res.result.ERRORMESSAGE);
}
