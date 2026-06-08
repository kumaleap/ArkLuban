import { CompressionTarget } from './LubanTypes';

/**
 * Android 当前 Luban CompressionCalculator 的 ArkTS 迁移版。
 */
export class CompressionCalculator {
  private static readonly BASE_SHORT: number = 1440;
  private static readonly WALL_LONG: number = 10800;
  private static readonly WALL_RATIO: number = 0.4;
  private static readonly TRAP_PIXELS: number = 40960000;
  private static readonly CAP_PIXELS: number = 10240000;

  static calculateTarget(width: number, height: number): CompressionTarget {
    if (width <= 0 || height <= 0) {
      return {
        width: 0,
        height: 0,
        estimatedSizeKb: 0,
        isLongImage: false
      };
    }

    const shortSide = Math.min(width, height);
    const longSide = Math.max(width, height);
    const ratio = shortSide / longSide;
    const pixelCount = width * height;

    let targetShort = CompressionCalculator.BASE_SHORT;
    let targetLong = Math.floor(targetShort / ratio);

    if (longSide >= CompressionCalculator.WALL_LONG && ratio > CompressionCalculator.WALL_RATIO) {
      targetLong = CompressionCalculator.BASE_SHORT;
      targetShort = Math.floor(targetLong * ratio);
    }

    if (pixelCount > CompressionCalculator.TRAP_PIXELS) {
      const trapShort = Math.floor(shortSide * 0.25);
      if (trapShort < targetShort) {
        targetShort = trapShort;
        targetLong = Math.floor(targetShort / ratio);
      }
    }

    if (targetShort > shortSide) {
      targetShort = shortSide;
      targetLong = longSide;
    }

    const currentPixels = targetShort * targetLong;
    if (currentPixels > CompressionCalculator.CAP_PIXELS) {
      const scale = Math.floor(Math.sqrt(CompressionCalculator.CAP_PIXELS / currentPixels) * 1000) / 1000.0;
      targetShort = Math.floor(targetShort * scale);
      targetLong = Math.floor(targetLong * scale);
    }

    targetShort = Math.floor(targetShort / 2) * 2;
    targetLong = Math.floor(targetLong / 2) * 2;
    targetShort = Math.max(2, targetShort);
    targetLong = Math.max(2, targetLong);

    const finalWidth = width < height ? targetShort : targetLong;
    const finalHeight = width < height ? targetLong : targetShort;
    const finalPixels = finalWidth * finalHeight;

    let factor = 0.000025;
    if (finalPixels < 500000) {
      factor = 0.0005;
    } else if (finalPixels < 1000000) {
      factor = 0.00015;
    } else if (finalPixels < 3000000) {
      factor = 0.00011;
    }

    let estimatedSize = Math.floor(finalPixels * factor);
    estimatedSize = Math.max(20, estimatedSize);

    if (ratio < 0.2 && estimatedSize < 400) {
      estimatedSize = Math.max(estimatedSize, 250);
    }

    const isLongImage = ratio <= 0.5;
    const result: CompressionTarget = {
      width: finalWidth,
      height: finalHeight,
      estimatedSizeKb: estimatedSize,
      isLongImage: isLongImage
    };

    if (isLongImage) {
      result.targetSizeKb = estimatedSize;
    }

    return result;
  }
}
