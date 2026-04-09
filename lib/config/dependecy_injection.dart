import 'package:get_it/get_it.dart';
import 'package:quick_grader/controller/exam_controller.dart';
import 'package:quick_grader/controller/grade_controller.dart';
import 'package:quick_grader/controller/scan_controller.dart';
import 'package:quick_grader/controller/student_controller.dart';
import 'package:quick_grader/controller/student_selection_controller.dart';
import 'package:quick_grader/repository/exam_repository.dart';
import 'package:quick_grader/repository/preference_repository.dart';
import 'package:quick_grader/repository/grade_repository.dart';
import 'package:quick_grader/repository/studant_repository.dart';

abstract class DI {
  static final GetIt _getIt = GetIt.instance;

  static void configureDependencies() {
    // Repositories
    final preferenceRepository = PreferenceRepository();
    final studentRepository = StudentRepository();
    final examRepository = ExamRepository();
    final gradeRepository = GradeRepository();

    // Singleton
    _getIt.registerSingleton(
      StudentController(studentRepository: studentRepository),
    );
    _getIt.registerSingleton(ExamController(examRepository: examRepository));
    _getIt.registerSingleton(GradeController(gradeRepository: gradeRepository));

    // Factory
    _getIt.registerFactory(
      () => ScanController(preferenceRepository: preferenceRepository),
    );
    _getIt.registerFactory(
      () => StudentSelectionController(
        studentRepository: studentRepository,
        gradeRepository: gradeRepository,
      ),
    );
  }

  static T get<T extends Object>() {
    return _getIt.get<T>();
  }
}
