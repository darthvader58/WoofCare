import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woofcare/services/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalStorage.get crashes with null-check error when key is missing',
      () async {
    SharedPreferences.setMockInitialValues({});
    // Spec: helper should fall back to the provided default value.
    // Actual: `result!.isEmpty` on a null result throws.
    await expectLater(
      LocalStorage.get('missing-key', '{"fallback": true}'),
      throwsA(isA<TypeError>()),
    );
  });

  test('LocalStorage.get returns stored JSON when key exists', () async {
    SharedPreferences.setMockInitialValues({'k': '{"a": 1}'});
    final result = await LocalStorage.get('k', '{}');
    expect(result, {'a': 1});
  });
}
