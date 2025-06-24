/**
 * Luban 压缩引擎核心实现
 * 基于微信朋友圈压缩算法的鸿蒙版本
 */

import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { CompressFormat, CompressResult, ImageSize } from './LubanTypes';

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
    focusAlpha: boolean = false
  ): Promise<CompressResult> {
    try {
      // 1. 读取原图信息
      const originalSize = fileIo.statSync(sourcePath).size;
      const sourceFile = fileIo.openSync(sourcePath, fileIo.OpenMode.READ_ONLY);

      // 2. 创建图片源
      const imageSource = image.createImageSource(sourceFile.fd);
      const imageInfo = await imageSource.getImageInfo();

      // 3. 计算压缩后的尺寸
      const compressSize = LubanEngine.computeSize(imageInfo.size.width, imageInfo.size.height);

      // 4. 判断是否需要压缩
      if (!LubanEngine.needCompress(originalSize, compressSize.width, compressSize.height)) {
        // 不需要压缩，直接复制文件
        fileIo.copyFileSync(sourcePath, targetPath);

        const result: CompressResult = {
          success: true,
          filePath: targetPath,
          originalSize: originalSize,
          compressedSize: originalSize
        };
        return result;
      }

      // 5. 创建解码选项
      const decodingOptions: image.DecodingOptions = {
        desiredSize: {
          width: compressSize.width,
          height: compressSize.height
        },
        desiredRegion: {
          x: 0,
          y: 0,
          size: {
            width: imageInfo.size.width,
            height: imageInfo.size.height
          }
        },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };

      // 6. 解码图片
      const pixelMap = await imageSource.createPixelMap(decodingOptions);

      // 7. 创建图片打包器
      const imagePackerApi = image.createImagePacker();

      // 8. 设置打包选项
      const format = LubanEngine.getCompressFormat(sourcePath, focusAlpha);
      const quality = LubanEngine.computeQuality(originalSize);

      const packOpts: image.PackingOption = {
        format: format,
        quality: quality
      };

      // 9. 压缩并打包
      const compressedData = await imagePackerApi.packing(pixelMap, packOpts);

      // 10. 写入目标文件
      const targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      const writeLen = fileIo.writeSync(targetFile.fd, compressedData);
      fileIo.closeSync(targetFile.fd);
      fileIo.closeSync(sourceFile.fd);

      // 11. 释放资源
      pixelMap.release();
      imagePackerApi.release();

      const result: CompressResult = {
        success: true,
        filePath: targetPath,
        originalSize: originalSize,
        compressedSize: writeLen
      };
      return result;

    } catch (error) {
      console.error(LubanEngine.TAG, `压缩失败: ${error.message}`);
      const result: CompressResult = {
        success: false,
        error: error as Error
      };
      return result;
    }
  }

  /**
   * 计算压缩后的尺寸（仿微信算法）
   * @param srcWidth 原图宽度
   * @param srcHeight 原图高度
   * @returns 压缩后的尺寸
   */
  private static computeSize(srcWidth: number, srcHeight: number): ImageSize {
    let width = srcWidth;
    let height = srcHeight;

    // 1. 判断图片比例，按照微信的压缩策略
    const ratio = width / height;

    if (ratio <= 1 && ratio > 0.5625) {
      // 1:1 到 16:9 之间
      if (width < 1664) {
        if (width < 1280 && width > 720) {
          width = 720;
          height = width / ratio;
        } else if (width <= 720) {
          // 保持原尺寸
        } else {
          width = 1280;
          height = width / ratio;
        }
      } else {
        width = 1664;
        height = width / ratio;
      }
    } else if (ratio <= 0.5625 && ratio > 0.5) {
      // 9:16 到 1:2 之间
      height = 1664;
      width = height * ratio;
    } else if (ratio <= 0.5) {
      // 长图
      height = 1280;
      width = height * ratio;
    } else {
      // 宽图
      if (width < 1280) {
        // 保持原尺寸
      } else {
        width = 1280;
        height = width / ratio;
      }
    }

    const result: ImageSize = {
      width: Math.floor(width),
      height: Math.floor(height)
    };
    return result;
  }

  /**
   * 判断是否需要压缩
   * @param fileSize 文件大小（字节）
   * @param width 宽度
   * @param height 高度
   * @returns 是否需要压缩
   */
  private static needCompress(fileSize: number, width: number, height: number): boolean {
    // 小于 100KB 的图片不压缩
    if (fileSize < 100 * 1024) {
      return false;
    }

    // 像素小于 32万的图片不压缩
    if (width * height < 320000) {
      return false;
    }

    return true;
  }

  /**
   * 计算压缩质量
   * @param fileSize 文件大小（字节）
   * @returns 压缩质量 (0-100)
   */
  private static computeQuality(fileSize: number): number {
    const fileSizeKB = fileSize / 1024;

    if (fileSizeKB < 150) {
      return 85;
    } else if (fileSizeKB < 300) {
      return 80;
    } else if (fileSizeKB < 500) {
      return 75;
    } else if (fileSizeKB < 1000) {
      return 70;
    } else if (fileSizeKB < 2000) {
      return 65;
    } else {
      return 60;
    }
  }

  /**
   * 获取压缩格式
   * @param sourcePath 源文件路径
   * @param focusAlpha 是否保留透明通道
   * @returns 压缩格式
   */
  private static getCompressFormat(sourcePath: string, focusAlpha: boolean): string {
    const extension = sourcePath.toLowerCase().split('.').pop() || '';

    if (focusAlpha && (extension === 'png' || extension === 'webp')) {
      return extension === 'webp' ? CompressFormat.WEBP : CompressFormat.PNG;
    }

    return CompressFormat.JPEG;
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

    const fileName = originalPath.split('/').pop() || 'compressed';
    const nameWithoutExt = fileName.split('.')[0];
    const timestamp = Date.now();

    return `${targetDir}/${nameWithoutExt}_luban_${timestamp}.jpg`;
  }
} 