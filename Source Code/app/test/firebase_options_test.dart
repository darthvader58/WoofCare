import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/firebase_options.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('selects the registered iOS Firebase app', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final options = DefaultFirebaseOptions.currentPlatform;

    expect(options.appId, '1:506976961145:ios:9c902046c4a17cb8240aa8');
    expect(options.iosBundleId, 'com.epics.woofcare');
    expect(options.projectId, 'woofcare-a9fac');
  });

  test('keeps the existing Android Firebase app', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final options = DefaultFirebaseOptions.currentPlatform;

    expect(options.appId, '1:506976961145:android:b19e9a2b082f7b95240aa8');
    expect(options.projectId, 'woofcare-a9fac');
  });
}
