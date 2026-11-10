import '../domain/expression_parser.dart';
import '../domain/saving_record.dart';
import 'records_controller.dart';

/// Desktop entry uses the same controller, validation and idempotent repository.
class HomeWidgetService {
  HomeWidgetService(this.controller);
  final RecordsController controller;

  Map<String, Object?> snapshot() => {
    'goalId': controller.goal?.id,
    'name': controller.goal?.name,
    'style': controller.goal?.style ?? 'gift',
    'targetMinor': controller.goal?.targetMinor ?? 0,
    'progressMinor': controller.goalProgressMinor,
    'ready': controller.canWrite,
  };

  Future<Map<String, Object?>> submit(Map<Object?, Object?> request) async {
    final token = request['token'];
    final amount = request['amountMinor'];
    final goalId = request['goalId'];
    final date = request['date'];
    if (token is! String ||
        !token.startsWith('widget:') ||
        token.length > 100 ||
        amount is! int ||
        date is! String ||
        (goalId != null && goalId is! int)) {
      throw const RuleViolation('Invalid widget request');
    }
    // A retry after process death must acknowledge a committed record even if
    // its wish was subsequently changed/deleted or a backup was restored.
    if (controller.busy || !await controller.load()) {
      return {'status': 'unavailable', ...snapshot()};
    }
    final existing = controller.records.where((r) => r.clientToken == token);
    if (existing.isNotEmpty) {
      final record = existing.single;
      if (record.savedMinor != amount || record.occurredOn != date) {
        throw const RuleViolation('Widget request identity mismatch');
      }
      return {'status': 'saved', ...snapshot()};
    }
    if (controller.goal?.id != goalId) {
      return {'status': 'changed', ...snapshot()};
    }
    final now = DateTime.now();
    final record = SavingRecord(
      kind: DecisionKind.quick,
      description: '',
      amountMinor: amount,
      clientToken: token,
      occurredOn: date,
      createdAt: now,
      updatedAt: now,
      today: now,
    );
    final saved = await controller.save(
      record,
      goalId: goalId as int?,
      updateGoal: true,
    );
    return {'status': saved ? 'saved' : 'unavailable', ...snapshot()};
  }
}
