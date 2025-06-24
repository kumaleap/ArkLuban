/**
 * Luban 工具类
 * 提供文件检查、格式判断等实用功能
 */

import { fileIo } from '@kit.CoreFileKit';
import { FilterCollection, CompressionPredicate } from './LubanTypes';

/**
 * 只压缩图片文件的过滤器
 */
export class ImagesOnlyFilter implements CompressionPredicate {
  apply(path: string): boolean {
    return LubanUtils.isImage(path);
  }
}

/**
 * 排除 GIF 文件的过滤器
 */
export class ExcludeGifFilter implements CompressionPredicate {
  apply(path: string): boolean {
    const extension = LubanUtils.getFileExtension(path);
    return LubanUtils.isImage(path) && extension !== 'gif';
  }
}

/**
 * 只压缩大于指定大小文件的过滤器
 */
export class MinSizeFilter implements CompressionPredicate {
  private minSizeKB: number;

  constructor(minSizeKB: number) {
    this.minSizeKB = minSizeKB;
  }

  apply(path: string): boolean {
    const sizeKB = LubanUtils.getFileSizeInKB(path);
    return sizeKB > this.minSizeKB;
  }
}

/**
 * 默认组合过滤器：排除 GIF 且大于指定大小
 */
export class DefaultFilter implements CompressionPredicate {
  private minSizeKB: number;

  constructor(minSizeKB: number) {
    this.minSizeKB = minSizeKB;
  }

  apply(path: string): boolean {
    return new ExcludeGifFilter().apply(path) &&
    new MinSizeFilter(this.minSizeKB).apply(path);
  }
}

/**
 * Luban 工具类
 */
export class LubanUtils {
  /**
   * 支持的图片格式
   */
  private static readonly SUPPORTED_FORMATS = [
    'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'
  ];

  /**
   * 检查文件是否为支持的图片格式
   * @param filePath 文件路径
   * @returns 是否为支持的图片格式
   */
  static isImage(filePath: string): boolean {
    if (!filePath) {
      return false;
    }

    const extension = LubanUtils.getFileExtension(filePath);
    return LubanUtils.SUPPORTED_FORMATS.includes(extension);
  }

  /**
   * 获取文件扩展名
   * @param filePath 文件路径
   * @returns 文件扩展名（小写）
   */
  static getFileExtension(filePath: string): string {
    const fileName = filePath.split('/').pop() || '';
    const dotIndex = fileName.lastIndexOf('.');

    if (dotIndex === -1 || dotIndex === fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  /**
   * 获取文件名（不包含扩展名）
   * @param filePath 文件路径
   * @returns 文件名
   */
  static getFileNameWithoutExtension(filePath: string): string {
    const fileName = filePath.split('/').pop() || '';
    const dotIndex = fileName.lastIndexOf('.');

    if (dotIndex === -1) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

  /**
   * 获取文件大小（KB）
   * @param filePath 文件路径
   * @returns 文件大小（KB）
   */
  static getFileSizeInKB(filePath: string): number {
    try {
      const size = fileIo.statSync(filePath).size;
      return Math.round(size / 1024);
    } catch (error) {
      console.error('获取文件大小失败:', error);
      return 0;
    }
  }

  /**
   * 格式化文件大小
   * @param sizeInBytes 文件大小（字节）
   * @returns 格式化后的文件大小字符串
   */
  static formatFileSize(sizeInBytes: number): string {
    if (sizeInBytes < 1024) {
      return `${sizeInBytes} B`;
    } else if (sizeInBytes < 1024 * 1024) {
      return `${Math.round(sizeInBytes / 1024)} KB`;
    } else {
      return `${Math.round(sizeInBytes / (1024 * 1024) * 100) / 100} MB`;
    }
  }

  /**
   * 检查文件是否存在
   * @param filePath 文件路径
   * @returns 文件是否存在
   */
  static fileExists(filePath: string): boolean {
    try {
      return fileIo.accessSync(filePath);
    } catch (error) {
      return false;
    }
  }

  /**
   * 确保目录存在
   * @param dirPath 目录路径
   * @returns 是否成功创建或已存在
   */
  static ensureDirectoryExists(dirPath: string): boolean {
    try {
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath, true);
      }
      return true;
    } catch (error) {
      console.error('创建目录失败:', error);
      return false;
    }
  }

  /**
   * 删除文件
   * @param filePath 文件路径
   * @returns 是否删除成功
   */
  static deleteFile(filePath: string): boolean {
    try {
      if (fileIo.accessSync(filePath)) {
        fileIo.unlinkSync(filePath);
        return true;
      }
      return false;
    } catch (error) {
      console.error('删除文件失败:', error);
      return false;
    }
  }

  /**
   * 获取默认的压缩输出目录
   * @returns 默认输出目录路径
   */
  static getDefaultOutputDir(): string {
    try {
      const context = getContext();
      return context.cacheDir + '/luban_compressed';
    } catch (error) {
      console.error('获取默认输出目录失败:', error);
      return '/data/storage/el2/base/cache/luban_compressed';
    }
  }

  /**
   * 生成唯一的文件名
   * @param originalPath 原文件路径
   * @param prefix 前缀（可选）
   * @returns 唯一的文件名
   */
  static generateUniqueFileName(originalPath: string, prefix: string = 'luban'): string {
    const nameWithoutExt = LubanUtils.getFileNameWithoutExtension(originalPath);
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000);

    return `${prefix}_${nameWithoutExt}_${timestamp}_${random}.jpg`;
  }

  /**
   * 计算压缩比
   * @param originalSize 原文件大小
   * @param compressedSize 压缩后文件大小
   * @returns 压缩比百分比
   */
  static calculateCompressionRatio(originalSize: number, compressedSize: number): number {
    if (originalSize === 0) {
      return 0;
    }

    const ratio = ((originalSize - compressedSize) / originalSize) * 100;
    return Math.round(ratio * 100) / 100;
  }

  /**
   * 预设的压缩过滤器
   */
  static readonly FILTERS: FilterCollection = {
    /**
     * 只压缩图片文件
     */
    IMAGES_ONLY: new ImagesOnlyFilter(),

    /**
     * 排除 GIF 文件
     */
    EXCLUDE_GIF: new ExcludeGifFilter(),

    /**
     * 只压缩大于指定大小的文件
     * @param minSizeKB 最小文件大小（KB）
     */
    MIN_SIZE: (minSizeKB: number): CompressionPredicate => {
      return new MinSizeFilter(minSizeKB);
    },

    /**
     * 组合过滤器：只压缩图片且排除 GIF 且大于指定大小
     * @param minSizeKB 最小文件大小（KB）
     */
    DEFAULT: (minSizeKB: number = 100): CompressionPredicate => {
      return new DefaultFilter(minSizeKB);
    }
  };
}