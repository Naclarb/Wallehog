import 'dart:convert';
import 'expression_parser.dart';
import 'saving_record.dart';
import 'wishlist_goal.dart';

const maxBackupBytes = 10 * 1024 * 1024;
const maxBackupRecords = 50000;
const _invalid = RuleViolation('备份格式无效、版本不支持或数据超出范围，请选择完整的 Wallehog 备份。');

abstract interface class BackupRepository {
  Future<SavingsBackup> exportBackup();
  Future<void> restoreBackup(SavingsBackup backup);
}

/// 只通过编码/解码创建已验证且不可修改的恢复快照。
class SavingsBackup {
  SavingsBackup._(
    this.records,
    this.goal,
    this.highWater,
    this.exportedAt,
    this.goals,
  );
  final List<SavingRecord> records;
  final WishlistGoal? goal;
  final List<WishlistGoal> goals;
  final int highWater;
  final DateTime exportedAt;
  SavingsSummary get summary => SavingsSummary.fromRecords(records);

  static SavingsBackup create({
    required List<SavingRecord> records,
    required WishlistGoal? goal,
    required int highWater,
    required DateTime exportedAt,
    List<WishlistGoal>? goals,
  }) => decode(_encode(records, goal, highWater, exportedAt, goals));

  // today 保留旧调用兼容性；历史发生日期不再与设备当前日历比较。
  static SavingsBackup decode(String source, {DateTime? today}) {
    if (source.length > maxBackupBytes ||
        utf8.encode(source).length > maxBackupBytes) {
      throw const RuleViolation('备份不能超过 10 MiB。');
    }
    try {
      final root = jsonDecode(source) as Map<String, dynamic>;
      if (root['format'] != 'wallehog' ||
          root['version'] is! int ||
          ![1, 2].contains(root['version']) ||
          root['currency'] != 'CNY') {
        throw _invalid;
      }
      final highWater = _integer(root['highWater']);
      final exportedAt = _time(root['exportedAt']);
      final rows = root['records'] as List;
      if (rows.length > maxBackupRecords) throw _invalid;
      final ids = <int>{};
      final tokens = <String>{};
      final records = <SavingRecord>[];
      for (final item in rows) {
        final row = item as Map<String, dynamic>;
        final id = _integer(row['id']);
        final token = row['clientToken'] as String?;
        if (id <= 0 ||
            id > highWater ||
            !ids.add(id) ||
            (token != null &&
                (token.isEmpty || token.length > 256 || !tokens.add(token)))) {
          throw _invalid;
        }
        records.add(
          SavingRecord.fromStorage(
            id: id,
            kind: DecisionKind.values.byName(row['kind'] as String),
            description: row['description'] as String,
            amountMinor: _optionalInteger(row['amountMinor']),
            baselineMinor: _optionalInteger(row['baselineMinor']),
            actualMinor: _optionalInteger(row['actualMinor']),
            clientToken: token,
            occurredOn: row['occurredOn'] as String,
            createdAt: _time(row['createdAt']),
            updatedAt: _time(row['updatedAt']),
          ),
        );
      }
      final goals = <WishlistGoal>[];
      final goalIds = <int>{};
      final assigned = <int>{};
      final legacy = root['version'] == 1;
      final goalRows = legacy
          ? (root['goal'] == null ? [] : [root['goal']])
          : root['goals'] as List;
      if (goalRows.length > 50) throw _invalid;
      for (final item in goalRows) {
        final row = item as Map<String, dynamic>;
        final boundary = _integer(row['startAfterId']);
        final id = legacy ? 1 : _integer(row['id']);
        if (id <= 0 || !goalIds.add(id) || boundary > highWater) throw _invalid;
        final recordIds = legacy
            ? ids.where((id) => id > boundary).toSet()
            : <int>{};
        if (!legacy) {
          for (final rawId in row['recordIds'] as List) {
            final recordId = _integer(rawId);
            if (!ids.contains(recordId) ||
                recordId <= boundary ||
                !recordIds.add(recordId) ||
                !assigned.add(recordId)) {
              throw _invalid;
            }
          }
        }
        goals.add(
          WishlistGoal(
            id: id,
            name: row['name'] as String,
            targetMinor: _integer(row['targetMinor']),
            startAfterId: boundary,
            style: legacy ? 'gift' : row['style'] as String,
            recordIds: recordIds,
          ),
        );
      }
      final selected = legacy
          ? (goals.isEmpty ? null : 1)
          : root['selectedGoalId'];
      if ((selected != null &&
              (selected is! int || !goalIds.contains(selected))) ||
          (goals.isNotEmpty && selected == null)) {
        throw _invalid;
      }
      final goal = goals.where((g) => g.id == selected).firstOrNull;
      SavingsSummary.fromRecords(records);
      records.sort((a, b) => b.id!.compareTo(a.id!));
      return SavingsBackup._(
        List.unmodifiable(records),
        goal,
        highWater,
        exportedAt,
        List.unmodifiable(goals),
      );
    } catch (_) {
      throw _invalid;
    }
  }

  static int _integer(Object? value) {
    if (value is! int || value < 0 || value > maxAggregateMinor) throw _invalid;
    return value;
  }

  static int? _optionalInteger(Object? value) =>
      value == null ? null : _integer(value);
  static DateTime _time(Object? value) {
    if (value is! String ||
        !RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$',
        ).hasMatch(value)) {
      throw _invalid;
    }
    final time = DateTime.parse(value);
    if (dateKey(time) != value.substring(0, 10) ||
        time.hour != int.parse(value.substring(11, 13)) ||
        time.minute != int.parse(value.substring(14, 16)) ||
        time.second != int.parse(value.substring(17, 19))) {
      throw _invalid;
    }
    return time;
  }

  String encode() => _encode(records, goal, highWater, exportedAt, goals);
  static String _encode(
    List<SavingRecord> records,
    WishlistGoal? goal,
    int highWater,
    DateTime exportedAt,
    List<WishlistGoal>? goals,
  ) => jsonEncode({
    'format': 'wallehog',
    'version': 2,
    'currency': 'CNY',
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'highWater': highWater,
    'records': records
        .map(
          (r) => {
            'id': r.id,
            'kind': r.kind.name,
            'description': r.description,
            'amountMinor': r.amountMinor,
            'baselineMinor': r.baselineMinor,
            'actualMinor': r.actualMinor,
            'clientToken': r.clientToken,
            'occurredOn': r.occurredOn,
            'createdAt': r.createdAt.toIso8601String(),
            'updatedAt': r.updatedAt.toIso8601String(),
          },
        )
        .toList(),
    'selectedGoalId': goal == null ? null : goal.id ?? 1,
    'goals': (goals ?? (goal == null ? <WishlistGoal>[] : [goal]))
        .map(
          (g) => {
            'id': g.id ?? 1,
            'name': g.name,
            'targetMinor': g.targetMinor,
            'startAfterId': g.startAfterId,
            'style': g.style,
            'recordIds':
                (g.recordIds ??
                        records
                            .where(
                              (r) => r.id != null && r.id! > g.startAfterId,
                            )
                            .map((r) => r.id!)
                            .toSet())
                    .toList(),
          },
        )
        .toList(),
  });
}
