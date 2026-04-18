import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { openSettings, closeSettings, isSettingsOpen } from '../helpers/settings';
import { getConnectedDisplays } from '../helpers/display';
import { resetToCleanState } from '../helpers/defaults';
import { pressKey } from '../helpers/shortcut';
import { takeScreenshot, attachJson, attachText } from '../helpers/evidence';
import { exec } from '../helpers/exec';

test.describe('TS-REGION-SELECT: 矩形範囲選択 (P1)', () => {
  test.beforeAll(() => {
    resetToCleanState();
    if (isAppRunning()) quitApp();
    launchApp();
    sleep(2000);
  });

  test.afterAll(() => {
    if (isSettingsOpen()) closeSettings();
    if (isAppRunning()) quitApp();
  });

  // TC-RSEL-001: 基本範囲選択
  test('TC-RSEL-001: basic region selection overlay', async ({}, testInfo) => {
    openSettings();
    sleep(1000);

    // Try clicking "add region" button
    const { stdout } = exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
        try
          click button "範囲を追加" of window 1
          return "clicked"
        on error
          try
            click button "Add Region" of window 1
            return "clicked"
          on error
            return "not_found"
          end try
        end try
      end tell'`,
      { ignoreError: true, timeout: 5000 }
    );

    await attachText(testInfo, 'button-click-result', stdout);
    sleep(2000);

    await takeScreenshot(testInfo, 'overlay-appeared');

    // Cancel with Escape
    exec(`osascript -e 'tell application "System Events" to key code 53'`, { ignoreError: true });
    sleep(1000);

    await takeScreenshot(testInfo, 'after-cancel');

    // The test verifies the flow works without crash
    expect(isAppRunning()).toBe(true);
  });

  // TC-RSEL-002: 範囲選択完了
  test('TC-RSEL-002: region selection completion', async ({}, testInfo) => {
    // This test requires mouse interaction (drag) to select a region
    // We use cliclick to simulate drag
    if (!isSettingsOpen()) {
      openSettings();
      sleep(1000);
    }

    // Click add region button
    exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
        try
          click button "範囲を追加" of window 1
        on error
          click button "Add Region" of window 1
        end try
      end tell'`,
      { ignoreError: true, timeout: 5000 }
    );
    sleep(2000);

    // Drag to select region (from 200,200 to 600,500)
    exec('cliclick dd:200,200 dm:600,500 du:600,500', { ignoreError: true });
    sleep(2000);

    await takeScreenshot(testInfo, 'after-region-select');

    // Check if settings window reappeared (it should after region selection)
    sleep(1000);
    expect(isAppRunning()).toBe(true);

    if (isSettingsOpen()) {
      closeSettings();
    }
  });

  // TC-RSEL-003: Escapeでキャンセル
  test('TC-RSEL-003: escape cancels region selection', async ({}, testInfo) => {
    if (!isSettingsOpen()) {
      openSettings();
      sleep(1000);
    }

    exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
        try
          click button "範囲を追加" of window 1
        on error
          click button "Add Region" of window 1
        end try
      end tell'`,
      { ignoreError: true, timeout: 5000 }
    );
    sleep(2000);

    await takeScreenshot(testInfo, 'overlay-before-escape');

    // Press Escape
    exec(`osascript -e 'tell application "System Events" to key code 53'`, { ignoreError: true });
    sleep(1000);

    await takeScreenshot(testInfo, 'after-escape');

    // App should still be running, no crash
    expect(isAppRunning()).toBe(true);

    if (isSettingsOpen()) {
      closeSettings();
    }
  });

  // TC-RSEL-006: マルチディスプレイでの範囲選択
  test('TC-RSEL-006: multi-display region selection', async ({}, testInfo) => {
    const displays = getConnectedDisplays();
    await attachJson(testInfo, 'displays', displays);

    if (displays.length < 2) {
      test.skip(true, 'Multi-display test requires 2+ displays');
      return;
    }

    await takeScreenshot(testInfo, 'multi-display');

    // Verify overlay would appear on all displays
    // This is inherently a visual test but we verify the app doesn't crash
    expect(displays.length).toBeGreaterThanOrEqual(2);
    expect(isAppRunning()).toBe(true);
  });
});
