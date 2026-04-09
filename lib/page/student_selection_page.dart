import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/controller/student_selection_controller.dart';
import 'package:quick_grader/model/exam.dart';

class StudentSelectionPage extends StatefulWidget {
  const StudentSelectionPage({super.key});

  @override
  State<StudentSelectionPage> createState() => _StudentSelectionPageState();
}

class _StudentSelectionPageState extends State<StudentSelectionPage> {
  late final StudentSelectionController _studentSelectionController =
      DI.get<StudentSelectionController>();

  late Exam _exam;
  late int _score;

  @override
  void initState() {
    super.initState();
    _studentSelectionController.loadStudents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _exam = args['exam'] as Exam;
    _score = args['score'] as int;
  }

  @override
  void dispose() {
    _studentSelectionController.dispose();
    super.dispose();
  }

  Future<void> _showAlertDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione um aluno'),
          content: Text('Por favor, selecione um aluno!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGrade(bool nextExam) async {
    final student = _studentSelectionController.selectedStudent;

    if (student == null) {
      await _showAlertDialog();
      return;
    }

    await _studentSelectionController.addGrade({
      "studentName": student.fullName,
      "examId": _exam.id,
      "score": _score,
    });

    if (!mounted) {
      return;
    }

    Navigator.of(context)
      ..pop()
      ..pop()
      ..pop();

    if (nextExam) {
      Navigator.of(context).pushNamed(AppRoutes.examScan, arguments: _exam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alunos")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                onChanged: _studentSelectionController.filterStudents,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: "Pesquisar aluno",
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _studentSelectionController,
                builder: (_, __) {
                  if (_studentSelectionController.state is LoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_studentSelectionController.students.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum aluno encontrado",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: _studentSelectionController.students.length,
                    separatorBuilder: (_, __) {
                      return Divider(height: 1, color: Colors.grey.shade300);
                    },
                    itemBuilder: (_, index) {
                      final student =
                          _studentSelectionController.students[index];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        leading: Checkbox(
                          value: _studentSelectionController.isSelected(index),
                          onChanged: (_) {
                            _studentSelectionController.onSelection(index);
                          },
                        ),
                        title: Text(student.fullName),
                        onTap: () {
                          _studentSelectionController.onSelection(index);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListenableBuilder(
                listenable: _studentSelectionController,
                builder: (_, __) {
                  if (_studentSelectionController.state is LoadingState) {
                    return Container();
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _saveGrade(false);
                          },
                          child: Text('Concluir'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _saveGrade(true);
                          },
                          child: Text('Próxima'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
