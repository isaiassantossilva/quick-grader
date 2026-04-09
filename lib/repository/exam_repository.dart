import 'dart:convert';

import 'package:quick_grader/model/exam.dart';
import 'package:quick_grader/config/database.dart';

class ExamRepository {
  Future<void> create(Exam exam) async {
    final db = await DB.instance.database;
    final id = await db.insert(DB.examsTable, _examToMap(exam));
    exam.id = id;
  }

  Future<void> update(Exam exam) async {
    final db = await DB.instance.database;
    await db.update(
      DB.examsTable,
      _examToMap(exam),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await DB.instance.database;
    await db.delete(DB.examsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Exam?> findById(int id) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.examsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.map((map) => Exam.fromMap(map)).firstOrNull;
  }

  Future<List<Exam>> findAll() async {
    final db = await DB.instance.database;
    final results = await db.query(DB.examsTable, orderBy: 'name ASC');
    return results.map(_mapToExam).toList();
  }

  Future<List<Exam>> findAllByName(String name) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.examsTable,
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
    return results.map(_mapToExam).toList();
  }

  Map<String, dynamic> _examToMap(Exam exam) {
    final answers = jsonEncode(
      exam.answers.map((k, v) => MapEntry(k.toString(), v)),
    );
    return {...exam.toMap(), "answers": answers};
  }

  Exam _mapToExam(Map<String, dynamic> map) {
    final answers = (jsonDecode(map['answers'] as String) as Map).map(
      (k, v) => MapEntry(int.parse(k), v as int),
    );
    return Exam.fromMap({...map, "answers": answers});
  }
}
