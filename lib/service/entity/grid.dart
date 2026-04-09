import 'dart:math' as math;

import 'package:quick_grader/service/entity/box.dart';

class Grid {
  static const int minNumberOfQuestions = 10;
  static const int maxNumberOfQuestions = 160;
  static const int minNumberOfOptions = 2;
  static const int maxNumberOfOptions = 5;

  static const int maxNumberOfQuestionsPerSession = 20;
  static const int numberOfCornerMarkers = 4;
  static const int _maxNumberOfRows = 23;

  final int numberOfQuestions;
  final int numberOfOptions;
  final int numberOfRows;
  final int numberOfColumns;
  final int numberOfSessions;
  final SheetSize sheetSize;
  final BoxSize boxSize;
  final List<List<Box>> boxes;

  int get fisrtRow => 0;
  int get lastRow => numberOfRows - 1;
  int get firstColumn => 0;
  int get lastColumn => numberOfColumns - 1;

  Grid({
    required this.numberOfQuestions,
    required this.numberOfOptions,
    required this.numberOfRows,
    required this.numberOfColumns,
    required this.numberOfSessions,
    required this.sheetSize,
    required this.boxSize,
    required this.boxes,
  });

  factory Grid.ofSheet({
    required int numberOfQuestions,
    required int numberOfOptions,
    required SheetSize sheetSize,
  }) {
    final numberOfRows = _calculateNumberOfRows(numberOfQuestions);

    final numberOfSessions = _calculateNumberOfSessions(numberOfQuestions);

    final numberOfColumns = _calculateNumberOfColumns(
      numberOfOptions,
      numberOfSessions,
    );

    final boxSize = BoxSize(
      height: (sheetSize.height + 1) / numberOfRows,
      width: (sheetSize.width + 1) / numberOfColumns,
    );

    final boxes = _buildBoxes(numberOfRows, numberOfColumns, boxSize);

    return Grid(
      numberOfQuestions: numberOfQuestions,
      numberOfOptions: numberOfOptions,
      numberOfRows: numberOfRows,
      numberOfColumns: numberOfColumns,
      numberOfSessions: numberOfSessions,
      sheetSize: sheetSize,
      boxSize: boxSize,
      boxes: boxes,
    );
  }

  factory Grid.ofBox({
    required int numberOfQuestions,
    required int numberOfOptions,
    required BoxSize boxSize,
  }) {
    final numberOfRows = _calculateNumberOfRows(numberOfQuestions);

    final numberOfSessions = _calculateNumberOfSessions(numberOfQuestions);

    final numberOfColumns = _calculateNumberOfColumns(
      numberOfOptions,
      numberOfSessions,
    );

    final sheetSize = SheetSize(
      height: (numberOfRows * boxSize.height).toInt(),
      width: (numberOfColumns * boxSize.width).toInt(),
    );

    final boxes = _buildBoxes(numberOfRows, numberOfColumns, boxSize);

    return Grid(
      numberOfQuestions: numberOfQuestions,
      numberOfOptions: numberOfOptions,
      numberOfRows: numberOfRows,
      numberOfColumns: numberOfColumns,
      numberOfSessions: numberOfSessions,
      sheetSize: sheetSize,
      boxSize: boxSize,
      boxes: boxes,
    );
  }

  static int _calculateNumberOfRows(int numberOfQuestions) {
    return math.min(_maxNumberOfRows, numberOfQuestions + 3);
  }

  static int _calculateNumberOfSessions(int numberOfQuestions) {
    return (numberOfQuestions / maxNumberOfQuestionsPerSession).ceil();
  }

  static int _calculateNumberOfColumns(
    int numberOfOptions,
    int numberOfSessions,
  ) {
    return (numberOfOptions + 1) * numberOfSessions +
        (numberOfSessions - 1) +
        2;
  }

  static List<List<Box>> _buildBoxes(
    int numberOfRows,
    int numberOfColumns,
    BoxSize boxSize,
  ) {
    return List.generate(numberOfRows, (row) {
      return List.generate(numberOfColumns, (column) {
        return Box(
          x: column * boxSize.width,
          y: row * boxSize.height,
          width: boxSize.width,
          height: boxSize.height,
        );
      }, growable: false);
    }, growable: false);
  }

  List<Box> operator [](int row) => boxes[row];
}

class SheetSize {
  final int height;
  final int width;

  SheetSize({required this.height, required this.width});
}

class BoxSize {
  final double height;
  final double width;

  BoxSize({required this.height, required this.width});
}
