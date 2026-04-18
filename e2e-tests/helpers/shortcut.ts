import { exec } from './exec';
import { sleep } from './app-control';

// cliclick key mapping for modifier keys
const MODIFIER_MAP: Record<string, string> = {
  command: 'cmd',
  shift: 'shift',
  control: 'ctrl',
  option: 'alt',
};

// cliclick key names for special keys
const KEY_MAP: Record<string, string> = {
  F1: 'f1',
  F2: 'f2',
  F3: 'f3',
  F4: 'f4',
  F5: 'f5',
  F6: 'f6',
  F7: 'f7',
  F8: 'f8',
  F9: 'f9',
  F10: 'f10',
  F11: 'f11',
  F12: 'f12',
  Escape: 'esc',
  Return: 'return',
  Tab: 'tab',
  Space: 'space',
  Delete: 'delete',
};

export interface ShortcutSpec {
  key: string;
  modifiers: string[];
}

export function pressShortcut(spec: ShortcutSpec): void {
  const mods = spec.modifiers.map((m) => MODIFIER_MAP[m] || m);
  const key = KEY_MAP[spec.key] || spec.key.toLowerCase();

  // cliclick kd (key down) for modifiers, then kp (key press) for the key, then ku (key up) for modifiers
  const cmds: string[] = [];
  for (const mod of mods) {
    cmds.push(`kd:${mod}`);
  }
  cmds.push(`kp:${key}`);
  for (const mod of mods.reverse()) {
    cmds.push(`ku:${mod}`);
  }

  exec(`cliclick ${cmds.join(' ')}`);
  sleep(300);
}

export function pressKey(key: string): void {
  const mappedKey = KEY_MAP[key] || key.toLowerCase();
  exec(`cliclick kp:${mappedKey}`);
  sleep(200);
}

export function typeText(text: string): void {
  exec(`cliclick t:"${text}"`);
  sleep(200);
}
