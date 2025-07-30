# ArkLuban 使用示例

ArkLuban 是一个基于微信朋友圈压缩算法的鸿蒙图片压缩库，提供高效、简单的图片压缩功能。

## 安装

```bash
ohpm install @ark/luban
```

## 导入

```typescript
import { Luban, LubanUtils } from '@ark/luban';
```

## 基本使用

### 1. 单张图片压缩

```typescript
// 最简单的使用方式
await Luban.with('/path/to/image.jpg')
  .launch();

// 带回调的压缩
Luban.with('/path/to/image.jpg')
  .onSuccess((filePath) => {
    console.log('压缩成功:', filePath);
  })
  .onError((error) => {
    console.error('压缩失败:', error);
  })
  .launch();
```

### 2. 批量图片压缩

```typescript
const imagePaths = [
  '/path/to/image1.jpg',
  '/path/to/image2.png',
  '/path/to/image3.webp'
];

await Luban.with(imagePaths)
  .ignoreBy(100) // 忽略小于100KB的图片
  .onStart(() => console.log('开始批量压缩...'))
  .onSuccess((filePath) => console.log('压缩完成:', filePath))
  .launch();
```

### 3. 获取压缩结果

```typescript
// 同步获取压缩后的文件路径
const compressedFiles = await Luban.with('/path/to/image.jpg')
  .ignoreBy(50)
  .get();

console.log('压缩后的文件:', compressedFiles);
```

## 高级配置

### 1. 设置压缩参数

```typescript
await Luban.with('/path/to/image.jpg')
  .ignoreBy(200)                    // 忽略小于200KB的图片
  .setFocusAlpha(true)              // 保留透明通道
  .setTargetDir('/custom/output')   // 自定义输出目录
  .launch();
```

### 2. 使用过滤器

```typescript
// 使用预设过滤器
await Luban.with(imagePaths)
  .filter(LubanUtils.FILTERS.EXCLUDE_GIF)  // 排除GIF文件
  .launch();

// 自定义过滤器
await Luban.with(imagePaths)
  .filter((path) => {
    // 只压缩JPEG图片且大于500KB的文件
    const isJpeg = path.toLowerCase().includes('.jpg');
    const sizeKB = LubanUtils.getFileSizeInKBSync(path);
    return isJpeg && sizeKB > 500;
  })
  .launch();
```

### 3. 自定义文件命名

```typescript
await Luban.with('/path/to/image.jpg')
  .onRename((originalPath) => {
    const timestamp = Date.now();
    const fileName = originalPath.split('/').pop();
    const nameWithoutExt = fileName?.split('.')[0];
    return `compressed_${nameWithoutExt}_${timestamp}.jpg`;
  })
  .launch();
```

## 完整示例

```typescript
import { Luban, LubanUtils } from '@ark/luban';

export class ImageCompressionExample {
  
  /**
   * 压缩相册选择的图片
   */
  static async compressSelectedImages(imageUris: string[]) {
    try {
      let processedCount = 0;
      const total = imageUris.length;

      await Luban.with(imageUris)
        .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
        .ignoreBy(100)
        .setFocusAlpha(false)
        .onStart(() => {
          console.log(`开始压缩 ${total} 张图片`);
        })
        .onSuccess((filePath) => {
          processedCount++;
          const progress = Math.round((processedCount / total) * 100);
          console.log(`压缩进度: ${progress}% - 完成: ${filePath}`);
        })
        .onError((error) => {
          console.error('压缩失败:', error);
        })
        .launch();

      console.log('所有图片压缩完成');
    } catch (error) {
      console.error('压缩过程出错:', error);
    }
  }

  /**
   * 获取压缩统计信息
   */
  static async getCompressionStats(imagePaths: string[]) {
    try {
      const results = await Luban.with(imagePaths)
        .ignoreBy(50)
        .get();

      // 计算压缩统计
      let totalOriginalSize = 0;
      let totalCompressedSize = 0;

      for (let i = 0; i < imagePaths.length; i++) {
        const originalSize = await LubanUtils.getFileSizeInBytes(imagePaths[i]);
        const compressedSize = LubanUtils.getFileSizeInKBSync(results[i]) * 1024;
        
        totalOriginalSize += originalSize;
        totalCompressedSize += compressedSize;
      }

      const compressionRatio = LubanUtils.calculateCompressionRatio(
        totalOriginalSize, 
        totalCompressedSize
      );

      console.log(`压缩统计:`);
      console.log(`原始总大小: ${LubanUtils.formatFileSize(totalOriginalSize)}`);
      console.log(`压缩后总大小: ${LubanUtils.formatFileSize(totalCompressedSize)}`);
      console.log(`压缩率: ${compressionRatio}%`);
      console.log(`节省空间: ${LubanUtils.formatFileSize(totalOriginalSize - totalCompressedSize)}`);

      return {
        originalSize: totalOriginalSize,
        compressedSize: totalCompressedSize,
        compressionRatio: compressionRatio,
        savedSize: totalOriginalSize - totalCompressedSize
      };
    } catch (error) {
      console.error('获取压缩统计失败:', error);
      return null;
    }
  }
}
```

## 工具函数

```typescript
// 检查文件是否为图片
const isImage = LubanUtils.isImage('/path/to/file.jpg');

// 获取文件大小
const sizeKB = await LubanUtils.getFileSizeInKB('/path/to/file.jpg');

// 格式化文件大小
const formattedSize = LubanUtils.formatFileSize(1024000); // "1000 KB"

// 计算压缩比
const ratio = LubanUtils.calculateCompressionRatio(2048000, 512000); // 75%

// 清理临时缓存
const cleanedCount = LubanUtils.cleanTempCache();
```

## 支持的图片格式

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- BMP (.bmp)
- GIF (.gif) - 可通过过滤器排除

## 注意事项

1. **URI 支持**: 库自动处理 `file://`、`content://` 等 URI 格式
2. **权限处理**: 自动处理相册图片的权限限制，复制到临时目录
3. **内存管理**: 自动释放图片处理过程中的资源
4. **并发控制**: 批量压缩时自动控制并发数量，避免内存溢出
5. **错误处理**: 提供详细的错误信息和回调

## 性能建议

- 对于大批量图片，建议设置合理的 `ignoreBy` 阈值
- 使用过滤器排除不需要压缩的文件类型
- 定期调用 `LubanUtils.cleanTempCache()` 清理临时文件
- 在压缩完成后及时处理结果文件

## 更多信息

- [GitHub 仓库](https://github.com/kumaleap/ArkLuban)
- [API 文档](../README.md)
- [更新日志](../CHANGELOG.md)
