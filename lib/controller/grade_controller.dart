import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/model/grade.dart';
import 'package:quick_grader/repository/grade_repository.dart';

class GradeController extends ChangeNotifier {
  final GradeRepository gradeRepository;

  ControllerState _state = LoadingState();
  List<Grade> _grades = [];

  GradeController({required this.gradeRepository});

  ControllerState get state => _state;
  List<Grade> get grades => _grades;

  Future<void> loadGrades(int examId) async {
    _state = LoadingState();
    notifyListeners();
    _grades = await gradeRepository.findAllByExamId(examId);
    _state = DoneState();
    notifyListeners();
  }

  Future<void> deleteGrade(int id) async {
    await gradeRepository.deleteById(id);
    _grades.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> filterGrades(int examId, String studentName) async {
    if (_state is LoadingState) {
      return;
    }
    _state = LoadingState();
    notifyListeners();

    if (studentName.isEmpty) {
      _grades = await gradeRepository.findAllByExamId(examId);
    } else {
      _grades = await gradeRepository.findAllByExamIdAndStudentName(
        examId,
        studentName,
      );
    }

    _state = DoneState();
    notifyListeners();
  }

  Uint8List generateCsvFile(int numberOfQuestions) {
    final buffer = StringBuffer();
    buffer.writeln('Aluno,Nota,%');
    for (final grade in grades) {
      buffer.writeln(
        "${grade.studentName},${grade.score}/$numberOfQuestions',${(grade.score / numberOfQuestions * 100).toStringAsFixed(2)}'",
      );
    }
    return utf8.encode(buffer.toString());
  }
}
