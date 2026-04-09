import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/model/exam.dart';

class ExamDetailsPage extends StatefulWidget {
  const ExamDetailsPage({super.key});

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  late Exam _exam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exam = ModalRoute.of(context)?.settings.arguments as Exam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da prova'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.examForm, arguments: _exam);
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: [
          Text(
            _exam.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined),
              SizedBox(width: 12),
              Text('${_exam.numberOfQuestions} Questões'),
            ],
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_list_bulleted),
              SizedBox(width: 12),
              Text('${_exam.numberOfOptions} Opções'),
            ],
          ),

          SizedBox(height: 24.0),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FilledButton(
              child: Text('Editar gabarito'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.editAnswerKeys, arguments: _exam);
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FilledButton(
              child: Text('Gerar folha de respostas'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.answerSheetGeneration, arguments: _exam);
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FilledButton(
              child: Text('Relatório'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.gradeList, arguments: _exam);
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FilledButton(
              child: Text('Corrigir prova'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.examScan, arguments: _exam);
              },
            ),
          ),
        ],
      ),
    );
  }
}
