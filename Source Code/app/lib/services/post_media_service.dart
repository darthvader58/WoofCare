import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'post_media_uploader_io.dart'
    if (dart.library.js_interop) 'post_media_uploader_web.dart'
    as media_uploader;

class PostMediaUploadException implements Exception {
  final String message;

  const PostMediaUploadException(this.message);

  @override
  String toString() => message;
}

class VideoUploadMetadata {
  final String extension;
  final String contentType;

  const VideoUploadMetadata({
    required this.extension,
    required this.contentType,
  });
}

class PostMediaService {
  static const int maxImagesPerPost = 6;
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxVideoBytes = 100 * 1024 * 1024;

  static const Map<String, String> _videoMimeByExtension = {
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
    '3gp': 'video/3gpp',
    '3g2': 'video/3gpp2',
    'avi': 'video/x-msvideo',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
  };

  static const Map<String, String> _videoExtensionByMime = {
    'video/mp4': 'mp4',
    'video/quicktime': 'mov',
    'video/x-quicktime': 'mov',
    'video/x-m4v': 'm4v',
    'video/3gpp': '3gp',
    'video/3gpp2': '3g2',
    'video/x-msvideo': 'avi',
    'video/avi': 'avi',
    'video/webm': 'webm',
    'video/x-matroska': 'mkv',
  };

  static final ImagePicker _picker = ImagePicker();

  static Future<List<XFile>> pickImagesFromGallery({
    required int remainingSlots,
  }) async {
    if (remainingSlots <= 0) return [];
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    return picked.take(remainingSlots).toList();
  }

  static Future<XFile?> pickImageFromCamera() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  static Future<XFile?> pickVideoFromGallery() {
    return _picker.pickVideo(source: ImageSource.gallery);
  }

  static Future<XFile?> pickVideoFromCamera() {
    return _picker.pickVideo(source: ImageSource.camera);
  }

  /// Uploads images under posts/{uid}/images/{postId}-{index} and returns
  /// their download URLs in the same order as [images].
  static Future<List<String>> uploadImages({
    required List<XFile> images,
    required String uid,
    required String postId,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final size = await image.length();
      if (size > maxImageBytes) {
        throw const PostMediaUploadException('An image is larger than 10 MB.');
      }

      final ref = FirebaseStorage.instance.ref(
        'posts/$uid/images/$postId-$i.jpg',
      );
      await media_uploader.uploadPickedFile(
        ref: ref,
        file: image,
        metadata: SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  static Future<String> uploadVideo({
    required XFile video,
    required String uid,
    required String postId,
  }) async {
    final size = await video.length();
    if (size > maxVideoBytes) {
      throw const PostMediaUploadException('The video is larger than 100 MB.');
    }

    final metadata = resolveVideoUploadMetadata(
      path: video.path,
      mimeType: video.mimeType,
    );
    final ref = FirebaseStorage.instance.ref(
      'posts/$uid/videos/$postId.${metadata.extension}',
    );
    await media_uploader.uploadPickedFile(
      ref: ref,
      file: video,
      metadata: SettableMetadata(contentType: metadata.contentType),
    );
    return ref.getDownloadURL();
  }

  /// Resolves the actual video container instead of renaming every picked file
  /// to MP4. In particular, iOS commonly returns QuickTime `.mov` files.
  static VideoUploadMetadata resolveVideoUploadMetadata({
    required String path,
    String? mimeType,
  }) {
    final fileName = path.replaceAll('\\', '/').split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final pathExtension = dotIndex > 0 && dotIndex < fileName.length - 1
        ? fileName.substring(dotIndex + 1).toLowerCase()
        : null;

    final extensionMime = pathExtension == null
        ? null
        : _videoMimeByExtension[pathExtension];
    if (pathExtension != null && extensionMime != null) {
      return VideoUploadMetadata(
        extension: pathExtension,
        contentType: extensionMime,
      );
    }

    final normalizedMimeType = mimeType?.split(';').first.trim().toLowerCase();
    final mimeExtension = _videoExtensionByMime[normalizedMimeType];
    if (normalizedMimeType != null && mimeExtension != null) {
      return VideoUploadMetadata(
        extension: mimeExtension,
        contentType: _videoMimeByExtension[mimeExtension]!,
      );
    }

    throw const PostMediaUploadException(
      'This video format is not supported. Choose an MP4, MOV, or M4V video.',
    );
  }
}
