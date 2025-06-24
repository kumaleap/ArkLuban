/**
 * Luban 图片压缩主类
 * 提供链式调用 API，仿照 Android 版本的使用方式
 */

import { fileIo } from '@kit.CoreFileKit';
import { LubanEngine } from './LubanEngine';
import {
  CompressionPredicate,
  CompressConfig,
  CompressResult,
  CompressOptions,
  RenameCallback
} from './LubanTypes';

/**
 * Luban 压缩器构建类
 */
export class LubanBuilder {
  private config: CompressConfig;

  constructor(paths: string | string[]) {
    this.config = {
      paths: Array.isArray(paths) ? paths : [paths],
      ignoreBy: 100, // 默认 100KB
      focusAlpha: false, // 默认不保留透明通道
      targetDir: '' // 默认为空，使用系统缓存目录
    };
  }

  /**
   * 设置压缩条件过滤器
   * @param predicate 过滤条件
   * @returns 构建器实例
   */
  filter(predicate: CompressionPredicate): LubanBuilder {
    this.config.filter = predicate;
    return this;
  }

  /**
   * 设置忽略压缩的文件大小阈值
   * @param sizeInKB 文件大小阈值（KB）
   * @returns 构建器实例
   */
  ignoreBy(sizeInKB: number): LubanBuilder {
    this.config.ignoreBy = sizeInKB;
    return this;
  }

  /**
   * 设置是否保留透明通道
   * @param focusAlpha 是否保留透明通道
   * @returns 构建器实例
   */
  setFocusAlpha(focusAlpha: boolean): LubanBuilder {
    this.config.focusAlpha = focusAlpha;
    return this;
  }

  /**
   * 设置目标目录
   * @param targetDir 目标目录路径
   * @returns 构建器实例
   */
  setTargetDir(targetDir: string): LubanBuilder {
    this.config.targetDir = targetDir;
    return this;
  }

  /**
   * 设置压缩开始回调函数
   * @param callback 开始压缩时的回调函数
   * @returns 构建器实例
   */
  setOnStart(callback: () => void): LubanBuilder {
    this.config.onStart = callback;
    return this;
  }

  /**
   * 设置压缩成功回调函数
   * @param callback 压缩成功时的回调函数
   * @returns 构建器实例
   */
  setOnSuccess(callback: (filePath: string) => void): LubanBuilder {
    this.config.onSuccess = callback;
    return this;
  }

  /**
   * 设置压缩错误回调函数
   * @param callback 压缩出错时的回调函数
   * @returns 构建器实例
   */
  setOnError(callback: (error: Error) => void): LubanBuilder {
    this.config.onError = callback;
    return this;
  }

  /**
   * 设置重命名回调函数
   * @param callback 重命名回调函数
   * @returns 构建器实例
   */
  setOnRename(callback: RenameCallback): LubanBuilder {
    this.config.onRename = callback;
    return this;
  }

  // 为新 API 提供更简洁的别名方法
  /**
   * 设置压缩开始回调函数（别名）
   * @param callback 开始压缩时的回调函数
   * @returns 构建器实例
   */
  onStart(callback: () => void): LubanBuilder {
    return this.setOnStart(callback);
  }

  /**
   * 设置压缩成功回调函数（别名）
   * @param callback 压缩成功时的回调函数
   * @returns 构建器实例
   */
  onSuccess(callback: (filePath: string) => void): LubanBuilder {
    return this.setOnSuccess(callback);
  }

  /**
   * 设置压缩错误回调函数（别名）
   * @param callback 压缩出错时的回调函数
   * @returns 构建器实例
   */
  onError(callback: (error: Error) => void): LubanBuilder {
    return this.setOnError(callback);
  }

  /**
   * 设置重命名回调函数（别名）
   * @param callback 重命名回调函数
   * @returns 构建器实例
   */
  onRename(callback: RenameCallback): LubanBuilder {
    return this.setOnRename(callback);
  }

  /**
   * 启动异步压缩
   */
  async launch(): Promise<void> {
    if (this.config.onStart) {
      this.config.onStart();
    }

    try {
      // 确保目标目录存在
      const targetDir = this.getTargetDirectory();
      await this.ensureDirectoryExists(targetDir);

      // 过滤需要压缩的文件
      const filteredPaths = this.filterPaths();

      if (filteredPaths.length === 0) {
        this.config.onError?.(new Error('没有需要压缩的文件'));
        return;
      }

      // 并行压缩多个文件
      const compressTasks = filteredPaths.map(async (path) => {
        return await this.compressSingleFile(path, targetDir);
      });

      const results = await Promise.all(compressTasks);

      // 处理结果
      for (const result of results) {
        if (result.success && result.filePath) {
          this.config.onSuccess?.(result.filePath);
        } else if (result.error) {
          this.config.onError?.(result.error);
        }
      }

    } catch (error) {
      this.config.onError?.(error as Error);
    }
  }

  /**
   * 同步获取压缩结果
   * @returns 压缩后的文件列表
   */
  async get(): Promise<string[]> {
    const targetDir = this.getTargetDirectory();
    await this.ensureDirectoryExists(targetDir);

    const filteredPaths = this.filterPaths();
    const results: string[] = [];

    for (const path of filteredPaths) {
      const result = await this.compressSingleFile(path, targetDir);
      if (result.success && result.filePath) {
        results.push(result.filePath);
      } else if (result.error) {
        throw result.error;
      }
    }

    return results;
  }

  /**
   * 压缩单个文件
   * @param sourcePath 源文件路径
   * @param targetDir 目标目录
   * @returns 压缩结果
   */
  private async compressSingleFile(sourcePath: string, targetDir: string): Promise<CompressResult> {
    try {
      // 检查文件是否存在
      if (!fileIo.accessSync(sourcePath)) {
        throw new Error(`文件不存在: ${sourcePath}`);
      }
      // 检查文件大小是否超过阈值
      const fileSize = fileIo.statSync(sourcePath).size;
      if (fileSize < (this.config.ignoreBy || 100) * 1024) {
        // 文件太小，不需要压缩，直接复制
        const fileName = this.generateFileName(sourcePath);
        const targetPath = `${targetDir}/${fileName}`;
        fileIo.copyFileSync(sourcePath, targetPath);

        const result: CompressResult = {
          success: true,
          filePath: targetPath,
          originalSize: fileSize,
          compressedSize: fileSize
        };
        return result;
      }

      // 生成目标文件路径
      const fileName = this.generateFileName(sourcePath);
      const targetPath = `${targetDir}/${fileName}`;

      // 调用压缩引擎
      return await LubanEngine.compressSingle(
        sourcePath,
        targetPath,
        this.config.focusAlpha || false
      );

    } catch (error) {
      const result: CompressResult = {
        success: false,
        error: error as Error
      };
      return result;
    }
  }

  /**
   * 过滤需要压缩的文件路径
   * @returns 过滤后的文件路径列表
   */
  private filterPaths(): string[] {
    if (!this.config.filter) {
      return this.config.paths;
    }

    return this.config.paths.filter(path => this.config.filter!.apply(path));
  }

  /**
   * 生成文件名
   * @param sourcePath 源文件路径
   * @returns 生成的文件名
   */
  private generateFileName(sourcePath: string): string {
    if (this.config.onRename) {
      return this.config.onRename(sourcePath);
    }

    const fileName = sourcePath.split('/').pop() || 'compressed';
    const nameWithoutExt = fileName.split('.')[0];
    const timestamp = Date.now();

    return `${nameWithoutExt}_luban_${timestamp}.jpg`;
  }

  /**
   * 获取目标目录
   * @returns 目标目录路径
   */
  private getTargetDirectory(): string {
    if (this.config.targetDir) {
      return this.config.targetDir;
    }

    // 使用应用缓存目录
    return getContext().cacheDir + '/luban';
  }

  /**
   * 确保目录存在
   * @param dirPath 目录路径
   */
  private async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath, true);
      }
    } catch (error) {
      console.error('创建目录失败:', error);
      throw new Error(`无法创建目标目录: ${dirPath}`);
    }
  }
}

/**
 * Luban 主类
 */
export class Luban {
  /**
   * 创建 Luban 构建器
   * @param paths 图片路径，可以是单个路径或路径数组
   * @returns Luban 构建器实例
   */
  static with(paths: string | string[]): LubanBuilder {
    return new LubanBuilder(paths);
  }

  /**
   * 快速压缩单张图片
   * @param sourcePath 源图片路径
   * @param targetPath 目标路径（可选）
   * @param options 压缩选项（可选）
   * @returns 压缩结果
   */
  static async compress(
    sourcePath: string,
    targetPath?: string,
    options?: CompressOptions
  ): Promise<CompressResult> {
    const targetDir = targetPath ?
    targetPath.substring(0, targetPath.lastIndexOf('/')) : getContext().cacheDir + '/luban';

    const fileName = targetPath ?
    targetPath.substring(targetPath.lastIndexOf('/') + 1) :
    LubanEngine.generateCompressedFileName(sourcePath, targetDir);

    const finalTargetPath = targetPath || `${targetDir}/${fileName}`;

    // 确保目录存在
    try {
      if (!fileIo.accessSync(targetDir)) {
        fileIo.mkdirSync(targetDir, true);
      }
    } catch (error) {
      const result: CompressResult = {
        success: false,
        error: new Error(`无法创建目标目录: ${targetDir}`)
      };
      return result;
    }

    return await LubanEngine.compressSingle(
      sourcePath,
      finalTargetPath,
      options?.focusAlpha || false
    );
  }
} 