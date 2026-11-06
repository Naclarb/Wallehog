import 'saving_record.dart';
import 'wishlist_goal.dart';

abstract interface class RecordRepository {
  Future<List<SavingRecord>> readAll();
  Future<RecordSnapshot> readSnapshot();
  Future<void> createGoal(
    String name,
    int targetMinor, {
    String style = 'gift',
  });
  Future<void> editGoal(String name, int targetMinor, {String? style});
  Future<void> selectGoal(int id);
  Future<void> clearGoal();
  Future<void> save(SavingRecord record);
  Future<void> delete(int id);
  Future<void> close();
}
