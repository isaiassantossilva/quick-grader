import 'package:flutter/foundation.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/model/student.dart';
import 'package:quick_grader/repository/studant_repository.dart';

class StudentController extends ChangeNotifier {
  final StudentRepository studentRepository;

  ControllerState _state = LoadingState();
  List<Student> _students = [];

  StudentController({required this.studentRepository});

  ControllerState get state => _state;
  List<Student> get students => _students;

  Future<void> loadStudents() async {
    _state = LoadingState();
    notifyListeners();
    _students = await studentRepository.findAll();
    _state = DoneState();
    notifyListeners();
  }

  Future<void> addStudent(Map<String, dynamic> input) async {
    final student = Student.fromMap(input);
    await studentRepository.create(student);
    _students.insert(0, student);
    notifyListeners();
  }

  Future<void> updateStudent(Map<String, dynamic> input) async {
    final id = input['id'] as int;
    final student = _students.where((e) => e.id == id).firstOrNull;
    if (student == null) {
      return;
    }
    student.firstName = input['firstName'] as String;
    student.lastName = input['lastName'] as String;
    await studentRepository.update(student);
    notifyListeners();
  }

  Future<void> deleteStudent(int id) async {
    await studentRepository.deleteById(id);
    _students.removeWhere((s) => s.id == id);
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
}
