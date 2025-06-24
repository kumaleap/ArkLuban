# Luban 鸿蒙版 - 图片压缩库

基于 [Luban Android 版本](https://github.com/Curzibn/Luban) 的鸿蒙 ArkTS 实现，仿照微信朋友圈的图片压缩算法。

## 功能特点

- 🚀 **高效压缩** - 基于微信朋友圈压缩策略，压缩效果接近微信
- 📱 **鸿蒙原生** - 使用鸿蒙官方 API，完全兼容 HarmonyOS
- ⚡ **异步处理** - 支持异步压缩，不阻塞主线程
- 🔧 **灵活配置** - 支持多种压缩参数配置
- 📊 **批量处理** - 支持单张和批量图片压缩
- 🎯 **链式调用** - 提供优雅的链式 API

## 压缩效果对比

| 内容 | 原图 | Luban 鸿蒙版 | 说明 |
|------|------|-------------|------|
| 截屏 720P | 720×1280, 390KB | 720×1280, ~90KB | ~77% 压缩率 |
| 截屏 1080P | 1080×1920, 2.21MB | 1080×1920, ~110KB | ~95% 压缩率 |
| 拍照 4:3 | 3096×4128, 3.12MB | 1548×2064, ~150KB | ~95% 压缩率 |
| 拍照 16:9 | 4128×2322, 4.64MB | 1032×581, ~100KB | ~98% 压缩率 |

## 安装使用

### 1. 导入库模块

```typescript
import { 
  Luban, 
  LubanUtils, 
  OnCompressListener,
  CompressionPredicate 
} from 'library'
```

### 2. 基本使用

#### 异步压缩（推荐）

```typescript
// 单张图片异步压缩
Luban.with(imagePath)
  .ignoreBy(100) // 忽略小于 100KB 的文件
  .setFocusAlpha(false) // 不保留透明通道
  .setTargetDir('/data/storage/el2/base/cache/compressed') // 设置输出目录
  .setCompressListener({
    onStart: () => {
      console.log('开始压缩...')
    },
    onSuccess: (filePath: string) => {
      console.log(`压缩成功: ${filePath}`)
    },
    onError: (error: Error) => {
      console.error(`压缩失败: ${error.message}`)
    }
  })
  .launch();
```

#### 同步压缩

```typescript
// 获取压缩结果
try {
  const compressedFiles = await Luban.with([imagePath1, imagePath2])
    .ignoreBy(50)
    .setFocusAlpha(true)
    .get();
    
  console.log(`压缩完成，共 ${compressedFiles.length} 个文件`);
} catch (error) {
  console.error('压缩失败:', error);
}
```

#### 快速压缩

```typescript
// 简单快速压缩
import { CompressOptions } from 'library';

const options: CompressOptions = {
  focusAlpha: false,
  ignoreBy: 100
};

const result = await Luban.compress(sourcePath, targetPath, options);

if (result.success) {
  console.log('压缩成功:', result.filePath);
} else {
  console.error('压缩失败:', result.error?.message);
}
```

#### 函数回调方式（推荐）

**为了完全解决 ArkTS 对象字面量兼容性问题**，我们已经移除了接口监听器，统一使用函数回调：

```typescript
// ✅ 使用函数回调，完全兼容 ArkTS 严格模式
await Luban.with(imagePaths)
  .ignoreBy(50)
  .setFocusAlpha(false)
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
  .onStart(() => {
    console.log('🚀 开始压缩...');
  })
  .onSuccess((filePath: string) => {
    console.log('✅ 压缩成功:', filePath);
    // 处理成功逻辑
  })
  .onError((error: Error) => {
    console.error('❌ 压缩失败:', error.message);
    // 处理错误逻辑
  })
  .launch();

// 也可以只设置需要的回调
await Luban.with(imagePaths)
  .onSuccess((filePath: string) => {
    console.log('压缩完成:', filePath);
  })
  .launch();

// 使用完整方法名（更明确）
await Luban.with(imagePaths)
  .setOnStart(() => console.log('开始'))
  .setOnSuccess((filePath) => console.log('成功:', filePath))
  .setOnError((error) => console.error('失败:', error))
  .launch();
```

**函数回调的优势**：
- 完全兼容 ArkTS 严格模式，无任何对象字面量
- 更简洁的 API，直接传递函数
- 更好的类型安全和 TypeScript 支持
- 支持链式调用，灵活性更高

### 3. 高级配置

#### 自定义过滤器

使用预设过滤器类：
```typescript
import { ExcludeGifFilter, MinSizeFilter, DefaultFilter } from 'library';

// 使用预设过滤器类
Luban.with(imagePaths)
  .filter(new ExcludeGifFilter())
  .launch();

// 使用最小文件大小过滤器
Luban.with(imagePaths)
  .filter(new MinSizeFilter(500))
  .launch();

// 使用默认组合过滤器
Luban.with(imagePaths)
  .filter(new DefaultFilter(200))
  .launch();
```

创建自定义过滤器类：
```typescript
class JpegOnlyFilter implements CompressionPredicate {
  apply(path: string): boolean {
    // 只压缩 JPG 和 PNG 文件
    return LubanUtils.isImage(path) && 
           !path.toLowerCase().endsWith('.gif');
  }
}

Luban.with(imagePaths)
  .filter(new JpegOnlyFilter())
  .launch();
```

#### 使用预设过滤器

```typescript
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF) // 排除 GIF
  .launch();

// 或者组合过滤器
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.DEFAULT(200)) // 排除 GIF 且大于 200KB
  .launch();
```

#### 自定义文件命名

```typescript
// 使用函数回调方式
Luban.with(imagePaths)
  .onRename((filePath: string): string => {
    const name = LubanUtils.getFileNameWithoutExtension(filePath);
    return `compressed_${name}_${Date.now()}.jpg`;
  })
  .launch();

// 或使用完整方法名
Luban.with(imagePaths)
  .setOnRename((filePath: string): string => {
    const timestamp = Date.now();
    return `luban_${timestamp}.jpg`;
  })
  .launch();
```

## API 文档

### Luban 主类

| 方法 | 描述 | 参数 |
|------|------|------|
| `with(paths)` | 创建压缩构建器 | `string \| string[]` - 图片路径 |
| `compress(source, target?, options?)` | 快速压缩单张图片 | 源路径、目标路径（可选）、选项（可选） |

### LubanBuilder 构建器

| 方法 | 描述 | 参数 |
|------|------|------|
| `ignoreBy(size)` | 设置忽略阈值 | `number` - 文件大小（KB） |
| `setFocusAlpha(focus)` | 设置透明通道 | `boolean` - 是否保留 |
| `setTargetDir(dir)` | 设置输出目录 | `string` - 目录路径 |
| `filter(predicate)` | 设置过滤条件 | `CompressionPredicate` - 过滤器 |
| **`setOnStart(callback)`** | **设置开始回调** | `() => void` - 开始回调函数 |
| **`setOnSuccess(callback)`** | **设置成功回调** | `(filePath: string) => void` - 成功回调函数 |
| **`setOnError(callback)`** | **设置错误回调** | `(error: Error) => void` - 错误回调函数 |
| **`setOnRename(callback)`** | **设置重命名回调** | `(filePath: string) => string` - 重命名回调函数 |
| `onStart(callback)` | 开始回调（别名） | `() => void` - 开始回调函数 |
| `onSuccess(callback)` | 成功回调（别名） | `(filePath: string) => void` - 成功回调函数 |
| `onError(callback)` | 错误回调（别名） | `(error: Error) => void` - 错误回调函数 |
| `onRename(callback)` | 重命名回调（别名） | `(filePath: string) => string` - 重命名回调函数 |
| `launch()` | 启动异步压缩 | 无 |
| `get()` | 同步获取结果 | 返回 `Promise<string[]>` |

### LubanUtils 工具类

| 方法 | 描述 |
|------|------|
| `isImage(path)` | 检查是否为图片文件 |
| `getFileExtension(path)` | 获取文件扩展名 |
| `getFileSizeInKB(path)` | 获取文件大小（KB） |
| `formatFileSize(bytes)` | 格式化文件大小 |
| `fileExists(path)` | 检查文件是否存在 |
| `calculateCompressionRatio(original, compressed)` | 计算压缩比 |

### 预设过滤器

| 过滤器类 | 描述 | 使用方式 |
|----------|------|----------|
| `ImagesOnlyFilter` | 只处理图片文件 | `new ImagesOnlyFilter()` |
| `ExcludeGifFilter` | 排除 GIF 文件 | `new ExcludeGifFilter()` |
| `MinSizeFilter` | 最小文件大小过滤 | `new MinSizeFilter(kb)` |
| `DefaultFilter` | 默认过滤器（排除 GIF + 最小大小） | `new DefaultFilter(kb)` |

#### 通过 FILTERS 使用

| 方法 | 描述 |
|------|------|
| `LubanUtils.FILTERS.IMAGES_ONLY` | 只处理图片文件 |
| `LubanUtils.FILTERS.EXCLUDE_GIF` | 排除 GIF 文件 |
| `LubanUtils.FILTERS.MIN_SIZE(kb)` | 最小文件大小过滤 |
| `LubanUtils.FILTERS.DEFAULT(kb)` | 默认过滤器（排除 GIF + 最小大小） |

### 类型接口

| 接口/类型 | 描述 |
|-----------|------|
| `ImageSize` | 图片尺寸，包含 width 和 height |
| `CompressOptions` | 压缩选项，包含 focusAlpha 和 ignoreBy |
| `CompressResult` | 压缩结果，包含成功状态、文件路径、错误信息等 |
| **`CompressCallbacks`** | **压缩回调函数集合接口** `{ onStart?, onSuccess?, onError? }` |
| **`RenameCallback`** | **重命名回调函数类型** `(filePath: string) => string` |
| `CompressionPredicate` | 压缩条件判断接口 |
| `FilterCollection` | 预设过滤器集合接口 |

## 压缩算法说明

本库的压缩算法基于对微信朋友圈压缩策略的逆向分析：

1. **尺寸计算**：根据图片宽高比和尺寸，按照微信的规则计算目标尺寸
2. **质量控制**：根据文件大小动态调整 JPEG 质量参数
3. **格式选择**：智能选择最优的输出格式（JPEG/PNG/WebP）
4. **阈值过滤**：小于阈值的图片直接跳过压缩

### 尺寸规则

- **1:1 到 16:9** - 宽度限制在 720px-1664px 之间
- **9:16 到 1:2** - 高度限制在 1664px
- **长图模式** - 高度限制在 1280px
- **宽图模式** - 宽度限制在 1280px

### 质量规则

- < 150KB: 质量 85%
- 150KB-300KB: 质量 80%
- 300KB-500KB: 质量 75%
- 500KB-1MB: 质量 70%
- 1MB-2MB: 质量 65%
- > 2MB: 质量 60%

## 权限要求

确保您的应用具有以下权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.READ_MEDIA",
      "reason": "需要读取媒体文件进行压缩"
    },
    {
      "name": "ohos.permission.WRITE_MEDIA", 
      "reason": "需要写入压缩后的文件"
    }
  ]
}
```

## 注意事项

1. **线程安全**：压缩操作在后台线程执行，回调在主线程触发
2. **内存管理**：大图片压缩时注意内存使用，建议分批处理
3. **文件路径**：确保输入路径有效，输出目录有写入权限
4. **格式支持**：支持 JPG、PNG、WebP、BMP 格式，输出默认为 JPG
5. **错误处理**：务必处理压缩失败的情况

## 示例项目

项目中的 `entry` 模块包含了完整的使用示例，运行项目即可查看效果。

## 许可证

Apache License 2.0

## 贡献

欢迎提交 Issue 和 Pull Request！

---

基于 [Curzibn/Luban](https://github.com/Curzibn/Luban) 项目改造，感谢原作者的优秀工作。 