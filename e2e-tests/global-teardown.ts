import { isAppRunning, quitApp } from './helpers/app-control';
import { resetToCleanState } from './helpers/defaults';

async function globalTeardown() {
  console.log('\n=== E2E Global Teardown ===\n');

  // Stop app if running
  if (isAppRunning()) {
    console.log('Stopping app...');
    quitApp();
    console.log('✓ App stopped');
  }

  // Reset UserDefaults
  resetToCleanState();
  console.log('✓ UserDefaults reset');

  console.log('\n=== Teardown Complete ===\n');
}

export default globalTeardown;
