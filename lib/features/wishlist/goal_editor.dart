import 'package:flutter/material.dart';
import '../../application/records_controller.dart';
import '../../app/design_tokens.dart';
import '../../domain/expression_parser.dart';
import '../../domain/wishlist_goal.dart';

Future<void> showGoalEditor(
  BuildContext context,
  RecordsController controller, {
  bool creating = false,
}) => showDialog<void>(
  context: context,
  builder: (_) => _GoalEditor(controller: controller, creating: creating),
);

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({required this.controller, required this.creating});
  final RecordsController controller;
  final bool creating;
  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final _name = TextEditingController(
    text: widget.creating ? '' : widget.controller.goal?.name,
  );
  late final _target = TextEditingController(
    text: widget.creating || widget.controller.goal == null
        ? ''
        : formatMoney(widget.controller.goal!.targetMinor),
  );
  late final _editing = !widget.creating && widget.controller.goal != null;
  late String _style = _editing ? widget.controller.goal!.style : 'gift';
  bool _busy = false;
  bool _committed = false;
  bool get _readOnly => _committed || widget.controller.needsRecovery;
  bool _clearing = false;
  String? _error;
  Future<void> _clear() async {
    if (_busy || !widget.controller.canWrite) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除心愿？'),
        content: const Text('只清除这个心愿，所有记录仍会保留，不会转入其他心愿。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('confirmClearGoal'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _clearing = true;
      _error = null;
    });
    final success = await widget.controller.clearGoal();
    _committed = widget.controller.writeCommitted;
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = widget.controller.error;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || widget.controller.busy) return;
    if (_readOnly) {
      setState(() {
        _busy = true;
        _error = null;
      });
      final success = await widget.controller.load();
      if (!mounted) return;
      if (success && _committed) {
        Navigator.pop(context);
      } else {
        setState(() {
          _busy = false;
          _error = widget.controller.error;
        });
      }
      return;
    }
    if (_clearing) {
      setState(() {
        _busy = true;
        _error = null;
      });
      final success = await widget.controller.clearGoal();
      _committed = _committed || widget.controller.writeCommitted;
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          _busy = false;
          _error = widget.controller.error;
        });
      }
      return;
    }
    int amount;
    try {
      amount = evaluateMoney(_target.text);
    } on RuleViolation catch (e) {
      setState(() {
        _error = e.message;
      });
      return;
    }
    if (_name.text.trim().isEmpty ||
        _name.text.trim().length > 60 ||
        amount <= 0) {
      setState(() {
        _error = '请填写心愿名称和正数目标金额';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = _editing
        ? await widget.controller.editGoal(_name.text, amount, style: _style)
        : await widget.controller.createGoal(_name.text, amount, style: _style);
    _committed = _committed || widget.controller.writeCommitted;
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = widget.controller.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => _buildEditor(context),
  );

  Widget _buildEditor(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      key: const Key('goalEditor'),
      backgroundColor: pageBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: deepPink),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: mutedInk),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, area) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final style in goalStyles)
                      SizedBox(
                        width: (area.maxWidth - 24) / 4,
                        height: 72,
                        child: Tooltip(
                          message: goalStyleNames[style]!,
                          child: Semantics(
                            label: goalStyleNames[style],
                            selected: _style == style,
                            button: true,
                            child: Material(
                              color: _style == style
                                  ? const Color(0xFFF2DFE6)
                                  : const Color(0xFFF9F1F0),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                key: Key('style_$style'),
                                borderRadius: BorderRadius.circular(20),
                                onTap: _busy || _readOnly || _clearing
                                    ? null
                                    : () => setState(() {
                                        if (_name.text.isEmpty ||
                                            goalStyleNames.values.contains(
                                              _name.text,
                                            )) {
                                          _name.text = style == 'gift'
                                              ? ''
                                              : goalStyleNames[style]!;
                                        }
                                        _style = style;
                                      }),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    goalAsset(style),
                                    excludeFromSemantics: true,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: '心愿名称',
                child: TextField(
                  key: const Key('goalNameInput'),
                  controller: _name,
                  enabled: !_busy && !_readOnly && !_clearing,
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '心愿名称',
                    counterText: '',
                    prefixIcon: Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: '目标金额，元',
                child: TextField(
                  key: const Key('goalTargetInput'),
                  controller: _target,
                  enabled: !_busy && !_readOnly && !_clearing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  maxLength: 128,
                  decoration: const InputDecoration(
                    hintText: '目标金额',
                    counterText: '',
                    prefixIcon: Icon(Icons.currency_yen_rounded, size: 20),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: deepPink),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_editing)
                    IconButton(
                      key: const Key('clearGoal'),
                      tooltip: '清除心愿',
                      onPressed: _busy || _readOnly ? null : _clear,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: mutedInk,
                      ),
                    ),
                  const Spacer(),
                  IconButton.filled(
                    key: const Key('saveGoal'),
                    tooltip: _busy
                        ? '保存中'
                        : _readOnly
                        ? '重试读取'
                        : _clearing
                        ? '重试清除'
                        : '保存心愿',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFECC2D2),
                      foregroundColor: goalInk,
                      minimumSize: const Size(64, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _readOnly || _clearing
                                ? Icons.refresh_rounded
                                : Icons.check_rounded,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
