import { exec, execOsascript, execJxa } from './exec';
import { APP_NAME, TIMEOUT } from './constants';
import { sleep } from './app-control';

// LSUIElement apps with NSStatusItem use menu bar 1, not menu bar 2
const MENU_BAR = 'menu bar 1';

export function clickMenuBarItem(): void {
  execOsascript(
    `tell application "System Events"
      tell process "${APP_NAME}"
        click menu bar item 1 of ${MENU_BAR}
      end tell
    end tell`
  );
  sleep(TIMEOUT.short);
}

export function closeMenu(): void {
  execOsascript(
    `tell application "System Events"
      key code 53
    end tell`
  );
  sleep(300);
}

export function getMenuItems(): string[] {
  const result = execOsascript(
    `tell application "System Events"
      tell process "${APP_NAME}"
        click menu bar item 1 of ${MENU_BAR}
        delay 0.5
        set menuItems to {}
        repeat with mi in menu items of menu 1 of menu bar item 1 of ${MENU_BAR}
          try
            set end of menuItems to name of mi
          on error
            set end of menuItems to "---"
          end try
        end repeat
        key code 53
        return menuItems
      end tell
    end tell`
  );
  return result
    .split(', ')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

export function selectMenuItem(title: string): void {
  execOsascript(
    `tell application "System Events"
      tell process "${APP_NAME}"
        click menu bar item 1 of ${MENU_BAR}
        delay 0.3
        click menu item "${title}" of menu 1 of menu bar item 1 of ${MENU_BAR}
      end tell
    end tell`
  );
  sleep(500);
}

export function hasMenuBarItem(): boolean {
  try {
    const result = execOsascript(
      `tell application "System Events"
        tell process "${APP_NAME}"
          return exists menu bar item 1 of ${MENU_BAR}
        end tell
      end tell`
    );
    return result.trim() === 'true';
  } catch {
    return false;
  }
}
