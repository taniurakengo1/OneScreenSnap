import { execSync, ExecSyncOptions } from 'child_process';

const DEFAULT_TIMEOUT = 30_000;

export interface ExecResult {
  stdout: string;
  exitCode: number;
}

export function exec(
  command: string,
  options?: { timeout?: number; cwd?: string; ignoreError?: boolean }
): ExecResult {
  const opts: ExecSyncOptions = {
    timeout: options?.timeout ?? DEFAULT_TIMEOUT,
    cwd: options?.cwd,
    encoding: 'utf-8',
    stdio: ['pipe', 'pipe', 'pipe'],
  };

  try {
    const stdout = execSync(command, opts) as unknown as string;
    return { stdout: stdout.trim(), exitCode: 0 };
  } catch (err: any) {
    if (options?.ignoreError) {
      return { stdout: (err.stdout ?? '').toString().trim(), exitCode: err.status ?? 1 };
    }
    throw err;
  }
}

export function execOsascript(script: string): string {
  const escaped = script.replace(/'/g, "'\\''");
  return exec(`osascript -e '${escaped}'`).stdout;
}

export function execJxa(script: string): string {
  const escaped = script.replace(/'/g, "'\\''");
  return exec(`osascript -l JavaScript -e '${escaped}'`).stdout;
}
