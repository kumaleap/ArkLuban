/**
 * Luban 工具类
 * 提供文件检查、格式判断等实用功能
 */

import { fileIo } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { FilterCollection, CompressionPredicate } from './LubanTypes';

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
   * @deprecated 此方法已废弃，请使用 preprocessImageFile 方法
   * 检测并转换 URI 路径
   * 处理鸿蒙系统中的 file:// URI
   * @param uriOrPath URI 或普通路径
   * @returns 转换后的文件路径
   */
  static resolveFilePath(uriOrPath: string): string {
    console.warn('⚠️ resolveFilePath 方法已废弃，建议使用 preprocessImageFile 方法');
    
    if (!uriOrPath) {
      throw new Error('路径或URI不能为空');
    }

    // 如果不是 URI，直接返回原路径
    if (!LubanUtils.isUri(uriOrPath)) {
      return uriOrPath;
    }

    // 对于 URI，抛出错误提示使用正确的方法
    throw new Error('URI 需要使用 preprocessImageFile 方法进行预处理，不能直接转换路径');
  }

  /**
   * 检查是否为 URI 格式
   * @param path 路径字符串
   * @returns 是否为 URI
   */
  static isUri(path: string): boolean {
    if (!path) {
      return false;
    }
    return path.startsWith('file://') || path.startsWith('content://') || path.startsWith('datashare://');
  }

  /**
   * 检查文件是否为支持的图片格式
   * @param filePath 文件路径或URI
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
   * 获取文件大小（字节）- 支持 URI 和普通路径
   * @param filePath 文件路径或 URI
   * @returns 文件大小（字节）
   */
  static async getFileSizeInBytes(filePath: string): Promise<number> {
    try {
      if (LubanUtils.isUri(filePath)) {
        // 对于 URI，通过 fs.open 获取文件信息
        console.log(`📏 获取 URI 文件大小: ${filePath}`);
        const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
        try {
          const stat = await fs.stat(file.fd);
          return stat.size;
        } finally {
          await fs.close(file.fd);
        }
      } else {
        // 对于普通路径，直接使用 fileIo.statSync
        const size = fileIo.statSync(filePath).size;
        return size;
      }
    } catch (error) {
      console.error('获取文件大小失败:', error);
      return 0;
    }
  }

  /**
   * 获取文件大小（KB）- 支持 URI 和普通路径
   * @param filePath 文件路径或 URI
   * @returns 文件大小（KB）
   */
  static async getFileSizeInKB(filePath: string): Promise<number> {
    const sizeInBytes = await LubanUtils.getFileSizeInBytes(filePath);
    return Math.round(sizeInBytes / 1024);
  }

  /**
   * 获取文件大小（KB）- 同步版本，只支持普通文件路径，不支持 URI
   * @deprecated 建议使用异步版本 getFileSizeInKB
   * @param filePath 文件路径（不支持 URI）
   * @returns 文件大小（KB）
   */
  static getFileSizeInKBSync(filePath: string): number {
    try {
      // 检查是否为 URI
      if (LubanUtils.isUri(filePath)) {
        console.error('❌ getFileSizeInKBSync 不支持 URI，请使用异步版本 getFileSizeInKB');
        return 0;
      }

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
   * 注意：此方法只支持普通文件路径，不支持 URI
   * @param filePath 文件路径（不支持 URI）
   * @returns 文件是否存在
   */
  static fileExists(filePath: string): boolean {
    try {
      // 检查是否为 URI
      if (LubanUtils.isUri(filePath)) {
        console.error('❌ fileExists 不支持 URI，请先使用 preprocessImageFile 预处理');
        return false;
      }

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
   * @returns 默认输出目录路径（filesDir/luban/）
   */
  static getDefaultOutputDir(): string {
    try {
      const context = getContext();
      const outputDir = context.getApplicationContext().filesDir + '/luban';
      
      // 确保目录存在
      if (!fileIo.accessSync(outputDir)) {
        fileIo.mkdirSync(outputDir, true);
      }
      
      return outputDir;
    } catch (error) {
      console.error('获取默认输出目录失败:', error);
      return '/data/storage/el2/base/files/luban';
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
    IMAGES_ONLY: (path: string): boolean => {
      return LubanUtils.isImage(path);
    },

    /**
     * 排除 GIF 文件
     */
    EXCLUDE_GIF: (path: string): boolean => {
      const extension = LubanUtils.getFileExtension(path);
      return LubanUtils.isImage(path) && extension !== 'gif';
    },

    /**
     * 只压缩大于指定大小的文件
     * @param minSizeKB 最小文件大小（KB）
     */
    MIN_SIZE: (minSizeKB: number): CompressionPredicate => {
      return (path: string): boolean => {
        const sizeKB = LubanUtils.getFileSizeInKBSync(path);
        return sizeKB > minSizeKB;
      };
    },

    /**
     * 组合过滤器：只压缩图片且排除 GIF 且大于指定大小
     * @param minSizeKB 最小文件大小（KB）
     */
    DEFAULT: (minSizeKB: number = 100): CompressionPredicate => {
      return (path: string): boolean => {
        return LubanUtils.FILTERS.EXCLUDE_GIF(path) &&
          LubanUtils.FILTERS.MIN_SIZE(minSizeKB)(path);
      };
    }
  };

    /**
   * 获取临时目录下的文件夹路径或文件路径
   * @param dirPath 文件路径；支持完整路径和相对路径（download/wps/doc）；dirPath传空字符串表示根目录
   * @param fileName 文件名（test.text）；fileName传空字符串表示文件夹路径
   * @param blHap true：HAP级别文件路径、 false：App级别文件路径
   * @returns 临时目录路径
   */
  static getTempDirPath(dirPath: string = "", fileName: string = "", blHap: boolean = true): string {
    try {
      const context = getContext();
      let filePath = blHap ? context.tempDir : context.getApplicationContext().tempDir; // 根目录

      if (dirPath && dirPath.trim() !== "") {
        if (LubanUtils.hasDirPath(dirPath)) { 
          // 路径中包含根目录，是完整路径
          filePath = dirPath;
        } else { 
          // 路径中不包含根目录，拼接成完整路径
          filePath = filePath + LubanUtils.separator + dirPath;
        }
        
        if (!fileIo.accessSync(filePath)) {
          fileIo.mkdirSync(filePath, true); // 如果文件夹不存在就创建
        }
      }
      
      if (fileName && fileName.trim() !== "") {
        filePath = filePath + LubanUtils.separator + fileName;
      }
      
      return filePath;
    } catch (error) {
      console.error('获取临时目录路径失败:', error);
      throw new Error(`获取临时目录失败: ${error}`);
    }
  }

  /**
   * 获取缓存目录下的文件夹路径或文件路径（保留用于缓存清理等功能）
   * @param dirPath 文件路径；支持完整路径和相对路径（download/wps/doc）；dirPath传空字符串表示根目录
   * @param fileName 文件名（test.text）；fileName传空字符串表示文件夹路径
   * @param blHap true：HAP级别文件路径、 false：App级别文件路径
   * @returns 缓存目录路径
   */
  static getCacheDirPath(dirPath: string = "", fileName: string = "", blHap: boolean = true): string {
    try {
      const context = getContext();
      let filePath = blHap ? context.cacheDir : context.getApplicationContext().cacheDir; // 根目录

      if (dirPath && dirPath.trim() !== "") {
        if (LubanUtils.hasDirPath(dirPath)) { 
          // 路径中包含根目录，是完整路径
          filePath = dirPath;
        } else { 
          // 路径中不包含根目录，拼接成完整路径
          filePath = filePath + LubanUtils.separator + dirPath;
        }
        
        if (!fileIo.accessSync(filePath)) {
          fileIo.mkdirSync(filePath, true); // 如果文件夹不存在就创建
        }
      }
      
      if (fileName && fileName.trim() !== "") {
        filePath = filePath + LubanUtils.separator + fileName;
      }
      
      return filePath;
    } catch (error) {
      console.error('获取缓存目录路径失败:', error);
      throw new Error(`获取缓存目录失败: ${error}`);
    }
  }

  /**
   * 检查路径是否包含目录路径（是否为绝对路径）
   * @param path 路径字符串
   * @returns 是否包含目录路径
   */
  private static hasDirPath(path: string): boolean {
    return path.startsWith('/') || path.includes('://');
  }

  /**
   * 文件路径分隔符
   */
  private static readonly separator = '/';

  /**
   * 将受权限限制的文件复制到应用临时目录
   * 解决从相册选择图片权限有限的问题
   * @param srcFileUri 源文件 URI（如相册图片的 file:// URI）
   * @param targetDir 目标目录（可选，默认为 luban）
   * @returns 复制后的文件路径
   */
  static async copyToTemp(srcFileUri: string, targetDir: string = "luban"): Promise<string> {
    try {
      console.log('📋 开始复制文件到临时目录...');
      console.log(`🔗 源文件URI: ${srcFileUri}`);

      // 生成目标文件路径
      const fileName = LubanUtils.generateTempFileName(srcFileUri);
      const tempFilePath = LubanUtils.getTempDirPath(targetDir, fileName);
      console.log(`🎯 目标文件路径: ${tempFilePath}`);

      // 打开源文件（只读）- 直接使用 URI
      console.log('🔓 打开源文件（使用URI）...');
      const srcFile = await fs.open(srcFileUri, fs.OpenMode.READ_ONLY);

      // 创建目标文件（读写+创建）
      console.log('📝 创建目标文件...');
      const mode: number = fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE;
      const destFile = await fs.open(tempFilePath, mode);

      try {
        // 复制文件内容
        console.log('📋 正在复制文件内容...');
        await fs.copyFile(srcFile.fd, destFile.fd);
        console.log('✅ 文件复制成功!');

        return tempFilePath;
      } finally {
        // 确保关闭文件描述符
        try {
          await fs.close(srcFile.fd);
          await fs.close(destFile.fd);
          console.log('🔒 文件描述符已关闭');
        } catch (closeError) {
          console.warn('⚠️ 关闭文件描述符时出现警告:', closeError);
        }
      }
    } catch (error) {
      console.error('❌ 复制文件到临时目录失败:', error);
      throw new Error(`复制文件到临时目录失败: ${error}`);
    }
  }

  /**
   * @deprecated 请使用 copyToTemp 方法
   * 将受权限限制的文件复制到应用缓存目录
   */
  static async copyToCache(srcFileUri: string, targetDir: string = "luban_temp"): Promise<string> {
    console.warn('⚠️ copyToCache 方法已废弃，请使用 copyToTemp 方法');
    return await LubanUtils.copyToTemp(srcFileUri, targetDir);
  }

  /**
   * 生成临时文件名
   * @param originalPath 原文件路径
   * @returns 生成的临时文件名
   */
  private static generateTempFileName(originalPath: string): string {
    const extension = LubanUtils.getFileExtension(originalPath);
    const nameWithoutExt = LubanUtils.getFileNameWithoutExtension(originalPath);
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000);

    return `temp_${nameWithoutExt}_${timestamp}_${random}.${extension}`;
  }

  /**
   * 预处理图片文件路径
   * 对于 URI，直接复制到临时目录；对于普通路径，直接返回
   * @param filePath 原文件路径或 URI
   * @returns 处理后的可访问文件路径
   */
  static async preprocessImageFile(filePath: string): Promise<string> {
    try {
      console.log(`🔧 预处理图片文件: ${filePath}`);

      // 如果不是 URI，直接返回
      if (!LubanUtils.isUri(filePath)) {
        console.log('📁 普通路径，直接返回');
        return filePath;
      }

      // 对于 URI，直接复制到临时目录
      console.log('🔗 检测到 URI，复制到临时目录...');
      const tempFilePath = await LubanUtils.copyToTemp(filePath);
      console.log(`✅ 已复制到临时目录: ${tempFilePath}`);
      return tempFilePath;
    } catch (error) {
      console.error('❌ 预处理图片文件失败:', error);
      throw new Error(`预处理图片文件失败: ${error}`);
    }
  }

  /**
   * 清理临时缓存文件（同时清理临时目录和缓存目录）
   * @param tempDir 临时目录名（默认为 luban）
   * @param cacheDir 缓存目录名（默认为 luban_temp，兼容旧版本）
   * @returns 清理的文件数量
   */
  static cleanTempCache(tempDir: string = "luban", cacheDir: string = "luban_temp"): number {
    try {
      let totalCleanedCount = 0;

      // 清理临时目录（新版本使用的目录）
      const tempDirPath = LubanUtils.getTempDirPath(tempDir);
      console.log(`🧹 清理临时目录: ${tempDirPath}`);

      if (fileIo.accessSync(tempDirPath)) {
        const tempFiles = fileIo.listFileSync(tempDirPath);
        for (const fileName of tempFiles) {
          try {
            const filePath = tempDirPath + LubanUtils.separator + fileName;
            if (fileIo.statSync(filePath).isFile()) {
              fileIo.unlinkSync(filePath);
              totalCleanedCount++;
              console.log(`🗑️ 删除临时文件: ${fileName}`);
            }
          } catch (error) {
            console.warn(`⚠️ 清理临时文件失败: ${fileName}`, error);
          }
        }
      } else {
        console.log('📁 临时目录不存在，无需清理');
      }

      // 清理缓存目录（兼容旧版本）
      const cacheDirPath = LubanUtils.getCacheDirPath(cacheDir);
      console.log(`🧹 清理缓存目录: ${cacheDirPath}`);

      if (fileIo.accessSync(cacheDirPath)) {
        const cacheFiles = fileIo.listFileSync(cacheDirPath);
        for (const fileName of cacheFiles) {
          try {
            const filePath = cacheDirPath + LubanUtils.separator + fileName;
            if (fileIo.statSync(filePath).isFile()) {
              fileIo.unlinkSync(filePath);
              totalCleanedCount++;
              console.log(`🗑️ 删除缓存文件: ${fileName}`);
            }
          } catch (error) {
            console.warn(`⚠️ 清理缓存文件失败: ${fileName}`, error);
          }
        }
      } else {
        console.log('📁 缓存目录不存在，无需清理');
      }

      console.log(`🧹 清理完成，总共删除了 ${totalCleanedCount} 个文件`);
      return totalCleanedCount;
    } catch (error) {
      console.error('❌ 清理临时缓存失败:', error);
      return 0;
    }
  }

  /**
   * 测试 URI 处理功能
   * @param uriOrPath 要测试的 URI 或路径
   * @returns 测试结果信息
   */
  static testUriHandling(uriOrPath: string): string {
    try {
      console.log(`🧪 测试URI处理: ${uriOrPath}`);

      const isUri = LubanUtils.isUri(uriOrPath);
      console.log(`📋 是否为URI: ${isUri}`);

      if (isUri) {
        console.log(`🔗 检测到 URI，需要使用 preprocessImageFile 进行预处理`);
        
        const isImage = LubanUtils.isImage(uriOrPath);
        console.log(`🖼️ 是否为图片: ${isImage}`);
        
        return `URI测试完成 - 原始: ${uriOrPath}, 类型: URI, 是否为图片: ${isImage}`;
      } else {
        // 普通路径的处理
        const exists = LubanUtils.fileExists(uriOrPath);
        console.log(`📂 文件是否存在: ${exists}`);

        if (exists) {
          const sizeKB = LubanUtils.getFileSizeInKBSync(uriOrPath);
          console.log(`📏 文件大小: ${sizeKB} KB`);

          const isImage = LubanUtils.isImage(uriOrPath);
          console.log(`🖼️ 是否为图片: ${isImage}`);
        }

        return `路径测试完成 - 原始: ${uriOrPath}, 类型: 普通路径, 存在: ${exists}`;
      }
    } catch (error) {
      const errorMsg = `URI处理测试失败: ${error}`;
      console.error(errorMsg);
      return errorMsg;
    }
  }
}