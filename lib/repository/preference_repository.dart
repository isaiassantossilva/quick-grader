import 'package:quick_grader/config/database.dart';

class PreferenceRepository {
  static const int preferenceId = 1;

  Future<bool> isFlashOn() async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.preferencesTable,
      where: "id = ?",
      whereArgs: [preferenceId],
    );
    if (results.isEmpty) {
      await db.insert(DB.preferencesTable, {"id": preferenceId, "flashOn": 0});
      return false;
    }
    return results.first["flashOn"] == 1;
  }

  Future<void> updateFlashPreference(bool flashOn) async {
    final db = await DB.instance.database;
    await db.update(
      DB.preferencesTable,
      {"id": preferenceId, "flashOn": flashOn ? 1 : 0},
      where: "id = ?",
      whereArgs: [preferenceId],
    );
  }
}
