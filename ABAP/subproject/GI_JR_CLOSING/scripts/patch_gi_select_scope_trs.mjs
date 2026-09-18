import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const { HANDLERS } = await import(
  'file:///var/www/MCP/MCP%20SAP/sap-leader-mcp/src/tool-registry.js'
);

const programName = 'ZPPR_GI_JR_CLOSING';

function replaceOnce(source, search, replacement, label) {
  const first = source.indexOf(search);
  if (first < 0 || source.indexOf(search, first + search.length) >= 0) {
    throw new Error(`Expected one ${label} block.`);
  }
  return source.replace(search, replacement);
}

const server = await HANDLERS.set_active_server({ server_ref: 'sandbox-new' });
if (!server.connected || server.sid !== 'TRS') {
  throw new Error(`TRS connection unavailable: ${JSON.stringify(server)}`);
}

const live = await HANDLERS.read_program({ program_name: programName });
if (live.mode !== 'LIVE' || !live.source) {
  throw new Error('Unable to read the live TRS source.');
}

const backupDir = resolve('subproject/GI_JR_CLOSING/outputs');
mkdirSync(backupDir, { recursive: true });
writeFileSync(
  resolve(backupDir, 'ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_gi_scope.abap'),
  `${live.source}\n`,
  'utf8'
);

let source = live.source;

source = replaceOnce(
  source,
  `TYPES: BEGIN OF TY_REL,\n         OUT_ORDER TYPE AUFNR,\n         MOV_ORDER TYPE AUFNR,\n       END OF TY_REL.`,
  `TYPES: BEGIN OF TY_REL,\n         OUT_ORDER TYPE AUFNR,\n         MOV_ORDER TYPE AUFNR,\n         WERKS     TYPE MSEG-WERKS,\n         MATNR     TYPE MSEG-MATNR,\n         CHARG     TYPE MSEG-CHARG,\n         BKTXT     TYPE MKPF-BKTXT,\n       END OF TY_REL.`,
  'TY_REL declaration'
);

source = replaceOnce(
  source,
  `      GT_REL      TYPE SORTED TABLE OF TY_REL\n                  WITH UNIQUE KEY OUT_ORDER MOV_ORDER,`,
  `      GT_REL      TYPE SORTED TABLE OF TY_REL\n                  WITH NON-UNIQUE KEY OUT_ORDER MOV_ORDER WERKS MATNR CHARG BKTXT,`,
  'GT_REL declaration'
);

source = replaceOnce(
  source,
  `    LS_REL-OUT_ORDER = LS_OUT-AUFNR.\n    LS_REL-MOV_ORDER = LS_OUT-AUFNR.`,
  `    LS_REL-OUT_ORDER = LS_OUT-AUFNR.\n    LS_REL-MOV_ORDER = LS_OUT-AUFNR.\n    LS_REL-WERKS     = LS_OUT-WERKS.\n    LS_REL-MATNR     = LS_OUT-MATNR.\n    LS_REL-CHARG     = LS_OUT-CHARG.\n    LS_REL-BKTXT     = LS_OUT-BKTXT.`,
  'root relation assignment'
);

source = replaceOnce(
  source,
  `        CLEAR LS_REL_NEW.\n        LS_REL_NEW-OUT_ORDER = LS_REL_PARENT-OUT_ORDER.\n        LS_REL_NEW-MOV_ORDER = LS_AFPO-AUFNR.`,
  `        LS_REL_NEW = LS_REL_PARENT.\n        LS_REL_NEW-MOV_ORDER = LS_AFPO-AUFNR.`,
  'child relation assignment'
);

source = replaceOnce(
  source,
  `   WHERE B~BUDAT LE LV_CUTOFF\n     AND A~AUFNR = GT_REL-MOV_ORDER\n     AND ( A~BWART = '261' OR A~BWART = '262' OR\n           A~BWART = '901' OR A~BWART = '902' ).`,
  `   WHERE B~BUDAT LE LV_CUTOFF\n     AND A~AUFNR = GT_REL-MOV_ORDER\n     AND A~WERKS = GT_REL-WERKS\n     AND A~MATNR = GT_REL-MATNR\n     AND A~CHARG = GT_REL-CHARG\n     AND B~BKTXT = GT_REL-BKTXT\n     AND ( A~BWART = '261' OR A~BWART = '262' OR\n           A~BWART = '901' OR A~BWART = '902' ).`,
  'GI query filters'
);

const lines = source.split('\n');
if (lines.some((line) => line.length > 255)) {
  throw new Error('Patched source contains a line longer than 255 characters.');
}

const update = await HANDLERS.call_function({
  function_name: 'Z_RFC_PROGRAM_UPDATE',
  parameters: {
    IV_PROGRAM_NAME: programName,
    IV_PACKAGE: '$TMP',
    IV_CORRNUMBER: ' ',
    IT_SOURCE: lines.map((LINE) => ({ LINE }))
  }
});

if (update.mode !== 'LIVE' || !update.result?.EV_SUCCESS) {
  throw new Error(`Source update failed: ${JSON.stringify(update)}`);
}

console.log(JSON.stringify({
  backup: 'subproject/GI_JR_CLOSING/outputs/ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_gi_scope.abap',
  sourceLinesBefore: live.line_count,
  sourceLinesAfter: lines.length,
  update: update.result
}, null, 2));
