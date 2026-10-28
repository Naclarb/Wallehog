import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../app/design_tokens.dart';
import '../../domain/expression_parser.dart';
import '../../domain/saving_record.dart';

class RecentSavings extends StatefulWidget {
  const RecentSavings({
    super.key,
    required this.records,
    required this.onRecord,
    required this.onDelete,
    this.enabled = true,
  });
  final bool enabled;
  final List<SavingRecord> records;
  final ValueChanged<SavingRecord> onRecord;
  final ValueChanged<SavingRecord> onDelete;
  @override
  State<RecentSavings> createState() => _RecentSavingsState();
}

class _RecentSavingsState extends State<RecentSavings> {
  int? _openId;
  List<SavingRecord> get records => widget.records;
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('littleWins'),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: '记录',
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: mutedInk,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (records.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Text('暂无记录', style: AppType.caption),
          ),
        for (final record in records)
          _SwipeRecord(
            key: ValueKey(record.id),
            id: record.id!,
            open: _openId == record.id,
            enabled: widget.enabled,
            onOpen: (open) => setState(() => _openId = open ? record.id : null),
            onEdit: () => widget.onRecord(record),
            onDelete: () => widget.onDelete(record),
            child: Container(
              key: ValueKey('recentSaving_${record.id}'),
              constraints: const BoxConstraints(minHeight: 52),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1E5EA))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: softPink,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF4DDE7)),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 17,
                      color: primaryPink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.description.isEmpty
                              ? record.occurredOn
                              : record.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (record.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(record.occurredOn, style: AppType.small),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      record.savedMinor == 0
                          ? '一次好选择'
                          : '+¥${formatMoney(record.savedMinor)}',
                      style: AppType.recordAmount.copyWith(
                        color: moneyColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _SwipeRecord extends StatefulWidget {
  const _SwipeRecord({
    super.key,
    required this.id,
    required this.open,
    required this.enabled,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.child,
  });
  final int id;
  final bool open;
  final bool enabled;
  final ValueChanged<bool> onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget child;
  @override
  State<_SwipeRecord> createState() => _SwipeRecordState();
}

class _SwipeRecordState extends State<_SwipeRecord> {
  double? _drag;
  void _close() {
    setState(() => _drag = null);
    widget.onOpen(false);
  }

  void _edit() {
    _close();
    widget.onEdit();
  }

  void _delete() {
    _close();
    widget.onDelete();
  }

  @override
  void didUpdateWidget(covariant _SwipeRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open || !widget.enabled) _drag = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      final half = area.maxWidth / 2;
      final offset = widget.enabled ? _drag ?? (widget.open ? half : 0.0) : 0.0;
      return Semantics(
        customSemanticsActions: widget.enabled
            ? {
                const CustomSemanticsAction(label: '编辑记录'): _edit,
                const CustomSemanticsAction(label: '删除记录'): _delete,
              }
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                right: half,
                child: ExcludeSemantics(
                  excluding: !widget.open || !widget.enabled,
                  child: IgnorePointer(
                    ignoring: !widget.open || !widget.enabled,
                    child: Material(
                      color: const Color(0xFFF5DFE4),
                      child: InkWell(
                        key: ValueKey('deleteSaving_${widget.id}'),
                        onTap: _delete,
                        child: const Center(
                          child: Tooltip(
                            message: '删除记录',
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: deepPink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                key: ValueKey('swipeSaving_${widget.id}'),
                behavior: HitTestBehavior.deferToChild,
                onHorizontalDragStart: !widget.enabled
                    ? null
                    : (_) => setState(() => _drag = widget.open ? half : 0),
                onHorizontalDragUpdate: !widget.enabled
                    ? null
                    : (d) => setState(
                        () =>
                            _drag = ((_drag ?? 0) + d.delta.dx).clamp(0, half),
                      ),
                onHorizontalDragEnd: !widget.enabled
                    ? null
                    : (d) {
                        final reveal = d.velocity.pixelsPerSecond.dx.abs() > 350
                            ? d.velocity.pixelsPerSecond.dx > 0
                            : (_drag ?? 0) >= half / 2;
                        setState(() => _drag = null);
                        widget.onOpen(reveal);
                      },
                onHorizontalDragCancel: () => setState(() => _drag = null),
                child: AnimatedContainer(
                  key: ValueKey('savingOffset_${widget.id}'),
                  duration:
                      _drag != null || MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(offset, 0, 0),
                  child: Material(
                    color: pageBackground,
                    child: InkWell(
                      onTap: widget.enabled ? _close : null,
                      onLongPress: widget.enabled ? _edit : null,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
