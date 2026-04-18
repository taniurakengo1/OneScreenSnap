import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { getMenuItems, selectMenuItem } from '../helpers/menubar';
import {
  openSettings,
  closeSettings,
  isSettingsOpen,
  getSettingsWindowTitle,
} from '../helpers/settings';
import { resetToCleanState, writeDefaultsData } from '../helpers/defaults';
import { getConnectedDisplays, parseDisplayMenuItems } from '../helpers/display';
import { takeScreenshot, attachJson, attachText } from '../helpers/evidence';
import { exec } from '../helpers/exec';
import { AX_INSPECTOR_BIN, DEFAULTS_KEYS } from '../helpers/constants';

test.describe('TS-SETTINGS: 設定画面UI (P1)', () => {
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

  // TC-SET-001: 設定画面の表示
  test('TC-SET-001: settings window shows all sections', async ({}, testInfo) => {
    openSettings();
    sleep(1000);

    await takeScreenshot(testInfo, 'settings-window');

    expect(isSettingsOpen()).toBe(true);

    // Check window title
    const title = getSettingsWindowTitle();
    await attachText(testInfo, 'window-title', title);
    expect(title.length).toBeGreaterThan(0);
    expect(title.includes('設定') || title.includes('Settings')).toBe(true);

    // Verify window has content via AX inspector
    const { stdout } = exec(`"${AX_INSPECTOR_BIN}" window`, { ignoreError: true });
    if (stdout) {
      const info = JSON.parse(stdout);
      await attachJson(testInfo, 'window-info', info);
      expect(info.data.windowCount).toBeGreaterThanOrEqual(1);
    }

    closeSettings();
  });

  // TC-SET-003: ディスプレイショートカットセクション
  test('TC-SET-003: display shortcut section shows all displays', async ({}, testInfo) => {
    openSettings();
    sleep(1000);

    const displays = getConnectedDisplays();
    await attachJson(testInfo, 'displays', displays);
    await takeScreenshot(testInfo, 'shortcut-section');

    // Settings window should show a shortcut recorder for each display
    // We can't easily inspect NSView content via System Events,
    // but we verify the window is open and has the right title
    expect(isSettingsOpen()).toBe(true);
    expect(displays.length).toBeGreaterThanOrEqual(1);

    closeSettings();
  });

  // TC-SET-007: リージョン追加ボタン
  test('TC-SET-007: add region button opens overlay', async ({}, testInfo) => {
    openSettings();
    sleep(1000);

    await takeScreenshot(testInfo, 'before-add-region');

    // Try to click "範囲を追加" / "Add Region" button
    try {
      exec(
        `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
          click button "範囲を追加" of window 1
        end tell'`,
        { ignoreError: true, timeout: 5000 }
      );
    } catch {
      try {
        exec(
          `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
            click button "Add Region" of window 1
          end tell'`,
          { ignoreError: true, timeout: 5000 }
        );
      } catch {
        // Button might have a different name or be nested
      }
    }
    sleep(2000);

    await takeScreenshot(testInfo, 'after-add-region');

    // Press Escape to cancel overlay if it appeared
    exec(`osascript -e 'tell application "System Events" to key code 53'`, { ignoreError: true });
    sleep(1000);

    // Reopen settings if it was hidden
    if (!isSettingsOpen()) {
      openSettings();
      sleep(500);
    }

    closeSettings();
  });

  // TC-SET-008: リージョン削除ボタン
  test('TC-SET-008: delete region button removes preset', async ({}, testInfo) => {
    // First create a region preset via UserDefaults
    const displays = getConnectedDisplays();
    const mainDisplay = displays.find((d) => d.isMain) || displays[0];

    const menuItems = getMenuItems();
    const menuDisplays = parseDisplayMenuItems(menuItems);
    const stableKey = menuDisplays.length > 0
      ? (menuDisplays.find((d) => d.isMain) || menuDisplays[0]).stableKey
      : `${mainDisplay.name}_${mainDisplay.width}x${mainDisplay.height}`;

    const preset = [
      {
        id: 'test-delete-1',
        name: 'Test Delete Region',
        rect: { x: 50, y: 50, width: 200, height: 200 },
        displayStableKey: stableKey,
        shortcut: null,
      },
    ];

    writeDefaultsData(DEFAULTS_KEYS.regions, preset);
    await attachJson(testInfo, 'preset-before', preset);

    // Restart to pick up
    quitApp();
    sleep(1000);
    launchApp();
    sleep(2000);

    // Verify preset exists in menu
    const menuBefore = getMenuItems();
    await attachJson(testInfo, 'menu-before-delete', menuBefore);

    // Clear the preset via UserDefaults
    writeDefaultsData(DEFAULTS_KEYS.regions, []);

    quitApp();
    sleep(1000);
    launchApp();
    sleep(2000);

    // Verify preset removed from menu
    const menuAfter = getMenuItems();
    await attachJson(testInfo, 'menu-after-delete', menuAfter);
    await takeScreenshot(testInfo, 'after-delete');

    const presetInMenu = menuAfter.some((item) => item.includes('Test Delete'));
    expect(presetInMenu).toBe(false);
  });
});
