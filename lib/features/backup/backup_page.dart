import '../../app/app_strings.dart';
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
              ? (e.message ?? tr(context, '文件操作失败，请重试。'))
              : tr(context, '文件操作暂未完成，请重试。当前记录未被替换。'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final backup = await widget.controller.exportBackup();
    final saved = await _files.save(backup.encode());
    if (mounted) {
      setState(
        () => _message = saved
            ? tr(context, '备份已保存到你选择的位置。')
            : tr(context, '已取消导出。'),
      );
    }
  });

  Future<void> _open() => _run(() async {
    final source = await _files.open();
    if (!mounted) return;
    final backup = source == null ? null : SavingsBackup.decode(source);
    setState(() {
      _preview = backup;
      _message = source == null ? tr(context, '已取消选择。') : null;
    });
  });

  Future<void> _restore() async {
    final preview = _preview;
    if (preview == null || _busy || !widget.controller.canWrite) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, '用备份替换当前数据？')),
        content: Text(
          tr(
            context,
            '当前 {0} 笔记录和心愿将被替换为备份中的 {1} 笔记录与心愿，不会合并。此操作不能撤销。\n\n建议先返回导出当前数据。',
            [widget.controller.records.length, preview.records.length],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, '返回')),
          ),
          TextButton(
            key: const Key('confirmRestore'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, '确认替换')),
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
            ? tr(context, '恢复完成，记录与心愿已更新。')
            : _committed
            ? tr(context, '数据已恢复，但读取失败。请重新读取，无需再次恢复。')
            : tr(context, '恢复失败，原有数据已保留。');
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
        appBar: AppBar(title: Text(tr(context, '备份与恢复'))),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  tr(
                    context,
                    '导出全部记录与当前心愿，换手机时可在 Wallehog 中恢复。备份是未加密的 JSON 文件，请保存到自己信任的位置。',
                  ),
                ),
                const SizedBox(height: 24),
                IconButton.filledTonal(
                  tooltip: tr(context, '导出当前数据'),
                  key: const Key('exportBackup'),
                  onPressed: _busy || _committed || !widget.controller.canWrite
                      ? null
                      : _export,
                  icon: const Icon(Icons.save_alt),
                ),
                const SizedBox(height: 12),
                IconButton.filledTonal(
                  tooltip: tr(context, '选择备份，预览恢复'),
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
                Text(
                  tr(
                    context,
                    '恢复会整体替换当前数据，不会合并。选择文件仅预览，不会立即修改记录。最多 10 MiB / 50,000 笔。',
                  ),
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
                            tr(context, '恢复预览'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(context, '备份日期：{0}', [
                              dateKey(backup.exportedAt.toLocal()),
                            ]),
                          ),
                          Text(
                            tr(context, '记录：{0} 笔', [backup.records.length]),
                          ),
                          Text(tr(context, '心愿：{0} 个', [backup.goals.length])),
                          Text(
                            tr(context, '累计省钱成果：{0}{1}', [
                              currencySymbol(context),
                              formatMoney(backup.summary.savedMinor),
                            ]),
                          ),
                          Text(
                            backup.goal == null
                                ? tr(context, '当前心愿：无')
                                : tr(
                                    context,
                                    '当前心愿：{0}\n激励进度：{1}{2} / {3}{4}',
                                    [
                                      backup.goal!.name,
                                      currencySymbol(context),
                                      formatMoney(
                                        backup.goal!.progressMinor(
                                          backup.records,
                                        ),
                                      ),
                                      currencySymbol(context),
                                      formatMoney(backup.goal!.targetMinor),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(tr(context, '记录的节省成果，不代表实际存款或可用资金。')),
                          const SizedBox(height: 16),
                          IconButton.filledTonal(
                            tooltip: tr(context, '继续恢复'),
                            key: const Key('restoreBackup'),
                            onPressed: _busy || !widget.controller.canWrite
                                ? null
                                : _restore,
                            icon: const Icon(Icons.restore_rounded),
                          ),
                          IconButton(
                            tooltip: tr(context, '取消预览'),
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
                    child: Semantics(
                      liveRegion: true,
                      child: Text(tr(context, _message!)),
                    ),
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
                                _message = success
                                    ? tr(context, '读取完成。')
                                    : tr(context, '读取失败，请重试。');
                              });
                            }
                          }),
                    child: Text(tr(context, '重新读取')),
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
