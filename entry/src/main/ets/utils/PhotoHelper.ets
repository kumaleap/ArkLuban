import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 照片选择工具类
 * 使用 photoAccessHelper API 提供更专业的照片选择功能
 */
export class PhotoHelper {
  // 默认最大选择数量
  private static readonly PHOTO_DEFAULT_SELECT_NUMBER = 9;

  /**
   * 通过选择模式拉起photoPicker界面，用户可以选择一个或多个图片/视频。
   * @param options
   * @returns
   */
  static async select(options?: photoAccessHelper.PhotoSelectOptions): Promise<Array<string>> {
    try {
      if (!options) {
        options = new photoAccessHelper.PhotoSelectOptions();
      }
      if (!options.MIMEType) { //可选择的媒体文件类型，若无此参数，则默认为图片和视频类型。
        options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      }
      if (!options.maxSelectNumber) { //选择媒体文件数量的最大值,默认9
        options.maxSelectNumber = PhotoHelper.PHOTO_DEFAULT_SELECT_NUMBER;
      }
      if (options.isPhotoTakingSupported == undefined) {
        options.isPhotoTakingSupported = true; //支持拍照。
      }
      if (options.isEditSupported == undefined) {
        options.isEditSupported = true; //支持编辑照片。
      }
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        return photoSelectResult.photoUris
      } else {
        return [];
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error(`PhotoHelper-select-异常 ~ code: ${error.code} -·- message: ${error.message}`);
      return [];
    }
  }

  /**
   * 选择单张照片
   * @param supportTaking 是否支持拍照，默认 true
   * @param supportEdit 是否支持编辑，默认 true
   * @returns 返回单个图片 URI，如果没有选择则返回 null
   */
  static async selectSingle(supportTaking: boolean = true, supportEdit: boolean = true): Promise<string | null> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    options.isPhotoTakingSupported = supportTaking;
    options.isEditSupported = supportEdit;

    const uris = await PhotoHelper.select(options);
    return uris.length > 0 ? uris[0] : null;
  }

  /**
   * 选择多张照片
   * @param maxCount 最大选择数量，默认 9
   * @param supportTaking 是否支持拍照，默认 true
   * @param supportEdit 是否支持编辑，默认 true
   * @returns 返回图片 URI 数组
   */
  static async selectMultiple(
    maxCount: number = PhotoHelper.PHOTO_DEFAULT_SELECT_NUMBER,
    supportTaking: boolean = true,
    supportEdit: boolean = true
  ): Promise<Array<string>> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxCount;
    options.isPhotoTakingSupported = supportTaking;
    options.isEditSupported = supportEdit;

    return await PhotoHelper.select(options);
  }

  /**
   * 只拍照，不选择相册
   * @param supportEdit 是否支持编辑，默认 true
   * @returns 返回拍照的图片 URI，如果取消则返回 null
   */
  static async takePhoto(supportEdit: boolean = true): Promise<string | null> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    options.isPhotoTakingSupported = true;
    options.isEditSupported = supportEdit;
    // 注意：这里仍然会显示相册选择界面，但用户可以选择拍照

    const uris = await PhotoHelper.select(options);
    return uris.length > 0 ? uris[0] : null;
  }

  /**
   * 选择图片和视频
   * @param maxCount 最大选择数量，默认 9
   * @param supportTaking 是否支持拍照，默认 true
   * @param supportEdit 是否支持编辑，默认 true
   * @returns 返回媒体文件 URI 数组
   */
  static async selectMedia(
    maxCount: number = PhotoHelper.PHOTO_DEFAULT_SELECT_NUMBER,
    supportTaking: boolean = true,
    supportEdit: boolean = true
  ): Promise<Array<string>> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE;
    options.maxSelectNumber = maxCount;
    options.isPhotoTakingSupported = supportTaking;
    options.isEditSupported = supportEdit;

    return await PhotoHelper.select(options);
  }
} 