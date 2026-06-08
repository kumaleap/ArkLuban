/**
 * 图片加载与 EXIF 方向处理。
 */

import { image } from '@kit.ImageKit';
import { CompressionTarget } from './LubanTypes';
import { LogUtil } from './LogUtil';

export interface ImageOrientationTransform {
  rotateDegrees: number;
  flipHorizontal: boolean;
  flipVertical: boolean;
}

export interface LoadedImageData {
  pixelMap: image.PixelMap;
  imageInfo: image.ImageInfo;
  orientation: string;
}

export class ImageLoader {
  private static readonly TAG = 'ImageLoader';

  static async load(
    imageSource: image.ImageSource,
    target: CompressionTarget,
    sourceInfo?: image.ImageInfo
  ): Promise<LoadedImageData> {
    const imageInfo = sourceInfo !== undefined ? sourceInfo : await imageSource.getImageInfo();
    const orientation = await ImageLoader.getOrientation(imageSource);

    const decodingOptions: image.DecodingOptions = {
      desiredSize: {
        width: target.width,
        height: target.height
      },
      desiredRegion: {
        x: 0,
        y: 0,
        size: {
          width: imageInfo.size.width,
          height: imageInfo.size.height
        }
      },
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    };

    const pixelMap = await imageSource.createPixelMap(decodingOptions);
    await ImageLoader.applyOrientation(pixelMap, orientation);

    return {
      pixelMap: pixelMap,
      imageInfo: imageInfo,
      orientation: orientation
    };
  }

  static async getImageInfo(imageSource: image.ImageSource): Promise<image.ImageInfo> {
    return await imageSource.getImageInfo();
  }

  private static async getOrientation(imageSource: image.ImageSource): Promise<string> {
    try {
      return await imageSource.getImageProperty(image.PropertyKey.ORIENTATION);
    } catch (error) {
      return 'Top-left';
    }
  }

  private static async applyOrientation(pixelMap: image.PixelMap, orientation: string): Promise<void> {
    const transform = ImageLoader.getOrientationTransform(orientation);

    if (transform.flipHorizontal || transform.flipVertical) {
      await pixelMap.flip(transform.flipHorizontal, transform.flipVertical);
    }

    if (transform.rotateDegrees !== 0) {
      await pixelMap.rotate(transform.rotateDegrees);
    }
  }

  private static getOrientationTransform(orientation: string): ImageOrientationTransform {
    if (orientation === 'Top-right' || orientation === '2') {
      return ImageLoader.createTransform(0, true, false);
    }

    if (orientation === 'Bottom-right' || orientation === '3') {
      return ImageLoader.createTransform(180, false, false);
    }

    if (orientation === 'Bottom-left' || orientation === '4') {
      return ImageLoader.createTransform(0, false, true);
    }

    if (orientation === 'Left-top' || orientation === '5') {
      return ImageLoader.createTransform(270, true, false);
    }

    if (orientation === 'Right-top' || orientation === '6') {
      return ImageLoader.createTransform(90, false, false);
    }

    if (orientation === 'Right-bottom' || orientation === '7') {
      return ImageLoader.createTransform(90, true, false);
    }

    if (orientation === 'Left-bottom' || orientation === '8') {
      return ImageLoader.createTransform(270, false, false);
    }

    if (orientation !== 'Top-left' && orientation !== '1') {
      LogUtil.warn(ImageLoader.TAG, `未知 EXIF 方向: ${orientation}`);
    }

    return ImageLoader.createTransform(0, false, false);
  }

  private static createTransform(
    rotateDegrees: number,
    flipHorizontal: boolean,
    flipVertical: boolean
  ): ImageOrientationTransform {
    return {
      rotateDegrees: rotateDegrees,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical
    };
  }
}
