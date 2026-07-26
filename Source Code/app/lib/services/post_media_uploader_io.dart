import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads through the native file API so Android and iOS keep streaming media
/// from disk instead of loading large videos into memory.
Future<void> uploadPickedFile({
  required Reference ref,
  required XFile file,
  required SettableMetadata metadata,
}) async {
  await ref.putFile(File(file.path), metadata);
}
