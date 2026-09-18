import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const registry = await import(
  'file:///var/www/MCP/MCP%20SAP/sap-leader-mcp/src/tool-registry.js'
);

const { HANDLERS } = registry;
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
  resolve(backupDir, 'ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_cutoff.abap'),
  `${live.source}\n`,
  'utf8'
);

let source = live.source;

source = replaceOnce(
  source,
  `        LV_AUART_VAL  TYPE ZMAP_TYPE-VALUE.\n  RANGES: LR_JR_AUART FOR AUFK-AUART.`,
  `        LV_AUART_VAL  TYPE ZMAP_TYPE-VALUE,\n        LV_CUTOFF     TYPE MKPF-BUDAT.\n  RANGES: LR_JR_AUART FOR AUFK-AUART.\n\n  CLEAR LV_CUTOFF.\n  LOOP AT S_BUDAT.\n    IF S_BUDAT-HIGH IS NOT INITIAL AND S_BUDAT-HIGH > LV_CUTOFF.\n      LV_CUTOFF = S_BUDAT-HIGH.\n    ELSEIF S_BUDAT-LOW > LV_CUTOFF.\n      LV_CUTOFF = S_BUDAT-LOW.\n    ENDIF.\n  ENDLOOP.`,
  'cutoff declaration'
);

source = replaceOnce(
  source,
  `   WHERE A~AUFNR = GT_REL-MOV_ORDER\n     AND ( A~BWART = '261' OR A~BWART = '262' OR`,
  `   WHERE B~BUDAT LE LV_CUTOFF\n     AND A~AUFNR = GT_REL-MOV_ORDER\n     AND ( A~BWART = '261' OR A~BWART = '262' OR`,
  'GI cutoff'
);

source = replaceOnce(
  source,
  `    SELECT MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART\n      INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO\n      FROM MSEG\n      FOR ALL ENTRIES IN GT_GR\n     WHERE SMBLN = GT_GR-MBLNR\n       AND SJAHR = GT_GR-MJAHR\n       AND SMBLP = GT_GR-ZEILE\n       AND BWART = '102'.`,
  `    SELECT A~MBLNR A~MJAHR A~ZEILE A~SMBLN A~SJAHR A~SMBLP\n           A~BWART B~BUDAT\n      INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO\n      FROM MSEG AS A INNER JOIN MKPF AS B\n        ON A~MBLNR = B~MBLNR\n       AND A~MJAHR = B~MJAHR\n      FOR ALL ENTRIES IN GT_GR\n     WHERE A~SMBLN = GT_GR-MBLNR\n       AND A~SJAHR = GT_GR-MJAHR\n       AND A~SMBLP = GT_GR-ZEILE\n       AND A~BWART = '102'\n       AND B~BUDAT LE LV_CUTOFF.`,
  'GR reversal cutoff'
);

source = replaceOnce(
  source,
  `      SELECT MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART\n        INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO\n        FROM MSEG\n        FOR ALL ENTRIES IN GT_GIMOV\n       WHERE SMBLN = GT_GIMOV-MBLNR\n         AND SJAHR = GT_GIMOV-MJAHR\n         AND SMBLP = GT_GIMOV-ZEILE\n         AND ( BWART = '262' OR BWART = '902' ).`,
  `      SELECT A~MBLNR A~MJAHR A~ZEILE A~SMBLN A~SJAHR A~SMBLP\n             A~BWART B~BUDAT\n        INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO\n        FROM MSEG AS A INNER JOIN MKPF AS B\n          ON A~MBLNR = B~MBLNR\n         AND A~MJAHR = B~MJAHR\n        FOR ALL ENTRIES IN GT_GIMOV\n       WHERE A~SMBLN = GT_GIMOV-MBLNR\n         AND A~SJAHR = GT_GIMOV-MJAHR\n         AND A~SMBLP = GT_GIMOV-ZEILE\n         AND ( A~BWART = '262' OR A~BWART = '902' )\n         AND B~BUDAT LE LV_CUTOFF.`,
  'GI reversal cutoff'
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
  backup: 'subproject/GI_JR_CLOSING/outputs/ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_cutoff.abap',
  sourceLinesBefore: live.line_count,
  sourceLinesAfter: lines.length,
  update: update.result
}, null, 2));
