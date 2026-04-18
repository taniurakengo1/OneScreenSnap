import { execOsascript } from './exec';
import { APP_NAME } from './constants';
import { sleep } from './app-control';
import { selectMenuItem } from './menubar';

export function openSettings(): void {
  // Use osascript to open settings via menu
  try {
    selectMenuItem('設定...');
  } catch {
    // Try English
    selectMenuItem('Settings...');
  }
  sleep(1000);
}

export function closeSettings(): void {
  execOsascript(
    `tell application "System Events"
      tell process "${APP_NAME}"
        try
          click button 1 of window 1
        end try
      end tell
    end tell`
  );
  sleep(500);
}

export function isSettingsOpen(): boolean {
  try {
    const result = execOsascript(
      `tell application "System Events"
        tell process "${APP_NAME}"
          return count of windows
        end tell
      end tell`
    );
    return parseInt(result.trim(), 10) > 0;
  } catch {
    return false;
  }
}

export function getSettingsWindowTitle(): string {
  try {
    const result = execOsascript(
      `tell application "System Events"
        tell process "${APP_NAME}"
          return name of window 1
        end tell
      end tell`
    );
    return result.trim();
  } catch {
    return '';
  }
}
