import { exec } from './exec';
import { DEFAULTS_DOMAIN, DEFAULTS_KEYS } from './constants';

export function readDefaults(key: string): string {
  const { stdout } = exec(`defaults read ${DEFAULTS_DOMAIN} ${key}`, { ignoreError: true });
  return stdout;
}

export function writeDefaults(key: string, value: string): void {
  exec(`defaults write ${DEFAULTS_DOMAIN} ${key} '${value}'`);
}

export function writeDefaultsInt(key: string, value: number): void {
  exec(`defaults write ${DEFAULTS_DOMAIN} ${key} -int ${value}`);
}

/**
 * Write JSON object as NSData to UserDefaults.
 * Converts JSON to hex and uses `defaults write -data`.
 */
export function writeDefaultsData(key: string, jsonObj: unknown): void {
  const jsonStr = JSON.stringify(jsonObj);
  const hex = Buffer.from(jsonStr, 'utf-8').toString('hex');
  exec(`defaults write ${DEFAULTS_DOMAIN} ${key} -data "${hex}"`);
}

export function deleteDefaults(key: string): void {
  exec(`defaults delete ${DEFAULTS_DOMAIN} ${key}`, { ignoreError: true });
}

export function clearAllDefaults(): void {
  for (const key of Object.values(DEFAULTS_KEYS)) {
    deleteDefaults(key);
  }
}

export function resetToCleanState(): void {
  clearAllDefaults();
}

export function readBindings(): any[] {
  const raw = readDefaults(DEFAULTS_KEYS.bindings);
  if (!raw) return [];
  try {
    const { stdout } = exec(
      `defaults export ${DEFAULTS_DOMAIN} - | plutil -extract ${DEFAULTS_KEYS.bindings} raw -o - -`,
      { ignoreError: true }
    );
    if (stdout) {
      const decoded = Buffer.from(stdout.trim(), 'base64').toString('utf-8');
      return JSON.parse(decoded);
    }
  } catch {
    // fallback
  }
  return [];
}

export function readFeedbackMode(): number {
  const raw = readDefaults(DEFAULTS_KEYS.feedback);
  return parseInt(raw, 10) || 0;
}

export function readResizeMode(): number {
  const raw = readDefaults(DEFAULTS_KEYS.resize);
  return parseInt(raw, 10) || 0;
}
