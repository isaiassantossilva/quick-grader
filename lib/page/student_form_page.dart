import 'package:flutter/material.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/student_controller.dart';
import 'package:quick_grader/model/student.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key});

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _studentController = DI.get<StudentController>();

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameTextController;
  late TextEditingController _lastNameTextController;

  Student? _student;

  @override
  void initState() {
    super.initState();
    _firstNameTextController = TextEditingController();
    _lastNameTextController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _student = ModalRoute.of(context)?.settings.arguments as Student?;
    if (_student == null) {
      return;
    }
    _firstNameTextController.text = _student!.firstName;
    _lastNameTextController.text = _student!.lastName;
  }

  @override
  void dispose() {
    _firstNameTextController.dispose();
    _lastNameTextController.dispose();
    super.dispose();
  }

  Future<void> _saveSudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameTextController.text.trim();
    final lastName = _lastNameTextController.text.trim();

    if (_student == null) {
      await _studentController.addStudent({
        'firstName': firstName,
        'lastName': lastName,
      });
    } else {
      await _studentController.updateStudent({
        'id': _student!.id!,
        'firstName': firstName,
        'lastName': lastName,
      });
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar aluno'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveSudent)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            TextFormField(
              controller: _firstNameTextController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              validator: (firstName) {
                if (firstName == null || firstName.trim().isEmpty) {
                  return "O nome do aluno é obrigatório";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Nome do aluno",
                hintText: "Nome do aluno",
                helperText: "",
                border: OutlineInputBorder(),
              ),
            ),

            TextFormField(
              controller: _lastNameTextController,
              textCapitalization: TextCapitalization.words,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              validator: (lastName) {
                if (lastName == null || lastName.trim().isEmpty) {
                  return "O sobrenome do aluno é obrigatório";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Sobrenome do aluno",
                hintText: "Sobrenome do aluno",
                helperText: "",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
