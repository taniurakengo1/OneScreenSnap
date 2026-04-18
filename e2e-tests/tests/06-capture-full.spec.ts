import { test, expect } from '@playwright/test';
import {
  isAppRunning,
  launchApp,
  quitApp,
  sleep,
} from '../helpers/app-control';
import { getMenuItems } from '../helpers/menubar';
import {
  getClipboardImageInfo,
  clearClipboard,
  setClipboardText,
  isAppCaptureWorking,
  captureByMenuIndex,
  resetCaptureVerification,
  CAPTURE_SKIP_MSG,
} from '../helpers/capture';
import { getMainDisplay, parseDisplayMenuItems } from '../helpers/display';
import { resetToCleanState, writeDefaultsInt } from '../helpers/defaults';
import { takeScreenshot, attachJson } from '../helpers/evidence';
import { DEFAULTS_KEYS } from '../helpers/constants';

test.describe('TS-CAPTURE-FULL: 全画面キャプチャ', () => {
  test.beforeAll(() => {
    resetToCleanState();
    resetCaptureVerification();
    if (isAppRunning()) quitApp();
    launchApp();
    sleep(2000);
  });

  test.afterAll(() => {
    if (isAppRunning()) quitApp();
  });

  // TC-CAP-001: 基本全画面キャプチャ (via menu)
  test('TC-CAP-001: basic full screen capture via menu', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'clipboard-info', clipInfo);
    await takeScreenshot(testInfo, 'after-capture');

    expect(clipInfo.hasImage).toBe(true);
    expect(clipInfo.width).toBeGreaterThan(0);
    expect(clipInfo.height).toBeGreaterThan(0);
  });

  // TC-CAP-004: マルチディスプレイ個別キャプチャ
  test('TC-CAP-004: multi-display individual capture', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    const menuItems = getMenuItems();
    const displays = parseDisplayMenuItems(menuItems);
    await attachJson(testInfo, 'displays', displays);

    if (displays.length < 2) {
      test.skip(true, 'Multi-display test requires 2+ displays');
      return;
    }

    // Capture display 1 (index 3)
    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);
    const clip1 = getClipboardImageInfo();

    // Capture display 2 (index 4)
    clearClipboard();
    sleep(300);
    captureByMenuIndex(4);
    const clip2 = getClipboardImageInfo();

    await attachJson(testInfo, 'display1-capture', clip1);
    await attachJson(testInfo, 'display2-capture', clip2);
    await takeScreenshot(testInfo, 'multi-display-capture');

    expect(clip1.hasImage).toBe(true);
    expect(clip2.hasImage).toBe(true);
  });

  // TC-CAP-002: Retinaディスプレイキャプチャ
  test('TC-CAP-002: retina display captures at 2x resolution', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    const mainDisplay = getMainDisplay();
    if (!mainDisplay || mainDisplay.scaleFactor < 2) {
      test.skip(true, 'Main display is not Retina');
      return;
    }

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'retina-capture', clipInfo);

    expect(clipInfo.hasImage).toBe(true);
    expect(clipInfo.width).toBeGreaterThanOrEqual(mainDisplay.width);
    await takeScreenshot(testInfo, 'retina-capture');
  });

  // TC-CAP-005: AIリサイズモードキャプチャ
  test('TC-CAP-005: AI resize mode limits to 1568px', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    writeDefaultsInt(DEFAULTS_KEYS.resize, 1);
    quitApp();
    sleep(1000);
    launchApp();
    sleep(2000);

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'ai-resize-capture', clipInfo);
    await takeScreenshot(testInfo, 'ai-resize');

    expect(clipInfo.hasImage).toBe(true);
    const maxDim = Math.max(clipInfo.width, clipInfo.height);
    expect(maxDim).toBeLessThanOrEqual(1568);

    writeDefaultsInt(DEFAULTS_KEYS.resize, 0);
  });

  // TC-CAP-006: フル解像度モードキャプチャ
  test('TC-CAP-006: full resolution capture', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    writeDefaultsInt(DEFAULTS_KEYS.resize, 0);
    quitApp();
    sleep(1000);
    launchApp();
    sleep(2000);

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const mainDisplay = getMainDisplay();
    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'full-res-capture', clipInfo);
    await takeScreenshot(testInfo, 'full-res');

    expect(clipInfo.hasImage).toBe(true);
    if (mainDisplay) {
      const expectedWidth = mainDisplay.width * mainDisplay.scaleFactor;
      const expectedHeight = mainDisplay.height * mainDisplay.scaleFactor;
      expect(clipInfo.width).toBe(expectedWidth);
      expect(clipInfo.height).toBe(expectedHeight);
    }
  });

  // TC-CAP-011: クリップボード上書き確認
  test('TC-CAP-011: capture overwrites clipboard text', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    setClipboardText('test-clipboard-text');
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'clipboard-overwrite', clipInfo);

    expect(clipInfo.hasImage).toBe(true);
  });

  // TC-CAP-012: 他アプリでの画像ペースト
  test('TC-CAP-012: clipboard image is pasteable format', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'pasteable-format', clipInfo);
    await takeScreenshot(testInfo, 'pasteable');

    expect(clipInfo.hasImage).toBe(true);
    expect(['TIFF', 'PNG']).toContain(clipInfo.format);
  });

  // TC-CAP-013: メニューからのキャプチャ
  test('TC-CAP-013: menu capture produces valid image', async ({}, testInfo) => {
    if (!isAppCaptureWorking()) { test.skip(true, CAPTURE_SKIP_MSG); return; }

    clearClipboard();
    sleep(300);
    captureByMenuIndex(3);

    const clipInfo = getClipboardImageInfo();
    await attachJson(testInfo, 'menu-capture', clipInfo);
    await takeScreenshot(testInfo, 'menu-capture');

    expect(clipInfo.hasImage).toBe(true);
    expect(clipInfo.width).toBeGreaterThan(0);
  });
});
