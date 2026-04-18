import { test, expect } from '@playwright/test';
import { exec } from '../helpers/exec';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { resetToCleanState } from '../helpers/defaults';
import { takeScreenshot, attachText } from '../helpers/evidence';

test.describe('TS-PERMISSION: 権限管理', () => {
  test.beforeAll(() => {
    resetToCleanState();
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
  });

  // TC-PERM-001: アクセシビリティ権限要求
  test('TC-PERM-001: accessibility permission check', async ({}, testInfo) => {
    const { stdout } = exec(
      `osascript -l JavaScript -e 'ObjC.import("ApplicationServices"); $.AXIsProcessTrusted();'`,
      { ignoreError: true }
    );

    await attachText(testInfo, 'ax-permission-status', `Process trusted: ${stdout.trim()}`);
    await takeScreenshot(testInfo, 'ax-permission');

    if (stdout.trim() === 'false') {
      test.skip(true, 'Accessibility permission not granted — grant manually in System Settings');
    }
    expect(stdout.trim()).toBe('true');
  });

  // TC-PERM-002: 画面収録権限要求
  test('TC-PERM-002: screen recording permission check', async ({}, testInfo) => {
    const { exitCode } = exec('screencapture -x /tmp/e2e-perm-check.png 2>&1', {
      ignoreError: true,
    });
    exec('rm -f /tmp/e2e-perm-check.png', { ignoreError: true });

    await takeScreenshot(testInfo, 'screen-recording-permission');

    expect(exitCode).toBe(0);
  });

  // TC-PERM-003: 両権限付与後の正常動作
  test('TC-PERM-003: app works with permissions granted', async ({}, testInfo) => {
    launchApp();
    sleep(2000);

    await takeScreenshot(testInfo, 'app-with-permissions');

    expect(isAppRunning()).toBe(true);

    // Verify AX access
    const { stdout } = exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap" to get every menu bar item of menu bar 1'`,
      { ignoreError: true }
    );

    await attachText(testInfo, 'ax-access', stdout);
    expect(stdout.length).toBeGreaterThan(0);
  });

  // TC-PERM-004: アクセシビリティ権限拒否時
  test('TC-PERM-004: app survives without accessibility permission', async () => {
    test.skip(true, 'Cannot programmatically revoke accessibility permission — manual test required');
  });

  // TC-PERM-005: 画面収録権限拒否時
  test('TC-PERM-005: app survives without screen recording permission', async () => {
    test.skip(true, 'Cannot programmatically revoke screen recording permission — manual test required');
  });
});
