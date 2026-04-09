/*
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quick_grader/service/answer_sheet_generator_service.dart';
import 'package:external_path/external_path.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AnswerSheetGeneratorService answerSheetGeneratorService;

  setUp(() {
    answerSheetGeneratorService = AnswerSheetGeneratorService();
  });

  test('Deve criar um png com uma folha de resposta', () async {
    final generateAnswerSheetInputDTO = GeneratorInputDTO(
      numberOfQuestions: 30,
      numberOfOptions: 5,
    );

    final generateAnswerSheetOutputDTO = await answerSheetGeneratorService
        .generateAnswerSheet(generateAnswerSheetInputDTO);

    expect(generateAnswerSheetOutputDTO, isNotNull);

    // Salvar arquivo para verificação visual
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS,
    );
    final filePath =
        '$directory/test_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);

    await file.writeAsBytes(generateAnswerSheetOutputDTO.answerSheet);

    debugPrint('File saved at: $filePath');
  });
}
*/
