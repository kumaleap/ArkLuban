# Luban 图片压缩库 - 鸿蒙版本

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](oh-package.json5)

基于著名的 [Luban Android 版本](https://github.com/Curzibn/Luban) 实现的鸿蒙 ArkTS 图片压缩库，完美仿照微信朋友圈的图片压缩算法，为鸿蒙生态提供高效的图片压缩解决方案。

<p align="center">
  <img src="demo.gif" alt="ArkLuban 演示" width="600" style="max-width: 100%;" />
</p>

## 目录

- [特性](#特性)
- [安装](#安装)
- [快速开始](#快速开始)
- [详细 API](#详细-api)
  - [Luban 主类](#luban-主类)
  - [LubanBuilder 类](#lubanbuilder-类)
  - [过滤器](#过滤器)
  - [实用工具](#实用工具)
- [高级用法](#高级用法)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)
- [贡献](#贡献)
- [许可证](#许可证)

## 特性

- 🚀 **高性能压缩**: 基于微信朋友圈压缩算法，提供高效的图片压缩
- 🔧 **灵活配置**: 支持多种压缩参数和过滤器配置
- 📱 **鸿蒙原生**: 专为鸿蒙系统设计，使用 ArkTS 开发
- 🎯 **链式调用**: 提供流畅的链式 API，使用简单
- 🔄 **异步处理**: 支持异步压缩，不阻塞主线程
- 📊 **详细回调**: 提供完整的压缩过程回调
- 🎨 **透明通道**: 支持保留 PNG/WebP 的透明通道
- 📁 **批量处理**: 支持批量压缩多个图片
- 🔍 **智能过滤**: 提供多种过滤器和自定义过滤功能

## 安装

```bash
ohpm install @ark/luban
```
## 快速开始

### 基本使用

```typescript
import { Luban } from '@ark/luban';

// 压缩单张图片
Luban.with('/path/to/image.jpg')
  .launch()
  .then(() => console.log('压缩完成'))
  .catch(error => console.error('压缩失败:', error));
```

### 批量压缩

```typescript
import { Luban, LubanUtils } from 'library';

// 批量压缩多张图片
Luban.with(['/path/to/image1.jpg', '/path/to/image2.png'])
  .filter((path) => !path.endsWith('.gif')) // 使用函数过滤器排除 GIF
  .ignoreBy(200) // 忽略小于 200KB 的图片
  .setTargetDir('/custom/output/dir') // 自定义输出目录
  .onStart(() => console.log('开始压缩...'))
  .onSuccess((filePath) => console.log('压缩成功:', filePath))
  .onError((error) => console.error('压缩失败:', error))
  .launch();
```

### 同步获取结果

```typescript
import { Luban } from '@ark/luban';

async function compressImages() {
  try {
    const compressedFiles = await Luban.with('/path/to/image.jpg')
      .ignoreBy(100)
      .get();
    
    console.log('压缩后的文件:', compressedFiles);
  } catch (error) {
    console.error('压缩失败:', error);
  }
}
```

## 详细 API

### Luban 主类

#### `Luban.with(paths: string | string[]): LubanBuilder`

创建 Luban 构建器实例。

```typescript
// 单文件
const builder = Luban.with('/path/to/image.jpg');

// 多文件
const builder = Luban.with([
  '/path/to/image1.jpg',
  '/path/to/image2.png'
]);
```

#### `Luban.compress(sourcePath: string, targetPath?: string, options?: CompressOptions): Promise<CompressResult>`

快速压缩单张图片。

```typescript
const result = await Luban.compress(
  '/path/to/source.jpg',
  '/path/to/target.jpg',
  { focusAlpha: true }
);
```

### LubanBuilder 类

#### 配置方法

```typescript
Luban.with(paths)
  .filter((path) => path.endsWith('.jpg')) // 设置过滤器
  .ignoreBy(100) // 忽略小于 100KB 的文件
  .setFocusAlpha(true) // 保留透明通道
  .setTargetDir('/output/dir') // 设置输出目录
  .launch();
```

#### 回调方法

```typescript
Luban.with(paths)
  .onStart(() => {
    // 开始压缩
  })
  .onSuccess((filePath) => {
    // 单个文件压缩成功
    //显示时 使用 fileUri 获取uri 直接赋值给Image就可以显示了
  })
  .onError((error) => {
    // 发生错误
  })
  .onRename((filePath) => {
    // 自定义压缩后的文件名
    return `compressed_${Date.now()}.jpg`;
  })
  .launch();
```

### 过滤器

#### 函数式过滤器

```typescript
// 简单过滤器
.filter((path) => path.endsWith('.jpg'))

// 复杂过滤器
.filter((path) => {
  const isImage = path.match(/\.(jpg|jpeg|png|webp)$/i);
  const isLarge = LubanUtils.getFileSizeInKBSync(path) > 1024;
  return isImage && isLarge;
})
```

#### 预设过滤器

```typescript
import { LubanUtils } from '@ark/luban';

// 只压缩图片
.filter(LubanUtils.FILTERS.IMAGES_ONLY)

// 排除 GIF
.filter(LubanUtils.FILTERS.EXCLUDE_GIF)

// 大于指定大小
.filter(LubanUtils.FILTERS.MIN_SIZE(500)) // 500KB

// 默认过滤器（排除GIF且大于100KB）
.filter(LubanUtils.FILTERS.DEFAULT())
```

### 实用工具

```typescript
import { LubanUtils } from '@ark/luban';

// 检查是否为图片
LubanUtils.isImage(path);

// 获取文件大小
const sizeKB = LubanUtils.getFileSizeInKBSync(path);

// 格式化文件大小
const size = LubanUtils.formatFileSize(bytes);
```

## 高级用法

### 自定义压缩流程

```typescript
Luban.with(paths)
  // 自定义过滤规则
  .filter((path) => {
    const extension = path.toLowerCase().split('.').pop();
    const size = LubanUtils.getFileSizeInKBSync(path);
    return ['jpg', 'png'].includes(extension) && size > 500;
  })
  // 自定义输出文件名
  .onRename((path) => {
    const original = path.split('/').pop();
    return `compressed_${Date.now()}_${original}`;
  })
  // 处理压缩结果
  .onSuccess(async (filePath) => {
    const originalSize = await LubanUtils.getFileSizeInKB(path);
    const compressedSize = await LubanUtils.getFileSizeInKB(filePath);
    const ratio = LubanUtils.calculateCompressRatio(originalSize, compressedSize);
    console.log(`压缩率: ${ratio}%`);
  })
  .launch();
```

### 批量处理优化

```typescript
async function compressInBatches(paths: string[]) {
  const batchSize = 3; // 每批处理3张
  const batches = [];
  
  for (let i = 0; i < paths.length; i += batchSize) {
    const batch = paths.slice(i, i + batchSize);
    batches.push(
      Luban.with(batch)
        .filter(LubanUtils.FILTERS.DEFAULT())
        .get()
    );
  }
  
  const results = await Promise.all(batches);
  return results.flat();
}
```

## 最佳实践

1. **合理设置阈值**
```typescript
// 根据实际需求设置忽略阈值
Luban.with(paths)
  .ignoreBy(200) // 忽略小于200KB的图片
  .launch();
```

2. **使用适当的过滤器**
```typescript
// 组合多个条件
.filter((path) => {
  const isImage = LubanUtils.isImage(path);
  const isNotGif = !path.endsWith('.gif');
  const isLarge = LubanUtils.getFileSizeInKBSync(path) > 500;
  return isImage && isNotGif && isLarge;
})
```

3. **错误处理**
```typescript
Luban.with(paths)
  .onError((error) => {
    console.error('压缩错误:', error);
    // 可以在这里实现重试逻辑
  })
  .launch()
  .catch((error) => {
    console.error('整体流程错误:', error);
    // 处理致命错误
  });
```

4. **资源清理**
```typescript
// 压缩完成后清理临时文件
.onSuccess(async (filePath) => {
  // 处理压缩后的文件
  await processCompressedFile(filePath);
  // 清理临时文件
  LubanUtils.cleanupTempFiles();
})
```

## 常见问题

### Q: 如何保持图片的透明通道？
```typescript
Luban.with('/path/to/transparent.png')
  .setFocusAlpha(true) // 启用透明通道支持
  .launch();
```

### Q: 如何自定义输出文件名？
```typescript
Luban.with(paths)
  .onRename((path) => {
    const timestamp = Date.now();
    const original = path.split('/').pop();
    return `compressed_${timestamp}_${original}`;
  })
  .launch();
```

### Q: 如何处理大量图片？
```typescript
// 使用批量处理并显示进度
async function compressWithProgress(paths: string[]) {
  let processed = 0;
  const total = paths.length;
  
  await Luban.with(paths)
    .onSuccess(() => {
      processed++;
      const progress = (processed / total) * 100;
      console.log(`进度: ${progress.toFixed(1)}%`);
    })
    .launch();
}
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 [Apache 2.0](LICENSE) 许可证。 