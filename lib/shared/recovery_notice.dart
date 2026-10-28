import 'package:flutter/material.dart';
import '../application/records_controller.dart';

/// 仅异常恢复时展示，不改变正常页面布局。
class RecoveryNotice extends StatelessWidget {
  const RecoveryNotice({super.key, required this.controller});
  final RecordsController controller;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(controller.error ?? '请重新读取最新数据后继续，不会重复提交。'),
      ),
      TextButton(
        onPressed: controller.busy ? null : controller.load,
        child: const Text('重新读取'),
      ),
    ],
  );
}
