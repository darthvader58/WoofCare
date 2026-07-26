import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/services/post_media_service.dart';

void main() {
  group('PostMediaService.resolveVideoUploadMetadata', () {
    test('preserves an iPhone QuickTime MOV container', () {
      final metadata = PostMediaService.resolveVideoUploadMetadata(
        path: '/private/var/mobile/Containers/Data/clip.MOV',
      );

      expect(metadata.extension, 'mov');
      expect(metadata.contentType, 'video/quicktime');
    });

    test('keeps MP4 uploads as MP4', () {
      final metadata = PostMediaService.resolveVideoUploadMetadata(
        path: '/tmp/clip.mp4',
        mimeType: 'video/mp4',
      );

      expect(metadata.extension, 'mp4');
      expect(metadata.contentType, 'video/mp4');
    });

    test(
      'uses a picker MIME type when the temporary path has no extension',
      () {
        final metadata = PostMediaService.resolveVideoUploadMetadata(
          path: '/tmp/picked-video',
          mimeType: 'video/quicktime; charset=binary',
        );

        expect(metadata.extension, 'mov');
        expect(metadata.contentType, 'video/quicktime');
      },
    );

    test(
      'prefers a recognized container extension over conflicting metadata',
      () {
        final metadata = PostMediaService.resolveVideoUploadMetadata(
          path: r'C:\picker\camera.mov',
          mimeType: 'video/mp4',
        );

        expect(metadata.extension, 'mov');
        expect(metadata.contentType, 'video/quicktime');
      },
    );

    test('rejects an unknown container instead of mislabeling it as MP4', () {
      expect(
        () => PostMediaService.resolveVideoUploadMetadata(
          path: '/tmp/video.unknown',
          mimeType: 'application/octet-stream',
        ),
        throwsA(isA<PostMediaUploadException>()),
      );
    });
  });
}
