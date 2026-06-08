/**
 * Luban 图片压缩库的类型定义
 * 仿照微信朋友圈压缩策略的鸿蒙版本
 */

import { common } from '@kit.AbilityKit';

/**
 * 图片尺寸接口
 */
export interface ImageSize {
  width: number;
  height: number;
}

/**
 * Android 当前 Luban 目标压缩参数
 */
export interface CompressionTarget {
  width: number;
  height: number;
  estimatedSizeKb: number;
  isLongImage: boolean;
  targetSizeKb?: number;
}

/**
 * 压缩选项接口
 */
export interface CompressOptions {
  focusAlpha?: boolean;
  ignoreBy?: number;
  /**
   * JPEG 压缩质量，建议范围 5-95；越高越清晰，文件也越大。
   */
  quality?: number;
}

export type LubanContext = common.Context;

export interface PreprocessedImageFile {
  path: string;
  shouldClean: boolean;
}

/**
 * 压缩条件判断函数类型
 */
export type CompressionPredicate = (path: string) => boolean;

/**
 * 过滤器集合接口
 */
export interface FilterCollection {
  /**
   * 只压缩图片文件
   */
  IMAGES_ONLY: CompressionPredicate;

  /**
   * 排除 GIF 文件
   */
  EXCLUDE_GIF: CompressionPredicate;

  /**
   * 只压缩大于指定大小的文件
   * @param minSizeKB 最小文件大小（KB）
   */
  MIN_SIZE: (minSizeKB: number) => CompressionPredicate;

  /**
   * 组合过滤器：只压缩图片且排除 GIF 且大于指定大小
   * @param minSizeKB 最小文件大小（KB）
   */
  DEFAULT: (minSizeKB?: number) => CompressionPredicate;
}

/**
 * 压缩回调函数集合接口
 */
export interface CompressCallbacks {
  onStart?: () => void;
  onSuccess?: (filePath: string) => void;
  onError?: (error: Error) => void;
}

/**
 * 文件重命名回调函数类型
 */
export type RenameCallback = (filePath: string) => string;

/**
 * 压缩配置
 */
export interface CompressConfig {
  /**
   * 原图路径列表
   */
  paths: string[];

  /**
   * 压缩条件过滤器
   */
  filter?: CompressionPredicate;

  /**
   * 忽略压缩的文件大小阈值（KB）
   */
  ignoreBy?: number;

  /**
   * 是否保留透明通道
   */
  focusAlpha?: boolean;

  /**
   * JPEG 压缩质量，建议范围 5-95。
   */
  quality?: number;

  /**
   * 目标目录
   */
  targetDir?: string;

  /**
   * 批量压缩最大并发数
   */
  maxConcurrency?: number;

  /**
   * 压缩开始回调
   */
  onStart?: () => void;

  /**
   * 压缩成功回调
   */
  onSuccess?: (filePath: string) => void;

  /**
   * 压缩错误回调
   */
  onError?: (error: Error) => void;

  /**
   * 重命名回调
   */
  onRename?: RenameCallback;
}

/**
 * 压缩质量枚举
 */
export enum CompressFormat {
  JPEG = 'image/jpeg',
  PNG = 'image/png',
  WEBP = 'image/webp'
}

/**
 * 压缩结果
 */
export interface CompressResult {
  /**
   * 是否成功
   */
  success: boolean;

  /**
   * 原始输入路径或 URI
   */
  sourcePath?: string;

  /**
   * 压缩后的文件路径
   */
  filePath?: string;

  /**
   * 错误信息
   */
  error?: Error;

  /**
   * 原文件大小
   */
  originalSize?: number;

  /**
   * 压缩后文件大小
   */
  compressedSize?: number;
}

export interface CompressSettledResult {
  status: 'fulfilled' | 'rejected';
  value?: CompressResult;
  reason?: Error;
} 
