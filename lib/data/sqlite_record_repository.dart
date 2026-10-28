import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../domain/expression_parser.dart';
import '../domain/record_repository.dart';
import '../domain/saving_record.dart';
import '../domain/wishlist_goal.dart';
import '../domain/backup.dart';
import '../domain/pig_growth.dart';

class SqliteRecordRepository
    implements RecordRepository, BackupRepository, GrowthCelebrationStore {
  SqliteRecordRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final Database _db;
  final DateTime Function() _clock;

  static Future<void> _createRecords(DatabaseExecutor db) => db.execute('''
    CREATE TABLE saving_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kind TEXT NOT NULL CHECK(kind IN ('quick','budget','alternative','forgone')),
      description TEXT NOT NULL CHECK(length(description) <= 200),
      baseline_minor INTEGER, actual_minor INTEGER,
      saved_minor INTEGER NOT NULL CHECK(saved_minor BETWEEN 0 AND 999999999),
      currency_code TEXT NOT NULL CHECK(currency_code = 'CNY'),
      occurred_on TEXT NOT NULL, created_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL,
      client_token TEXT UNIQUE,
      CHECK (
        (kind = 'quick' AND baseline_minor IS NULL AND actual_minor IS NULL AND saved_minor > 0)
        OR (kind = 'forgone' AND baseline_minor IS NULL AND actual_minor IS NULL AND saved_minor = 0)
        OR (kind IN ('budget','alternative') AND baseline_minor IS NOT NULL AND actual_minor IS NOT NULL
            AND baseline_minor BETWEEN 1 AND 999999999 AND actual_minor BETWEEN 0 AND 999999999
            AND baseline_minor > actual_minor AND saved_minor = baseline_minor - actual_minor)
      )
    )
  ''');
  static Future<void> _createGoal(DatabaseExecutor db) => db.execute('''
    CREATE TABLE active_goal (
      id INTEGER PRIMARY KEY CHECK(id = 1),
      name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 60),
      target_minor INTEGER NOT NULL CHECK(target_minor BETWEEN 1 AND 999999999),
      start_after_id INTEGER NOT NULL CHECK(start_after_id >= 0)
    )
  ''');

  static Future<void> _createCelebrations(DatabaseExecutor db) => db.execute(
    'CREATE TABLE pig_celebrations (level INTEGER PRIMARY KEY CHECK(level BETWEEN 2 AND 5))',
  );

  static Future<void> _createMultipleGoals(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 60),
      target_minor INTEGER NOT NULL CHECK(target_minor BETWEEN 1 AND 999999999),
      start_after_id INTEGER NOT NULL CHECK(start_after_id >= 0),
      style TEXT NOT NULL CHECK(style IN ('gift','ps5','headphones','camera'))
    )''');
    await db.execute(
      'CREATE TABLE goal_records (record_id INTEGER PRIMARY KEY, goal_id INTEGER NOT NULL)',
    );
    await db.execute('CREATE INDEX goal_records_goal ON goal_records(goal_id)');
    await db.execute(
      'CREATE TABLE goal_selection (id INTEGER PRIMARY KEY CHECK(id=1), goal_id INTEGER)',
    );
    await db.execute('INSERT INTO goal_selection(id,goal_id) VALUES(1,NULL)');
  }

  static Future<void> _migrateGoals(DatabaseExecutor db) async {
    await _createMultipleGoals(db);
    await db.execute(
      "INSERT INTO goals(id,name,target_minor,start_after_id,style) SELECT id,name,target_minor,start_after_id,'gift' FROM active_goal",
    );
    await db.execute(
      'INSERT INTO goal_records(record_id,goal_id) SELECT r.id,g.id FROM saving_records r JOIN goals g ON r.id > g.start_after_id',
    );
    await db.execute(
      'UPDATE goal_selection SET goal_id=(SELECT id FROM goals LIMIT 1) WHERE id=1',
    );
    await db.execute('DROP TABLE active_goal');
  }

  @override
  Future<bool> claimGrowthCelebration(int level) async {
    if (level < 2 || level > 5) throw ArgumentError.value(level, 'level');
    return _db.transaction((tx) async {
      await tx.rawInsert(
        'INSERT OR IGNORE INTO pig_celebrations(level) VALUES (?)',
        [level],
      );
      final changes = await tx.rawQuery('SELECT changes() AS count');
      return changes.single['count'] == 1;
    });
  }

  static Future<SqliteRecordRepository> open({
    String? databasePath,
    DatabaseFactory? factory,
    DateTime Function()? clock,
  }) async {
    final provider = factory ?? databaseFactory;
    final location =
        databasePath ??
        path.join(await provider.getDatabasesPath(), 'wallehog.db');
    final db = await provider.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await _createRecords(db);
          await _createMultipleGoals(db);
          await _createCelebrations(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 1 || oldVersion > 3 || newVersion != 4) {
            throw StateError('不支持的数据库升级路径');
          }
          if (oldVersion == 1) {
            // sqflite 的 onUpgrade 在事务内执行；不删库，保留所有 ID、原始比较数据和时间。
            final sequence = await db.rawQuery(
              "SELECT seq FROM sqlite_sequence WHERE name = 'saving_records'",
            );
            final highWater = sequence.isEmpty
                ? 0
                : sequence.single['seq'] as int;
            await db.execute(
              'ALTER TABLE saving_records RENAME TO saving_records_v1',
            );
            await _createRecords(db);
            await db.execute('''INSERT INTO saving_records
          (id,kind,description,baseline_minor,actual_minor,saved_minor,currency_code,occurred_on,created_at_utc,updated_at_utc)
          SELECT id,kind,description,baseline_minor,actual_minor,saved_minor,currency_code,occurred_on,created_at_utc,updated_at_utc
          FROM saving_records_v1''');
            await db.execute('DROP TABLE saving_records_v1');
            // 连已删除的最大 ID 也保留为高水位，目标边界不会复用旧记录的顺序。
            await db.delete(
              'sqlite_sequence',
              where: 'name = ?',
              whereArgs: ['saving_records'],
            );
            await db.insert('sqlite_sequence', {
              'name': 'saving_records',
              'seq': highWater,
            });
            await _createGoal(db);
          }
          if (oldVersion < 3) await _createCelebrations(db);
          await _migrateGoals(db);
        },
      ),
    );
    return SqliteRecordRepository(db, clock: clock);
  }

  SavingRecord _decode(Map<String, Object?> row) {
    final kind = DecisionKind.values.byName(row['kind'] as String);
    final record = SavingRecord.fromStorage(
      id: row['id'] as int,
      kind: kind,
      description: row['description'] as String,
      baselineMinor: row['baseline_minor'] as int?,
      actualMinor: row['actual_minor'] as int?,
      amountMinor: kind == DecisionKind.quick
          ? row['saved_minor'] as int
          : null,
      clientToken: row['client_token'] as String?,
      occurredOn: row['occurred_on'] as String,
      createdAt: DateTime.parse(row['created_at_utc'] as String),
      updatedAt: DateTime.parse(row['updated_at_utc'] as String),
    );
    if (row['saved_minor'] != record.savedMinor ||
        row['currency_code'] != 'CNY') {
      throw StateError('记录金额或币种与规则不一致');
    }
    return record;
  }

  @override
  Future<List<SavingRecord>> readAll() async => (await _db.query(
    'saving_records',
    orderBy: 'id DESC',
  )).map(_decode).toList();
  @override
  Future<RecordSnapshot> readSnapshot() => _db.transaction((tx) async {
    final records = (await tx.query(
      'saving_records',
      orderBy: 'id DESC',
    )).map(_decode).toList();
    final goals = await _readGoals(tx);
    final selected = await _selectedId(tx);
    return RecordSnapshot(
      records,
      goals.where((g) => g.id == selected).firstOrNull,
      allGoals: goals,
    );
  });

  Future<int?> _selectedId(DatabaseExecutor tx) async =>
      (await tx.query('goal_selection')).single['goal_id'] as int?;

  Future<List<WishlistGoal>> _readGoals(DatabaseExecutor tx) async {
    final assignments = await tx.query('goal_records');
    return (await tx.query('goals', orderBy: 'id'))
        .map(
          (row) => WishlistGoal(
            id: row['id'] as int,
            name: row['name'] as String,
            targetMinor: row['target_minor'] as int,
            startAfterId: row['start_after_id'] as int,
            style: row['style'] as String,
            recordIds: assignments
                .where((a) => a['goal_id'] == row['id'])
                .map((a) => a['record_id'] as int)
                .toSet(),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(SavingRecord record) async {
    final values = <String, Object?>{
      'kind': record.kind.name,
      'description': record.description,
      'baseline_minor': record.baselineMinor,
      'actual_minor': record.actualMinor,
      'saved_minor': record.savedMinor,
      'currency_code': 'CNY',
      'occurred_on': record.occurredOn,
      'created_at_utc': record.createdAt.toIso8601String(),
      'updated_at_utc': record.updatedAt.toIso8601String(),
      'client_token': record.clientToken,
    };
    await _db.transaction((tx) async {
      if (record.id == null) {
        if (record.clientToken != null) {
          final existing = await tx.query(
            'saving_records',
            where: 'client_token = ?',
            whereArgs: [record.clientToken],
          );
          if (existing.isNotEmpty) {
            final old = _decode(existing.single);
            if (old.savedMinor != record.savedMinor ||
                old.description != record.description ||
                old.occurredOn != record.occurredOn) {
              throw const RuleViolation('这次选择可能已保存，请重新读取记录确认');
            }
            return; // 同一次保存重试，不增加记录或好选择。
          }
        }
        record.validateInputDate(_clock());
        final id = await tx.insert('saving_records', values);
        final selected = await _selectedId(tx);
        if (selected != null) {
          await tx.insert('goal_records', {
            'record_id': id,
            'goal_id': selected,
          });
        }
      } else {
        final old = await tx.query(
          'saving_records',
          where: 'id = ?',
          whereArgs: [record.id],
        );
        if (old.isEmpty) throw const RuleViolation('记录已不存在，请刷新后重试');
        record.validateInputDate(
          _clock(),
          originalOccurredOn: old.single['occurred_on'] as String,
        );
        if (old.single['created_at_utc'] !=
                record.createdAt.toIso8601String() ||
            old.single['client_token'] != record.clientToken) {
          throw const RuleViolation('创建时间和记录身份不能修改');
        }
        await tx.update(
          'saving_records',
          values,
          where: 'id = ?',
          whereArgs: [record.id],
        );
      }
      SavingsSummary.fromRecords(
        (await tx.query('saving_records')).map(_decode),
      );
    });
  }

  @override
  Future<void> delete(int id) => _db.transaction((tx) async {
    if (await tx.delete('saving_records', where: 'id = ?', whereArgs: [id]) !=
        1) {
      throw const RuleViolation('记录已不存在，请刷新后重试');
    }
    await tx.delete('goal_records', where: 'record_id = ?', whereArgs: [id]);
  });
  @override
  Future<void> createGoal(
    String name,
    int targetMinor, {
    String style = 'gift',
  }) => _db.transaction((tx) async {
    if ((await tx.query('goals', columns: ['id'])).length >= 50) {
      throw const RuleViolation('最多保留 50 个心愿');
    }
    final sequence = await tx.rawQuery(
      "SELECT seq FROM sqlite_sequence WHERE name = 'saving_records'",
    );
    final goal = WishlistGoal(
      name: name,
      style: style,
      targetMinor: targetMinor,
      startAfterId: sequence.isEmpty ? 0 : sequence.single['seq'] as int,
    );
    final id = await tx.insert('goals', {
      'name': goal.name,
      'target_minor': goal.targetMinor,
      'start_after_id': goal.startAfterId,
      'style': goal.style,
    });
    await tx.update('goal_selection', {'goal_id': id}, where: 'id=1');
  });
  @override
  Future<void> editGoal(String name, int targetMinor, {String? style}) =>
      _db.transaction((tx) async {
        final selected = await _selectedId(tx);
        if (selected == null) throw const RuleViolation('心愿已不存在');
        final old = await tx.query(
          'goals',
          where: 'id=?',
          whereArgs: [selected],
        );
        if (old.isEmpty) throw const RuleViolation('心愿已不存在');
        final goal = WishlistGoal(
          name: name,
          style: style ?? old.single['style'] as String,
          targetMinor: targetMinor,
          startAfterId: old.single['start_after_id'] as int,
        );
        await tx.update(
          'goals',
          {
            'name': goal.name,
            'target_minor': goal.targetMinor,
            'style': goal.style,
          },
          where: 'id = ?',
          whereArgs: [selected],
        );
      });
  @override
  Future<void> clearGoal() => _db.transaction((tx) async {
    final selected = await _selectedId(tx);
    await tx.delete('goal_records', where: 'goal_id=?', whereArgs: [selected]);
    await tx.delete('goals', where: 'id=?', whereArgs: [selected]);
    final remaining = await tx.query('goals', orderBy: 'id', limit: 1);
    await tx.update('goal_selection', {
      'goal_id': remaining.firstOrNull?['id'],
    }, where: 'id=1');
  });

  @override
  Future<void> selectGoal(int id) => _db.transaction((tx) async {
    if ((await tx.query('goals', where: 'id=?', whereArgs: [id])).isEmpty) {
      throw const RuleViolation('心愿已不存在');
    }
    await tx.update('goal_selection', {'goal_id': id}, where: 'id=1');
  });

  @override
  Future<void> close() => _db.close();

  @override
  Future<SavingsBackup> exportBackup() => _db.transaction((tx) async {
    final records = (await tx.query('saving_records')).map(_decode).toList();
    final goals = await _readGoals(tx);
    final selected = await _selectedId(tx);
    final sequence = await tx.rawQuery(
      "SELECT seq FROM sqlite_sequence WHERE name = 'saving_records'",
    );
    return SavingsBackup.create(
      records: records,
      goal: goals.where((g) => g.id == selected).firstOrNull,
      goals: goals,
      highWater: sequence.isEmpty ? 0 : sequence.single['seq'] as int,
      exportedAt: _clock(),
    );
  });

  @override
  Future<void> restoreBackup(SavingsBackup backup) async {
    // 再次验证通过后才开启替换事务；任何插入失败都会回滚全部替换。
    final verified = SavingsBackup.decode(backup.encode(), today: _clock());
    await _db.transaction((tx) async {
      await tx.delete('goal_records');
      await tx.delete('goals');
      await tx.delete('saving_records');
      final batch = tx.batch();
      for (final r in verified.records) {
        batch.insert('saving_records', {
          'id': r.id,
          'kind': r.kind.name,
          'description': r.description,
          'baseline_minor': r.baselineMinor,
          'actual_minor': r.actualMinor,
          'saved_minor': r.savedMinor,
          'currency_code': 'CNY',
          'occurred_on': r.occurredOn,
          'created_at_utc': r.createdAt.toIso8601String(),
          'updated_at_utc': r.updatedAt.toIso8601String(),
          'client_token': r.clientToken,
        });
      }
      await batch.commit(noResult: true);
      await tx.delete(
        'sqlite_sequence',
        where: 'name = ?',
        whereArgs: ['saving_records'],
      );
      await tx.insert('sqlite_sequence', {
        'name': 'saving_records',
        'seq': verified.highWater,
      });
      for (final goal in verified.goals) {
        await tx.insert('goals', {
          'id': goal.id,
          'name': goal.name,
          'target_minor': goal.targetMinor,
          'start_after_id': goal.startAfterId,
          'style': goal.style,
        });
        for (final recordId in goal.recordIds!) {
          await tx.insert('goal_records', {
            'record_id': recordId,
            'goal_id': goal.id,
          });
        }
      }
      await tx.update('goal_selection', {
        'goal_id': verified.goal?.id,
      }, where: 'id=1');
    });
  }
}
