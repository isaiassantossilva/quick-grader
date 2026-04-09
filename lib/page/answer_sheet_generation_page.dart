import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grader/service/answer_sheet_generator_service.dart';
import 'package:quick_grader/model/exam.dart';
import 'package:share_plus/share_plus.dart';

enum _PageStatus { loading, success, error }

class AnswerSheetGenerationPage extends StatefulWidget {
  const AnswerSheetGenerationPage({super.key});

  @override
  State<AnswerSheetGenerationPage> createState() =>
      _AnswerSheetGenerationPageState();
}

class _AnswerSheetGenerationPageState extends State<AnswerSheetGenerationPage> {
  _PageStatus _status = _PageStatus.loading;

  late Exam _exam;
  late Uint8List _imageBytes;
  bool get isSuccess => _PageStatus.success == _status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exam = ModalRoute.of(context)?.settings.arguments as Exam;
    _generateAnswerSheet();
  }

  Future<void> _generateAnswerSheet() async {
    try {
      final input = GeneratorInputDTO(
        numberOfQuestions: _exam.numberOfQuestions,
        numberOfOptions: _exam.numberOfOptions,
      );

      _imageBytes = await Isolate.run(() {
        final service = AnswerSheetGeneratorService();
        final output = service.generateAnswerSheet(input);
        return output.imageBytes;
      });

      _status = _PageStatus.success;
    } catch (e) {
      log("Error generating answer sheet", error: e);
      _status = _PageStatus.error;
    }

    setState(() {});
  }

  Future<void> _shareAnswerSheet() async {
    final fileName = '${_exam.name}.png';
    final mimeType = 'image/png';
    final file = XFile.fromData(
      _imageBytes,
      mimeType: mimeType,
      name: fileName,
    );

    await Share.shareXFiles([file], fileNameOverrides: [fileName]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folha de Resposta'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: isSuccess ? _shareAnswerSheet : null,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: switch (_status) {
            _PageStatus.loading => CircularProgressIndicator(),
            _PageStatus.success => Image.memory(_imageBytes),
            _PageStatus.error => Text(
              'Problema ao gerar folha de respostas',
              textAlign: TextAlign.center,
            ),
          },
        ),
      ),
    );
  }
}
