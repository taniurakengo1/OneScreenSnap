import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { getMenuItems } from '../helpers/menubar';
import { getConnectedDisplays } from '../helpers/display';
import { resetToCleanState } from '../helpers/defaults';
import { takeScreenshot, attachJson } from '../helpers/evidence';

test.describe('TS-DISPLAY: ディスプレイ検出', () => {
  test.beforeAll(() => {
    resetToCleanState();
    if (isAppRunning()) quitApp();
    launchApp();
    sleep(2000);
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
  });

  // TC-DISP-001: シングルディスプレイ検出
  test('TC-DISP-001: detects at least one display', async ({}, testInfo) => {
    const displays = getConnectedDisplays();
    await attachJson(testInfo, 'system-displays', displays);

    expect(displays.length).toBeGreaterThanOrEqual(1);

    const mainDisplay = displays.find((d) => d.isMain);
    expect(mainDisplay).toBeDefined();
    expect(mainDisplay!.width).toBeGreaterThan(0);
    expect(mainDisplay!.height).toBeGreaterThan(0);

    // Verify menu shows display items
    const menuItems = getMenuItems();
    await attachJson(testInfo, 'menu-items', menuItems);
    await takeScreenshot(testInfo, 'single-display');

    expect(menuItems.length).toBeGreaterThanOrEqual(3);
  });

  // TC-DISP-002: デュアルディスプレイ検出
  test('TC-DISP-002: detects dual displays', async ({}, testInfo) => {
    const displays = getConnectedDisplays();
    await attachJson(testInfo, 'displays', displays);
    await takeScreenshot(testInfo, 'dual-display');

    if (displays.length < 2) {
      test.skip(true, 'Only 1 display connected — dual display test requires 2+ displays');
    }

    expect(displays.length).toBeGreaterThanOrEqual(2);

    const menuItems = getMenuItems();
    await attachJson(testInfo, 'menu-items', menuItems);

    expect(menuItems.length).toBeGreaterThanOrEqual(displays.length + 2);
  });

  // TC-DISP-004: ディスプレイ名と解像度表示
  test('TC-DISP-004: display name and resolution are correct', async ({}, testInfo) => {
    const displays = getConnectedDisplays();
    await attachJson(testInfo, 'displays-detail', displays);

    for (const display of displays) {
      expect(display.name).toBeTruthy();
      expect(display.name.length).toBeGreaterThan(0);
      expect(display.width).toBeGreaterThan(0);
      expect(display.height).toBeGreaterThan(0);
      expect([1, 2, 3]).toContain(display.scaleFactor);
    }

    await takeScreenshot(testInfo, 'display-details');
  });

  // TC-DISP-005 & TC-DISP-006: ホットプラグ
  test('TC-DISP-005: hotplug add — physical test', async ({}, testInfo) => {
    test.skip(true, 'Hotplug test requires physical display connection — manual test');
  });

  test('TC-DISP-006: hotplug remove — physical test', async ({}, testInfo) => {
    test.skip(true, 'Hotplug test requires physical display disconnection — manual test');
  });
});
