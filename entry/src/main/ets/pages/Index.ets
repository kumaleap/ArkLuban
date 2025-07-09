import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { Luban, LubanUtils } from 'arkluban';
import { PhotoHelper } from '../utils/PhotoHelper';

interface CompressInfo {
  originalPath: string;
  compressedPath: string;
  originalSize: number;
  compressedSize: number;
  compressionRatio: number;
  imageWidth?: number;
  imageHeight?: number;
}

@Entry
@Component
struct Index {
  @State message: string = 'Luban 图片压缩演示'
  @State isCompressing: boolean = false
  @State cardList: CompressInfo[] = []

  build() {
    Scroll() {
      Column() {
        // 标题
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
          .fontColor('#2c3e50')

        // 操作按钮组
        Row({ space: 12 }) {
          Button('📷 单图选择')
            .width('30%')
            .height(50)
            .enabled(!this.isCompressing)
            .backgroundColor('#3498db')
            .onClick(() => {
              this.selectSingleImageAndCompress()
            })

          Button('🖼️ 多图选择')
            .width('30%')
            .height(50)
            .enabled(!this.isCompressing)
            .backgroundColor('#27ae60')
            .onClick(() => {
              this.selectMultipleImagesAndCompress()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ bottom: 20 })

        // 加载状态
        if (this.isCompressing) {
          Row() {
            LoadingProgress()
              .width(30)
              .height(30)
              .margin({ right: 10 })
            Text('压缩处理中...')
              .fontSize(16)
              .fontColor('#3498db')
          }
          .margin({ bottom: 20 })
        }

        // 图片预览和压缩结果
        if (this.cardList.length > 0) {
          ForEach(this.cardList, (item: CompressInfo, index) => {
            this.buildCompressResultCard(item)
          })
        }

        // 操作按钮组
        if (this.cardList.length > 0 && !this.isCompressing) {
          Column({ space: 10 }) {
            Row({ space: 12 }) {
              Button('清除结果')
                .width('48%')
                .height(45)
                .type(ButtonType.Normal)
                .backgroundColor('#e74c3c')
                .onClick(() => {
                  this.clearResult()
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            // 缓存管理按钮
            Button('🧹 清理临时缓存')
              .width('100%')
              .height(40)
              .type(ButtonType.Normal)
              .backgroundColor('#95a5a6')
              .onClick(() => {
                this.cleanTempCache()
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20 })
    }
    .height('100%')
    .width('100%')
  }

  // 构建压缩结果卡片
  @Builder
  buildCompressResultCard(item: CompressInfo) {
    Column() {
      Text('📊 压缩结果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
        .fontColor('#2c3e50')

      // 图片预览
      Image(item!.originalPath)
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Contain)
        .borderRadius(8)
        .margin({ bottom: 15 })
        .backgroundColor('#f8f9fa')

      // 压缩详情
      Column({ space: 10 }) {
        // 原始大小
        Row() {
          Text('📁 原始大小:')
            .fontSize(14)
            .fontColor('#7f8c8d')
            .width('30%')
          Text(LubanUtils.formatFileSize(item!.originalSize))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#e74c3c')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 压缩后大小
        Row() {
          Text('📦 压缩后:')
            .fontSize(14)
            .fontColor('#7f8c8d')
            .width('30%')
          Text(LubanUtils.formatFileSize(item!.compressedSize))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#27ae60')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 压缩比
        Row() {
          Text('📊 压缩比:')
            .fontSize(14)
            .fontColor('#7f8c8d')
            .width('30%')
          Text(`${item!.compressionRatio}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#f39c12')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 节省空间
        Row() {
          Text('💾 节省空间:')
            .fontSize(14)
            .fontColor('#7f8c8d')
            .width('30%')
          Text(LubanUtils.formatFileSize(item!.originalSize - item!.compressedSize))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#9b59b6')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 文件路径
        Divider().margin({ top: 10, bottom: 10 })

        Column({ space: 5 }) {
          Text('📍 压缩后路径:')
            .fontSize(12)
            .fontColor('#7f8c8d')
            .alignSelf(ItemAlign.Start)
          Text(item!.compressedPath)
            .fontSize(11)
            .fontColor('#34495e')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(2)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(15)
    }
    .width('100%')
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#e0e0e0',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ bottom: 20 })
    .padding(16)
  }

  /**
   * 选择单张图片并压缩
   */
  private async selectSingleImageAndCompress() {
    try {
      this.isCompressing = true
      this.clearResult()

      console.log('🔍 使用 PhotoHelper 选择单张图片...');
      const selectedImageUri = await PhotoHelper.selectSingle(true, true);

      if (selectedImageUri) {
        console.log('✅ 选择了图片:', selectedImageUri);
        await this.processImageCompression(selectedImageUri);
      } else {
        console.log('❌ 用户取消了选择');
        this.isCompressing = false;
      }
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  /**
   * 选择多张图片并批量压缩
   */
  private async selectMultipleImagesAndCompress() {
    try {
      this.isCompressing = true
      this.clearResult()
      console.log('🔍 使用 PhotoHelper 选择多张图片...');
      const selectedImageUris = await PhotoHelper.selectMultiple(5, true, true);

      if (selectedImageUris.length > 0) {
        console.log(`✅ 选择了 ${selectedImageUris.length} 张图片:`, selectedImageUris);

        // 执行批量压缩
        await this.processBatchCompression(selectedImageUris);
      } else {
        console.log('❌ 用户取消了选择');
        this.isCompressing = false;
      }
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  private async displayBatchResult(imageUris: Array<string>, index: number, filePath: string) {
    try {
      const firstImageUri = imageUris[index];
      const firstImageOriginalSize = await LubanUtils.getFileSizeInBytes(firstImageUri);
      const compressedSize = fileIo.statSync(filePath).size;
      const ratio = LubanUtils.calculateCompressionRatio(firstImageOriginalSize, compressedSize);
      this.cardList.push({
        originalPath: firstImageUri,
        compressedPath: filePath,
        originalSize: firstImageOriginalSize,
        compressedSize: compressedSize,
        compressionRatio: ratio,
        imageWidth: 0,
        imageHeight: 0
      })
    } catch (error) {
      console.error("displayBatchResult error", error)
    }
  }

  /**
   * 处理批量图片压缩
   */
  private async processBatchCompression(imageUris: Array<string>) {
    try {
      let index = 0;
      // 执行批量压缩
      await Luban.with(imageUris)
        .ignoreBy(50)
        .setFocusAlpha(false)
        .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
        .onStart(() => {
          console.log(`🚀 批量压缩开始 - 共 ${imageUris.length} 张图片`);
        })
        .onSuccess((filePath: string) => {
          this.displayBatchResult(imageUris, index, filePath)
          index++
        })
        .onError((error: Error) => {
          index++
          console.error(`❌ 批量压缩失败:`, error.message);
          this.handleCompressError(error);
        })
        .launch();
      this.isCompressing = false;
    } catch (error) {
      this.isCompressing = false;
      this.handleCompressError(error as Error);
    }
  }

  /**
   * 处理图片压缩
   */
  private async processImageCompression(imageUri: string) {
    try {
      console.log('🔄 开始处理图片 URI:', imageUri);
      // 测试 URI 处理功能
      const testResult = LubanUtils.testUriHandling(imageUri);
      console.log('🧪 URI 测试结果:', testResult);

      // 获取原图信息
      const originalSize = await LubanUtils.getFileSizeInBytes(imageUri);
      let imageWidth = 0;
      let imageHeight = 0;

      // 获取图片尺寸 - 直接使用 URI，因为 image API 可以处理 file:// URI
      try {
        const imageSource = image.createImageSource(imageUri);
        const imageInfo = await imageSource.getImageInfo();
        imageWidth = imageInfo.size.width;
        imageHeight = imageInfo.size.height;
        console.log(`📐 图片尺寸: ${imageWidth} × ${imageHeight}`);
      } catch (error) {
        console.warn('获取图片信息失败:', error);
      }

      // 使用 Luban 压缩图片 - 新的函数监听器方式
      await Luban.with(imageUri)
        .ignoreBy(50) // 忽略小于 50KB 的文件
        .setFocusAlpha(false) // 不保留透明通道
        .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
        .onStart(() => {
          console.log('🚀 开始压缩图片...');
          console.log(`📐 原图尺寸: ${imageWidth} × ${imageHeight}`);
          console.log(`📁 原图大小: ${LubanUtils.formatFileSize(originalSize)}`);
          // UI 状态已经在外层设置了 isCompressing = true
        })
        .onSuccess((filePath: string) => {
          console.log('✅ 压缩成功:', filePath);
          const compressedSize = fileIo.statSync(filePath).size;
          const ratio = LubanUtils.calculateCompressionRatio(originalSize, compressedSize);
          console.log(`📦 压缩后大小: ${LubanUtils.formatFileSize(compressedSize)}`);
          console.log(`📊 压缩比: ${ratio}%`);
          console.log(`💾 节省空间: ${LubanUtils.formatFileSize(originalSize - compressedSize)}`);
          this.handleCompressSuccess(imageUri, filePath, originalSize, imageWidth, imageHeight);
        })
        .onError((error: Error) => {
          console.error('❌ 压缩失败:', error.message);
          this.handleCompressError(error);
        })
        .launch();
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  /**
   * 处理压缩成功
   */
  private handleCompressSuccess(
    originalPath: string,
    compressedFilePath: string,
    originalSize: number,
    imageWidth?: number,
    imageHeight?: number
  ) {
    try {
      const compressedSize = fileIo.statSync(compressedFilePath).size;
      const compressionRatio = LubanUtils.calculateCompressionRatio(originalSize, compressedSize);

      this.cardList.push({
        originalPath: originalPath,
        compressedPath: compressedFilePath,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        imageWidth: imageWidth,
        imageHeight: imageHeight
      });
    } catch (error) {
      this.handleCompressError(new Error(`压缩成功，但获取文件信息失败: ${error.message}`));
    } finally {
      this.isCompressing = false;
    }
  }

  /**
   * 处理压缩错误
   */
  private handleCompressError(error: Error) {
    console.error('压缩失败:', error);
    this.isCompressing = false;
    // 可以在这里显示错误提示
    // 或者设置一个错误状态
  }

  /**
   * 清除结果
   */
  private clearResult() {
    this.cardList = [];
    this.isCompressing = false;
  }

  /**
   * 清理临时缓存文件
   */
  private cleanTempCache() {
    try {
      console.log('🧹 开始清理临时缓存...');
      const cleanedCount = LubanUtils.cleanTempCache();
      console.log(`✅ 清理完成，删除了 ${cleanedCount} 个临时文件`);

      // 可以在这里显示一个简单的提示（如果需要的话）
      if (cleanedCount > 0) {
        console.log(`🎉 成功清理 ${cleanedCount} 个临时文件`);
      } else {
        console.log('📁 临时缓存目录为空，无需清理');
      }
    } catch (error) {
      console.error('❌ 清理临时缓存失败:', error);
    }
  }
}