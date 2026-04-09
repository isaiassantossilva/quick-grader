import 'package:quick_grader/model/student.dart';
import 'package:quick_grader/config/database.dart';

class StudentRepository {
  Future<void> create(Student student) async {
    final db = await DB.instance.database;
    final id = await db.insert(DB.studentsTable, student.toMap());
    student.id = id;
  }

  Future<void> update(Student student) async {
    final db = await DB.instance.database;
    await db.update(
      DB.studentsTable,
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id!],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await DB.instance.database;
    await db.delete(DB.studentsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Student?> findById(int id) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.studentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.map((map) => Student.fromMap(map)).firstOrNull;
  }

  Future<List<Student>> findAll() async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.studentsTable,
      orderBy: 'firstName ASC, lastName ASC',
    );
    return results.map((map) => Student.fromMap(map)).toList();
  }

  Future<List<Student>> findAllByName(String name) async {
    final db = await DB.instance.database;
    final results = await db.query(
      DB.studentsTable,
      where: 'firstName LIKE ? OR lastName LIKE ?',
      whereArgs: ['%$name%', '%$name%'],
      orderBy: 'firstName ASC, lastName ASC',
    );
    return results.map((map) => Student.fromMap(map)).toList();
  }
}
