'use strict';
const {spawnSync} = require('node:child_process');
process.chdir(require('node:path').resolve(__dirname, '..'));
for (const args of [['scripts/seed.js'], ['--test', 'test/emulator/workflows.test.js']]) {
  const run = spawnSync(process.execPath, args, {stdio: 'inherit', env: process.env});
  if (run.status !== 0) process.exit(run.status || 1);
}
