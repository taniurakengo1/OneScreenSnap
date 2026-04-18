import { exec } from './exec';

export interface DisplayInfo {
  name: string;
  resolution: string;
  width: number;
  height: number;
  scaleFactor: number;
  isMain: boolean;
}

export function getConnectedDisplays(): DisplayInfo[] {
  const { stdout } = exec('system_profiler SPDisplaysDataType -json', { timeout: 10_000 });
  const data = JSON.parse(stdout);

  const displays: DisplayInfo[] = [];

  for (const gpu of data.SPDisplaysDataType || []) {
    for (const display of gpu.spdisplays_ndrvs || []) {
      const name = display._name || 'Unknown';
      const resMatch = display._spdisplays_resolution?.match(/(\d+)\s*x\s*(\d+)/);
      const width = resMatch ? parseInt(resMatch[1], 10) : 0;
      const height = resMatch ? parseInt(resMatch[2], 10) : 0;
      const isMain = display.spdisplays_main === 'spdisplays_yes';

      const pixelRes = display._spdisplays_pixels?.match(/(\d+)\s*x\s*(\d+)/);
      let scaleFactor = 1;
      if (pixelRes) {
        const pixelWidth = parseInt(pixelRes[1], 10);
        if (width > 0 && pixelWidth > width) {
          scaleFactor = Math.round(pixelWidth / width);
        }
      }

      displays.push({
        name,
        resolution: `${width}×${height}`,
        width,
        height,
        scaleFactor,
        isMain,
      });
    }
  }

  return displays;
}

export function getDisplayCount(): number {
  return getConnectedDisplays().length;
}

export function getMainDisplay(): DisplayInfo | undefined {
  return getConnectedDisplays().find((d) => d.isMain);
}

/**
 * Parse display info from the app's menu items.
 * Menu format: "DisplayName (WxH)  [Position]" or "DisplayName (N) (WxH) ★  [Position]"
 */
export interface MenuDisplayInfo {
  menuTitle: string;
  displayName: string;
  width: number;
  height: number;
  stableKey: string;
  isMain: boolean;
}

export function parseDisplayMenuItems(menuItems: string[]): MenuDisplayInfo[] {
  const results: MenuDisplayInfo[] = [];

  for (const item of menuItems) {
    // Match patterns like:
    //   "MF27X3A (2) (1920×1080)  [← 左]"
    //   "Built-in Retina Display (2560×1600) ★  [右 →]"
    const match = item.match(/^(.+?)\s+\((\d+)[×x](\d+)\)/);
    if (match) {
      const displayName = match[1].trim();
      const width = parseInt(match[2], 10);
      const height = parseInt(match[3], 10);
      const isMain = item.includes('★');
      const stableKey = `${displayName}_${width}x${height}`;

      results.push({
        menuTitle: item,
        displayName,
        width,
        height,
        stableKey,
        isMain,
      });
    }
  }

  return results;
}
