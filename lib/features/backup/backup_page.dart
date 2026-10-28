import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../application/records_controller.dart';
import '../../data/backup_files.dart';
import '../../domain/backup.dart';
import '../../domain/expression_parser.dart';
import '../../domain/saving_record.dart';
import '../../shared/recovery_notice.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.controller});
  final RecordsController controller;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _files = BackupFiles();
  bool _busy = false;
  bool _committed = false;
  String? _message;
  SavingsBackup? _preview;

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is RuleViolation
              ? e.message
              : e is PlatformException
              ? (e.message ?? '文件操作失败，请重试。')
              : '文件操作暂未完成，请重试。当前记录未被替换。',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final backup = await widget.controller.exportBackup();
    final saved = await _files.save(backup.encode());
    if (mounted) setState(() => _message = saved ? '备份已保存到你选择的位置。' : '已取消导出。');
  });

  Future<void> _open() => _run(() async {
    final source = await _files.open();
    if (!mounted) return;
    final backup = source == null ? null : SavingsBackup.decode(source);
    setState(() {
      _preview = backup;
      _message = source == null ? '已取消选择。' : null;
    });
  });

  Future<void> _restore() async {
    final preview = _preview;
    if (preview == null || _busy || !widget.controller.canWrite) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('用备份替换当前数据？'),
        content: Text(
          '当前 ${widget.controller.records.length} 笔记录和心愿将被替换为备份中的 '
          '${preview.records.length} 笔记录与心愿，不会合并。此操作不能撤销。\n\n建议先返回导出当前数据。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('返回'),
          ),
          TextButton(
            key: const Key('confirmRestore'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认替换'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final success = await widget.controller.restoreBackup(preview);
      if (!mounted) return;
      setState(() {
        _committed = !success && widget.controller.writeCommitted;
        _message = success
            ? '恢复完成，记录与心愿已更新。'
            : _committed
            ? '数据已恢复，但读取失败。请重新读取，无需再次恢复。'
            : '恢复失败，原有数据已保留。';
        if (success || _committed) _preview = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('备份与恢复')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '导出全部记录与当前心愿，换手机时可在 Wallehog 中恢复。备份是未加密的 JSON 文件，请保存到自己信任的位置。',
                ),
                const SizedBox(height: 24),
                IconButton.filledTonal(
                  tooltip: '导出当前数据',
                  key: const Key('exportBackup'),
                  onPressed: _busy || _committed || !widget.controller.canWrite
                      ? null
                      : _export,
                  icon: const Icon(Icons.save_alt),
                ),
                const SizedBox(height: 12),
                IconButton.filledTonal(
                  tooltip: '选择备份，预览恢复',
                  key: const Key('openBackup'),
                  onPressed: _busy || _committed || !widget.controller.canWrite
                      ? null
                      : () {
                          setState(() => _preview = null);
                          _open();
                        },
                  icon: const Icon(Icons.folder_open),
                ),
                const SizedBox(height: 12),
                const Text(
                  '恢复会整体替换当前数据，不会合并。选择文件仅预览，不会立即修改记录。最多 10 MiB / 50,000 笔。',
                ),
                if (_preview case final backup?) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '恢复预览',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('备份日期：${dateKey(backup.exportedAt.toLocal())}'),
                          Text('记录：${backup.records.length} 笔'),
                          Text('心愿：${backup.goals.length} 个'),
                          Text(
                            '累计省钱成果：¥${formatMoney(backup.summary.savedMinor)}',
                          ),
                          Text(
                            backup.goal == null
                                ? '当前心愿：无'
                                : '当前心愿：${backup.goal!.name}\n'
                                      '激励进度：¥${formatMoney(backup.goal!.progressMinor(backup.records))} / ¥${formatMoney(backup.goal!.targetMinor)}',
                          ),
                          const SizedBox(height: 12),
                          const Text('记录的节省成果，不代表实际存款或可用资金。'),
                          const SizedBox(height: 16),
                          IconButton.filledTonal(
                            tooltip: '继续恢复',
                            key: const Key('restoreBackup'),
                            onPressed: _busy || !widget.controller.canWrite
                                ? null
                                : _restore,
                            icon: const Icon(Icons.restore_rounded),
                          ),
                          IconButton(
                            tooltip: '取消预览',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _preview = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(liveRegion: true, child: Text(_message!)),
                  ),
                if (_committed)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            final success = await widget.controller.load();
                            if (mounted) {
                              setState(() {
                                _committed = !success;
                                _message = success ? '读取完成。' : '读取失败，请重试。';
                              });
                            }
                          }),
                    child: const Text('重新读取'),
                  ),
                if (widget.controller.needsRecovery && !_committed)
                  RecoveryNotice(controller: widget.controller),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
