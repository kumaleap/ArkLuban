import { image } from '@kit.ImageKit';
import { CompressFormat, CompressionTarget } from './LubanTypes';

/**
 * ImagePacker 压缩策略，迁移 Android 当前非长图固定质量和长图目标体积搜索行为。
 */
export class Compressor {
  private static readonly DEFAULT_JPEG_QUALITY: number = 60;
  private static readonly LOW_QUALITY: number = 5;
  private static readonly HIGH_QUALITY: number = 95;

  static async compress(
    pixelMap: image.PixelMap,
    format: string,
    target: CompressionTarget,
    fixedQuality?: number
  ): Promise<ArrayBuffer> {
    const quality = fixedQuality !== undefined ? Compressor.normalizeQuality(fixedQuality) : undefined;

    if (format !== CompressFormat.JPEG) {
      return await Compressor.packWithQuality(pixelMap, format, quality || Compressor.HIGH_QUALITY);
    }

    if (quality !== undefined) {
      return await Compressor.packWithQuality(pixelMap, format, quality);
    }

    if (!target.isLongImage || target.targetSizeKb === undefined) {
      return await Compressor.packWithQuality(pixelMap, format, Compressor.DEFAULT_JPEG_QUALITY);
    }

    const testResult = await Compressor.packWithQuality(pixelMap, format, Compressor.HIGH_QUALITY);
    if (testResult.byteLength / 1024 <= target.targetSizeKb) {
      return testResult;
    }

    let currentLow = Compressor.LOW_QUALITY;
    let currentHigh = Compressor.HIGH_QUALITY;
    let bestData: ArrayBuffer | undefined = undefined;

    while (currentLow <= currentHigh) {
      const mid = Math.floor((currentLow + currentHigh) / 2);
      const compressed = await Compressor.packWithQuality(pixelMap, format, mid);
      const currentSizeKb = compressed.byteLength / 1024;

      if (currentSizeKb <= target.targetSizeKb) {
        bestData = compressed;
        currentLow = mid + 1;
      } else {
        currentHigh = mid - 1;
      }
    }

    if (bestData !== undefined) {
      return bestData;
    }

    return await Compressor.packWithQuality(pixelMap, format, Compressor.LOW_QUALITY);
  }

  private static async packWithQuality(pixelMap: image.PixelMap, format: string, quality: number): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    try {
      const packOpts: image.PackingOption = {
        format: format,
        quality: quality
      };
      return await imagePackerApi.packToData(pixelMap, packOpts);
    } catch (error) {
      throw new Error(`图片编码失败: ${(error as Error).message}`);
    } finally {
      imagePackerApi.release();
    }
  }

  private static normalizeQuality(quality: number): number {
    if (!Number.isFinite(quality)) {
      return Compressor.DEFAULT_JPEG_QUALITY;
    }

    return Math.min(Compressor.HIGH_QUALITY, Math.max(Compressor.LOW_QUALITY, Math.floor(quality)));
  }
}
