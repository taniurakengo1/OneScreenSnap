import { test, expect } from '@playwright/test';
import { exec } from '../helpers/exec';
import {
  isAppRunning,
  launchApp,
  quitApp,
  forceQuitApp,
  waitForMenuBarItem,
  isDockIconVisible,
  sleep,
} from '../helpers/app-control';
import { hasMenuBarItem, getMenuItems } from '../helpers/menubar';
import { resetToCleanState } from '../helpers/defaults';
import { getConnectedDisplays } from '../helpers/display';
import { takeScreenshot, attachJson } from '../helpers/evidence';
import { AX_INSPECTOR_BIN } from '../helpers/constants';

test.describe('TS-LAUNCH: 起動・終了', () => {
  test.beforeAll(() => {
    if (isAppRunning()) forceQuitApp();
    resetToCleanState();
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
  });

  // TC-LAUNCH-001: 初回起動
  test('TC-LAUNCH-001: first launch shows menu bar icon', async ({}, testInfo) => {
    launchApp();
    waitForMenuBarItem();

    await takeScreenshot(testInfo, 'after-launch');

    expect(isAppRunning()).toBe(true);

    // Verify via ax-inspector
    const { stdout } = exec(`"${AX_INSPECTOR_BIN}" status-item`, { ignoreError: true });
    if (stdout) {
      const info = JSON.parse(stdout);
      await attachJson(testInfo, 'ax-status-item', info);
      expect(info.data.isRunning).toBe(true);
    }
  });

  // TC-LAUNCH-002: Dockアイコン非表示
  test('TC-LAUNCH-002: Dock icon is hidden', async ({}, testInfo) => {
    if (!isAppRunning()) launchApp();
    sleep(1000);

    // Check via System Events
    const dockVisible = isDockIconVisible();
    await takeScreenshot(testInfo, 'dock-check');

    expect(dockVisible).toBe(false);

    // Also verify via ax-inspector (activationPolicy: 0=regular, 1=accessory, 2=prohibited)
    const { stdout } = exec(`"${AX_INSPECTOR_BIN}" status-item`, { ignoreError: true });
    if (stdout) {
      const info = JSON.parse(stdout);
      await attachJson(testInfo, 'activation-policy', info);
      expect(info.data.activationPolicy).toBe(1); // .accessory = LSUIElement
    }
  });

  // TC-LAUNCH-003: メニューバーアイコン表示
  test('TC-LAUNCH-003: menu bar icon is visible', async ({}, testInfo) => {
    if (!isAppRunning()) launchApp();
    sleep(1000);

    const exists = hasMenuBarItem();
    await takeScreenshot(testInfo, 'menu-bar-icon');

    expect(exists).toBe(true);
  });

  // TC-LAUNCH-004: メニュー項目一覧
  test('TC-LAUNCH-004: menu contains expected items', async ({}, testInfo) => {
    if (!isAppRunning()) launchApp();
    sleep(1000);

    const items = getMenuItems();
    await attachJson(testInfo, 'menu-items', items);
    await takeScreenshot(testInfo, 'menu-items');

    // Should contain settings and quit items
    const hasSettings = items.some(
      (item) => item.includes('設定') || item.includes('Settings')
    );
    const hasQuit = items.some(
      (item) => item.includes('終了') || item.includes('Quit')
    );

    expect(hasSettings).toBe(true);
    expect(hasQuit).toBe(true);
    expect(items.length).toBeGreaterThanOrEqual(3);
  });

  // TC-LAUNCH-005: メニューから終了
  test('TC-LAUNCH-005: quit from menu', async ({}, testInfo) => {
    if (!isAppRunning()) launchApp();
    sleep(1000);

    await takeScreenshot(testInfo, 'before-quit');

    quitApp();
    sleep(1000);

    await takeScreenshot(testInfo, 'after-quit');

    expect(isAppRunning()).toBe(false);
  });

  // TC-LAUNCH-010: 起動時のディスプレイ検出
  test('TC-LAUNCH-010: displays detected on launch', async ({}, testInfo) => {
    launchApp();
    waitForMenuBarItem();

    const systemDisplays = getConnectedDisplays();
    await attachJson(testInfo, 'system-displays', systemDisplays);

    const menuItems = getMenuItems();
    await attachJson(testInfo, 'menu-items', menuItems);
    await takeScreenshot(testInfo, 'displays-in-menu');

    // Menu should have items for each display plus settings/quit/separators
    expect(menuItems.length).toBeGreaterThanOrEqual(systemDisplays.length + 2);
  });
});
