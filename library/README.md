# Luban 图片压缩库 - 鸿蒙版本

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](oh-package.json5)

ArkLuban 是参考 [Luban Android 版本](https://github.com/Curzibn/Luban) 和微信朋友圈压缩策略实现的 HarmonyOS ArkTS 图片压缩库。它提供链式 API、批量并发、URI 预处理、EXIF 方向处理、透明通道保留和可调 JPEG 质量，适合在上传、分享、IM、表单图片等场景中降低图片体积。

## 目录

- [特性](#特性)
- [安装](#安装)
- [初始化](#初始化)
- [快速开始](#快速开始)
- [结果语义](#结果语义)
- [详细 API](#详细-api)
- [高级用法](#高级用法)
- [常见问题](#常见问题)
- [许可证](#许可证)

## 特性

- 基于 Luban 压缩思路，按图片尺寸和体积计算目标压缩参数
- 支持普通文件路径、`file://`、`content://`、`datashare://` 等 URI 输入
- 支持 EXIF 方向读取和旋转修正
- 支持批量压缩，并可通过 `setMaxConcurrency()` 控制并发数
- 支持 `setQuality()` / `quality` 调整 JPEG 清晰度和体积
- 支持 PNG / WebP 透明通道保留
- 支持 `.get()`、`.getResults()` 和 `.launch()` 三种使用方式
- 小图或压缩后不更小的图片会复制原图作为成功结果，避免输出文件变大

## 安装

```bash
ohpm install @ark/luban
```

## 初始化

在应用启动时注入一次 `Context`。如果使用默认输出目录、URI 临时文件预处理或缓存清理能力，必须先调用该方法。

```typescript
import { UIAbility } from '@kit.AbilityKit';
import { LubanUtils } from '@ark/luban';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    LubanUtils.setContext(this.context);
  }
}
```

## 快速开始

### 获取压缩文件路径

`.get()` 返回成功文件路径数组；如果任意一张图片失败，会直接抛出错误。

```typescript
import { Luban } from '@ark/luban';

async function compressOne() {
  const files = await Luban.with('/path/to/image.jpg')
    .ignoreBy(100)
    .setQuality(82)
    .get();

  console.log('压缩后的文件:', files[0]);
}
```

### 批量压缩并保留失败项

如果需要知道每一张图片的成功或失败状态，使用 `.getResults()`。

```typescript
import { Luban } from '@ark/luban';

async function compressBatch(paths: string[]) {
  const results = await Luban.with(paths)
    .ignoreBy(200)
    .setQuality(82)
    .setMaxConcurrency(3)
    .getResults();

  results.forEach((result) => {
    if (result.success) {
      console.log('压缩成功:', result.sourcePath, '=>', result.filePath);
    } else {
      console.error('压缩失败:', result.sourcePath, result.error?.message);
    }
  });
}
```

### 回调模式

`.launch()` 适合已经接入回调式流程的场景。

```typescript
import { Luban } from '@ark/luban';

Luban.with(['/path/to/image1.jpg', '/path/to/image2.png'])
  .filter((path) => !path.endsWith('.gif'))
  .ignoreBy(200)
  .setQuality(82)
  .setTargetDir('/custom/output/dir')
  .setMaxConcurrency(3)
  .onStart(() => console.log('开始压缩...'))
  .onSuccess((filePath) => console.log('压缩成功:', filePath))
  .onError((error) => console.error('压缩失败:', error))
  .launch();
```

## 结果语义

| 方法 | 返回值 | 失败行为 | 适用场景 |
| --- | --- | --- | --- |
| `.get()` | `Promise<string[]>` | 任意一张失败就抛出错误，不返回失败项 | 全部成功才继续后续流程 |
| `.getResults()` | `Promise<CompressResult[]>` | 每张图片都有独立结果，失败项保留在数组中 | 批量压缩、需要定位失败图片 |
| `.launch()` | `Promise<void>` | 通过 `onSuccess` / `onError` 回调通知 | 回调式业务流程 |

`getResults()` 的结果只对应实际进入压缩流程的输入。如果配置了 `filter`，被过滤掉的图片不会出现在结果数组中。

`CompressResult` 结构如下：

```typescript
interface CompressResult {
  success: boolean;
  sourcePath?: string;
  filePath?: string;
  error?: Error;
  originalSize?: number;
  compressedSize?: number;
}
```

说明：

- `sourcePath` 是原始输入路径或 URI，失败时也会尽量保留，便于定位问题图片。
- `filePath` 是输出文件路径，仅成功时有值。
- 小于 `ignoreBy` 的图片会复制原图作为成功结果。
- 压缩后如果不比原图更小，也会复制原图作为成功结果。

## 详细 API

### `Luban.with(paths: string | string[]): LubanBuilder`

创建链式压缩构建器。

```typescript
const single = Luban.with('/path/to/image.jpg');

const batch = Luban.with([
  '/path/to/image1.jpg',
  '/path/to/image2.png'
]);
```

### `Luban.compress(sourcePath: string, targetPath?: string, options?: CompressOptions): Promise<CompressResult>`

快速压缩单张图片。

```typescript
const result = await Luban.compress(
  '/path/to/source.jpg',
  '/path/to/target.jpg',
  {
    ignoreBy: 100,
    focusAlpha: false,
    quality: 82
  }
);

if (result.success) {
  console.log(result.filePath);
}
```

### `LubanBuilder`

```typescript
Luban.with(paths)
  .filter((path) => path.endsWith('.jpg'))
  .ignoreBy(100)
  .setFocusAlpha(true)
  .setQuality(82)
  .setTargetDir('/output/dir')
  .setMaxConcurrency(3)
  .onRename((sourcePath) => {
    return `compressed_${Date.now()}.jpg`;
  })
  .get();
```

| 方法 | 说明 |
| --- | --- |
| `filter(predicate)` | 自定义过滤条件，返回 `false` 的输入不会进入结果数组 |
| `ignoreBy(sizeInKB)` | 小于该体积的图片直接复制，默认 `100` KB |
| `setFocusAlpha(focusAlpha)` | 是否保留透明通道，适合 PNG / WebP |
| `setQuality(quality)` | 设置 JPEG 质量，建议 `75-85` 起步 |
| `setTargetDir(targetDir)` | 设置输出目录，不设置时使用默认目录 |
| `setMaxConcurrency(count)` | 设置批量压缩并发数，默认 `3` |
| `onStart(callback)` | 压缩开始回调 |
| `onSuccess(callback)` | 单张图片成功回调 |
| `onError(callback)` | 单张图片或整体流程错误回调 |
| `onRename(callback)` | 自定义输出文件名 |

### 过滤器

```typescript
import { LubanUtils } from '@ark/luban';

Luban.with(paths)
  .filter(LubanUtils.FILTERS.DEFAULT(200))
  .get();
```

内置过滤器：

- `LubanUtils.FILTERS.IMAGES_ONLY`：只保留支持的图片格式。
- `LubanUtils.FILTERS.EXCLUDE_GIF`：保留图片但排除 GIF。
- `LubanUtils.FILTERS.MIN_SIZE(sizeInKB)`：只保留大于指定体积的图片。
- `LubanUtils.FILTERS.DEFAULT(sizeInKB = 100)`：排除 GIF，并只保留大于指定体积的图片。

自定义过滤器：

```typescript
Luban.with(paths)
  .filter((path) => {
    const isImage = LubanUtils.isImage(path);
    const isNotGif = !path.toLowerCase().endsWith('.gif');
    const isLarge = LubanUtils.isUri(path) || LubanUtils.getFileSizeInKBSync(path) > 500;
    return isImage && isNotGif && isLarge;
  })
  .getResults();
```

### 实用工具

```typescript
import { LubanUtils } from '@ark/luban';

LubanUtils.setContext(context);
LubanUtils.isImage(path);
LubanUtils.getFileExtension(path);
LubanUtils.getFileSizeInKB(path);
LubanUtils.formatFileSize(bytes);
LubanUtils.calculateCompressionRatio(originalSize, compressedSize);
```

## 高级用法

### 调整清晰度

默认 JPEG 质量偏体积优先。如果压缩后感觉发糊，可以提高质量值。`quality` 会被限制在 `5-95` 范围内，数值越高越清晰，输出文件也越大。

建议：

- 普通照片：`75-82`
- 商品图、证件图、带文字截图：`82-90`
- 更关注体积：不设置或使用 `70-75`

```typescript
await Luban.with(paths)
  .setQuality(82)
  .get();

const result = await Luban.compress('/path/source.jpg', undefined, {
  quality: 82
});
```

### 统计压缩结果

需要统计每张图片的原始大小、输出大小和压缩率时，优先使用 `.getResults()`。

```typescript
import { Luban, LubanUtils } from '@ark/luban';

const results = await Luban.with(paths)
  .setQuality(82)
  .getResults();

for (const result of results) {
  if (!result.success || result.originalSize === undefined || result.compressedSize === undefined) {
    console.error('压缩失败:', result.sourcePath, result.error?.message);
    continue;
  }

  const ratio = LubanUtils.calculateCompressionRatio(result.originalSize, result.compressedSize);
  console.log(`${result.sourcePath} 压缩率: ${ratio}%`);
}
```

### 大批量处理

`setMaxConcurrency()` 控制单个批次内部并发。图片数量很多时，可以再按批切分，避免一次性创建过多任务。

```typescript
import { Luban, LubanUtils, CompressResult } from '@ark/luban';

async function compressInBatches(paths: string[]) {
  const batchSize = 30;
  const allResults: CompressResult[] = [];

  for (let index = 0; index < paths.length; index += batchSize) {
    const batch = paths.slice(index, index + batchSize);
    const results = await Luban.with(batch)
      .filter(LubanUtils.FILTERS.DEFAULT())
      .setMaxConcurrency(3)
      .getResults();

    allResults.push(...results);
  }

  return allResults;
}
```

### 保留透明通道

默认输出偏向 JPEG 体积优势。需要保留 PNG / WebP 的透明通道时，启用 `setFocusAlpha(true)`。

```typescript
await Luban.with('/path/to/transparent.png')
  .setFocusAlpha(true)
  .get();
```

### 自定义输出文件名

```typescript
await Luban.with(paths)
  .onRename((sourcePath) => {
    const original = sourcePath.split('/').pop() || 'image.jpg';
    return `compressed_${Date.now()}_${original}`;
  })
  .get();
```

### 清理缓存

URI 输入在压缩过程中产生的内部临时文件会在单次压缩结束后自动清理。一般业务不需要手动清理。

如果你把输出目录放在默认缓存目录，并且确认输出文件已经上传、复制或不再使用，可以按需清理：

```typescript
const removedCount = LubanUtils.cleanTempCache();
console.log('清理文件数量:', removedCount);
```

不要在每张图片的 `onSuccess` 中立即清理缓存，否则可能影响后续展示、上传或业务读取输出文件。

## 常见问题

### Q: 批量压缩 10 张，其中 1 张失败，`.get()` 返回什么？

`.get()` 会抛出错误，不会返回成功 9 张的数组，也不会把失败项放进数组。需要保留每张图片状态时，请使用 `.getResults()`。

### Q: 为什么我测试时一直是成功，拿不到失败项？

小图直接复制原图会返回成功；压缩后不比原图小，也会复制原图返回成功。只有源文件不可读、解码失败、目录创建失败、写入失败等情况才算失败。

### Q: 压缩后图片发糊怎么办？

提高 JPEG 质量，例如：

```typescript
await Luban.with(paths)
  .setQuality(82)
  .get();
```

带文字、证件、商品细节的图片可以尝试 `85-90`。质量越高，文件越大。

### Q: 如何显示压缩后的本地文件？

压缩成功后会返回普通文件路径。实际展示时可以根据业务需要把文件路径转成可用于 `Image` 组件的数据源。

### Q: 什么时候需要 `LubanUtils.setContext()`？

建议应用启动时始终初始化一次。默认输出目录、URI 临时文件复制、缓存目录和临时目录相关能力都依赖 `Context`。

## 许可证

本项目采用 [Apache 2.0](LICENSE) 许可证。
