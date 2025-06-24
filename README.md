# 🌟 ArkLuban - 鸿蒙图片压缩库

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-ArkTS-blue.svg)](https://developer.harmonyos.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](https://github.com/your-repo/ArkLuban)

基于著名的 [Luban Android 版本](https://github.com/Curzibn/Luban) 实现的鸿蒙 ArkTS 图片压缩库，完美仿照微信朋友圈的图片压缩算法，为鸿蒙生态提供高效的图片压缩解决方案。

## ✨ 核心特性

- 🚀 **智能压缩算法** - 完美复现微信朋友圈压缩策略，压缩率高达 95%
- 📱 **鸿蒙原生支持** - 100% 使用鸿蒙官方 API，完全兼容 HarmonyOS/OpenHarmony
- ⚡ **高性能异步** - 多线程异步处理，不阻塞 UI 线程
- 🎯 **ArkTS 严格模式** - 完全兼容 ArkTS 严格编译检查，无任何警告
- 🔧 **灵活配置系统** - 支持质量、尺寸、格式等多维度压缩参数
- 📊 **批量处理能力** - 支持单张、批量图片并行压缩
- 🎨 **链式调用 API** - 优雅的函数式编程体验
- 🛡️ **类型安全保障** - 完整的 TypeScript 类型定义

## 📊 压缩效果展示

> 基于微信朋友圈压缩算法，在保证视觉质量的前提下大幅度减小文件体积

| 场景类型 | 原图尺寸与大小 | 压缩后效果 | 压缩率 | 视觉质量 |
|---------|---------------|-----------|-------|----------|
| 📱 手机截屏 (720P) | 720×1280, 390KB | 720×1280, ~90KB | **77%** | 🟢 无损感知 |
| 📱 手机截屏 (1080P) | 1080×1920, 2.21MB | 1080×1920, ~110KB | **95%** | 🟢 无损感知 |
| 📷 相机拍摄 (4:3) | 3096×4128, 3.12MB | 1548×2064, ~150KB | **95%** | 🟢 优秀品质 |
| 📷 相机拍摄 (16:9) | 4128×2322, 4.64MB | 1032×581, ~100KB | **98%** | 🟢 优秀品质 |

## 🚀 快速开始

### 模块引入

将库模块集成到您的鸿蒙项目中：

```typescript
import { 
  Luban, 
  LubanUtils, 
  CompressCallbacks,
  CompressionPredicate,
  RenameCallback
} from 'library'
```

### 基础用法示例

#### 🎯 单图片压缩（推荐方式）

```typescript
// 使用现代函数回调 API，完全兼容 ArkTS 严格模式
await Luban.with(imagePath)
  .ignoreBy(100)                    // 忽略小于 100KB 的文件
  .setFocusAlpha(false)            // 不保留透明通道，减小体积
  .setTargetDir('/data/storage/el2/base/cache/compressed')
  .onStart(() => {
    console.log('🚀 开始压缩图片...')
  })
  .onSuccess((filePath: string) => {
    console.log(`✅ 压缩成功: ${filePath}`)
    // 在这里更新UI或进行后续处理
  })
  .onError((error: Error) => {
    console.error(`❌ 压缩失败: ${error.message}`)
  })
  .launch();
```

#### 📦 批量图片压缩

```typescript
// 批量处理多张图片，并行压缩提升效率
await Luban.with([imagePath1, imagePath2, imagePath3])
  .ignoreBy(50)                     // 跳过小于 50KB 的文件
  .setFocusAlpha(false)
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF)  // 过滤掉 GIF 格式
  .onStart(() => {
    console.log('🚀 开始批量压缩...')
  })
  .onSuccess((filePath: string) => {
    console.log(`✅ 单个文件压缩完成: ${filePath}`)
  })
  .onError((error: Error) => {
    console.error(`❌ 文件压缩失败: ${error.message}`)
  })
  .launch();
```

#### ⚡ 同步获取结果

```typescript
// 当需要等待所有文件压缩完成时使用
try {
  const compressedFiles = await Luban.with([imagePath1, imagePath2])
    .ignoreBy(50)
    .setFocusAlpha(true)
    .get();                         // 返回所有压缩后的文件路径
    
  console.log(`✅ 批量压缩完成，共 ${compressedFiles.length} 个文件`);
  // 进行后续处理...
} catch (error) {
  console.error('❌ 压缩过程中发生错误:', error);
}
```

#### 🎨 极简API调用

```typescript
// 最简单的调用方式
await Luban.with(imagePath)
  .onSuccess((filePath: string) => {
    console.log('压缩完成:', filePath);
  })
  .launch();

// 使用静态方法快速压缩
const result = await Luban.compress(sourcePath, targetPath, {
  focusAlpha: false,
  ignoreBy: 100
});

if (result.success) {
  console.log('✅ 快速压缩成功:', result.filePath);
}
```

#### 📱 鸿蒙 URI 处理

ArkLuban 完美支持鸿蒙系统的 `file://` URI 格式：

```typescript
// 从相册选择图片后获得的 URI
const photoUri = 'file://media/Photo/2/IMG_1750751898_001/IMG_001.jpg';

// 直接使用 URI 进行压缩，库会自动处理 URI 转换
await Luban.with(photoUri)
  .onStart(() => console.log('🚀 开始压缩 URI 图片'))
  .onSuccess((filePath: string) => {
    console.log('✅ URI 图片压缩成功:', filePath);
  })
  .onError((error: Error) => {
    console.error('❌ URI 处理失败:', error.message);
  })
  .launch();

// 测试 URI 处理功能
const testResult = LubanUtils.testUriHandling(photoUri);
console.log('🧪 URI 测试:', testResult);
```

## 🔧 高级配置

### 智能过滤系统

ArkLuban 提供多种预设过滤器，让您精确控制哪些文件需要压缩：

#### 🎯 预设过滤器

```typescript
// 📋 排除 GIF 动图（推荐）
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
  .launch();

// 📏 按文件大小过滤
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.MIN_SIZE(500))  // 只压缩大于 500KB 的文件
  .launch();

// 🎨 智能组合过滤器
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.DEFAULT(200))   // 排除GIF + 大于200KB + 仅图片格式
  .launch();

// 🖼️ 仅图片格式
Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.IMAGES_ONLY)
  .launch();
```

#### 🔧 自定义过滤器类

```typescript
// 创建高级自定义过滤器
class HighQualityImageFilter implements CompressionPredicate {
  apply(path: string): boolean {
    const sizeKB = LubanUtils.getFileSizeInKB(path);
    const extension = LubanUtils.getFileExtension(path).toLowerCase();
    
    // 只压缩大于1MB的JPG和PNG文件
    return sizeKB > 1024 && 
           ['jpg', 'jpeg', 'png'].includes(extension);
  }
}

// 使用自定义过滤器
Luban.with(imagePaths)
  .filter(new HighQualityImageFilter())
  .onSuccess((filePath) => console.log(`高质量图片压缩完成: ${filePath}`))
  .launch();
```

### 📝 智能文件命名

ArkLuban 支持灵活的文件重命名策略：

```typescript
// 🕐 时间戳命名策略
Luban.with(imagePaths)
  .onRename((filePath: string): string => {
    const name = LubanUtils.getFileNameWithoutExtension(filePath);
    const timestamp = Date.now();
    return `compressed_${name}_${timestamp}.jpg`;
  })
  .launch();

// 📱 设备相关命名
Luban.with(imagePaths)
  .onRename((filePath: string): string => {
    const deviceInfo = "HarmonyOS_Device";
    return `${deviceInfo}_luban_${Date.now()}.jpg`;
  })
  .launch();

// 🎨 自定义命名规则
Luban.with(imagePaths)
  .setOnRename((filePath: string): string => {
    const originalName = LubanUtils.getFileNameWithoutExtension(filePath);
    const date = new Date().toISOString().slice(0, 10);
    return `${date}_optimized_${originalName}.jpg`;
  })
  .launch();
```

### ⚙️ 详细参数配置

```typescript
await Luban.with(imagePaths)
  .ignoreBy(100)                    // 跳过小于100KB的文件
  .setFocusAlpha(false)            // 不保留透明通道，优化体积
  .setTargetDir('/custom/output/path')  // 自定义输出目录
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
  .onStart(() => console.log('🚀 压缩开始'))
  .onSuccess((filePath) => console.log(`✅ 完成: ${filePath}`))
  .onError((error) => console.error(`❌ 错误: ${error.message}`))
  .onRename((path) => `luban_${Date.now()}.jpg`)
  .launch();
```

## 📚 完整 API 参考

### 🏗️ Luban 核心类

#### 静态方法

| 方法 | 功能说明 | 参数说明 | 返回值 |
|------|---------|----------|-------|
| `Luban.with(paths)` | 创建压缩构建器实例 | `string \| string[]` 图片路径 | `LubanBuilder` |
| `Luban.compress(source, target?, options?)` | 快速压缩单张图片 | 源路径、目标路径、压缩选项 | `Promise<CompressResult>` |

### 🔧 LubanBuilder 构建器

#### 配置方法

| 方法 | 功能 | 参数 | 链式调用 |
|------|------|------|----------|
| `ignoreBy(size)` | 设置文件大小阈值 | `number` KB为单位 | ✅ |
| `setFocusAlpha(focus)` | 是否保留透明通道 | `boolean` | ✅ |
| `setTargetDir(dir)` | 设置输出目录 | `string` 目录路径 | ✅ |
| `filter(predicate)` | 设置过滤条件 | `CompressionPredicate` | ✅ |

#### 回调方法 (推荐使用)

| 方法 | 触发时机 | 回调参数 | 链式调用 |
|------|----------|----------|----------|
| `onStart(callback)` | 压缩开始时 | `() => void` | ✅ |
| `onSuccess(callback)` | 单个文件压缩成功 | `(filePath: string) => void` | ✅ |
| `onError(callback)` | 压缩失败时 | `(error: Error) => void` | ✅ |
| `onRename(callback)` | 生成文件名时 | `(filePath: string) => string` | ✅ |

#### 完整方法名 (可选)

| 方法 | 对应简洁方法 | 使用场景 |
|------|-------------|----------|
| `setOnStart(callback)` | `onStart()` | 需要明确语义时 |
| `setOnSuccess(callback)` | `onSuccess()` | 需要明确语义时 |
| `setOnError(callback)` | `onError()` | 需要明确语义时 |
| `setOnRename(callback)` | `onRename()` | 需要明确语义时 |

#### 执行方法

| 方法 | 功能 | 返回值 | 使用场景 |
|------|------|--------|----------|
| `launch()` | 启动异步压缩 | `Promise<void>` | 只关心压缩过程 |
| `get()` | 同步获取所有结果 | `Promise<string[]>` | 需要获取所有压缩文件路径 |

### 🛠️ LubanUtils 工具类

#### 文件操作方法

| 方法 | 功能说明 | 参数 | 返回值 |
|------|----------|------|--------|
| `isImage(path)` | 检查是否为图片文件 | `string` | `boolean` |
| `getFileExtension(path)` | 获取文件扩展名 | `string` | `string` |
| `getFileSizeInKB(path)` | 获取文件大小 | `string` | `number` (KB) |
| `formatFileSize(bytes)` | 格式化文件大小显示 | `number` | `string` |
| `fileExists(path)` | 检查文件是否存在 | `string` | `boolean` |
| `calculateCompressionRatio(original, compressed)` | 计算压缩比 | `number, number` | `number` (%) |
| `resolveFilePath(uriOrPath)` | **URI路径解析** | `string` | `string` |
| `isUri(path)` | **检查是否为URI** | `string` | `boolean` |
| `testUriHandling(uriOrPath)` | **测试URI处理** | `string` | `string` |

#### 预设过滤器 (FILTERS)

| 过滤器 | 功能描述 | 使用方法 |
|--------|----------|----------|
| `IMAGES_ONLY` | 只处理图片格式文件 | `LubanUtils.FILTERS.IMAGES_ONLY` |
| `EXCLUDE_GIF` | 排除 GIF 动图文件 | `LubanUtils.FILTERS.EXCLUDE_GIF` |
| `MIN_SIZE(kb)` | 只压缩大于指定大小的文件 | `LubanUtils.FILTERS.MIN_SIZE(500)` |
| `DEFAULT(kb)` | 智能组合过滤器 | `LubanUtils.FILTERS.DEFAULT(200)` |

### 🏷️ TypeScript 类型定义

#### 核心接口

| 类型 | 说明 | 属性/签名 |
|------|------|----------|
| `CompressCallbacks` | 压缩回调函数集合 | `{ onStart?, onSuccess?, onError? }` |
| `CompressOptions` | 压缩配置选项 | `{ focusAlpha?, ignoreBy? }` |
| `CompressResult` | 压缩结果 | `{ success, filePath?, error?, originalSize?, compressedSize? }` |
| `ImageSize` | 图片尺寸信息 | `{ width: number, height: number }` |

#### 函数类型

| 类型 | 说明 | 函数签名 |
|------|------|----------|
| `RenameCallback` | 文件重命名回调 | `(filePath: string) => string` |
| `CompressionPredicate` | 压缩条件判断 | `{ apply(path: string): boolean }` |

#### 枚举类型

| 枚举 | 说明 | 可选值 |
|------|------|--------|
| `CompressFormat` | 压缩输出格式 | `JPEG \| PNG \| WEBP` |

## 🧠 智能压缩算法

ArkLuban 基于对微信朋友圈压缩策略的深度逆向分析，实现了高度智能的压缩算法：

### 🎯 核心算法特性

- **🔍 智能尺寸计算** - 根据图片宽高比和尺寸，精确按照微信规则计算目标尺寸
- **⚖️ 动态质量控制** - 根据文件大小动态调整 JPEG 质量参数，平衡体积与画质
- **🎨 格式智能选择** - 自动选择最优输出格式（JPEG/PNG/WebP）
- **🚫 智能阈值过滤** - 小文件直接跳过压缩，避免无意义处理

### 📐 尺寸压缩规则

| 图片比例范围 | 压缩策略 | 目标尺寸 |
|-------------|----------|----------|
| **1:1 到 16:9** | 宽度限制压缩 | 720px - 1664px 宽度 |
| **9:16 到 1:2** | 高度限制压缩 | 1664px 高度 |
| **长图模式** | 高度优先压缩 | 最大 1280px 高度 |
| **宽图模式** | 宽度优先压缩 | 最大 1280px 宽度 |

### 🎚️ 动态质量策略

| 文件大小范围 | JPEG 质量 | 压缩程度 | 适用场景 |
|-------------|-----------|----------|----------|
| **< 150KB** | 85% | 轻度压缩 | 小图片保持高质量 |
| **150KB - 300KB** | 80% | 中度压缩 | 平衡质量与大小 |
| **300KB - 500KB** | 75% | 中度压缩 | 日常分享图片 |
| **500KB - 1MB** | 70% | 强度压缩 | 高分辨率图片 |
| **1MB - 2MB** | 65% | 强度压缩 | 相机原图 |
| **> 2MB** | 60% | 最大压缩 | 超大图片处理 |

## ⚡ 性能特性

- **🚀 异步多线程** - 利用鸿蒙多核处理能力，不阻塞UI线程
- **📦 批量并行处理** - 支持多图片同时压缩，显著提升效率
- **💾 内存优化** - 智能内存管理，避免大图片导致的内存溢出
- **🔄 增量处理** - 支持断点续压，大批量处理更稳定

## 📋 环境要求

### 鸿蒙系统要求

- **HarmonyOS**: 3.1.0 (API 9) 及以上
- **OpenHarmony**: 3.2.0 及以上
- **DevEco Studio**: 4.0 及以上

### 必需权限配置

在 `module.json5` 中添加以下权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.READ_MEDIA",
      "reason": "$string:read_media_reason",
      "usedScene": {
        "abilities": ["EntryAbility"],
        "when": "inuse"
      }
    },
    {
      "name": "ohos.permission.WRITE_MEDIA", 
      "reason": "$string:write_media_reason",
      "usedScene": {
        "abilities": ["EntryAbility"],
        "when": "inuse"
      }
    }
  ]
}
```

## ⚠️ 重要提示

### 开发注意事项

1. **🔐 线程安全** - 压缩操作在后台线程执行，回调确保在主线程触发
2. **💾 内存管控** - 大图片批量压缩时建议分批处理，避免内存压力
3. **📁 路径权限** - 确保输入路径有效，输出目录具有写入权限
4. **🎨 格式支持** - 支持 JPG、PNG、WebP、BMP 输入，默认输出 JPEG
5. **🛡️ 异常处理** - 必须正确处理压缩失败情况，保证应用稳定性

### 最佳实践建议

- ✅ 使用函数回调方式，完全兼容 ArkTS 严格模式
- ✅ 合理设置 `ignoreBy` 阈值，避免压缩小文件
- ✅ 利用预设过滤器，提高处理效率
- ✅ 批量处理时监控内存使用情况
- ✅ 在生产环境中充分测试各种图片格式

## 🎮 演示项目

项目中的 `entry` 模块提供了完整的使用示例：

- 📷 **拍照压缩演示** - 集成相机API，实时压缩展示
- 🖼️ **相册选择压缩** - 从相册选择图片进行压缩
- 📊 **压缩效果对比** - 直观展示压缩前后的大小变化
- 🔧 **参数调节界面** - 动态调整压缩参数查看效果

运行演示项目即可体验完整功能。

## 📄 开源协议

本项目采用 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目！

---

**💡 让您的鸿蒙应用拥有微信级别的图片压缩体验！**

---

<small>基于 [Curzibn/Luban](https://github.com/Curzibn/Luban) 项目改造，感谢原作者的优秀工作。</small> 