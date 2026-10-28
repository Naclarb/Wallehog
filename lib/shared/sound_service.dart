import 'package:flutter/services.dart';

/// 音效与记录、动画互不依赖；平台不可用时静默降级。
class SoundService {
  static const _channel = MethodChannel('dev.wallehog/sound');

  static Future<bool> enabled() async {
    try {
      return await _channel.invokeMethod<bool>('enabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setEnabled(bool value) async {
    try {
      return await _channel.invokeMethod<bool>('setEnabled', value) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> play(String event) async {
    try {
      await _channel.invokeMethod<void>('play', event);
    } catch (_) {
      /* 音效失败不影响记录。 */
    }
  }
}
