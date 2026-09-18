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
      { LINE: 'REPORT ZTMP_TRACE_STEP.' },
      { LINE: 'DATA: lt_gr TYPE STANDARD TABLE OF mseg,' },
      { LINE: '      lt_out TYPE STANDARD TABLE OF mseg,' },
      { LINE: '      lt_storno TYPE STANDARD TABLE OF mseg,' },
      { LINE: '      ls_storno TYPE mseg,' },
      { LINE: '      lv_cnt TYPE i.' },
      { LINE: 'SELECT a~mblnr a~mjahr a~zeile a~bwart a~charg a~smbln' },
      { LINE: '  INTO CORRESPONDING FIELDS OF TABLE lt_gr' },
      { LINE: '  FROM mkpf AS b INNER JOIN mseg AS a' },
      { LINE: '    ON a~mblnr = b~mblnr AND a~mjahr = b~mjahr' },
      { LINE: " WHERE a~werks = '2000'" },
      { LINE: "   AND ( a~bwart = '101' OR a~bwart = '102' OR" },
      { LINE: "         a~bwart = '531' OR a~bwart = '532' )" },
      { LINE: '   AND a~charg NE space.' },
      { LINE: 'DESCRIBE TABLE lt_gr LINES lv_cnt.' },
      { LINE: "WRITE: / 'Step 1 (Raw GR in 2000):', lv_cnt." },
      { LINE: 'lt_storno[] = lt_gr[].' },
      { LINE: 'DELETE lt_storno WHERE smbln IS INITIAL.' },
      { LINE: 'DESCRIBE TABLE lt_storno LINES lv_cnt.' },
      { LINE: "WRITE: / 'Step 2 (Storno docs in range):', lv_cnt." },
      { LINE: 'LOOP AT lt_storno INTO ls_storno.' },
      { LINE: '  DELETE lt_gr WHERE mblnr = ls_storno-smbln' },
      { LINE: '                 AND mjahr = ls_storno-sjahr' },
      { LINE: '                 AND zeile = ls_storno-smblp.' },
      { LINE: 'ENDLOOP.' },
      { LINE: 'DELETE lt_gr WHERE smbln IS NOT INITIAL' },
      { LINE: "                OR bwart = '102' OR bwart = '532'." },
      { LINE: 'DESCRIBE TABLE lt_gr LINES lv_cnt.' },
      { LINE: "WRITE: / 'Step 3 (After pair matching):', lv_cnt." }
    ]
  }
});

console.log('Result:', JSON.stringify(res.result?.WRITES, null, 2));
if (res.result?.ERRORMESSAGE) {
  console.log('Error:', res.result.ERRORMESSAGE);
}
