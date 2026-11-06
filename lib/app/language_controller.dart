import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A device preference, independent of records and backup contents.
class LanguageController extends ChangeNotifier {
  static const channel = MethodChannel('dev.wallehog/settings');
  static const chinese = Locale('zh', 'CN');
  static const english = Locale('en');
  static const supported = [chinese, english];

  Locale _locale = chinese;
  Locale get locale => _locale;
  bool loaded = false;
  bool saving = false;
  bool saveFailed = false;
  bool _disposed = false;

  Future<void> load() async {
    if (loaded) return;
    try {
      final code = await channel.invokeMethod<String>('getLanguage');
      _locale = code == 'en' ? english : chinese;
    } on PlatformException {
      _locale = chinese;
    } on MissingPluginException {
      _locale = chinese;
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<bool> select(Locale value) async {
    if (_disposed || !loaded || saving || !supported.contains(value)) {
      return false;
    }
    if (_locale == value) {
      saveFailed = false;
      return true;
    }
    saveFailed = false;
    saving = true;
    notifyListeners();
    var saved = false;
    try {
      saved =
          await channel.invokeMethod<bool>(
            'setLanguage',
            value == english ? 'en' : 'zh_CN',
          ) ??
          false;
      if (saved) _locale = value;
    } on PlatformException {
      saved = false;
    } on MissingPluginException {
      saved = false;
    } finally {
      saving = false;
      saveFailed = !saved;
      if (!_disposed) notifyListeners();
    }
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}
