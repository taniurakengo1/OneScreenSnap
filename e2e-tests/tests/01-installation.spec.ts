import { test, expect } from '@playwright/test';
import { exec } from '../helpers/exec';
import { PROJECT_ROOT, APP_PATH, APP_EXECUTABLE, APP_INSTALLED } from '../helpers/constants';
import { isAppRunning, launchApp, quitApp, waitForApp, sleep } from '../helpers/app-control';
import { takeScreenshot } from '../helpers/evidence';
import fs from 'fs';

test.describe('TS-INSTALL: インストール・アンインストール', () => {
  // TC-INSTALL-006: ビルド成功確認
  test('TC-INSTALL-006: swift build succeeds', async ({}, testInfo) => {
    const result = exec('swift build 2>&1', {
      timeout: 120_000,
      cwd: PROJECT_ROOT,
      ignoreError: true,
    });

    await takeScreenshot(testInfo, 'build-result');

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain('Build complete!');
  });

  // TC-INSTALL-007: テスト実行確認
  test('TC-INSTALL-007: make test passes', async ({}, testInfo) => {
    const result = exec('make test 2>&1', {
      timeout: 120_000,
      cwd: PROJECT_ROOT,
      ignoreError: true,
    });

    await takeScreenshot(testInfo, 'test-result');

    expect(result.exitCode).toBe(0);
  });

  // TC-INSTALL-001: アプリバンドル構造確認
  test('TC-INSTALL-001: app bundle exists and is valid', async ({}, testInfo) => {
    // Verify app bundle exists (local or installed)
    expect(fs.existsSync(APP_PATH)).toBe(true);
    expect(fs.existsSync(APP_EXECUTABLE)).toBe(true);

    // Verify Info.plist exists and has correct content
    const infoPlistPath = `${APP_PATH}/Contents/Info.plist`;
    expect(fs.existsSync(infoPlistPath)).toBe(true);

    const { stdout: bundleId } = exec(
      `defaults read "${APP_PATH}/Contents/Info.plist" CFBundleIdentifier`,
      { ignoreError: true }
    );
    expect(bundleId.trim()).toBe('com.onescreensnap.app');

    // Verify LSUIElement is set (background app)
    const { stdout: lsui } = exec(
      `defaults read "${APP_PATH}/Contents/Info.plist" LSUIElement`,
      { ignoreError: true }
    );
    expect(lsui.trim()).toBe('1');

    // Verify codesign
    const codesignResult = exec(`codesign -v "${APP_PATH}" 2>&1`, { ignoreError: true });

    await takeScreenshot(testInfo, 'app-bundle');
    expect(codesignResult.exitCode).toBe(0);
  });

  // TC-INSTALL-002: make start によるアプリ起動
  test('TC-INSTALL-002: make start launches app', async ({}, testInfo) => {
    if (!APP_INSTALLED) {
      test.skip(true, 'App not installed at /Applications — run `sudo make install` first');
    }

    // Stop if running
    if (isAppRunning()) {
      quitApp();
    }

    exec('make start 2>&1', { timeout: 10_000, cwd: PROJECT_ROOT, ignoreError: true });
    sleep(3000);

    await takeScreenshot(testInfo, 'after-make-start');

    expect(isAppRunning()).toBe(true);
  });

  // TC-INSTALL-003: make stop によるアプリ停止
  test('TC-INSTALL-003: make stop stops app', async ({}, testInfo) => {
    if (!APP_INSTALLED) {
      test.skip(true, 'App not installed at /Applications — run `sudo make install` first');
    }

    // Ensure app is running first
    if (!isAppRunning()) {
      launchApp();
    }

    exec('make stop 2>&1', { timeout: 10_000, cwd: PROJECT_ROOT, ignoreError: true });
    sleep(3000);

    await takeScreenshot(testInfo, 'after-make-stop');

    expect(isAppRunning()).toBe(false);
  });

  // TC-INSTALL-004: make uninstall — skip destructive test, just verify the target exists
  test('TC-INSTALL-004: make uninstall target exists', async ({}, testInfo) => {
    // We don't actually run uninstall in tests. Verify the Makefile target exists.
    const { stdout: makeTargets } = exec('make -n uninstall 2>&1', {
      cwd: PROJECT_ROOT,
      ignoreError: true,
    });

    await takeScreenshot(testInfo, 'uninstall-target');

    // Should not error with "No rule to make target"
    expect(makeTargets).not.toContain('No rule to make target');
  });
});
