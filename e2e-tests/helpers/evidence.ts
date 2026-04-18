import { exec } from './exec';
import { TestInfo } from '@playwright/test';
import path from 'path';
import fs from 'fs';

const EVIDENCE_DIR = path.resolve(__dirname, '..', 'evidence');

function ensureEvidenceDir(): void {
  if (!fs.existsSync(EVIDENCE_DIR)) {
    fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  }
}

export async function takeScreenshot(
  testInfo: TestInfo,
  name: string
): Promise<string> {
  ensureEvidenceDir();
  const filename = `${name}-${Date.now()}.png`;
  const filepath = path.join(EVIDENCE_DIR, filename);

  exec(`screencapture -x "${filepath}"`);

  await testInfo.attach(name, {
    path: filepath,
    contentType: 'image/png',
  });

  return filepath;
}

export async function attachText(
  testInfo: TestInfo,
  name: string,
  content: string
): Promise<void> {
  await testInfo.attach(name, {
    body: content,
    contentType: 'text/plain',
  });
}

export async function attachJson(
  testInfo: TestInfo,
  name: string,
  data: unknown
): Promise<void> {
  await testInfo.attach(name, {
    body: JSON.stringify(data, null, 2),
    contentType: 'application/json',
  });
}
