import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/exam_controller.dart';
import 'package:quick_grader/model/exam.dart';

class ExamFormPage extends StatefulWidget {
  const ExamFormPage({super.key});

  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  static const _minQuestions = 10;
  static const _maxQuestions = 160;
  static const _minOptions = 2;
  static const _maxOptions = 5;

  final _examController = DI.get<ExamController>();

  final _formKey = GlobalKey<FormState>();

  final _examNameTextController = TextEditingController();
  final _numberOfQuestionsTextController = TextEditingController();
  final _numberOfOptionsTextController = TextEditingController();

  Exam? _exam;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _exam = ModalRoute.of(context)?.settings.arguments as Exam?;
    if (_exam == null) {
      return;
    }
    _examNameTextController.text = _exam!.name;
    _numberOfQuestionsTextController.text = '${_exam!.numberOfQuestions}';
    _numberOfOptionsTextController.text = '${_exam!.numberOfOptions}';
  }

  @override
  void dispose() {
    _examNameTextController.dispose();
    _numberOfQuestionsTextController.dispose();
    _numberOfOptionsTextController.dispose();
    super.dispose();
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final examName = _examNameTextController.text.trim();
    final numberOfQuestions = int.parse(
      _numberOfQuestionsTextController.text.trim(),
    );
    final numberOfOptions = int.parse(
      _numberOfOptionsTextController.text.trim(),
    );

    if (_exam == null) {
      await _examController.addExam({
        "name": examName,
        "numberOfQuestions": numberOfQuestions,
        "numberOfOptions": numberOfOptions,
        "answers": <int, int>{},
      });
    } else {
      await _examController.updateExame({
        "id": _exam!.id!,
        "name": examName,
        "numberOfQuestions": numberOfQuestions,
        "numberOfOptions": numberOfOptions,
        "answers": _exam!.answers,
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
        title: Text('Editar prova'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveExam)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            TextFormField(
              controller: _examNameTextController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              validator: (examName) {
                if (examName == null || examName.trim().isEmpty) {
                  return "O nome da prova é obrigatório";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Nome da prova",
                hintText: "Nome da prova",
                helperText: "",
                border: OutlineInputBorder(),
              ),
            ),

            TextFormField(
              controller: _numberOfQuestionsTextController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              validator: (numberOfQuestions) {
                if (numberOfQuestions == null ||
                    numberOfQuestions.trim().isEmpty) {
                  return "O número de questões é obrigatório";
                }
                if (int.parse(numberOfQuestions) < _minQuestions ||
                    int.parse(numberOfQuestions) > _maxQuestions) {
                  return "O número de questões deve ser entre $_minQuestions e $_maxQuestions";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText:
                    "Número de questões ($_minQuestions a $_maxQuestions)",
                hintText:
                    "Número de questões ($_minQuestions a $_maxQuestions)",
                helperText: "",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),

            TextFormField(
              controller: _numberOfOptionsTextController,
              keyboardType: TextInputType.number,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              validator: (numberOfOptions) {
                if (numberOfOptions == null || numberOfOptions.trim().isEmpty) {
                  return "O número de opções é obrigatório";
                }
                if (int.parse(numberOfOptions) < _minOptions ||
                    int.parse(numberOfOptions) > _maxOptions) {
                  return "O número de opções deve ser entre $_minOptions e $_maxOptions";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Número de opções ($_minOptions a $_maxOptions)",
                hintText: "Número de opções ($_minOptions a $_maxOptions)",
                helperText: "",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
