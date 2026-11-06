import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/design_tokens.dart';
import '../../application/records_controller.dart';
import '../../domain/expression_parser.dart';
import '../../domain/saving_record.dart';

double _preferredCalculatorFraction = 1 / 2;

Future<int?> showCalculator(
  BuildContext context,
  RecordsController controller, {
  SavingRecord? record,
}) async {
  ModalRoute<dynamic>? sheetRoute;
  final result = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    constraints: MediaQuery.sizeOf(context).width >= 600
        ? const BoxConstraints(maxWidth: 480)
        : null,
    useSafeArea: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 280),
            reverseDuration: Duration(milliseconds: 220),
          ),
    backgroundColor: pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      sheetRoute = ModalRoute.of(sheetContext);
      return CalculatorSheet(controller: controller, record: record);
    },
  );
  // 等待真实退场结束，金币首段不会被仍在关闭的弹层/遮罩挡住。
  await sheetRoute?.completed;
  return result;
}

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key, required this.controller, this.record});
  final RecordsController controller;
  final SavingRecord? record;
  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  late final _expression = TextEditingController(
    text: widget.record == null ? '' : formatMoney(widget.record!.savedMinor),
  );
  late final _note = TextEditingController(text: widget.record?.description);
  late String _date = widget.record?.occurredOn ?? dateKey(DateTime.now());
  late final String _token =
      widget.record?.clientToken ??
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  bool _saving = false;
  bool _details = false;
  late double _heightFraction = _preferredCalculatorFraction;
  bool _committed = false;
  bool get _readOnly => _committed || widget.controller.needsRecovery;
  String? _error;
  int? get _amount {
    try {
      final value = evaluateMoney(_expression.text);
      return value > 0 ? value : null;
    } on RuleViolation {
      return null;
    }
  }

  String get _result {
    if (_expression.text.isEmpty) return '¥0.00';
    try {
      final value = evaluateMoney(_expression.text);
      return value > 0 ? '+¥${formatMoney(value)}' : '金额需要大于零';
    } on RuleViolation catch (e) {
      return e.message;
    }
  }

  @override
  void dispose() {
    _expression.dispose();
    _note.dispose();
    super.dispose();
  }

  void _key(String label) {
    if (_saving || _readOnly) return;
    final text = _expression.text;
    final selection = _expression.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    String next;
    int caret;
    if (label == 'C') {
      next = '';
      caret = 0;
    } else if (label == '⌫') {
      final removeFrom = start == end ? max(0, start - 1) : start;
      next = text.replaceRange(removeFrom, end, '');
      caret = removeFrom;
    } else {
      final token = switch (label) {
        '×' => '*',
        '÷' => '/',
        '−' => '-',
        '.' => start == 0 || '+-*/('.contains(text[start - 1]) ? '0.' : '.',
        _ => label,
      };
      next = text.replaceRange(start, end, token);
      caret = start + token.length;
    }
    if (next.length > 128) return;
    setState(() {
      _expression.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: caret),
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    final amount = _amount;
    final reading = _readOnly;
    if (_saving || widget.controller.busy || (!reading && amount == null)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    bool success;
    if (reading) {
      success = await widget.controller.load();
    } else {
      try {
        final now = DateTime.now();
        final created = widget.record?.createdAt ?? now;
        final record = SavingRecord.fromStorage(
          id: widget.record?.id,
          kind: DecisionKind.quick,
          description: _note.text,
          amountMinor: amount,
          clientToken: widget.record == null
              ? _token
              : widget.record!.clientToken,
          occurredOn: _date,
          createdAt: created,
          updatedAt: now.isBefore(created) ? created : now,
        );
        record.validateInputDate(
          now,
          originalOccurredOn: widget.record?.occurredOn,
        );
        success = await widget.controller.save(record);
        _committed = widget.controller.writeCommitted;
      } on RuleViolation catch (e) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
        return;
      }
    }
    if (!mounted) return;
    if (success) {
      if (reading && !_committed) {
        setState(() => _saving = false);
        return;
      }
      Navigator.pop(context, amount);
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.error;
      });
    }
  }

  void _resize(double delta) {
    setState(() {
      _heightFraction = (_heightFraction + delta).clamp(1 / 3, .9);
      _preferredCalculatorFraction = _heightFraction;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => _buildSheet(context),
  );

  Widget _buildSheet(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    const keys = [
      '7',
      '8',
      '9',
      '⌫',
      'C',
      '4',
      '5',
      '6',
      '×',
      '÷',
      '1',
      '2',
      '3',
      '−',
      '(',
      '.',
      '0',
      '00',
      '+',
      ')',
    ];
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: SizedBox(
            key: const Key('calculatorPanel'),
            height: min(
              screen * _heightFraction,
              max(150, screen * .9 - keyboard),
            ),
            child: LayoutBuilder(
              builder: (context, area) {
                final keyHeight = ((area.maxHeight - 108) / 4).clamp(
                  32.0,
                  64.0,
                );
                return Column(
                  children: [
                    SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          IconButton(
                            key: const Key('advancedDetails'),
                            tooltip: '备注与日期',
                            visualDensity: VisualDensity.compact,
                            onPressed: _saving || _readOnly
                                ? null
                                : () => setState(() => _details = !_details),
                            icon: const Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: mutedInk,
                            ),
                          ),
                          Expanded(
                            child: Semantics(
                              label: '调整计算器高度',
                              value: '${(_heightFraction * 100).round()}%',
                              increasedValue:
                                  '${((_heightFraction + .1).clamp(1 / 3, .9) * 100).round()}%',
                              decreasedValue:
                                  '${((_heightFraction - .1).clamp(1 / 3, .9) * 100).round()}%',
                              onIncrease: () => _resize(.1),
                              onDecrease: () => _resize(-.1),
                              child: GestureDetector(
                                key: const Key('calculatorResizeHandle'),
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragUpdate: (d) =>
                                    _resize(-d.delta.dy / screen),
                                onDoubleTap: () =>
                                    _resize(1 / 2 - _heightFraction),
                                child: Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2CED6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '关闭',
                            visualDensity: VisualDensity.compact,
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('calculatorScroll'),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    label: '节省金额算式',
                                    child: TextField(
                                      key: const Key('expression'),
                                      controller: _expression,
                                      readOnly: _saving || _readOnly,
                                      keyboardType: TextInputType.none,
                                      maxLength: 128,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        counterText: '',
                                        filled: false,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                      onChanged: (_) =>
                                          setState(() => _error = null),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      _amount == null ? '¥0.00' : _result,
                                      key: const Key('calculatorResult'),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: moneyColor(context),
                                      ),
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  key: const Key('confirmSaving'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(48, 44),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed:
                                      _saving ||
                                          (!_readOnly && _amount == null) ||
                                          widget.controller.busy
                                      ? null
                                      : _save,
                                  child: Semantics(
                                    label: _saving
                                        ? '正在保存'
                                        : _readOnly
                                        ? '重试读取已保存记录'
                                        : '保存节省金额',
                                    button: true,
                                    child: Tooltip(
                                      message: _readOnly
                                          ? '重试读取已保存记录'
                                          : '保存节省金额',
                                      child: _saving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              _readOnly
                                                  ? Icons.refresh_rounded
                                                  : Icons.check_rounded,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 5,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              mainAxisExtent: keyHeight,
                              children: keys
                                  .map(
                                    (key) => Material(
                                      color: ['÷', '×', '−', '+'].contains(key)
                                          ? softPink
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        key: Key('key_$key'),
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _saving || _readOnly
                                            ? null
                                            : () => _key(key),
                                        child: Center(
                                          child: Text(
                                            key,
                                            semanticsLabel: key == '⌫'
                                                ? '退格'
                                                : key == 'C'
                                                ? '清空'
                                                : key,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: ['C', '⌫'].contains(key)
                                                  ? deepPink
                                                  : ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (_amount == null && _expression.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _result,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: deepPink,
                                  ),
                                ),
                              ),
                            if (_details) ...[
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('optionalNote'),
                                controller: _note,
                                enabled: !_saving && !_readOnly,
                                maxLength: 200,
                                decoration: const InputDecoration(
                                  hintText: '备注',
                                  prefixIcon: Icon(Icons.notes_rounded),
                                  counterText: '',
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                                label: Text(_date),
                                onPressed: _saving || _readOnly
                                    ? null
                                    : () async {
                                        final now = DateTime.now();
                                        final selected = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              DateTime.parse(_date).isAfter(now)
                                              ? now
                                              : DateTime.parse(_date),
                                          firstDate: DateTime(1),
                                          lastDate: now,
                                        );
                                        if (selected != null && mounted) {
                                          setState(
                                            () => _date = dateKey(selected),
                                          );
                                        }
                                      },
                              ),
                            ],
                            if (widget.record != null &&
                                widget.record!.kind != DecisionKind.quick)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  '旧版记录：确认后改为直接记录金额，原比较依据不再保留。',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedInk,
                                  ),
                                ),
                              ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _error!,
                                    key: const Key('saveError'),
                                    style: const TextStyle(color: deepPink),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
