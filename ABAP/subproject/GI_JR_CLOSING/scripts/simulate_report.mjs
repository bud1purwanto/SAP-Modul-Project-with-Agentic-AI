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

const prog = [
  { LINE: 'REPORT ZTMP_SIMULATE.' },
  { LINE: 'TABLES: mseg, mkpf, aufk, ausp.' },
  { LINE: 'DATA: lt_gr TYPE STANDARD TABLE OF mseg,' },
  { LINE: '      lt_out TYPE STANDARD TABLE OF mseg,' },
  { LINE: '      lv_cnt1 TYPE i, lv_cnt2 TYPE i, lv_cnt3 TYPE i.' },
  { LINE: "SELECT a~mblnr a~mjahr a~zeile a~bwart a~matnr a~werks" },
  { LINE: "       a~charg a~menge a~meins a~aufnr a~smbln a~sjahr" },
  { LINE: "       a~smblp b~budat b~bktxt" },
  { LINE: "  INTO CORRESPONDING FIELDS OF TABLE lt_gr" },
  { LINE: "  FROM mkpf AS b INNER JOIN mseg AS a" },
  { LINE: "    ON a~mblnr = b~mblnr AND a~mjahr = b~mjahr" },
  { LINE: " WHERE b~budat BETWEEN '20200101' AND '20201231'" },
  { LINE: "   AND a~werks = '2000'" },
  { LINE: "   AND ( a~bwart = '101' OR a~bwart = '102' OR" },
  { LINE: "         a~bwart = '531' OR a~bwart = '532' )" },
  { LINE: "   AND a~charg NE space." },
  { LINE: 'DESCRIBE TABLE lt_gr LINES lv_cnt1.' },
  { LINE: "WRITE: / '2020 GR count:', lv_cnt1." },
  { LINE: "SELECT a~mblnr a~mjahr a~zeile a~bwart a~matnr a~werks" },
  { LINE: "       a~charg a~menge a~meins a~aufnr a~smbln a~sjahr" },
  { LINE: "       a~smblp b~budat b~bktxt" },
  { LINE: "  INTO CORRESPONDING FIELDS OF TABLE lt_gr" },
  { LINE: "  FROM mkpf AS b INNER JOIN mseg AS a" },
  { LINE: "    ON a~mblnr = b~mblnr AND a~mjahr = b~mjahr" },
  { LINE: " WHERE b~budat BETWEEN '20230101' AND '20231231'" },
  { LINE: "   AND a~werks = '2000'" },
  { LINE: "   AND ( a~bwart = '101' OR a~bwart = '102' OR" },
  { LINE: "         a~bwart = '531' OR a~bwart = '532' )" },
  { LINE: "   AND a~charg NE space." },
  { LINE: 'DESCRIBE TABLE lt_gr LINES lv_cnt2.' },
  { LINE: "WRITE: / '2023 GR count:', lv_cnt2." },
  { LINE: "SELECT a~mblnr a~mjahr a~zeile a~bwart a~matnr a~werks" },
  { LINE: "       a~charg a~menge a~meins a~aufnr a~smbln a~sjahr" },
  { LINE: "       a~smblp b~budat b~bktxt" },
  { LINE: "  INTO CORRESPONDING FIELDS OF TABLE lt_gr" },
  { LINE: "  FROM mkpf AS b INNER JOIN mseg AS a" },
  { LINE: "    ON a~mblnr = b~mblnr AND a~mjahr = b~mjahr" },
  { LINE: " WHERE b~budat BETWEEN '20240101' AND '20241231'" },
  { LINE: "   AND a~werks = '2000'" },
  { LINE: "   AND ( a~bwart = '101' OR a~bwart = '102' OR" },
  { LINE: "         a~bwart = '531' OR a~bwart = '532' )" },
  { LINE: "   AND a~charg NE space." },
  { LINE: 'DESCRIBE TABLE lt_gr LINES lv_cnt3.' },
  { LINE: "WRITE: / '2024 GR count:', lv_cnt3." }
];

const res = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: prog
  }
});

console.log('Counts:', JSON.stringify(res.result?.WRITES, null, 2));
if (res.result?.ERRORMESSAGE) {
  console.log('Error:', res.result.ERRORMESSAGE);
}
