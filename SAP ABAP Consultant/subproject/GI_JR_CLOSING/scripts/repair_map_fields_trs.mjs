const { HANDLERS } = await import(
  'file:///var/www/MCP/MCP%20SAP/sap-leader-mcp/src/tool-registry.js'
);

const server = await HANDLERS.set_active_server({ server_ref: 'sandbox-new' });
if (!server.connected || server.sid !== 'TRS') {
  throw new Error(`TRS connection unavailable: ${JSON.stringify(server)}`);
}

const live = await HANDLERS.read_program({ program_name: 'ZPPR_GI_JR_CLOSING' });
if (live.mode !== 'LIVE' || !live.source) {
  throw new Error('Unable to read the live TRS source.');
}

const oldSelect = `  SELECT TCODE PROG TYPE OPT VALUE DELETION\n    INTO CORRESPONDING FIELDS OF TABLE GT_MAP_REC\n    FROM ZMAP_TYPE`;
const newSelect = `  SELECT PROG TYPE OPT VALUE DELETION TEXT1 TEXT2 TEXT3 TEXT5\n    INTO CORRESPONDING FIELDS OF TABLE GT_MAP_REC\n    FROM ZMAP_TYPE`;
const first = live.source.indexOf(oldSelect);
if (first < 0 || live.source.indexOf(oldSelect, first + oldSelect.length) >= 0) {
  throw new Error('Expected one narrowed ZMAP_TYPE SELECT.');
}

const source = live.source.replace(oldSelect, newSelect);
const lines = source.split('\n');
const update = await HANDLERS.call_function({
  function_name: 'Z_RFC_PROGRAM_UPDATE',
  parameters: {
    IV_PROGRAM_NAME: 'ZPPR_GI_JR_CLOSING',
    IV_PACKAGE: '$TMP',
    IV_CORRNUMBER: ' ',
    IT_SOURCE: lines.map((LINE) => ({ LINE }))
  }
});

if (update.mode !== 'LIVE' || !update.result?.EV_SUCCESS) {
  throw new Error(`Source update failed: ${JSON.stringify(update)}`);
}

console.log(JSON.stringify({ update: update.result }, null, 2));
