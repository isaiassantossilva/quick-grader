import 'package:flutter/material.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/controller/grade_controller.dart';
import 'package:quick_grader/model/exam.dart';
import 'package:quick_grader/model/grade.dart';
import 'package:share_plus/share_plus.dart';

class GradeListPage extends StatefulWidget {
  const GradeListPage({super.key});

  @override
  State<GradeListPage> createState() => _GradeListPageState();
}

class _GradeListPageState extends State<GradeListPage> {
  final _gradeController = DI.get<GradeController>();

  late Exam _exam;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _exam = ModalRoute.of(context)?.settings.arguments as Exam;
    _gradeController.loadGrades(_exam.id!);
  }

  Future<void> _shareReport() async {
    final csvFile = _gradeController.generateCsvFile(_exam.numberOfQuestions);
    final fileName = '${_exam.name}.csv';
    final mimeType = 'text/csv';
    final file = XFile.fromData(csvFile, mimeType: mimeType, name: fileName);
    await Share.shareXFiles([file], fileNameOverrides: [fileName]);
  }

  Future<void> _deleteGrade(Grade grade) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Excluir nota"),
          content: Text(
            "Tem certeza que deseja excluir nota do aluno '${grade.studentName}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _gradeController.deleteGrade(grade.id!);
              },
              child: Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Relatório de Provas"),
        actions: [
          ListenableBuilder(
            listenable: _gradeController,
            builder: (_, __) {
              return IconButton(
                icon: Icon(Icons.share),
                onPressed:
                    _gradeController.grades.isNotEmpty ? _shareReport : null,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                onChanged: (studentName) {
                  _gradeController.filterGrades(_exam.id!, studentName);
                },
                decoration: InputDecoration(
                  hintText: "Pesquisar aluno",
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _gradeController,
                builder: (_, __) {
                  if (_gradeController.state is LoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_gradeController.grades.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum relatório encontrado",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: _gradeController.grades.length,
                    separatorBuilder: (_, __) {
                      return Divider(height: 1, color: Colors.grey.shade300);
                    },
                    itemBuilder: (context, index) {
                      final grade = _gradeController.grades[index];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        title: Text(grade.studentName),
                        subtitle: Text(
                          "${grade.score}/${_exam.numberOfQuestions} - ${(grade.score / _exam.numberOfQuestions * 100).toStringAsFixed(2)}%",
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () {
                            _deleteGrade(grade);
                          },
                        ),
                      );
                    },
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
