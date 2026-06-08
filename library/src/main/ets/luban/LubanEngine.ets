/**
 * Luban 压缩引擎核心实现
 * 基于微信朋友圈压缩算法的鸿蒙版本
 */

import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { CompressFormat, CompressResult } from './LubanTypes';
import { LubanUtils } from './LubanUtils';
import { LogUtil } from './LogUtil';
import { CompressionCalculator } from './CompressionCalculator';
import { Compressor } from './Compressor';
import { ImageLoader } from './ImageLoader';

/**
 * 压缩引擎类
 */
export class LubanEngine {
  private static readonly TAG = 'LubanEngine';

  /**
   * 压缩单张图片
   * @param sourcePath 源图片路径
   * @param targetPath 目标路径
   * @param focusAlpha 是否保留透明通道
   * @returns 压缩结果
   */
  static async compressSingle(
    sourcePath: string,
    targetPath: string,
    focusAlpha: boolean = false,
    ignoreBy: number = 100,
    quality?: number
  ): Promise<CompressResult> {
    let sourceFd: number | undefined = undefined;
    let targetFd: number | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    let imageSource: image.ImageSource | undefined = undefined;

    try {
      // 0. 获取原始文件大小
      const originalSize = await LubanUtils.getFileSizeInBytes(sourcePath);
      LogUtil.debug(`📏 原始文件大小: ${originalSize} 字节`);

      // 1. 读取原图信息（sourcePath 必须是可访问的普通路径）
      const sourceFile = fileIo.openSync(sourcePath, fileIo.OpenMode.READ_ONLY);
      sourceFd = sourceFile.fd;

      // 2. 创建图片源
      imageSource = image.createImageSource(sourceFd);
      const imageInfo = await ImageLoader.getImageInfo(imageSource);

      // 3. 计算压缩后的尺寸
      const compressTarget = CompressionCalculator.calculateTarget(imageInfo.size.width, imageInfo.size.height);

      // 4. 判断是否需要压缩
      if (!LubanEngine.needCompress(originalSize, compressTarget.width, compressTarget.height, ignoreBy)) {
        // 不需要压缩，直接复制文件
        const copyTargetPath = LubanEngine.resolveCopyTargetPath(sourcePath, targetPath);
        fileIo.copyFileSync(sourcePath, copyTargetPath);
        const copiedSize = fileIo.statSync(copyTargetPath).size;

        const result: CompressResult = {
          success: true,
          sourcePath: sourcePath,
          filePath: copyTargetPath,
          originalSize: originalSize,
          compressedSize: copiedSize
        };
        return result;
      }

      // 5. 解码图片并应用 EXIF 方向
      const loadedImage = await ImageLoader.load(imageSource, compressTarget, imageInfo);
      pixelMap = loadedImage.pixelMap;

      // 6. 设置打包选项
      const format = LubanEngine.getCompressFormat(sourcePath, focusAlpha);

      // 7. 压缩并打包
      const compressedData = await Compressor.compress(pixelMap, format, compressTarget, quality);

      if (compressedData.byteLength >= originalSize) {
        const copyTargetPath = LubanEngine.resolveCopyTargetPath(sourcePath, targetPath);
        fileIo.copyFileSync(sourcePath, copyTargetPath);
        const copiedSize = fileIo.statSync(copyTargetPath).size;
        const copiedResult: CompressResult = {
          success: true,
          sourcePath: sourcePath,
          filePath: copyTargetPath,
          originalSize: originalSize,
          compressedSize: copiedSize
        };
        return copiedResult;
      }

      // 8. 写入目标文件
      const targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      targetFd = targetFile.fd;
      const writeLen = fileIo.writeSync(targetFd, compressedData);

      const result: CompressResult = {
        success: true,
        sourcePath: sourcePath,
        filePath: targetPath,
        originalSize: originalSize,
        compressedSize: writeLen
      };
      return result;

    } catch (error) {
      const err = error as Error;
      LogUtil.error(LubanEngine.TAG, `压缩失败: ${err.message}`);
      const result: CompressResult = {
        success: false,
        sourcePath: sourcePath,
        error: err
      };
      return result;
    } finally {
      if (targetFd !== undefined) {
        try {
          fileIo.closeSync(targetFd);
        } catch (closeError) {
          LogUtil.warn(LubanEngine.TAG, `关闭目标文件失败: ${(closeError as Error).message}`);
        }
      }

      if (pixelMap !== undefined) {
        try {
          pixelMap.release();
        } catch (releaseError) {
          LogUtil.warn(LubanEngine.TAG, `释放 PixelMap 失败: ${(releaseError as Error).message}`);
        }
      }

      if (imageSource !== undefined) {
        try {
          await imageSource.release();
        } catch (releaseError) {
          LogUtil.warn(LubanEngine.TAG, `释放 ImageSource 失败: ${(releaseError as Error).message}`);
        }
      }

      if (sourceFd !== undefined) {
        try {
          fileIo.closeSync(sourceFd);
        } catch (closeError) {
          LogUtil.warn(LubanEngine.TAG, `关闭源文件失败: ${(closeError as Error).message}`);
        }
      }
    }
  }

  /**
   * 判断是否需要压缩
   * @param fileSize 文件大小（字节）
   * @param width 宽度
   * @param height 高度
   * @returns 是否需要压缩
   */
  private static needCompress(fileSize: number, width: number, height: number, ignoreBy: number = 100): boolean {
    // 小于 100KB 的图片不压缩
    if (fileSize < ignoreBy * 1024) {
      return false;
    }

    // 像素小于 32万的图片不压缩
    if (width * height < 320000) {
      return false;
    }

    return true;
  }

  static getCompressFormat(sourcePath: string, focusAlpha: boolean): string {
    const extension = LubanUtils.getFileExtension(sourcePath);

    if (focusAlpha && (extension === 'png' || extension === 'webp')) {
      return extension === 'webp' ? CompressFormat.WEBP : CompressFormat.PNG;
    }

    return CompressFormat.JPEG;
  }

  static getOutputExtension(sourcePath: string, focusAlpha: boolean): string {
    return LubanUtils.getExtensionByMime(LubanEngine.getCompressFormat(sourcePath, focusAlpha));
  }

  private static resolveCopyTargetPath(sourcePath: string, targetPath: string): string {
    const sourceExtension = LubanUtils.getFileExtension(sourcePath);
    if (!sourceExtension) {
      return targetPath;
    }

    const targetExtension = LubanUtils.getFileExtension(targetPath);
    if (targetExtension === sourceExtension) {
      return targetPath;
    }

    return LubanUtils.replaceFileExtension(targetPath, sourceExtension);
  }

  /**
   * 生成压缩后的文件名
   * @param originalPath 原文件路径
   * @param targetDir 目标目录
   * @param customName 自定义名称
   * @returns 目标文件路径
   */
  static generateCompressedFileName(
    originalPath: string,
    targetDir: string,
    customName?: string
  ): string {
    if (customName) {
      return `${targetDir}/${customName}`;
    }

    const extension = LubanEngine.getOutputExtension(originalPath, false);
    const fileName = LubanUtils.generateOutputFileName(originalPath, extension);
    return `${targetDir}/${fileName}`;
  }
} 
