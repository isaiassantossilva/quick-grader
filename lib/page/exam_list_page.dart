import 'package:flutter/material.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/controller/exam_controller.dart';
import 'package:quick_grader/model/exam.dart';

class ExamListPage extends StatefulWidget {
  const ExamListPage({super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  final _examController = DI.get<ExamController>();

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _examController.loadExams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteExam(Exam exam) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Excluir prova"),
          content: Text("Tem certeza que deseja excluir '${exam.name}'?"),
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
                await _examController.deleteExam(exam.id!);
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
        title: Text("Provas"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.examForm);
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
                onChanged: _examController.filterExams,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: "Pesquisar prova",
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _examController,
                builder: (_, __) {
                  if (_examController.state is LoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_examController.exams.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhuma prova encontrada",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: _examController.exams.length,
                    separatorBuilder: (_, __) {
                      return Divider(height: 1, color: Colors.grey.shade300);
                    },
                    itemBuilder: (_, index) {
                      final exam = _examController.exams[index];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        title: Text(exam.name),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () async {
                            await _deleteExam(exam);
                          },
                        ),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.examDetails, arguments: exam);
                        },
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
