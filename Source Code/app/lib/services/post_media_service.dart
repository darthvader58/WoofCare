import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PostMediaUploadException implements Exception {
  final String message;

  const PostMediaUploadException(this.message);

  @override
  String toString() => message;
}

class PostMediaService {
  static const int maxImagesPerPost = 6;
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxVideoBytes = 100 * 1024 * 1024;

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
      final file = File(images[i].path);
      final size = await file.length();
      if (size > maxImageBytes) {
        throw const PostMediaUploadException('An image is larger than 10 MB.');
      }

      final ref = FirebaseStorage.instance.ref(
        'posts/$uid/images/$postId-$i.jpg',
      );
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  static Future<String> uploadVideo({
    required XFile video,
    required String uid,
    required String postId,
  }) async {
    final file = File(video.path);
    final size = await file.length();
    if (size > maxVideoBytes) {
      throw const PostMediaUploadException('The video is larger than 100 MB.');
    }

    final ref = FirebaseStorage.instance.ref('posts/$uid/videos/$postId.mp4');
    await ref.putFile(file, SettableMetadata(contentType: 'video/mp4'));
    return ref.getDownloadURL();
  }
}
