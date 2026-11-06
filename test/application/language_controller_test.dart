import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(LanguageController.channel, null),
  );

  test(
    'missing platform and unknown preference fall back to Chinese',
    () async {
      final unavailable = LanguageController();
      await unavailable.load();
      expect(unavailable.loaded, isTrue);
      expect(unavailable.locale, LanguageController.chinese);
      expect(await unavailable.select(LanguageController.english), isFalse);
      expect(unavailable.locale, LanguageController.chinese);
      unavailable.dispose();
      messenger.setMockMethodCallHandler(
        LanguageController.channel,
        (_) async => 'unsupported',
      );
      final unknown = LanguageController();
      await unknown.load();
      expect(unknown.locale, LanguageController.chinese);
      unknown.dispose();
    },
  );

  test(
    'platform failure leaves language intact and clears saving flag',
    () async {
      messenger.setMockMethodCallHandler(LanguageController.channel, (
        call,
      ) async {
        if (call.method == 'getLanguage') return 'en';
        throw PlatformException(code: 'storage');
      });
      final c = LanguageController();
      await c.load();
      expect(await c.select(LanguageController.chinese), isFalse);
      expect(c.locale, LanguageController.english);
      expect(c.saving, isFalse);
      c.dispose();
    },
  );
}
