import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { Luban, LubanUtils } from 'library';
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
  @State compressInfo: CompressInfo | null = null
  @State isCompressing: boolean = false
  @State selectedImageUri: string = ''

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

          Button('📱 仅拍照')
            .width('30%')
            .height(50)
            .enabled(!this.isCompressing)
            .backgroundColor('#e67e22')
            .onClick(() => {
              this.takePhotoAndCompress()
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
        if (this.compressInfo) {
          this.buildCompressResultCard()
        }

        // 操作按钮组
        if (this.compressInfo && !this.isCompressing) {
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

              Button('批量压缩演示')
                .width('48%')
                .height(45)
                .type(ButtonType.Normal)
                .backgroundColor('#9b59b6')
                .onClick(() => {
                  this.showBatchCompressExample()
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

        // 使用说明
        this.buildInstructions()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20 })
    }
    .height('100%')
    .width('100%')
  }

  // 构建压缩结果卡片
  @Builder
  buildCompressResultCard() {
    Column() {
      Text('📊 压缩结果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
        .fontColor('#2c3e50')

      // 图片预览
      if (this.selectedImageUri) {
        Image(this.selectedImageUri)
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .margin({ bottom: 15 })
          .backgroundColor('#f8f9fa')
      }

      // 压缩详情
      Column({ space: 10 }) {
        // 图片尺寸
        if (this.compressInfo?.imageWidth && this.compressInfo?.imageHeight) {
          Row() {
            Text('📐 图片尺寸:')
              .fontSize(14)
              .fontColor('#7f8c8d')
              .width('30%')
            Text(`${this.compressInfo.imageWidth} × ${this.compressInfo.imageHeight}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        // 原始大小
        Row() {
          Text('📁 原始大小:')
            .fontSize(14)
            .fontColor('#7f8c8d')
            .width('30%')
          Text(LubanUtils.formatFileSize(this.compressInfo!.originalSize))
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
          Text(LubanUtils.formatFileSize(this.compressInfo!.compressedSize))
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
          Text(`${this.compressInfo!.compressionRatio}%`)
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
          Text(LubanUtils.formatFileSize(this.compressInfo!.originalSize - this.compressInfo!.compressedSize))
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
          Text(this.compressInfo!.compressedPath)
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

  // 构建使用说明
  @Builder
  buildInstructions() {
    Column() {
      Text('📖 使用说明')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 10, top: 20 })
        .fontColor('#2c3e50')

      Column({ space: 8 }) {
        Text('📷 "单图选择" - 从相册选择单张图片或拍照压缩')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🖼️ "多图选择" - 批量选择最多5张图片同时压缩')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('📱 "仅拍照" - 直接拍照并压缩（支持编辑）')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🔍 使用专业的 photoAccessHelper API')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🔄 自动处理相册图片权限限制（复制到缓存）')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🧹 支持临时缓存清理和内存管理')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('✅ 支持 JPG、PNG、WebP 等常见格式和 URI')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#f8f9fa')
    .borderRadius(8)
    .margin({ top: 10 })
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
        
        // 显示第一张图片作为预览
        this.selectedImageUri = selectedImageUris[0];
        
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

  /**
   * 仅拍照并压缩
   */
  private async takePhotoAndCompress() {
    try {
      this.isCompressing = true
      this.clearResult()

      console.log('📷 使用 PhotoHelper 拍照...');
      const photoUri = await PhotoHelper.takePhoto(true);

      if (photoUri) {
        console.log('✅ 拍照成功:', photoUri);
        await this.processImageCompression(photoUri);
      } else {
        console.log('❌ 用户取消了拍照');
        this.isCompressing = false;
      }
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  /**
   * 处理批量图片压缩
   */
  private async processBatchCompression(imageUris: Array<string>) {
    try {
      console.log(`🚀 开始批量压缩 ${imageUris.length} 张图片...`);
      
      let compressedCount = 0;
      let totalOriginalSize = 0;
      let totalCompressedSize = 0;

      // 获取第一张图片的详细信息用于显示
      const firstImageUri = imageUris[0];
      const firstImageOriginalSize = await LubanUtils.getFileSizeInBytes(firstImageUri);
      let imageWidth = 0;
      let imageHeight = 0;

      // 获取第一张图片尺寸
      try {
        const imageSource = image.createImageSource(firstImageUri);
        const imageInfo = await imageSource.getImageInfo();
        imageWidth = imageInfo.size.width;
        imageHeight = imageInfo.size.height;
        console.log(`📐 第一张图片尺寸: ${imageWidth} × ${imageHeight}`);
      } catch (error) {
        console.warn('获取图片信息失败:', error);
      }

      // 执行批量压缩
      await Luban.with(imageUris)
        .ignoreBy(50)
        .setFocusAlpha(false)
        .filter(LubanUtils.FILTERS.EXCLUDE_GIF)
        .onStart(() => {
          console.log(`🚀 批量压缩开始 - 共 ${imageUris.length} 张图片`);
        })
        .onSuccess((filePath: string) => {
          compressedCount++;
          console.log(`✅ 批量压缩进度: ${compressedCount}/${imageUris.length} - ${filePath}`);
          
          // 如果是第一张图片，记录其压缩信息用于显示
          if (compressedCount === 1) {
            const compressedSize = fileIo.statSync(filePath).size;
            const ratio = LubanUtils.calculateCompressionRatio(firstImageOriginalSize, compressedSize);
            
            this.compressInfo = {
              originalPath: firstImageUri,
              compressedPath: filePath,
              originalSize: firstImageOriginalSize,
              compressedSize: compressedSize,
              compressionRatio: ratio,
              imageWidth: imageWidth,
              imageHeight: imageHeight
            };
          }
          
          // 如果全部完成，显示汇总信息
          if (compressedCount === imageUris.length) {
            console.log(`🎉 批量压缩完成! 成功压缩 ${compressedCount} 张图片`);
            this.isCompressing = false;
          }
        })
        .onError((error: Error) => {
          console.error(`❌ 批量压缩失败:`, error.message);
          this.handleCompressError(error);
        })
        .launch();

    } catch (error) {
      this.handleCompressError(error as Error);
    }
  }

  /**
   * 处理图片压缩
   */
  private async processImageCompression(imageUri: string) {
    try {
      this.selectedImageUri = imageUri;
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

      this.compressInfo = {
        originalPath: originalPath,
        compressedPath: compressedFilePath,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        imageWidth: imageWidth,
        imageHeight: imageHeight
      };

      console.log('压缩完成:', this.compressInfo);
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
   * 批量压缩演示
   */
  private showBatchCompressExample() {
    try {
      console.log('🎯 开始批量压缩演示...');

      // 模拟批量图片路径（实际使用时需要真实的图片路径）
      const imagePaths = [
        this.selectedImageUri,// 使用当前选中的图片作为示例
      // 更多图片路径可以添加在这里
      ];

      if (!this.selectedImageUri) {
        console.warn('⚠️ 请先选择一张图片作为批量压缩的示例');
        return;
      }

      // 执行批量压缩 - 新的函数监听器方式
      Luban.with(imagePaths)
        .ignoreBy(30) // 忽略小于 30KB 的文件
        .setFocusAlpha(false)
        .filter(LubanUtils.FILTERS.DEFAULT(50)) // 使用默认过滤器，排除GIF且大于50KB
        .onStart(() => {
          console.log('🚀 批量压缩开始...');
        })
        .onSuccess((filePath: string) => {
          console.log('✅ 批量压缩 - 文件压缩成功:', filePath);
          const fileName = filePath.split('/').pop() || '';
          console.log(`📁 文件名: ${fileName}`);
        })
        .onError((error: Error) => {
          console.error('❌ 批量压缩 - 文件压缩失败:', error.message);
        })
        .launch();

      console.log('📊 批量压缩任务已启动，请查看日志获取详细信息');

    } catch (error) {
      console.error('批量压缩演示失败:', error);
    }
  }

  /**
   * 清除结果
   */
  private clearResult() {
    this.compressInfo = null;
    this.selectedImageUri = '';
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