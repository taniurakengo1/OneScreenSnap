import path from 'path';
import fs from 'fs';

export const PROJECT_ROOT = path.resolve(__dirname, '..', '..');
export const E2E_ROOT = path.resolve(__dirname, '..');
export const BRIDGE_BIN = path.resolve(E2E_ROOT, 'bridge', 'bin');

export const APP_NAME = 'OneScreenSnap';

// Support both installed and local app bundle
const INSTALLED_APP_PATH = '/Applications/OneScreenSnap.app';
const LOCAL_APP_PATH = path.join(PROJECT_ROOT, 'OneScreenSnap.app');
export const APP_PATH = fs.existsSync(INSTALLED_APP_PATH) ? INSTALLED_APP_PATH : LOCAL_APP_PATH;
export const APP_INSTALLED = fs.existsSync(INSTALLED_APP_PATH);

export const APP_EXECUTABLE = `${APP_PATH}/Contents/MacOS/OneScreenSnap`;
export const APP_BUNDLE_ID = 'com.onescreensnap.app';
export const APP_PLIST_PATH = `${process.env.HOME}/Library/LaunchAgents/com.onescreensnap.app.plist`;

export const CLIPBOARD_INFO_BIN = path.join(BRIDGE_BIN, 'clipboard-info');
export const AX_INSPECTOR_BIN = path.join(BRIDGE_BIN, 'ax-inspector');

// The .app bundle uses CFBundleIdentifier as the UserDefaults domain
export const DEFAULTS_DOMAIN = 'com.onescreensnap.app';

// UserDefaults keys (from SettingsManager.swift)
export const DEFAULTS_KEYS = {
  bindings: 'displayShortcutBindings',
  regions: 'regionPresets',
  feedback: 'feedbackMode',
  resize: 'captureResizeMode',
} as const;

// Timeouts
export const TIMEOUT = {
  appLaunch: 10_000,
  appQuit: 5_000,
  capture: 5_000,
  menuOpen: 3_000,
  short: 1_000,
  flash: 500,
} as const;

// Key codes (from SettingsManager.swift keyCodeToString mapping)
export const KEY_CODES = {
  F1: 0x7a,
  F2: 0x78,
  F3: 0x63,
  F4: 0x76,
  F5: 0x60,
  F6: 0x61,
  F7: 0x62,
  F8: 0x64,
  F9: 0x65,
  F10: 0x6d,
  F11: 0x67,
  F12: 0x6f,
  A: 0x00,
  S: 0x01,
  D: 0x02,
  KEY_1: 0x12,
  KEY_2: 0x13,
  KEY_3: 0x14,
} as const;

// CGEventFlags modifier masks
export const MODIFIERS = {
  command: 0x100000,
  shift: 0x20000,
  control: 0x40000,
  option: 0x80000,
} as const;
