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
  resolve(backupDir, 'ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_email_layout.abap'),
  `${live.source}\n`,
  'utf8'
);

let source = live.source;

source = replaceOnce(
  source,
  `  LS_SOLI-LINE = '<style>body{margin:0;background:#f3f6f9;font-family:Arial,sans-serif;color:#1f2937;}'.`,
  `  LS_SOLI-LINE = '<style>body{margin:0;font-family:Arial,sans-serif;color:#1f2937;}'.`,
  'body style'
);

source = replaceOnce(
  source,
  `  LS_SOLI-LINE = '.wrap{max-width:1180px;margin:18px auto;background:#fff;border:1px solid #d9e2f3;}'.\n  APPEND LS_SOLI TO LT_BODY.\n`,
  ``,
  'outer container style'
);

source = replaceOnce(
  source,
  `  LS_SOLI-LINE = '<body><div class="wrap"><div class="head"><h2>Observasi GI Jumbo Roll Closing</h2>'.`,
  `  LS_SOLI-LINE = '<body><div class="head"><h2>Observasi GI Jumbo Roll Closing</h2>'.`,
  'outer container opening'
);

source = replaceOnce(
  source,
  `  LS_SOLI-LINE = '</div></div></body></html>'.`,
  `  LS_SOLI-LINE = '</div></body></html>'.`,
  'outer container closing'
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
  backup: 'subproject/GI_JR_CLOSING/outputs/ZPPR_GI_JR_CLOSING_backup_20260910_TRS_before_email_layout.abap',
  sourceLinesBefore: live.line_count,
  sourceLinesAfter: lines.length,
  update: update.result
}, null, 2));
