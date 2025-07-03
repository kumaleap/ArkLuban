# API 文档

## 概述

Luban 图片压缩库提供了完整的图片压缩功能，支持链式调用和异步处理。本文档详细介绍了所有可用的 API 接口。

## 核心类

### Luban

Luban 是库的主入口类，提供了创建压缩构建器的静态方法。

#### 静态方法

##### `Luban.with(paths: string | string[]): LubanBuilder`

创建 Luban 构建器实例，用于配置和执行图片压缩。

**参数:**
- `paths`: 图片路径或路径数组

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
import { Luban } from 'library';

// 压缩单张图片
const builder = Luban.with('/path/to/image.jpg');

// 批量压缩多张图片
const builder = Luban.with(['/path/to/image1.jpg', '/path/to/image2.png']);
```

### LubanBuilder

LubanBuilder 是压缩配置和执行的构建器类，提供了链式调用的 API。

#### 配置方法

##### `filter(predicate: CompressionPredicate): LubanBuilder`

设置压缩条件过滤器，用于过滤需要压缩的文件。

**参数:**
- `predicate`: 压缩条件判断函数

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
import { Luban, LubanUtils } from 'library';

Luban.with('/path/to/image.jpg')
  .filter(LubanUtils.ImagesOnlyFilter) // 只压缩图片文件
  .launch();
```

##### `ignoreBy(sizeInKB: number): LubanBuilder`

设置忽略压缩的文件大小阈值，小于此大小的文件将被跳过。

**参数:**
- `sizeInKB`: 文件大小阈值（KB）

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .ignoreBy(100) // 忽略小于100KB的图片
  .launch();
```

##### `setFocusAlpha(focusAlpha: boolean): LubanBuilder`

设置是否保留透明通道。

**参数:**
- `focusAlpha`: 是否保留透明通道

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.png')
  .setFocusAlpha(true) // 保留透明通道
  .launch();
```

##### `setTargetDir(targetDir: string): LubanBuilder`

设置压缩后文件的输出目录。

**参数:**
- `targetDir`: 目标目录路径

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .setTargetDir('/custom/output/dir') // 设置输出目录
  .launch();
```

#### 回调方法

##### `setOnStart(callback: () => void): LubanBuilder`

设置压缩开始时的回调函数。

**参数:**
- `callback`: 开始压缩时的回调函数

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .setOnStart(() => {
    console.log('开始压缩...');
  })
  .launch();
```

##### `setOnSuccess(callback: (filePath: string) => void): LubanBuilder`

设置压缩成功时的回调函数。

**参数:**
- `callback`: 压缩成功时的回调函数，参数为压缩后的文件路径

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .setOnSuccess((filePath) => {
    console.log('压缩成功:', filePath);
  })
  .launch();
```

##### `setOnError(callback: (error: Error) => void): LubanBuilder`

设置压缩出错时的回调函数。

**参数:**
- `callback`: 压缩出错时的回调函数，参数为错误对象

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .setOnError((error) => {
    console.error('压缩失败:', error);
  })
  .launch();
```

##### `setOnRename(callback: RenameCallback): LubanBuilder`

设置文件重命名回调函数。

**参数:**
- `callback`: 重命名回调函数，参数为原文件路径，返回新文件名

**返回:** `LubanBuilder` 实例

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .setOnRename((filePath) => {
    return 'compressed_' + Date.now() + '.jpg';
  })
  .launch();
```

#### 别名方法

为了提供更简洁的 API，以下方法提供了别名：

- `onStart(callback: () => void): LubanBuilder` - `setOnStart` 的别名
- `onSuccess(callback: (filePath: string) => void): LubanBuilder` - `setOnSuccess` 的别名
- `onError(callback: (error: Error) => void): LubanBuilder` - `setOnError` 的别名
- `onRename(callback: RenameCallback): LubanBuilder` - `setOnRename` 的别名

#### 执行方法

##### `launch(): Promise<void>`

启动异步压缩过程。

**返回:** `Promise<void>`

**示例:**
```typescript
Luban.with('/path/to/image.jpg')
  .ignoreBy(100)
  .launch()
  .then(() => {
    console.log('压缩完成');
  })
  .catch(error => {
    console.error('压缩失败:', error);
  });
```

##### `get(): Promise<string[]>`

同步获取压缩结果，返回压缩后的文件路径数组。

**返回:** `Promise<string[]>`

**示例:**
```typescript
const compressedFiles = await Luban.with('/path/to/image.jpg')
  .ignoreBy(100)
  .get();

console.log('压缩后的文件:', compressedFiles);
```

### LubanUtils

LubanUtils 提供了各种过滤器工具，用于过滤需要压缩的文件。

#### 过滤器

##### `ImagesOnlyFilter`

只压缩图片文件的过滤器。

**示例:**
```typescript
import { Luban, LubanUtils } from 'library';

Luban.with('/path/to/file')
  .filter(LubanUtils.ImagesOnlyFilter)
  .launch();
```

##### `ExcludeGifFilter`

排除 GIF 文件的过滤器。

**示例:**
```typescript
import { Luban, LubanUtils } from 'library';

Luban.with('/path/to/image.gif')
  .filter(LubanUtils.ExcludeGifFilter)
  .launch();
```

##### `MinSizeFilter(minSizeKB: number)`

只压缩大于指定大小的文件的过滤器。

**参数:**
- `minSizeKB`: 最小文件大小（KB）

**示例:**
```typescript
import { Luban, LubanUtils } from 'library';

Luban.with('/path/to/image.jpg')
  .filter(LubanUtils.MinSizeFilter(200)) // 只压缩大于200KB的文件
  .launch();
```

##### `DefaultFilter(minSizeKB?: number)`

默认过滤器组合，包含图片文件过滤、排除GIF、最小尺寸过滤。

**参数:**
- `minSizeKB`: 最小文件大小（KB），默认为100KB

**示例:**
```typescript
import { Luban, LubanUtils } from 'library';

Luban.with('/path/to/image.jpg')
  .filter(LubanUtils.DefaultFilter(150)) // 使用默认过滤器，最小150KB
  .launch();
```

### LubanEngine

LubanEngine 是核心压缩引擎，提供了底层的压缩功能。

#### 静态方法

##### `compressImage(sourcePath: string, targetPath: string, options: CompressOptions): Promise<CompressResult>`

压缩单张图片。

**参数:**
- `sourcePath`: 源图片路径
- `targetPath`: 目标图片路径
- `options`: 压缩选项

**返回:** `Promise<CompressResult>`

**示例:**
```typescript
import { LubanEngine } from 'library';

const result = await LubanEngine.compressImage(
  '/path/to/source.jpg',
  '/path/to/target.jpg',
  { focusAlpha: false, ignoreBy: 100 }
);

if (result.success) {
  console.log('压缩成功:', result.filePath);
} else {
  console.error('压缩失败:', result.error);
}
```

## 类型定义

### 接口

#### `CompressConfig`

压缩配置接口。

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

#### `CompressResult`

压缩结果接口。

```typescript
interface CompressResult {
  success: boolean;          // 是否成功
  filePath?: string;         // 压缩后的文件路径
  error?: Error;             // 错误信息
  originalSize?: number;     // 原文件大小
  compressedSize?: number;   // 压缩后文件大小
}
```

#### `CompressOptions`

压缩选项接口。

```typescript
interface CompressOptions {
  focusAlpha?: boolean;      // 是否保留透明通道
  ignoreBy?: number;         // 忽略压缩的文件大小阈值（KB）
}
```

#### `ImageSize`

图片尺寸接口。

```typescript
interface ImageSize {
  width: number;             // 图片宽度
  height: number;            // 图片高度
}
```

#### `CompressionPredicate`

压缩条件判断接口。

```typescript
interface CompressionPredicate {
  apply(path: string): boolean; // 判断是否需要压缩
}
```

#### `CompressCallbacks`

压缩回调函数集合接口。

```typescript
interface CompressCallbacks {
  onStart?: () => void;      // 压缩开始回调
  onSuccess?: (filePath: string) => void; // 压缩成功回调
  onError?: (error: Error) => void;       // 压缩错误回调
}
```

#### `FilterCollection`

过滤器集合接口。

```typescript
interface FilterCollection {
  IMAGES_ONLY: CompressionPredicate;                    // 只压缩图片文件
  EXCLUDE_GIF: CompressionPredicate;                    // 排除 GIF 文件
  MIN_SIZE: (minSizeKB: number) => CompressionPredicate; // 最小尺寸过滤器
  DEFAULT: (minSizeKB?: number) => CompressionPredicate; // 默认过滤器
}
```

### 枚举

#### `CompressFormat`

压缩格式枚举。

```typescript
enum CompressFormat {
  JPEG = 'image/jpeg',       // JPEG 格式
  PNG = 'image/png',         // PNG 格式
  WEBP = 'image/webp'        // WEBP 格式
}
```

### 类型别名

#### `RenameCallback`

文件重命名回调函数类型。

```typescript
type RenameCallback = (filePath: string) => string;
```

## 使用示例

### 基本压缩

```typescript
import { Luban } from 'library';

// 压缩单张图片
Luban.with('/path/to/image.jpg')
  .ignoreBy(100)
  .setFocusAlpha(false)
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
import { Luban, LubanUtils } from 'library';

// 批量压缩多张图片
Luban.with(['/path/to/image1.jpg', '/path/to/image2.png'])
  .filter(LubanUtils.ImagesOnlyFilter)
  .ignoreBy(200)
  .setTargetDir('/custom/output/dir')
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
import { Luban } from 'library';

// 同步获取压缩结果
const compressedFiles = await Luban.with('/path/to/image.jpg')
  .ignoreBy(100)
  .get();

console.log('压缩后的文件:', compressedFiles);
```

### 自定义过滤器

```typescript
import { Luban } from 'library';

// 自定义过滤器
const customFilter = {
  apply(path: string): boolean {
    return path.endsWith('.jpg') && path.includes('photo');
  }
};

Luban.with('/path/to/photo.jpg')
  .filter(customFilter)
  .launch();
```

### 文件重命名

```typescript
import { Luban } from 'library';

Luban.with('/path/to/image.jpg')
  .onRename((filePath) => {
    const timestamp = Date.now();
    return `compressed_${timestamp}.jpg`;
  })
  .launch();
```

## 错误处理

Luban 库提供了完善的错误处理机制：

```typescript
import { Luban } from 'library';

Luban.with('/path/to/image.jpg')
  .onError((error) => {
    console.error('压缩过程中发生错误:', error.message);
    
    // 根据错误类型进行不同处理
    if (error.message.includes('文件不存在')) {
      console.log('请检查文件路径是否正确');
    } else if (error.message.includes('权限不足')) {
      console.log('请检查文件访问权限');
    } else {
      console.log('未知错误，请重试');
    }
  })
  .launch();
```

## 性能优化建议

1. **合理设置忽略阈值**: 根据实际需求设置 `ignoreBy` 参数，避免压缩过小的文件
2. **使用过滤器**: 使用合适的过滤器减少不必要的文件处理
3. **批量处理**: 对于多个文件，使用批量压缩而不是逐个压缩
4. **异步处理**: 使用 `launch()` 方法进行异步压缩，避免阻塞主线程
5. **自定义输出目录**: 设置合适的输出目录，避免使用系统缓存目录

## 注意事项

1. **文件权限**: 确保应用有足够的文件读写权限
2. **存储空间**: 确保设备有足够的存储空间用于压缩后的文件
3. **文件格式**: 支持的图片格式包括 JPEG、PNG、WEBP
4. **内存使用**: 大图片压缩可能占用较多内存，建议在后台线程中处理
5. **网络图片**: 目前只支持本地文件路径，不支持网络图片URL 