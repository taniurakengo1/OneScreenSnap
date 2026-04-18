import { exec } from './helpers/exec';
import { BRIDGE_BIN, CLIPBOARD_INFO_BIN, AX_INSPECTOR_BIN, APP_PATH, E2E_ROOT } from './helpers/constants';
import fs from 'fs';
import path from 'path';

async function globalSetup() {
  console.log('\n=== E2E Global Setup ===\n');

  // 1. Check cliclick
  try {
    exec('which cliclick');
    console.log('✓ cliclick found');
  } catch {
    throw new Error('cliclick not found. Install with: brew install cliclick');
  }

  // 2. Build bridge tools if needed
  if (!fs.existsSync(CLIPBOARD_INFO_BIN) || !fs.existsSync(AX_INSPECTOR_BIN)) {
    console.log('Building bridge tools...');
    exec(`bash ${path.join(E2E_ROOT, 'bridge', 'build.sh')}`, {
      timeout: 120_000,
      cwd: path.join(E2E_ROOT, 'bridge'),
    });
    console.log('✓ Bridge tools built');
  } else {
    console.log('✓ Bridge tools already built');
  }

  // 3. Check app exists
  if (!fs.existsSync(APP_PATH)) {
    console.log('App not installed, building and installing...');
    const projectRoot = path.resolve(E2E_ROOT, '..');
    exec('make bundle', { timeout: 120_000, cwd: projectRoot });
    console.log('✓ App built (not installed to /Applications — run `sudo make install` manually)');
  } else {
    console.log(`✓ App found at ${APP_PATH}`);
  }

  // 4. Ensure evidence directory
  const evidenceDir = path.join(E2E_ROOT, 'evidence');
  if (!fs.existsSync(evidenceDir)) {
    fs.mkdirSync(evidenceDir, { recursive: true });
  }
  console.log('✓ Evidence directory ready');

  console.log('\n=== Setup Complete ===\n');
}

export default globalSetup;
