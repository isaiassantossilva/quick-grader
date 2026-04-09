import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:quick_grader/config/app_config.dart';
import 'package:quick_grader/service/entity/grid.dart';
import 'package:quick_grader/converter/image_converter.dart';
import 'package:quick_grader/service/entity/marker.dart';

import 'dart:math' as math;
import 'package:opencv_dart/opencv.dart' as cv;

class FindAnswerKeyInputDTO {
  final Uint8List imageBytes;

  FindAnswerKeyInputDTO({required this.imageBytes});
}

class FindAnswerKeyOutputDTO {
  final Uint8List imageBytes;
  final Uint8List imageGrayBytes;
  final List<Marker> markers;

  FindAnswerKeyOutputDTO({
    required this.imageBytes,
    required this.imageGrayBytes,
    required this.markers,
  });
}

class ExtractAnswersInputDTO {
  final int numberOfQuestions;
  final int numberOfOptions;
  final Uint8List imageBytes;
  final Uint8List imageGrayBytes;
  final List<Marker> markers;

  ExtractAnswersInputDTO({
    required this.numberOfQuestions,
    required this.numberOfOptions,
    required this.imageBytes,
    required this.imageGrayBytes,
    required this.markers,
  });
}

class ExtractAnswersOutputDTO {
  final Uint8List imageBytes;
  final Map<int, Set<int>> answers;

  ExtractAnswersOutputDTO({required this.imageBytes, required this.answers});
}

class AnswerSheetExtractorService {
  static const double _minFillPercentage = 0.7;

  FindAnswerKeyOutputDTO findAnswerKey(FindAnswerKeyInputDTO input) {
    cv.Mat? imageColor;
    cv.Mat? imageGray;
    try {
      log("Starting image bytes to image mat conversion");
      imageColor = _convertBytesToMat(input.imageBytes, cv.IMREAD_COLOR);

      log("Starting image color to image gray conversion");
      imageGray = _convertToGray(imageColor);

      log("Starting markers detection");
      final markers = _detectCornerMarkers(imageGray);

      log("Starting image mat to image bytes conversion");
      final imageBytes = ImageConverter.convertMatToUint8List(imageColor);

      log("Starting image gray mat to image gray bytes conversion");
      final imageGrayBytes = ImageConverter.convertMatToUint8List(imageGray);

      log("Answer key successfully found");

      return FindAnswerKeyOutputDTO(
        imageBytes: imageBytes,
        imageGrayBytes: imageGrayBytes,
        markers: markers,
      );
    } finally {
      imageColor?.dispose();
      imageGray?.dispose();
    }
  }

  ExtractAnswersOutputDTO extractAnswers(ExtractAnswersInputDTO input) {
    _validateInput(input);

    cv.Mat? imageColor;
    cv.Mat? imageGray;
    cv.Mat? imageBinary;
    try {
      log("Starting image color bytes to image color mat conversion");
      imageColor = _convertBytesToMat(input.imageBytes, cv.IMREAD_COLOR);

      log("Starting image gray bytes to image gray mat conversion");
      imageGray = _convertBytesToMat(input.imageGrayBytes, cv.IMREAD_GRAYSCALE);

      log("Starting grid initialization");
      final grid = _buildGrid(input, input.markers);

      log("Starting adjust perspective transform");
      imageColor = _adjustPerspectiveTransform(imageColor, grid, input.markers);
      imageGray = _adjustPerspectiveTransform(imageGray, grid, input.markers);

      log("Starting binarization");
      imageBinary = _binarize(imageGray);

      log("Starting to extract the answers");
      final answers = _extractAnswers(imageColor, imageBinary, grid);

      if (AppConfig.isDebugMode) {
        log("Starting debug grid draw");
        _drawDebugGrid(imageColor, grid);
      }

      final imageBytes = ImageConverter.convertMatToUint8List(imageColor);

      log("Answers successfully extracted");

      return ExtractAnswersOutputDTO(imageBytes: imageBytes, answers: answers);
    } finally {
      imageColor?.dispose();
      imageGray?.dispose();
      imageBinary?.dispose();
    }
  }

  void _validateInput(ExtractAnswersInputDTO input) {
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

  cv.Mat _convertBytesToMat(Uint8List imageBytes, int flag) {
    return cv.imdecode(imageBytes, flag);
  }

  cv.Mat _convertToGray(cv.Mat imageColor) {
    return cv.cvtColor(imageColor, cv.COLOR_BGR2GRAY);
  }

  List<Marker> _detectCornerMarkers(cv.Mat imageGray) {
    final dictionary = cv.ArucoDictionary.predefined(
      cv.PredefinedDictionaryType.DICT_6X6_50,
    );
    final parameters = cv.ArucoDetectorParameters.empty();
    final detector = cv.ArucoDetector.create(dictionary, parameters);

    try {
      final (corners, ids, rejected) = detector.detectMarkers(imageGray);

      try {
        if (ids.size() != Grid.numberOfCornerMarkers) {
          throw Exception('${ids.size()} corners detected');
        }

        return List.generate(
          ids.length,
          (i) => Marker(
            id: ids[i],
            points: corners[i].map((p) => Point(x: p.x, y: p.y)).toList(),
          ),
        );
      } finally {
        corners.dispose();
        ids.dispose();
        rejected.dispose();
      }
    } finally {
      dictionary.dispose();
      parameters.dispose();
      detector.dispose();
    }
  }

  Grid _buildGrid(ExtractAnswersInputDTO input, List<Marker> markers) {
    final boxSideLength =
        (markers.map(_markerSideLength).reduce((a, b) => a + b) /
                markers.length)
            .roundToDouble();

    return Grid.ofBox(
      numberOfQuestions: input.numberOfQuestions,
      numberOfOptions: input.numberOfOptions,
      boxSize: BoxSize(height: boxSideLength, width: boxSideLength),
    );
  }

  double _markerSideLength(Marker marker) {
    final points = marker.points;
    double totalLength = 0;
    for (int i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      totalLength += math.sqrt(
        math.pow(points[i].x - points[next].x, 2) +
            math.pow(points[i].y - points[next].y, 2),
      );
    }
    return totalLength / points.length;
  }

  cv.Mat _adjustPerspectiveTransform(
    cv.Mat image,
    Grid grid,
    List<Marker> markers,
  ) {
    final points = List.generate(markers.length, (i) {
      final marker = markers.firstWhere((m) => m.id == i);
      return marker.points[i];
    });

    final height = grid.sheetSize.height;
    final width = grid.sheetSize.width;

    final srcPoints = points.map((p) => cv.Point2f(p.x, p.y)).toList();

    final dstPoints = [
      cv.Point2f(0, 0),
      cv.Point2f(width - 1, 0),
      cv.Point2f(width - 1, height - 1),
      cv.Point2f(0, height - 1),
    ];

    cv.VecPoint2f srcVec = cv.VecPoint2f.fromList(srcPoints);
    cv.VecPoint2f dstVec = cv.VecPoint2f.fromList(dstPoints);
    try {
      cv.Mat matrix = cv.getPerspectiveTransform2f(srcVec, dstVec);
      try {
        return cv.warpPerspective(image, matrix, (width, height), dst: image);
      } finally {
        matrix.dispose();
      }
    } finally {
      for (final point in [...srcPoints, ...dstPoints]) {
        point.dispose();
      }
      srcVec.dispose();
      dstVec.dispose();
    }
  }

  cv.Mat _binarize(cv.Mat imageGray) {
    cv.Mat? threshold;
    cv.CLAHE? clahe;
    cv.Mat? kernel;
    try {
      threshold = imageGray.clone();

      clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
      clahe.apply(threshold, dst: threshold);

      cv.gaussianBlur(threshold, (7, 7), 0, dst: threshold);

      cv.adaptiveThreshold(
        threshold,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        511,
        32,
        dst: threshold,
      );

      kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (7, 7));
      // cv.morphologyEx(threshold, cv.MORPH_OPEN, kernel, dst: threshold);
      cv.morphologyEx(threshold, cv.MORPH_CLOSE, kernel, dst: threshold);
      cv.morphologyEx(threshold, cv.MORPH_OPEN, kernel, dst: threshold);

      return threshold;
    } finally {
      clahe?.dispose();
      kernel?.dispose();
    }
  }

  Map<int, Set<int>> _extractAnswers(
    cv.Mat imageColor,
    cv.Mat imageBinary,
    Grid grid,
  ) {
    final markColor = cv.Scalar.fromRgb(255, 255, 0);
    final numberOfQuestions = grid.numberOfQuestions;
    final numberOfOptions = grid.numberOfOptions;
    final answers = <int, Set<int>>{};

    for (
      int questionNumber = 1;
      questionNumber <= numberOfQuestions;
      questionNumber++
    ) {
      final row =
          ((questionNumber - 1) % Grid.maxNumberOfQuestionsPerSession) + 2;
      final column =
          (numberOfOptions + 2) *
              ((questionNumber - 1) ~/ Grid.maxNumberOfQuestionsPerSession) +
          2;

      for (
        int optionNumber = 0;
        optionNumber < numberOfOptions;
        optionNumber++
      ) {
        final box = grid[row][column + optionNumber];

        final bubbleRadius = ((box.width / 3 + box.height / 3) / 2).toInt();

        final bubbleCenter = cv.Point(
          (box.x + box.width / 2).toInt(),
          (box.y + box.height / 2).toInt(),
        );

        final bubbleRegion = cv.Rect(
          bubbleCenter.x - (bubbleRadius / 2).toInt(),
          bubbleCenter.y - (bubbleRadius / 2).toInt(),
          bubbleRadius,
          bubbleRadius,
        );

        final bubbleArea = imageBinary.region(bubbleRegion);
        final totalPixels = bubbleArea.rows * bubbleArea.cols;
        final fillPercentage = cv.countNonZero(bubbleArea) / totalPixels;

        log(
          'Question: $questionNumber, Option: ${String.fromCharCode(0x41 + optionNumber)}, Fill Percentage: $fillPercentage',
        );

        if (fillPercentage > _minFillPercentage) {
          cv.circle(imageColor, bubbleCenter, bubbleRadius, markColor);
          cv.rectangle(
            imageColor,
            bubbleRegion,
            markColor,
            thickness: cv.FILLED,
          );
          answers.putIfAbsent(questionNumber, () => <int>{}).add(optionNumber);
        }

        bubbleCenter.dispose();
        bubbleRegion.dispose();
        bubbleArea.dispose();
      }
    }

    markColor.dispose();

    return answers;
  }

  void _drawDebugGrid(cv.Mat sheet, Grid grid) {
    for (final box in grid.boxes.expand((row) => row)) {
      final boxRegion = cv.Rect(
        box.x.toInt(),
        box.y.toInt(),
        box.width.toInt(),
        box.height.toInt(),
      );
      try {
        cv.rectangle(sheet, boxRegion, cv.Scalar.black);
      } finally {
        boxRegion.dispose();
      }
    }
  }
}
