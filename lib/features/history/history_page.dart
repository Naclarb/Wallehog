import '../../app/app_strings.dart';
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
        title: Text(tr(context, '选择记录')),
        automaticallyImplyLeading: !embedded,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: !controller.loaded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr(context, controller.error ?? '正在读取…')),
                    TextButton(
                      onPressed: controller.busy ? null : controller.load,
                      child: Text(tr(context, '重新读取')),
                    ),
                  ],
                )
              : controller.records.isEmpty
              ? Center(child: Text(tr(context, '还没有记录，从一个小选择开始。')))
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
                              record.description.isEmpty
                                  ? tr(context, record.displayTitle)
                                  : record.description,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${tr(context, kindLabel(record.kind))} · ${record.occurredOn}',
                            ),
                            Text(
                              record.kind == DecisionKind.forgone
                                  ? tr(context, '一次值得记住的选择 · 未计金额')
                                  : tr(context, '省钱成果 +{0}{1}', [
                                      currencySymbol(context),
                                      formatMoney(record.savedMinor),
                                    ]),
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
                                  child: Text(tr(context, '编辑')),
                                ),
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                tr(context, '删除这个选择？'),
                                              ),
                                              content: Text(
                                                tr(
                                                  context,
                                                  '删除后，已节省金额和好选择次数会重新计算。此操作不能撤销。',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    tr(context, '保留'),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    tr(context, '删除'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await controller.delete(record.id!);
                                          }
                                        },
                                  child: Text(tr(context, '删除')),
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
