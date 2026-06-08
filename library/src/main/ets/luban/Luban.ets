/**
 * Luban 图片压缩主类
 * 提供链式调用 API，仿照 Android 版本的使用方式
 */

import { fileIo } from '@kit.CoreFileKit';
import { LubanEngine } from './LubanEngine';
import { LubanUtils } from './LubanUtils';
import {
  CompressionPredicate,
  CompressConfig,
  CompressResult,
  CompressOptions,
  CompressSettledResult,
  RenameCallback
} from './LubanTypes';
import { LogUtil } from './LogUtil';

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
      targetDir: '', // 默认为空，使用系统缓存目录
      maxConcurrency: 3
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
   * 设置 JPEG 压缩质量，建议 5-95。值越高越清晰，文件也越大。
   * @param quality JPEG 质量
   * @returns 构建器实例
   */
  setQuality(quality: number): LubanBuilder {
    this.config.quality = quality;
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
   * 设置批量压缩最大并发数
   * @param count 并发数量，最小为 1
   * @returns 构建器实例
   */
  setMaxConcurrency(count: number): LubanBuilder {
    this.config.maxConcurrency = Math.max(1, Math.floor(count));
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

      const results = await this.compressWithConcurrency(filteredPaths, targetDir);

      // 处理结果
      for (const result of results) {
        if (result.status === "fulfilled" && result.value?.success && result.value.filePath) {
          this.config.onSuccess?.(result.value.filePath);
        } else if (result.status === "rejected") {
          this.config.onError?.(result.reason || new Error('压缩失败'));
        } else if (result.status === "fulfilled" && result.value?.error) {
          this.config.onError?.(result.value.error);
        }
      }

    } catch (error) {
      // 只有在整体流程出现问题时才调用 onError
      LogUtil.error('压缩流程出现严重错误:', error);
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
    const settledResults = await this.compressWithConcurrency(filteredPaths, targetDir);
    const results: string[] = [];

    for (const settledResult of settledResults) {
      if (settledResult.status === 'rejected') {
        throw settledResult.reason || new Error('压缩失败');
      }

      const value = settledResult.value;
      if (value?.success && value.filePath) {
        results.push(value.filePath);
      } else if (value?.error) {
        throw value.error;
      }
    }

    return results;
  }

  /**
   * 获取完整压缩结果，保留每个文件的成功或失败状态。
   */
  async getResults(): Promise<CompressResult[]> {
    const targetDir = this.getTargetDirectory();
    await this.ensureDirectoryExists(targetDir);

    const filteredPaths = this.filterPaths();
    const settledResults = await this.compressWithConcurrency(filteredPaths, targetDir);

    return settledResults.map((settledResult: CompressSettledResult, index: number): CompressResult => {
      if (settledResult.status === 'fulfilled' && settledResult.value !== undefined) {
        return settledResult.value;
      }

      return {
        success: false,
        sourcePath: filteredPaths[index],
        error: settledResult.reason || new Error('压缩失败')
      };
    });
  }

  /**
   * 压缩单个文件
   * @param sourcePath 源文件路径
   * @param targetDir 目标目录
   * @returns 压缩结果
   */
  private async compressSingleFile(sourcePath: string, targetDir: string): Promise<CompressResult> {
    let processedSourcePath = sourcePath;
    let shouldCleanTemp = false;

    try {
      // 预处理图片文件（处理 URI 权限问题）
      const preprocessed = await LubanUtils.preprocessImageFileWithCleanup(sourcePath);
      processedSourcePath = preprocessed.path;
      shouldCleanTemp = preprocessed.shouldClean;
      LogUtil.debug(`🔧 压缩单文件 - 预处理: ${sourcePath} -> ${processedSourcePath}`);
      
      // 检查文件是否存在
      if (!fileIo.accessSync(processedSourcePath)) {
        throw new Error(`文件不存在: ${processedSourcePath}`);
      }
      // 检查文件大小是否超过阈值
      const fileSize = fileIo.statSync(processedSourcePath).size;
      if (fileSize < (this.config.ignoreBy || 100) * 1024) {
        // 文件太小，不需要压缩，直接复制
        const fileName = this.generateCopyFileName(sourcePath);
        const targetPath = `${targetDir}/${fileName}`;
        fileIo.copyFileSync(processedSourcePath, targetPath);

        const result: CompressResult = {
          success: true,
          sourcePath: sourcePath,
          filePath: targetPath,
          originalSize: fileSize,
          compressedSize: fileSize
        };
        return result;
      }

      // 生成目标文件路径
      const fileName = this.generateCompressedFileName(sourcePath);
      const targetPath = `${targetDir}/${fileName}`;

      // 调用压缩引擎（传入预处理后的路径）
      const result = await LubanEngine.compressSingle(
        processedSourcePath,
        targetPath,
        this.config.focusAlpha || false,
        this.config.ignoreBy || 100,
        this.config.quality
      );
      result.sourcePath = sourcePath;
      return result;

    } catch (error) {
      const result: CompressResult = {
        success: false,
        sourcePath: sourcePath,
        error: error as Error
      };
      return result;
    } finally {
      if (shouldCleanTemp) {
        LubanUtils.deleteFile(processedSourcePath);
      }
    }
  }

  private async compressWithConcurrency(paths: string[], targetDir: string): Promise<CompressSettledResult[]> {
    const maxConcurrency = Math.max(1, this.config.maxConcurrency || 3);
    const results: CompressSettledResult[] = new Array(paths.length);
    let nextIndex = 0;

    const worker = async (): Promise<void> => {
      while (nextIndex < paths.length) {
        const currentIndex = nextIndex;
        nextIndex++;

        try {
          const value = await this.compressSingleFile(paths[currentIndex], targetDir);
          results[currentIndex] = {
            status: 'fulfilled',
            value: value
          };
        } catch (error) {
          results[currentIndex] = {
            status: 'rejected',
            reason: error
          };
        }
      }
    };

    const workerCount = Math.min(maxConcurrency, paths.length);
    const workers: Promise<void>[] = [];
    for (let index = 0; index < workerCount; index++) {
      workers.push(worker());
    }

    await Promise.all(workers);
    return results;
  }

  /**
   * 过滤需要压缩的文件路径
   * @returns 过滤后的文件路径列表
   */
  private filterPaths(): string[] {
    if (!this.config.filter) {
      return this.config.paths;
    }

    return this.config.paths.filter(path => this.config.filter!(path));
  }

  /**
   * 生成文件名
   * @param sourcePath 源文件路径
   * @returns 生成的文件名
   */
  private generateCompressedFileName(sourcePath: string): string {
    if (this.config.onRename) {
      return this.config.onRename(sourcePath);
    }

    const extension = LubanEngine.getOutputExtension(sourcePath, this.config.focusAlpha || false);
    return LubanUtils.generateOutputFileName(sourcePath, extension);
  }

  private generateCopyFileName(sourcePath: string): string {
    if (this.config.onRename) {
      return this.config.onRename(sourcePath);
    }

    const extension = LubanUtils.getFileExtension(sourcePath) || 'jpg';
    return LubanUtils.generateOutputFileName(sourcePath, extension);
  }

  /**
   * 获取目标目录
   * @returns 目标目录路径
   */
  private getTargetDirectory(): string {
    if (this.config.targetDir) {
      return this.config.targetDir;
    }

    // 使用默认输出目录（filesDir/luban/）
    return LubanUtils.getDefaultOutputDir();
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
      LogUtil.error('创建目录失败:', error);
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
    let processedSourcePath = sourcePath;
    let shouldCleanTemp = false;

    const slashIndex = targetPath ? targetPath.lastIndexOf('/') : -1;
    const targetDir = targetPath && slashIndex > 0 ?
    targetPath.substring(0, slashIndex) : LubanUtils.getCacheDirPath('luban');
    let finalTargetPath = LubanEngine.generateCompressedFileName(sourcePath, targetDir);
    if (targetPath && slashIndex > 0) {
      finalTargetPath = targetPath;
    } else if (targetPath && slashIndex === -1) {
      finalTargetPath = `${targetDir}/${targetPath}`;
    }

    // 确保目录存在
    try {
      if (!fileIo.accessSync(targetDir)) {
        fileIo.mkdirSync(targetDir, true);
      }
    } catch (error) {
      const result: CompressResult = {
        success: false,
        sourcePath: sourcePath,
        error: new Error(`无法创建目标目录: ${targetDir}`)
      };
      return result;
    }

    try {
      const preprocessed = await LubanUtils.preprocessImageFileWithCleanup(sourcePath);
      processedSourcePath = preprocessed.path;
      shouldCleanTemp = preprocessed.shouldClean;

      const result = await LubanEngine.compressSingle(
        processedSourcePath,
        finalTargetPath,
        options?.focusAlpha || false,
        options?.ignoreBy || 100,
        options?.quality
      );
      result.sourcePath = sourcePath;
      return result;
    } finally {
      if (shouldCleanTemp) {
        LubanUtils.deleteFile(processedSourcePath);
      }
    }
  }
} 
