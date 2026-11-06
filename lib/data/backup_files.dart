import 'package:flutter/services.dart';

/// Android Storage Access Framework：用户选择文件，无广泛存储权限。
class BackupFiles {
  static const channel = MethodChannel('dev.wallehog/backup');
  Future<bool> save(String content) async =>
      await channel.invokeMethod<bool>('save', {
        'content': content,
        'name':
            'wallehog-${DateTime.now().toIso8601String().substring(0, 10)}.json',
      }) ??
      false;
  Future<String?> open() => channel.invokeMethod<String>('open');
}
