import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPreviewController(XFile video) {
  return VideoPlayerController.file(File(video.path));
}
