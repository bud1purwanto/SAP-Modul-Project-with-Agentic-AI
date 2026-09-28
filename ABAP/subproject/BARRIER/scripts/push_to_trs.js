import { serverManager } from '/var/www/MCP/MCP SAP/sap-leader-mcp/src/server-manager.js';
import { call_function } from '/var/www/MCP/MCP SAP/sap-leader-mcp/src/tools/query-tools.js';
import fs from 'fs';
import path from 'path';

async function main() {
  await serverManager.loadConfig();
  await serverManager.setActiveServer('sandbox-new');

  const abapPath = path.resolve('subproject/BARRIER/src/ZQMI_PENDING_BARRIER.abap');
  console.log('Reading ABAP file from:', abapPath);
  const sourceCode = fs.readFileSync(abapPath, 'utf-8');
  const sourceLines = sourceCode.split(/\r?\n/);

  console.log(`Total lines: ${sourceLines.length}`);

  // Check line lengths
  let maxLen = 0;
  let longLineIdx = -1;
  sourceLines.forEach((line, idx) => {
    if (line.length > maxLen) {
      maxLen = line.length;
      longLineIdx = idx + 1;
    }
    if (line.length > 255) {
      console.warn(`Line ${idx + 1} exceeds 255 chars (${line.length}): ${line.substring(0, 50)}...`);
    }
  });
  console.log(`Max line length: ${maxLen} at line ${longLineIdx}`);

  const itSource = sourceLines.map(line => ({ LINE: line }));

  console.log('Pushing to ZQMI_PENDING_BARRIER on TRS (sandbox-new)...');
  const result = await call_function({
    function_name: 'Z_RFC_PROGRAM_UPDATE',
    parameters: {
      IV_PROGRAM_NAME: 'ZQMI_PENDING_BARRIER',
      IV_PACKAGE: '$TMP',
      IV_CORRNUMBER: ' ',
      IT_SOURCE: itSource
    }
  });

  console.log('Update result:', JSON.stringify(result, null, 2));

  // Run syntax check & generate report via RFC_ABAP_INSTALL_AND_RUN
  console.log('\nRunning syntax check and report generation on TRS...');
  const checkProgram = [
    { LINE: 'REPORT ZCHECK.' },
    { LINE: 'DATA: LV_MSG TYPE STRING, LV_LINE TYPE I, LV_WORD TYPE STRING.' },
    { LINE: 'GENERATE REPORT \'ZQMI_PENDING_BARRIER\'' },
    { LINE: '  MESSAGE LV_MSG LINE LV_LINE WORD LV_WORD.' },
    { LINE: 'IF SY-SUBRC = 0.' },
    { LINE: '  WRITE: / \'GENERATE_OK\'.' },
    { LINE: 'ELSE.' },
    { LINE: '  WRITE: / \'GENERATE_FAILED:\', SY-SUBRC, \'LINE:\', LV_LINE, LV_MSG.' },
    { LINE: 'ENDIF.' }
  ];

  const checkResult = await call_function({
    function_name: 'RFC_ABAP_INSTALL_AND_RUN',
    parameters: {
      PROGRAM: checkProgram
    }
  });

  console.log('Check result:');
  if (checkResult && checkResult.result && checkResult.result.OUTPUT) {
    checkResult.result.OUTPUT.forEach(row => console.log(row.LINE || row));
  } else {
    console.log(JSON.stringify(checkResult, null, 2));
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
