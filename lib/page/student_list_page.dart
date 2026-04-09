import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/state/controller_state.dart';
import 'package:quick_grader/controller/student_controller.dart';
import 'package:quick_grader/model/student.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _studentController = DI.get<StudentController>();

  @override
  void initState() {
    super.initState();
    _studentController.loadStudents();
  }

  void _deleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Excluir aluno"),
          content: Text(
            "Tem certeza que deseja excluir '${student.fullName}'?",
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
                await _studentController.deleteStudent(student.id!);
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
        title: Text("Alunos"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.studentForm);
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
                onChanged: _studentController.filterStudents,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
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
                listenable: _studentController,
                builder: (_, __) {
                  if (_studentController.state is LoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_studentController.students.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum aluno encontrado",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: _studentController.students.length,
                    separatorBuilder: (_, __) {
                      return Divider(height: 1, color: Colors.grey.shade300);
                    },
                    itemBuilder: (context, index) {
                      final student = _studentController.students[index];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        title: Text(student.fullName),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () {
                            _deleteStudent(student);
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.studentForm,
                            arguments: student,
                          );
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
