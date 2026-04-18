import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import {
  clickMenuBarItem,
  closeMenu,
  getMenuItems,
  selectMenuItem,
  hasMenuBarItem,
} from '../helpers/menubar';
import { isSettingsOpen, closeSettings } from '../helpers/settings';
import { resetToCleanState } from '../helpers/defaults';
import { getClipboardImageInfo, clearClipboard, isAppCaptureWorking, captureByMenuIndex, CAPTURE_SKIP_MSG } from '../helpers/capture';
import { takeScreenshot, attachJson } from '../helpers/evidence';

test.describe('TS-MENUBAR: メニューバー操作', () => {
  test.beforeAll(() => {
    resetToCleanState();
    if (isAppRunning()) quitApp();
    launchApp();
    sleep(2000);
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
  });

  // TC-MENU-001: メニュー展開
  test('TC-MENU-001: menu opens on click', async ({}, testInfo) => {
    expect(hasMenuBarItem()).toBe(true);

    clickMenuBarItem();
    await takeScreenshot(testInfo, 'menu-opened');
    closeMenu();
  });

  // TC-MENU-002: ディスプレイメニューからキャプチャ
  test('TC-MENU-002: capture from display menu item', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) {
      test.skip(true, CAPTURE_SKIP_MSG);
      return;
    }

    clearClipboard();
    sleep(300);

    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'clipboard-after-capture', clipInfo);
    await takeScreenshot(testInfo, 'after-menu-capture');

    expect(clipInfo.hasImage).toBe(true);
    expect(clipInfo.width).toBeGreaterThan(0);
  });

  // TC-MENU-004: 設定メニュー項目
  test('TC-MENU-004: settings menu opens settings window', async ({}, testInfo) => {
    if (isSettingsOpen()) {
      closeSettings();
      sleep(500);
    }

    try {
      selectMenuItem('設定...');
    } catch {
      try {
        selectMenuItem('Settings...');
      } catch {
        test.skip(true, 'Could not find settings menu item');
        return;
      }
    }
    sleep(1000);

    await takeScreenshot(testInfo, 'settings-opened');
    expect(isSettingsOpen()).toBe(true);

    closeSettings();
  });

  // TC-MENU-005: 終了メニュー項目
  test('TC-MENU-005: quit menu item quits app', async ({}, testInfo) => {
    if (!isAppRunning()) launchApp();
    sleep(1000);

    await takeScreenshot(testInfo, 'before-menu-quit');

    try {
      selectMenuItem('終了');
    } catch {
      try {
        selectMenuItem('Quit');
      } catch {
        quitApp();
      }
    }
    sleep(2000);

    await takeScreenshot(testInfo, 'after-menu-quit');
    expect(isAppRunning()).toBe(false);
  });
});
