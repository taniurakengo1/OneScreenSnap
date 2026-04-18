import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { getMenuItems } from '../helpers/menubar';
import { parseDisplayMenuItems } from '../helpers/display';
import {
  resetToCleanState,
  writeDefaultsData,
} from '../helpers/defaults';
import {
  getClipboardImageInfo,
  clearClipboard,
  isAppCaptureWorking,
  CAPTURE_SKIP_MSG,
} from '../helpers/capture';
import { pressShortcut } from '../helpers/shortcut';
import { takeScreenshot, attachJson } from '../helpers/evidence';
import { DEFAULTS_KEYS, KEY_CODES, MODIFIERS } from '../helpers/constants';

test.describe('TS-CAPTURE-REGION: 矩形キャプチャ (P1)', () => {
  test.beforeAll(() => {
    resetToCleanState();
    if (isAppRunning()) quitApp();
    launchApp();
    sleep(2000);
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
    resetToCleanState();
  });

  // TC-RCAP-001: 基本矩形キャプチャ
  test('TC-RCAP-001: basic region capture via shortcut', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    const menuItems = getMenuItems();
    const displays = parseDisplayMenuItems(menuItems);
    if (displays.length === 0) { test.skip(true, 'No displays'); return; }

    const stableKey = (displays.find((d) => d.isMain) || displays[0]).stableKey;
    const regionWidth = 400;
    const regionHeight = 300;

    const preset = [
      {
        id: 'rcap001-basic',
        name: 'Basic Region',
        rect: { x: 100, y: 100, width: regionWidth, height: regionHeight },
        displayStableKey: stableKey,
        shortcut: {
          keyCode: KEY_CODES.F11,
          modifiers: MODIFIERS.command | MODIFIERS.shift,
        },
      },
    ];

    writeDefaultsData(DEFAULTS_KEYS.regions, preset);
    quitApp();
    sleep(1000);
    launchApp();
    sleep(2000);

    clearClipboard();
    sleep(300);

    pressShortcut({ key: 'F11', modifiers: ['command', 'shift'] });
    sleep(2000);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'region-capture', clipInfo);
    await takeScreenshot(testInfo, 'basic-region');

    expect(clipInfo.hasImage).toBe(true);
    expect(clipInfo.width).toBeGreaterThan(0);
    expect(clipInfo.height).toBeGreaterThan(0);

    // The captured image should approximately match the region size
    // (accounting for Retina scaling)
    expect(clipInfo.width).toBeGreaterThanOrEqual(regionWidth);
    expect(clipInfo.height).toBeGreaterThanOrEqual(regionHeight);
  });
});
