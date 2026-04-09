/*
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_grader/entity/answer_key.dart';
import 'package:quick_grader/service/answer_sheet_correction_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AnswerSheetCorrectionService answerSheetCorrectionService;

  setUp(() {
    answerSheetCorrectionService = AnswerSheetCorrectionService();
  });

  test('Deve corrigir uma folha de resposta corretamente', () async {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );

    final status = await Permission.storage.request();
    expect(status.isGranted, true);

    var file = File('$directory/30-q-r-2.jpg');

    final answerSheetBytes = await file.readAsBytes();

    final answerKeys = [                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
      AnswerKey(questionNumber: 1, optionNumber: 0),
      AnswerKey(questionNumber: 2, optionNumber: 1),
      AnswerKey(questionNumber: 3, optionNumber: 2),
    ];

    final correctAnswerSheetInputDTO = CorrectAnswerSheetInputDTO(
      answerSheet: answerSheetBytes,
      numberOfQuestions: 30,
      numberOfOptions: 5,
      answerKeys: answerKeys,
    );

    final correctAnswerSheetOutputDTO = await answerSheetCorrectionService
        .correctAnswerSheet(correctAnswerSheetInputDTO);

    expect(correctAnswerSheetOutputDTO, isNotNull);

    file = File('$directory/test_${DateTime.now().millisecondsSinceEpoch}.png');

    await file.writeAsBytes(correctAnswerSheetOutputDTO.answerSheet);

    debugPrint('File saved at: ${file.path}');

    final countCorrectAnswers =
        correctAnswerSheetOutputDTO.answers
            .where((answer) => answer.isCorrect)
            .length;

    debugPrint('Total correct answers: $countCorrectAnswers');

    for (final answer in correctAnswerSheetOutputDTO.answers) {
      debugPrint(
        'Question: ${answer.questionNumber}, Correct: ${answer.isCorrect}, Filled options: ${answer.selectedOptions}',
      );
    }
  });
}
*/
