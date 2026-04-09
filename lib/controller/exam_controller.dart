import 'package:flutter/foundation.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/model/exam.dart';
import 'package:quick_grader/repository/exam_repository.dart';

class ExamController extends ChangeNotifier {
  final ExamRepository examRepository;

  ControllerState _state = LoadingState();
  List<Exam> _exams = [];

  ExamController({required this.examRepository});

  ControllerState get state => _state;
  List<Exam> get exams => _exams;

  Future<void> loadExams() async {
    _state = LoadingState();
    notifyListeners();
    _exams = await examRepository.findAll();
    _state = DoneState();
    notifyListeners();
  }

  Future<void> addExam(Map<String, dynamic> input) async {
    final exam = Exam.fromMap(input);
    await examRepository.create(exam);
    _exams.insert(0, exam);
    notifyListeners();
  }

  Future<void> updateExame(Map<String, dynamic> input) async {
    final id = input['id'] as int;
    final exam = _exams.where((e) => e.id == id).firstOrNull;
    if (exam == null) {
      return;
    }
    exam.name = input['name'] as String;
    exam.numberOfQuestions = input['numberOfQuestions'] as int;
    exam.numberOfOptions = input['numberOfOptions'] as int;
    exam.answers = (input['answers'] as Map<int, int>);
    exam.answers.removeWhere((key, _) => key > exam.numberOfQuestions);
    await examRepository.update(exam);
    notifyListeners();
  }

  Future<void> deleteExam(int id) async {
    await examRepository.deleteById(id);
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> filterExams(String name) async {
    if (_state is LoadingState) {
      return;
    }
    _state = LoadingState();
    notifyListeners();

    if (name.isEmpty) {
      _exams = await examRepository.findAll();
    } else {
      _exams = await examRepository.findAllByName(name);
    }

    _state = DoneState();
    notifyListeners();
  }
}
