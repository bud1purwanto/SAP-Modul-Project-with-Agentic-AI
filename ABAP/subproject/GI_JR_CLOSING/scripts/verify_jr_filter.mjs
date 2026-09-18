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

const code = [
  'REPORT ZTMP_VERIFY_JR.',
  'DATA: lt_map TYPE STANDARD TABLE OF zmap_type-value,',
  '      lv_val TYPE zmap_type-value,',
  '      lv_cnt TYPE i.',
  'RANGES: lr_jr FOR aufk-auart.',
  "SELECT value FROM zmap_type INTO TABLE lt_map",
  "  WHERE ( prog = 'ZPPR_GI_JR_CLOSING' OR prog = 'ZPPI_COHVPI' )",
  "    AND type = 'ORDER TYPE' AND opt = 'JR'.",
  'lr_jr-sign = \'I\'. lr_jr-option = \'EQ\'.',
  'LOOP AT lt_map INTO lv_val.',
  '  lr_jr-low = lv_val. APPEND lr_jr.',
  'ENDLOOP.',
  'DESCRIBE TABLE lr_jr LINES lv_cnt.',
  "WRITE: / 'MAPPED_JR_TYPES_COUNT:', lv_cnt.",
  'TYPES: BEGIN OF ty_chk,',
  '         aufnr TYPE mseg-aufnr,',
  '         auart TYPE aufk-auart,',
  '         bwart TYPE mseg-bwart,',
  '         charg TYPE mseg-charg,',
  '       END OF ty_chk.',
  'DATA: lt_chk TYPE STANDARD TABLE OF ty_chk,',
  '      ls_chk TYPE ty_chk.',
  'SELECT a~aufnr c~auart a~bwart a~charg',
  '  INTO TABLE lt_chk',
  '  UP TO 20 ROWS',
  '  FROM mkpf AS b',
  '  INNER JOIN mseg AS a ON a~mblnr = b~mblnr AND a~mjahr = b~mjahr',
  '  INNER JOIN aufk AS c ON c~aufnr = a~aufnr',
  "  WHERE b~budat BETWEEN '20240101' AND '20241231'",
  "    AND a~werks = '2000'",
  '    AND c~auart IN lr_jr',
  "    AND ( a~bwart = '101' OR a~bwart = '531' )",
  '    AND a~charg NE space.',
  'DESCRIBE TABLE lt_chk LINES lv_cnt.',
  "WRITE: / 'SAMPLED_JR_RECORDS:', lv_cnt.",
  'LOOP AT lt_chk INTO ls_chk.',
  "  WRITE: / 'AUFNR:', ls_chk-aufnr, 'AUART:', ls_chk-auart, 'BWART:', ls_chk-bwart, 'BATCH:', ls_chk-charg.",
  'ENDLOOP.'
].map((line) => ({ LINE: line }));

const res = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: code
  }
});

console.log('Results:');
for (const w of res.result?.WRITES || []) {
  console.log(w.ZEILE);
}
