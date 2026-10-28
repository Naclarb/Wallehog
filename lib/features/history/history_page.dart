import 'package:flutter/material.dart';
import '../../application/records_controller.dart';
import '../../domain/expression_parser.dart';
import '../entry/entry_page.dart';
import '../entry/calculator_sheet.dart';
import '../../domain/saving_record.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.controller,
    this.embedded = false,
  });
  final RecordsController controller;
  final bool embedded;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('选择记录'),
        automaticallyImplyLeading: !embedded,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: !controller.loaded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.error ?? '正在读取…'),
                    TextButton(
                      onPressed: controller.busy ? null : controller.load,
                      child: const Text('重新读取'),
                    ),
                  ],
                )
              : controller.records.isEmpty
              ? const Center(child: Text('还没有记录，从一个小选择开始。'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.records.length,
                  itemBuilder: (context, index) {
                    final record = controller.records[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.displayTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${kindLabel(record.kind)} · ${record.occurredOn}',
                            ),
                            Text(
                              record.kind == DecisionKind.forgone
                                  ? '一次值得记住的选择 · 未计金额'
                                  : '省钱成果 +¥${formatMoney(record.savedMinor)}',
                            ),
                            Wrap(
                              spacing: 12,
                              children: [
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : record.kind != DecisionKind.forgone
                                      ? () => showCalculator(
                                          context,
                                          controller,
                                          record: record,
                                        )
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => EntryPage(
                                              controller: controller,
                                              record: record,
                                            ),
                                          ),
                                        ),
                                  child: const Text('编辑'),
                                ),
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('删除这个选择？'),
                                              content: const Text(
                                                '删除后，已节省金额和好选择次数会重新计算。此操作不能撤销。',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('保留'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('删除'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await controller.delete(record.id!);
                                          }
                                        },
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ),
  );
}
