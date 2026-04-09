import 'package:quick_grader/model/grade.dart';
import 'package:quick_grader/config/database.dart';

class GradeRepository {
  Future<void> create(Grade grade) async {
    final db = await DB.instance.database;
    final id = await db.insert(DB.gradesTable, grade.toMap());
    grade.id = id;
  }

  Future<void> deleteById(int id) async {
    final db = await DB.instance.database;
    await db.delete(DB.gradesTable, where: "id = ?", whereArgs: [id]);
  }

  Future<List<Grade>> findAllByExamId(int examId) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.gradesTable,
      where: "examId = ?",
      whereArgs: [examId],
      orderBy: "studentName ASC",
    );
    return results.map((map) => Grade.fromMap(map)).toList();
  }

  Future<List<Grade>> findAllByExamIdAndStudentName(
    int examId,
    String studentName,
  ) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.gradesTable,
      where: "examId = ? AND studentName LIKE ?",
      whereArgs: [examId, '%$studentName%'],
      orderBy: "studentName ASC",
    );
    return results.map((map) => Grade.fromMap(map)).toList();
  }
}
