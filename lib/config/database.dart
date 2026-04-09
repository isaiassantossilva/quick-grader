import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static const String databaseName = "quick_grader.db";
  static const int databaseVersion = 1;

  static final DB instance = DB._();

  static Database? _database;

  DB._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createExamsTableScript);
    await db.execute(_createGradesTableScript);
    await db.execute(_createStudentsTableScript);
    await db.execute(_createPreferencesTableScript);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> delete() async {
    final path = join(await getDatabasesPath(), databaseName);
    await deleteDatabase(path);
    _database = null;
  }

  static const String examsTable = "exams";
  static const String _createExamsTableScript = '''
      CREATE TABLE $examsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        numberOfQuestions INTEGER NOT NULL,
        numberOfOptions INTEGER NOT NULL,
        answers TEXT
      )
    ''';

  static const String gradesTable = "grades";
  static const String _createGradesTableScript = '''
      CREATE TABLE $gradesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId INTEGER NOT NULL,
        studentName TEXT NOT NULL,
        score INTEGER NOT NULL,
        FOREIGN KEY (examId) REFERENCES $examsTable (id) ON DELETE CASCADE
      )
    ''';

  static const String studentsTable = "students";
  static const String _createStudentsTableScript = '''
      CREATE TABLE $studentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL
      )
    ''';

  static const String preferencesTable = "preferences";
  static const String _createPreferencesTableScript = '''
      CREATE TABLE $preferencesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flashOn INTEGER NOT NULL
      )
    ''';
}
