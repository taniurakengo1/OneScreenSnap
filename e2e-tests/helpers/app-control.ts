import { exec, execOsascript } from './exec';
import { APP_PATH, APP_NAME, TIMEOUT } from './constants';

export function isAppRunning(): boolean {
  const { stdout } = exec(`pgrep -x "${APP_NAME}" || true`, { ignoreError: true });
  return stdout.trim().length > 0;
}

export function getAppPid(): number | null {
  const { stdout } = exec(`pgrep -x "${APP_NAME}" || true`, { ignoreError: true });
  const pid = parseInt(stdout.trim(), 10);
  return isNaN(pid) ? null : pid;
}

export function launchApp(): void {
  if (isAppRunning()) return;
  exec(`open "${APP_PATH}"`);
  waitForApp(true);
}

export function quitApp(): void {
  if (!isAppRunning()) return;
  try {
    execOsascript(`tell application "${APP_NAME}" to quit`);
  } catch {
    // If osascript fails, force kill
    exec(`pkill -x "${APP_NAME}" || true`, { ignoreError: true });
  }
  waitForApp(false);
}

export function forceQuitApp(): void {
  exec(`pkill -9 -x "${APP_NAME}" || true`, { ignoreError: true });
  sleep(500);
}

export function waitForApp(shouldBeRunning: boolean, timeoutMs = TIMEOUT.appLaunch): void {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (isAppRunning() === shouldBeRunning) return;
    sleep(200);
  }
  throw new Error(
    `Timeout waiting for app to ${shouldBeRunning ? 'start' : 'stop'} (${timeoutMs}ms)`
  );
}

export function waitForMenuBarItem(timeoutMs = TIMEOUT.appLaunch): void {
  // After launch, wait a bit for the menu bar item to appear
  waitForApp(true, timeoutMs);
  sleep(1000); // Extra time for UI to stabilize
}

export function sleep(ms: number): void {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    // busy wait for synchronous sleep
  }
}

export function isDockIconVisible(): boolean {
  // Check if the app appears in the Dock by checking its backgroundOnly property
  const { stdout } = exec(
    `osascript -e 'tell application "System Events" to get background only of process "${APP_NAME}"'`,
    { ignoreError: true }
  );
  // backgroundOnly is true for LSUIElement apps (not visible in Dock)
  return stdout.trim() === 'false';
}
