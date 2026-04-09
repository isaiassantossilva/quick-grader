import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/model/exam.dart';

class ExamScannedPage extends StatefulWidget {
  const ExamScannedPage({super.key});

  @override
  State<ExamScannedPage> createState() => _ExamScannedPageState();
}

class _ExamScannedPageState extends State<ExamScannedPage> {
  late Exam _exam;
  late Uint8List _imageBytes;
  late Map<int, Set<int>> _answers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _exam = args['exam'] as Exam;
    _imageBytes = args['imageBytes'] as Uint8List;
    _answers = args['extractedAnswers'] as Map<int, Set<int>>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folha de resposta')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Image.memory(_imageBytes, fit: BoxFit.contain)),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: FilledButton(
                child: Text('Próxima'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.extractedAnswerKeys,
                    arguments: {"exam": _exam, "extractedAnswers": _answers},
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
