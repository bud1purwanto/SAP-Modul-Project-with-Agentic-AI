import fs from 'node:fs';
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
const srvRes = await setActiveServer({ server_ref: 'sandbox-new' });
console.log('Server response:', srvRes.mode, srvRes.active_server, srvRes.sid);

console.log('2. Reading local ABAP source code...');
const abapPath = path.resolve('subproject/GI_JR_CLOSING/src/ZPPR_GI_JR_CLOSING.abap');
const code = fs.readFileSync(abapPath, 'utf8');
const lines = code.split(/\r?\n/).map((line) => ({ LINE: line }));

const textpool = [
  // Program title
  { ID: 'R', KEY: '', ENTRY: 'Observasi GI Jumbo Roll Closing', LENGTH: 31 },

  // Selection texts (8 leading spaces for parameters/select-options)
  { ID: 'S', KEY: 'P_RPT',   ENTRY: '        Tampilkan Report ALV', LENGTH: 28 },
  { ID: 'S', KEY: 'P_MAIL',  ENTRY: '        Kirim Email Notifikasi', LENGTH: 30 },
  { ID: 'S', KEY: 'R_ALL',   ENTRY: '        Semua Anomali Closing', LENGTH: 29 },
  { ID: 'S', KEY: 'R_NOGI',  ENTRY: '        Tidak Ada GI Sama Sekali', LENGTH: 32 },
  { ID: 'S', KEY: 'R_LESS',  ENTRY: '        GI Kurang dari JR', LENGTH: 25 },
  { ID: 'S', KEY: 'S_WERKS', ENTRY: '        Plant', LENGTH: 13 },
  { ID: 'S', KEY: 'S_BUDAT', ENTRY: '        Posting Date GR', LENGTH: 23 },
  { ID: 'S', KEY: 'S_LINE',  ENTRY: '        Production Line', LENGTH: 23 },
  { ID: 'S', KEY: 'S_AUFNR', ENTRY: '        Process Order', LENGTH: 21 },
  { ID: 'S', KEY: 'P_TOL',   ENTRY: '        Toleransi Selisih (Qty)', LENGTH: 31 },
  { ID: 'S', KEY: 'P_VARI',  ENTRY: '        Layout ALV', LENGTH: 18 },
  { ID: 'S', KEY: 'P_TEST',  ENTRY: '        Mode Simulasi (Test Run)', LENGTH: 32 },

  // Text symbols (Frame Titles & Messages)
  { ID: 'I', KEY: '001', ENTRY: 'Mode Eksekusi', LENGTH: 13 },
  { ID: 'I', KEY: '002', ENTRY: 'Kriteria Observasi Closing', LENGTH: 26 },
  { ID: 'I', KEY: '003', ENTRY: 'Parameter Seleksi', LENGTH: 17 },
  { ID: 'I', KEY: '004', ENTRY: 'Pengaturan Email', LENGTH: 16 },
  { ID: 'I', KEY: '010', ENTRY: 'Tidak ada anomali sesuai kriteria.', LENGTH: 34 },
  { ID: 'I', KEY: '013', ENTRY: 'Layout ALV tidak ditemukan.', LENGTH: 27 },
  { ID: 'I', KEY: '014', ENTRY: 'ALV gagal ditampilkan.', LENGTH: 22 }
];

console.log(`Read ${lines.length} lines. Calling Z_RFC_PROGRAM_UPDATE with textpool...`);
const res = await callFunction({
  function_name: 'Z_RFC_PROGRAM_UPDATE',
  parameters: {
    IV_PROGRAM_NAME: 'ZPPR_GI_JR_CLOSING',
    IV_PACKAGE: '$TMP',
    IV_CORRNUMBER: ' ',
    IT_SOURCE: lines,
    IT_TEXTPOOL: textpool
  }
});

console.log('Update result status:', res.result ? 'SUCCESS' : 'FAILED');

console.log('3. Syncing textpool to language I (Indonesian)...');
await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: [
      { LINE: 'REPORT ZTMP_SYNC_TP.' },
      { LINE: 'DATA: lt_tp TYPE TABLE OF textpool.' },
      { LINE: "READ TEXTPOOL 'ZPPR_GI_JR_CLOSING' INTO lt_tp LANGUAGE 'E'." },
      { LINE: "INSERT TEXTPOOL 'ZPPR_GI_JR_CLOSING' FROM lt_tp LANGUAGE 'I'." },
      { LINE: "WRITE: / 'SYNC_STATUS: SUCCESS'." }
    ]
  }
});

console.log('4. Verifying Syntax & Execution via SUBMIT...');
const testRes = await callFunction({
  function_name: 'RFC_ABAP_INSTALL_AND_RUN',
  parameters: {
    MODE: 'F',
    PROGRAM: [
      { LINE: 'REPORT ZTMP_TEST_PUSH.' },
      { LINE: 'RANGES: r_werks FOR mseg-werks,' },
      { LINE: '        r_budat FOR mkpf-budat.' },
      { LINE: "r_werks-sign = 'I'. r_werks-option = 'EQ'. r_werks-low = '2000'." },
      { LINE: 'APPEND r_werks.' },
      { LINE: "r_budat-sign = 'I'. r_budat-option = 'BT'." },
      { LINE: "r_budat-low = '20240101'. r_budat-high = '20240110'." },
      { LINE: 'APPEND r_budat.' },
      { LINE: "SUBMIT zppr_gi_jr_closing" },
      { LINE: "  WITH p_rpt = 'X'" },
      { LINE: "  WITH r_all = 'X'" },
      { LINE: "  WITH s_werks IN r_werks" },
      { LINE: "  WITH s_budat IN r_budat" },
      { LINE: '  AND RETURN.' },
      { LINE: "WRITE: / 'EXECUTION_STATUS:', 'SUCCESS', 'SY-SUBRC:', sy-subrc." }
    ]
  }
});

console.log('Verification Output:', JSON.stringify(testRes.result?.WRITES, null, 2));

