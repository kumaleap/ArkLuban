import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { Luban, LubanUtils } from 'library';

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
          Button('📷 拍照')
            .width('45%')
            .height(50)
            .enabled(!this.isCompressing)
            .backgroundColor('#3498db')
            .onClick(() => {
              this.takePhotoAndCompress()
            })

          Button('🖼️ 选择相册')
            .width('45%')
            .height(50)
            .enabled(!this.isCompressing)
            .backgroundColor('#27ae60')
            .onClick(() => {
              this.selectFromGalleryAndCompress()
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
        Text('📷 点击"拍照"按钮拍摄新照片并压缩')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🖼️ 点击"选择相册"从相册选择图片压缩')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('🔍 压缩算法基于微信朋友圈压缩策略')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('📊 实时显示压缩前后大小对比和节省空间')
          .fontSize(13)
          .fontColor('#7f8c8d')
          .lineHeight(20)
        Text('✅ 支持 JPG、PNG、WebP 等常见格式')
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
   * 拍照并压缩
   */
  private async takePhotoAndCompress() {
    try {
      this.isCompressing = true
      this.clearResult()

      // 创建相机拍照选择器
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult.photoUris.length > 0) {
        const selectedImageUri = photoSelectResult.photoUris[0];
        await this.processImageCompression(selectedImageUri);
      } else {
        this.isCompressing = false;
      }
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  /**
   * 从相册选择并压缩
   */
  private async selectFromGalleryAndCompress() {
    try {
      this.isCompressing = true
      this.clearResult()

      // 创建图片选择器
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult.photoUris.length > 0) {
        const selectedImageUri = photoSelectResult.photoUris[0];
        await this.processImageCompression(selectedImageUri);
      } else {
        this.isCompressing = false;
      }
    } catch (error) {
      this.handleCompressError(error as Error)
    }
  }

  /**
   * 处理图片压缩
   */
  private async processImageCompression(imageUri: string) {
    try {
      this.selectedImageUri = imageUri;

      // 获取原图信息
      const originalSize = fileIo.statSync(imageUri).size;
      let imageWidth = 0;
      let imageHeight = 0;

      // 获取图片尺寸
      try {
        const imageSource = image.createImageSource(imageUri);
        const imageInfo = await imageSource.getImageInfo();
        imageWidth = imageInfo.size.width;
        imageHeight = imageInfo.size.height;
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
}