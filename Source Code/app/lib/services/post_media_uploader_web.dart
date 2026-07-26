import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Browser-picked files do not have a usable `dart:io` path, so upload their
/// bytes through the Firebase Storage API supported by Flutter Web.
Future<void> uploadPickedFile({
  required Reference ref,
  required XFile file,
  required SettableMetadata metadata,
}) async {
  await ref.putData(await file.readAsBytes(), metadata);
}
