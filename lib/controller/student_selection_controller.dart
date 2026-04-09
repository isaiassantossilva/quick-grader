import 'package:flutter/material.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/model/grade.dart';
import 'package:quick_grader/model/student.dart';
import 'package:quick_grader/repository/grade_repository.dart';
import 'package:quick_grader/repository/studant_repository.dart';

class StudentSelectionController extends ChangeNotifier {
  final StudentRepository studentRepository;
  final GradeRepository gradeRepository;

  ControllerState _state = LoadingState();
  List<Student> _students = [];
  int _selectedStudentIndex = -1;

  StudentSelectionController({
    required this.studentRepository,
    required this.gradeRepository,
  });

  ControllerState get state => _state;
  List<Student> get students => _students;
  Student? get selectedStudent {
    if (_selectedStudentIndex == -1) {
      return null;
    }
    return _students[_selectedStudentIndex];
  }

  Future<void> loadStudents() async {
    _state = LoadingState();
    notifyListeners();
    _students = await studentRepository.findAll();
    _state = DoneState();
    notifyListeners();
  }

  Future<void> filterStudents(String name) async {
    if (_state is LoadingState) {
      return;
    }
    _state = LoadingState();
    notifyListeners();

    if (name.isEmpty) {
      _students = await studentRepository.findAll();
    } else {
      _students = await studentRepository.findAllByName(name);
    }

    _state = DoneState();
    notifyListeners();
  }

  bool isSelected(int index) {
    return _selectedStudentIndex == index;
  }

  void onSelection(int index) {
    if (isSelected(index)) {
      _selectedStudentIndex = -1;
    } else {
      _selectedStudentIndex = index;
    }
    notifyListeners();
  }

  Future<void> addGrade(Map<String, dynamic> input) async {
    _state = LoadingState();
    notifyListeners();
    final grade = Grade.fromMap(input);
    await gradeRepository.create(grade);
  }
}
