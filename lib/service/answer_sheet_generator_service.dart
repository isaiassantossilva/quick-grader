import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:quick_grader/config/app_config.dart';
import 'package:quick_grader/service/entity/grid.dart';
import 'package:quick_grader/converter/image_converter.dart';
import 'package:quick_grader/service/entity/box.dart';

import 'dart:math' as math;
import 'package:opencv_dart/opencv.dart' as cv;

class GeneratorInputDTO {
  final int numberOfQuestions;
  final int numberOfOptions;

  GeneratorInputDTO({
    required this.numberOfQuestions,
    required this.numberOfOptions,
  });
}

class GeneratorOutputDTO {
  final Uint8List imageBytes;

  GeneratorOutputDTO({required this.imageBytes});
}

class AnswerSheetGeneratorService {
  static const int _boxSideLength = 72;
  static const int _bubbleRadius = 24;
  static const int _textThickness = 2;
  static const int _bubbleThickness = 1;
  static const int _fontFace = cv.FONT_HERSHEY_COMPLEX;
  static const int _headerRow = 1;
  static const int _lineType = cv.LINE_AA;
  static const double _fontScale = 1;
  static const double _maxImageWidth = 1920;
  static const double _maxImageHeight = 1080;

  GeneratorOutputDTO generateAnswerSheet(GeneratorInputDTO input) {
    _validateInput(input);

    log("Starting build grid");
    final grid = _buildGrid(input);

    log("Starting create blank sheet");
    final sheet = _createBlankSheet(grid);
    try {
      log("Starting place corner marker");
      _placeCornerMarkers(sheet, grid);

      log("Starting draw question options");
      _drawQuestionOptions(sheet, grid);

      log("Starting draw question number and bubbles");
      _drawQuestionNumbersAndBubbles(sheet, grid);

      if (AppConfig.isDebugMode) {
        log("Starting draw debug grid");
        _drawDebugGrid(sheet, grid);
      }

      log("Starting resize sheet");
      final resizedSheet = _resizeSheet(sheet);
      try {
        final imageBytes = ImageConverter.convertMatToUint8List(resizedSheet);

        log("Sheet generated successfully");

        return GeneratorOutputDTO(imageBytes: imageBytes);
      } finally {
        resizedSheet.dispose();
      }
    } finally {
      sheet.dispose();
    }
  }

  void _validateInput(GeneratorInputDTO input) {
    if (input.numberOfQuestions < Grid.minNumberOfQuestions ||
        input.numberOfQuestions > Grid.maxNumberOfQuestions) {
      throw Exception(
        "Number of questions should be between ${Grid.minNumberOfQuestions} and ${Grid.maxNumberOfQuestions}",
      );
    }
    if (input.numberOfOptions < Grid.minNumberOfOptions ||
        input.numberOfOptions > Grid.maxNumberOfOptions) {
      throw Exception(
        "Number of options should be between ${Grid.minNumberOfOptions} and ${Grid.maxNumberOfOptions}",
      );
    }
  }

  Grid _buildGrid(GeneratorInputDTO input) {
    return Grid.ofBox(
      numberOfQuestions: input.numberOfQuestions,
      numberOfOptions: input.numberOfOptions,
      boxSize: BoxSize(
        height: _boxSideLength.toDouble(),
        width: _boxSideLength.toDouble(),
      ),
    );
  }

  cv.Mat _createBlankSheet(Grid grid) {
    return cv.Mat.fromScalar(
      grid.sheetSize.height,
      grid.sheetSize.width,
      cv.MatType.CV_8UC1,
      cv.Scalar.white,
    );
  }

  void _placeCornerMarkers(cv.Mat sheet, Grid grid) {
    final cornerBoxes = [
      grid[0][0],
      grid[0][grid.lastColumn],
      grid[grid.lastRow][grid.lastColumn],
      grid[grid.lastRow][0],
    ];

    for (int i = 0; i < Grid.numberOfCornerMarkers; i++) {
      final marker = cv.arucoGenerateImageMarker(
        cv.PredefinedDictionaryType.DICT_6X6_50,
        i,
        _boxSideLength,
        1,
      );

      final box = cornerBoxes[i];
      final markerRegion = cv.Rect(
        box.x.toInt(),
        box.y.toInt(),
        box.width.toInt(),
        box.height.toInt(),
      );
      final markerArea = sheet.region(markerRegion);

      marker.copyTo(markerArea);

      markerArea.dispose();
      marker.dispose();
      markerRegion.dispose();
    }
  }

  void _drawQuestionOptions(cv.Mat sheet, Grid grid) {
    for (int session = 0; session < grid.numberOfSessions; session++) {
      final column = session * (grid.numberOfOptions + 2) + 2;

      for (int option = 0; option < grid.numberOfOptions; option++) {
        final box = grid[_headerRow][column + option];
        final text = String.fromCharCode(0x41 + option);
        _drawCenteredText(sheet, box, text);
      }
    }
  }

  void _drawQuestionNumbersAndBubbles(cv.Mat sheet, Grid grid) {
    for (int question = 1; question <= grid.numberOfQuestions; question++) {
      final row =
          (_headerRow + 1) +
          ((question - 1) % Grid.maxNumberOfQuestionsPerSession);
      final column =
          (grid.numberOfOptions + 2) *
              ((question - 1) ~/ Grid.maxNumberOfQuestionsPerSession) +
          1;

      _drawCenteredText(sheet, grid[row][column], (question).toString());

      for (int option = 0; option < grid.numberOfOptions; option++) {
        final bubbleBox = grid[row][column + option + 1];
        final center = cv.Point(
          (bubbleBox.x + _boxSideLength / 2).toInt(),
          (bubbleBox.y + _boxSideLength / 2).toInt(),
        );

        cv.circle(
          sheet,
          center,
          _bubbleRadius,
          cv.Scalar.black,
          thickness: _bubbleThickness,
          lineType: _lineType,
        );
        center.dispose();
      }
    }
  }

  void _drawCenteredText(cv.Mat sheet, Box box, String text) {
    final (textSize, _) = cv.getTextSize(
      text,
      _fontFace,
      _fontScale,
      _textThickness,
    );

    final textPoint = cv.Point(
      (box.x + (box.width - textSize.width) / 2).toInt(),
      (box.y + (box.height + textSize.height) / 2).toInt(),
    );

    cv.putText(
      sheet,
      text,
      textPoint,
      _fontFace,
      _fontScale,
      cv.Scalar.black,
      thickness: _textThickness,
      lineType: _lineType,
    );

    textSize.dispose();
    textPoint.dispose();
  }

  cv.Mat _resizeSheet(cv.Mat sheet) {
    final newSheet = cv.Mat.fromScalar(
      sheet.rows + (2 * _boxSideLength),
      sheet.cols + (2 * _boxSideLength),
      cv.MatType.CV_8UC1,
      cv.Scalar.white,
    );

    final gridRegion = cv.Rect(
      _boxSideLength,
      _boxSideLength,
      sheet.cols,
      sheet.rows,
    );
    final gridArea = newSheet.region(gridRegion);

    sheet.copyTo(gridArea);

    gridRegion.dispose();
    gridArea.dispose();

    final scale = math.min(
      _maxImageWidth / newSheet.cols,
      _maxImageHeight / newSheet.rows,
    );

    if (scale >= 1.0) {
      return newSheet;
    }

    final newHeight = (newSheet.rows * scale).toInt();
    final newWidth = (newSheet.cols * scale).toInt();

    try {
      return cv.resize(newSheet, (
        newWidth,
        newHeight,
      ), interpolation: cv.INTER_AREA);
    } finally {
      newSheet.dispose();
    }
  }

  void _drawDebugGrid(cv.Mat sheet, Grid grid) {
    for (final row in grid.boxes) {
      for (final box in row) {
        final boxRegion = cv.Rect(
          box.x.toInt(),
          box.y.toInt(),
          box.width.toInt(),
          box.height.toInt(),
        );
        cv.rectangle(sheet, boxRegion, cv.Scalar.black);
        boxRegion.dispose();
      }
    }
  }
}
