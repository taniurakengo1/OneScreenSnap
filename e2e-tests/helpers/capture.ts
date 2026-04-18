import { exec } from './exec';
import { CLIPBOARD_INFO_BIN } from './constants';
import { sleep } from './app-control';

export interface ClipboardImageInfo {
  hasImage: boolean;
  width: number;
  height: number;
  format: string;
  bytesPerRow: number;
}

export function getClipboardImageInfo(): ClipboardImageInfo {
  const { stdout } = exec(CLIPBOARD_INFO_BIN);
  return JSON.parse(stdout);
}

export function clearClipboard(): void {
  exec(`osascript -e 'set the clipboard to ""'`);
  sleep(200);
}

export function setClipboardText(text: string): void {
  exec(`osascript -e 'set the clipboard to "${text}"'`);
  sleep(200);
}

export function getClipboardText(): string {
  const { stdout } = exec(`osascript -e 'the clipboard'`, { ignoreError: true });
  return stdout;
}

export function hasClipboardImage(): boolean {
  return getClipboardImageInfo().hasImage;
}

/**
 * Check if the app's screen capture actually works.
 * This tests the full capture pipeline including ScreenCaptureKit permissions.
 * Returns true if capture produces a clipboard image, false otherwise.
 */
let _captureVerified: boolean | null = null;

export function isAppCaptureWorking(): boolean {
  if (_captureVerified !== null) return _captureVerified;

  try {
    clearClipboard();
    sleep(300);

    // Try capturing via menu — click the first actual display item by index
    exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
        click menu bar item 1 of menu bar 1
        delay 0.5
        click menu item 3 of menu 1 of menu bar item 1 of menu bar 1
      end tell'`,
      { ignoreError: true, timeout: 10_000 }
    );

    sleep(3000);

    _captureVerified = hasClipboardImage();
  } catch {
    _captureVerified = false;
  }

  return _captureVerified;
}

/**
 * Capture by clicking a display menu item by index (more reliable than by name).
 * Index 3 = first display (after app name header + separator).
 */
export function captureByMenuIndex(index: number = 3): boolean {
  try {
    exec(
      `osascript -e 'tell application "System Events" to tell process "OneScreenSnap"
        click menu bar item 1 of menu bar 1
        delay 0.5
        click menu item ${index} of menu 1 of menu bar item 1 of menu bar 1
      end tell'`,
      { ignoreError: true, timeout: 10_000 }
    );
    sleep(2000);
    return true;
  } catch {
    return false;
  }
}

export function resetCaptureVerification(): void {
  _captureVerified = null;
}

export const CAPTURE_SKIP_MSG =
  'Screen recording permission not granted for this app bundle. ' +
  'Grant permission in System Settings > Privacy & Security > Screen Recording, then re-run tests.';
