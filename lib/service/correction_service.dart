import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as imglib;
import 'package:opencv_dart/opencv.dart' as cv;

import 'package:camera/camera.dart';
import 'package:quick_grader/entity/answer.dart';

import '../entity/marker.dart';

class CorrectionService {
  static const int _numberOfArucoMarkers = 4;
  static const int _maxNumberOfQuestionsPerGrid = 20;

  cv.Mat? mat;
  cv.Mat? gray;
  cv.Mat? threshold;
  //(cv.VecVecPoint, cv.VecVec4i)? contours;
  (cv.VecVecPoint2f, cv.VecI32, cv.VecVecPoint2f)? arucoMarkers;
  cv.ArucoDictionary? arucoDictionary;
  cv.ArucoDetectorParameters? arucoDetectorParameters;
  cv.ArucoDetector? arucoDetector;

  void _disposeResources() {
    mat?.dispose();
    gray?.dispose();
    threshold?.dispose();
    //contours?.$1.dispose();
    //contours?.$2.dispose();
    arucoMarkers?.$1.dispose();
    arucoMarkers?.$2.dispose();
    arucoMarkers?.$3.dispose();
    arucoDictionary?.dispose();
    arucoDetectorParameters?.dispose();
    arucoDetector?.dispose();
  }

  Future<void> handleCameraImage(Map<String, Object> request) async {
    final sendPort = request['sendPort'] as SendPort;
    final cameraImage = request['cameraImage'] as CameraImage;

    // Converte frame da câmera para Uint8List, formato utilizado para processamento
    final image = _cameraImageToImage(cameraImage);

    if (image == null) {
      _disposeResources();
      sendPort.send({'numberOfCorners': 0});
      return;
    }

    // Inicio do processamento da imagem para detecção de marcadores Aruco
    mat = await cv.imdecodeAsync(image, cv.IMREAD_COLOR);
    if (Platform.isAndroid) {
      mat = await cv.rotateAsync(mat!, cv.ROTATE_90_CLOCKWISE);
    }

    gray = cv.cvtColor(mat!, cv.COLOR_BGR2GRAY);

    // Detect ARUCO markers
    arucoDictionary = cv.ArucoDictionary.predefined(
      cv.PredefinedDictionaryType.DICT_6X6_250,
    );
    arucoDetectorParameters = cv.ArucoDetectorParameters.empty();

    arucoDetector = cv.ArucoDetector.create(
      arucoDictionary!,
      arucoDetectorParameters!,
    );

    arucoMarkers = arucoDetector!.detectMarkers(gray!);

    if (arucoMarkers == null) {
      _disposeResources();
      sendPort.send({'numberOfCorners': 0});
      return;
    }

    final (markerCorners, markerIds, rejectedCandidates) = arucoMarkers!;

    if (markerIds.length != _numberOfArucoMarkers) {
      _disposeResources();
      sendPort.send({'numberOfCorners': 0});
      return;
    }

    final markers = List.generate(
      markerIds.length,
      (i) => Marker(id: markerIds[i], points: markerCorners[i]),
      growable: false,
    );

    // Remover na versão final
    cv.arucoDrawDetectedMarkers(
      mat!,
      markerCorners,
      markerIds,
      cv.Scalar.green,
    );

    // Ajusta a região de interesse da imagem
    final topLeftMarker = markers.firstWhere((marker) => marker.id == 0);
    final topRightMarker = markers.firstWhere((marker) => marker.id == 1);
    final bottomRightMarker = markers.firstWhere((marker) => marker.id == 2);
    final bottomLeftMarker = markers.firstWhere((marker) => marker.id == 3);

    final points = cv.VecPoint2f.fromList([
      topLeftMarker.points[0],
      topRightMarker.points[1],
      bottomRightMarker.points[2],
      bottomLeftMarker.points[3],
    ]);

    threshold =
        (await cv.thresholdAsync(gray!, 100, 255, cv.THRESH_BINARY_INV)).$2;

    threshold = await _fourPointTransform(threshold!, points);

    // Talvez remover isso em produção.
    mat = await _fourPointTransform(mat!, points);
    gray = await _fourPointTransform(gray!, points);

    // Fim da extração da folha de respostas da imagem.
    // A partir de agora, processaremos a grade de respostas
    // Para identificar as repostas marcadas.

    final numberOfQuestions = 90;
    final numberOfOptions = 5;

    final numberOfGrids =
        (numberOfQuestions / _maxNumberOfQuestionsPerGrid).ceil();
    final numberOfCols =
        (numberOfOptions + 1) * numberOfGrids + (numberOfGrids - 1) + 2;
    final numberOfRows = math.min(23, numberOfQuestions + 3);

    double gridBoxWidth = threshold!.cols / numberOfCols;
    double gridBoxHeight = threshold!.rows / numberOfRows;

    final grid = List.generate(
      numberOfRows,
      (row) => List.generate(
        numberOfCols,
        (col) => cv.Rect2f(
          col * gridBoxWidth,
          row * gridBoxHeight,
          gridBoxWidth,
          gridBoxHeight,
        ),
        growable: false,
      ),
      growable: false,
    );

    // Remover na versão final
    // Draw a red rectangle around each grid box
    for (int row = 0; row < numberOfRows; ++row) {
      for (int col = 0; col < numberOfCols; ++col) {
        final rect = grid[row][col];
        cv.rectangle(
          mat!,
          cv.Rect(
            rect.x.toInt(),
            rect.y.toInt(),
            rect.width.toInt(),
            rect.height.toInt(),
          ),
          cv.Scalar.red,
        );
      }
    }

    final answers = <Answer>[];

    for (int i = 0; i < numberOfQuestions; i++) {
      int row = 2 + (i % _maxNumberOfQuestionsPerGrid);
      int col =
          ((numberOfOptions + 2) * (i / _maxNumberOfQuestionsPerGrid)).toInt();

      final questionNumber = i + 1;
      final answer = Answer(questionNumber);

      for (int j = 0; j < numberOfOptions; j++) {
        cv.Rect2f gridBox = grid[row][col + j + 2];

        final bubbleArea = threshold!.region(
          cv.Rect(
            gridBox.x.toInt(),
            gridBox.y.toInt(),
            gridBox.width.toInt(),
            gridBox.height.toInt(),
          ),
        );

        int nonZeroPixels = cv.countNonZero(bubbleArea);
        int totalPixels = bubbleArea.rows * bubbleArea.cols;

        double filledPercentage = (nonZeroPixels / totalPixels) * 100;

        if (filledPercentage > 30) {
          int optionNumber = j;
          answer.addFilledOption(optionNumber);
        }
      }

      answers.add(answer);
    }

    final (ok, jpg) = await cv.imencodeAsync(".jpg", mat!);
    _disposeResources();
    sendPort.send({'numberOfCorners': 4, 'image': jpg});
  }

  Future<cv.Mat> _fourPointTransform(cv.Mat image, cv.VecPoint2f points) async {
    final widthA = math.sqrt(
      math.pow(points[2].x - points[3].x, 2) +
          math.pow(points[2].y - points[3].y, 2),
    );
    final widthB = math.sqrt(
      math.pow(points[1].x - points[0].x, 2) +
          math.pow(points[1].y - points[0].y, 2),
    );

    final heightA = math.sqrt(
      math.pow(points[1].x - points[2].x, 2) +
          math.pow(points[1].y - points[2].y, 2),
    );
    final heightB = math.sqrt(
      math.pow(points[0].x - points[3].x, 2) +
          math.pow(points[0].y - points[3].y, 2),
    );

    final maxWidth = math.max(widthA, widthB).toInt();
    final maxHeight = math.max(heightA, heightB).toInt();

    final destination = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(maxWidth - 1, 0),
      cv.Point2f(maxWidth - 1, maxHeight - 1),
      cv.Point2f(0, maxHeight - 1),
    ]);

    final matrix = await cv.getPerspectiveTransform2fAsync(points, destination);

    final warped = await cv.warpPerspectiveAsync(image, matrix, (
      maxWidth,
      maxHeight,
    ));

    destination.dispose();
    matrix.dispose();

    return warped;
  }

  Uint8List? _cameraImageToImage(CameraImage image) {
    try {
      return switch (image.format.group) {
        ImageFormatGroup.yuv420 => _convertYUV420ToJpeg(image),
        ImageFormatGroup.bgra8888 => _convertBGRA8888ToJpeg(image),
        _ => null,
      };
    } catch (e) {
      return null;
    }
  }

  Uint8List _convertYUV420ToJpeg(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final rgbImage = imglib.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate the indices for Y and UV data.
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // Extract Y, U, and V values.
        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // Convert YUV values to RGB.
        final double yf = yValue.toDouble();
        final double uf = uValue.toDouble() - 128.0;
        final double vf = vValue.toDouble() - 128.0;

        int r = (yf + 1.402 * vf).round();
        int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
        int b = (yf + 1.772 * uf).round();

        // Clamp the results to ensure they remain within the 0-255 range.
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // Set the calculated RGB pixel in the image.
        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    // final width = image.width;
    // final height = image.height;

    // final yPlane = image.planes[0].bytes;
    // final uPlane = image.planes[1].bytes;
    // final vPlane = image.planes[2].bytes;

    // final uvRowStride = image.planes[1].bytesPerRow;
    // final uvPixelStride = image.planes[1].bytesPerPixel!;

    // final img = imglib.Image(width: width, height: height);

    // for (var h = 0; h < height; h++) {
    //   final uvRow = uvRowStride * (h >> 1);
    //   for (var w = 0; w < width; w++) {
    //     final uvIndex = uvRow + (w >> 1) * uvPixelStride;
    //     final yp = yPlane[h * image.planes[0].bytesPerRow + w];
    //     final up = uPlane[uvIndex];
    //     final vp = vPlane[uvIndex];

    //     int r = (yp + 1.403 * (vp - 128)).round().clamp(0, 255);
    //     int g = (yp - 0.344 * (up - 128) - 0.714 * (vp - 128)).round().clamp(
    //       0,
    //       255,
    //     );
    //     int b = (yp + 1.770 * (up - 128)).round().clamp(0, 255);

    //     img.setPixelRgb(w, h, r, g, b);
    //   }
    // }

    return imglib.encodeJpg(rgbImage);
  }

  Uint8List _convertBGRA8888ToJpeg(CameraImage image) {
    final imageFromBytes = imglib.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: imglib.ChannelOrder.bgra,
    );
    return imglib.encodeJpg(imageFromBytes);
  }
}

/*
cv.Mat _convertCameraImageToMat(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final Uint8List rgbBytes = Uint8List(width * height * 3);

  final int yRowStride = yPlane.bytesPerRow;
  final int uvRowStride = uPlane.bytesPerRow;
  final int uvPixelStride = uPlane.bytesPerPixel!;

  int rgbIndex = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * yRowStride + x;
      final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      // Extract Y, U, and V values.
      final int yValue = yPlane.bytes[yIndex];
      final int uValue = uPlane.bytes[uvIndex];
      final int vValue = vPlane.bytes[uvIndex];

      // Convert YUV values to RGB.
      final double yf = yValue.toDouble();
      final double uf = uValue.toDouble() - 128.0;
      final double vf = vValue.toDouble() - 128.0;

      int r = (yf + 1.402 * vf).round();
      int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
      int b = (yf + 1.772 * uf).round();

      // Clamp the results to ensure they remain within the 0-255 range.
      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      rgbBytes[rgbIndex++] = b;
      rgbBytes[rgbIndex++] = g;
      rgbBytes[rgbIndex++] = r;
    }
  }

  return cv.Mat.fromList(height, width, cv.MatType.CV_8UC3, rgbBytes);
}


List<cv.Point> _orderPoints(List<cv.Point> points) {
  // Helper functions to calculate sum and difference
  double sum(cv.Point p) => p.x.toDouble() + p.y.toDouble();
  double diff(cv.Point p) => p.y.toDouble() - p.x.toDouble();

  // Find top-left (minimum sum) and bottom-right (maximum sum)
  cv.Point topLeft = points.reduce((a, b) => sum(a) < sum(b) ? a : b);
  cv.Point bottomRight = points.reduce((a, b) => sum(a) > sum(b) ? a : b);

  // Find top-right (minimum difference) and bottom-left (maximum difference)
  cv.Point topRight = points.reduce((a, b) => diff(a) < diff(b) ? a : b);
  cv.Point bottomLeft = points.reduce((a, b) => diff(a) > diff(b) ? a : b);

  // Return ordered points as VecPoint
  return [topLeft, topRight, bottomRight, bottomLeft];
}
*/
