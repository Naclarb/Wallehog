import '../../app/app_strings.dart';
import 'package:flutter/material.dart';
import '../../application/records_controller.dart';
import '../../domain/expression_parser.dart';
import '../../domain/saving_record.dart';

String kindLabel(DecisionKind kind) => switch (kind) {
  DecisionKind.quick => '记录节省',
  DecisionKind.budget => '低于既定预算',
  DecisionKind.alternative => '选择便宜替代',
  DecisionKind.forgone => '放弃可选购买',
};

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.controller, this.record});
  final RecordsController controller;
  final SavingRecord? record;
  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  late final _description = TextEditingController(
    text: widget.record?.description,
  );
  late final _baseline = TextEditingController(
    text: widget.record?.baselineMinor == null
        ? ''
        : formatMoney(widget.record!.baselineMinor!),
  );
  late final _actual = TextEditingController(
    text: widget.record?.actualMinor == null
        ? ''
        : formatMoney(widget.record!.actualMinor!),
  );
  late DecisionKind _kind = widget.record?.kind ?? DecisionKind.budget;
  late String _date = widget.record?.occurredOn ?? dateKey(DateTime.now());
  bool _saving = false;
  bool _needsRead = false;
  bool get _readOnly => _needsRead || widget.controller.needsRecovery;
  String? _error;
  @override
  void dispose() {
    _description.dispose();
    _baseline.dispose();
    _actual.dispose();
    super.dispose();
  }

  SavingRecord _draft() {
    final now = DateTime.now();
    final created = widget.record?.createdAt ?? now;
    final draft = SavingRecord.fromStorage(
      id: widget.record?.id,
      clientToken: widget.record?.clientToken,
      kind: _kind,
      description: _description.text,
      baselineMinor: _kind == DecisionKind.forgone
          ? null
          : evaluateMoney(_baseline.text),
      actualMinor: _kind == DecisionKind.forgone
          ? null
          : evaluateMoney(_actual.text),
      occurredOn: _date,
      createdAt: created,
      updatedAt: now.isBefore(created) ? created : now,
    );
    draft.validateInputDate(now, originalOccurredOn: widget.record?.occurredOn);
    return draft;
  }

  String _preview() {
    if (_kind == DecisionKind.forgone) {
      return tr(context, '已节省金额 +{0}0.00 · 好选择 +1 次\n放弃购买不会自动折算成节省金额。', [
        currencySymbol(context),
      ]);
    }
    try {
      final baseline = evaluateMoney(_baseline.text);
      final actual = evaluateMoney(_actual.text);
      if (baseline <= actual) return tr(context, '比较基准需要大于实际支出。');
      return tr(context, '节省差额 {0}{1} · 好选择 1 次', [
        currencySymbol(context),
        formatMoney(baseline - actual),
      ]);
    } on RuleViolation catch (e) {
      return tr(context, e.message);
    }
  }

  Future<void> _save() async {
    if (_saving || _readOnly || !widget.controller.canWrite) return;
    SavingRecord draft;
    try {
      draft = _draft();
    } on RuleViolation catch (e) {
      setState(() {
        _error = e.message;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await widget.controller.save(draft);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _needsRead = widget.controller.needsRecovery;
        _error = widget.controller.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.record == null
                ? tr(context, '记录一个好选择')
                : tr(context, '编辑好选择'),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField<DecisionKind>(
                  key: const Key('decisionKind'),
                  initialValue: _kind,
                  decoration: InputDecoration(labelText: tr(context, '选择类型')),
                  items: DecisionKind.values
                      .where((kind) => kind != DecisionKind.quick)
                      .map(
                        (kind) => DropdownMenuItem(
                          value: kind,
                          child: Text(tr(context, kindLabel(kind))),
                        ),
                      )
                      .toList(),
                  onChanged: _saving || _readOnly
                      ? null
                      : (value) => setState(() {
                          _kind = value!;
                          _error = null;
                        }),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('description'),
                  controller: _description,
                  enabled: !_saving && !_readOnly,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: tr(context, '这个选择是什么？'),
                    hintText: tr(context, '例如：带水杯出门，少买一杯饮料'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_kind != DecisionKind.forgone) ...[
                  Text(
                    _kind == DecisionKind.budget
                        ? tr(context, '填写做决定前已确定的预算，而不是事后设定的金额。')
                        : tr(context, '填写原计划购买选项的价格，与实际替代品比较。'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('baseline'),
                    controller: _baseline,
                    enabled: !_saving && !_readOnly,
                    maxLength: 128,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _kind == DecisionKind.budget
                          ? tr(context, '既定预算（元）')
                          : tr(context, '原选项价格（元）'),
                      hintText: tr(context, '例如：(20 + 10) / 2'),
                    ),
                    onChanged: (_) => setState(() {
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('actual'),
                    controller: _actual,
                    enabled: !_saving && !_readOnly,
                    maxLength: 128,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: tr(context, '实际支出（元）'),
                      hintText: tr(context, '支持 + - * / 和括号'),
                    ),
                    onChanged: (_) => setState(() {
                      _error = null;
                    }),
                  ),
                ],
                TextButton.icon(
                  onPressed: _saving || _readOnly
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(_date).isAfter(now)
                                ? now
                                : DateTime.parse(_date),
                            firstDate: DateTime(1),
                            lastDate: now,
                          );
                          if (selected != null && mounted) {
                            setState(() {
                              _date = dateKey(selected);
                            });
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(tr(context, '发生日期：{0}', [_date])),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_preview(), key: const Key('preview')),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(context, '这里记录的是你的选择，不是实际存款。'),
                  textAlign: TextAlign.center,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      tr(context, _error!),
                      key: const Key('entryError'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if ((_needsRead || widget.controller.needsRecovery) && !_saving)
                  TextButton(
                    onPressed: widget.controller.busy
                        ? null
                        : () async {
                            final success = await widget.controller.load();
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(tr(context, '重新读取并返回，确认记录后再继续')),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('saveRecord'),
                  onPressed:
                      _saving ||
                          _needsRead ||
                          !widget.controller.loaded ||
                          widget.controller.busy
                      ? null
                      : _save,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _saving ? tr(context, '正在保存…') : tr(context, '保存好选择'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
