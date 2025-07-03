# Luban 图片压缩库 - 鸿蒙版本

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](oh-package.json5)

基于著名的 [Luban Android 版本](https://github.com/Curzibn/Luban) 实现的鸿蒙 ArkTS 图片压缩库，完美仿照微信朋友圈的图片压缩算法，为鸿蒙生态提供高效的图片压缩解决方案。

## 特性

- 🚀 **高性能压缩**: 基于微信朋友圈压缩算法，提供高效的图片压缩
- 🔧 **灵活配置**: 支持多种压缩参数和过滤器配置
- 📱 **鸿蒙原生**: 专为鸿蒙系统设计，使用 ArkTS 开发
- 🎯 **链式调用**: 提供流畅的链式 API，使用简单
- 🔄 **异步处理**: 支持异步压缩，不阻塞主线程
- 📊 **详细回调**: 提供完整的压缩过程回调

## 🚀 快速开始

### 安装

```bash
# 在你的模块目录下
ohpm install arkluban
```

然后运行：

```bash
ohpm install
```

## 快速开始

### 基本使用

```typescript
import { Luban } from 'arkluban';

// 压缩单张图片
Luban.with('/path/to/image.jpg')
  .ignoreBy(100) // 忽略小于100KB的图片
  .setFocusAlpha(false) // 不保留透明通道
  .launch()
  .then(() => {
    console.log('压缩完成');
  })
  .catch(error => {
    console.error('压缩失败:', error);
  });
```

### 批量压缩

```typescript
import { Luban } from 'arkluban';

// 批量压缩多张图片
Luban.with(['/path/to/image1.jpg', '/path/to/image2.png'])
  .filter(LubanUtils.ImagesOnlyFilter) // 只压缩图片文件
  .ignoreBy(200) // 忽略小于200KB的图片
  .setTargetDir('/custom/output/dir') // 设置输出目录
  .onStart(() => {
    console.log('开始压缩...');
  })
  .onSuccess((filePath) => {
    console.log('压缩成功:', filePath);
  })
  .onError((error) => {
    console.error('压缩失败:', error);
  })
  .launch();
```

### 获取压缩结果

```typescript
import { Luban } from 'arkluban';

// 同步获取压缩结果
const compressedFiles = await Luban.with('/path/to/image.jpg')
  .ignoreBy(100)
  .get();

console.log('压缩后的文件:', compressedFiles);
```

## API 文档

### Luban 主类

#### `Luban.with(paths: string | string[]): LubanBuilder`

创建 Luban 构建器实例。

**参数:**
- `paths`: 图片路径或路径数组

**返回:** `LubanBuilder` 实例

### LubanBuilder 类

#### 配置方法

- `filter(predicate: CompressionPredicate): LubanBuilder` - 设置压缩条件过滤器
- `ignoreBy(sizeInKB: number): LubanBuilder` - 设置忽略压缩的文件大小阈值
- `setFocusAlpha(focusAlpha: boolean): LubanBuilder` - 设置是否保留透明通道
- `setTargetDir(targetDir: string): LubanBuilder` - 设置目标目录

#### 回调方法

- `setOnStart(callback: () => void): LubanBuilder` - 设置压缩开始回调
- `setOnSuccess(callback: (filePath: string) => void): LubanBuilder` - 设置压缩成功回调
- `setOnError(callback: (error: Error) => void): LubanBuilder` - 设置压缩错误回调
- `setOnRename(callback: RenameCallback): LubanBuilder` - 设置重命名回调

#### 别名方法

- `onStart(callback: () => void): LubanBuilder` - 压缩开始回调别名
- `onSuccess(callback: (filePath: string) => void): LubanBuilder` - 压缩成功回调别名
- `onError(callback: (error: Error) => void): LubanBuilder` - 压缩错误回调别名
- `onRename(callback: RenameCallback): LubanBuilder` - 重命名回调别名

#### 执行方法

- `launch(): Promise<void>` - 启动异步压缩
- `get(): Promise<string[]>` - 同步获取压缩结果

### LubanUtils 工具类

#### 过滤器

- `ImagesOnlyFilter` - 只压缩图片文件
- `ExcludeGifFilter` - 排除 GIF 文件
- `MinSizeFilter(minSizeKB: number)` - 只压缩大于指定大小的文件
- `DefaultFilter(minSizeKB?: number)` - 默认过滤器组合

## 类型定义

### CompressConfig

```typescript
interface CompressConfig {
  paths: string[];           // 原图路径列表
  filter?: CompressionPredicate; // 压缩条件过滤器
  ignoreBy?: number;         // 忽略压缩的文件大小阈值（KB）
  focusAlpha?: boolean;      // 是否保留透明通道
  targetDir?: string;        // 目标目录
  onStart?: () => void;      // 压缩开始回调
  onSuccess?: (filePath: string) => void; // 压缩成功回调
  onError?: (error: Error) => void;       // 压缩错误回调
  onRename?: RenameCallback; // 重命名回调
}
```

### CompressResult

```typescript
interface CompressResult {
  success: boolean;          // 是否成功
  filePath?: string;         // 压缩后的文件路径
  error?: Error;             // 错误信息
  originalSize?: number;     // 原文件大小
  compressedSize?: number;   // 压缩后文件大小
}
```

## 示例

更多使用示例请参考 [API.md](API.md) 文档。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 [Apache 2.0](LICENSE) 许可证。 