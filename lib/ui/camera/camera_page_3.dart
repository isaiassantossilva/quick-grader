import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:image/image.dart' as imglib;

class CameraPage3 extends StatefulWidget {
  const CameraPage3({super.key});

  @override
  State<CameraPage3> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage3> {
  final ReceivePort _receivePort = ReceivePort();

  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  double _cameraScreenScale = 0;

  bool _isProcessing = false;
  Uint8List? _frame;

  Isolate? _isolate;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) {
      return;
    }

    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraDescription = backCamera;

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
    );

    _receivePort.listen(_onReceive);

    await _cameraController?.initialize();
    await _cameraController?.startImageStream(_processCameraImage);

    setState(() {});
  }

  void _onReceive(dynamic response) {
    final numberOfCorners = response['numberOfCorners'] as int;

    debugPrint('Number of corners detected: $numberOfCorners');

    _isolate?.kill(priority: Isolate.immediate);
    _isProcessing = false;

    if (numberOfCorners == 4) {
      _cameraController?.stopImageStream();
      setState(() => _frame = response['image']);
    }
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessing) {
      return;
    }

    debugPrint('Image size: ${cameraImage.width}x${cameraImage.height}');

    if (_cameraScreenScale == 0) {
      final newWith =
          (_cameraDescription?.sensorOrientation == 0 ||
                  _cameraDescription?.sensorOrientation == 180)
              ? cameraImage.width
              : cameraImage.height;
      _cameraScreenScale = MediaQuery.of(context).size.width / newWith;
    }

    _isProcessing = true;

    final request = {
      'sendPort': _receivePort.sendPort,
      'cameraImage': cameraImage,
    };

    _isolate = await Isolate.spawn(_handleCameraImage, request);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;

    // double width = 1280;
    // double height = 720;

    if (_frame != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Preview'),
          centerTitle: true,
          leading: BackButton(
            onPressed: () => GoRouter.of(context).pop(_frame),
          ),
        ),
        body: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: width,
            height: height,
            child: Image.memory(_frame!),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // FittedBox(
          //   fit: BoxFit.cover,
          //   child: SizedBox(
          //     width: width,
          //     height: height,
          //     child: CustomPaint(painter: ContourPainter(bytes: _frame)),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class ContourPainter extends CustomPainter {
  final Uint8List? bytes;

  ContourPainter({required this.bytes});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset.zero;
    final p2 = Offset(50, 50);

    canvas.drawRect(Rect.fromPoints(p1, p2), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

cv.Mat? mat;
cv.Mat? gray;
cv.Mat? threshold;
(cv.VecVecPoint, cv.VecVec4i)? contours;
(cv.VecVecPoint2f, cv.VecI32, cv.VecVecPoint2f)? arucoMarkers;
cv.ArucoDictionary? dictionary;
cv.ArucoDetectorParameters? detectorParams;
cv.ArucoDetector? arucoDetector;

void _disposeResources() {
  mat?.dispose();
  gray?.dispose();
  threshold?.dispose();
  contours?.$1.dispose();
  contours?.$2.dispose();
  arucoMarkers?.$1.dispose();
  arucoMarkers?.$2.dispose();
  arucoMarkers?.$3.dispose();
  dictionary?.dispose();
  detectorParams?.dispose();
  arucoDetector?.dispose();
}

Future<void> _handleCameraImage(Map<String, Object> request) async {
  final sendPort = request['sendPort'] as SendPort;
  final cameraImage = request['cameraImage'] as CameraImage;

  final image = _cameraImageToUint8List(cameraImage);

  mat = await cv.imdecodeAsync(image!, cv.IMREAD_COLOR);
  if (Platform.isAndroid) {
    mat = await cv.rotateAsync(mat!, cv.ROTATE_90_CLOCKWISE);
  }

  gray = cv.cvtColor(mat!, cv.COLOR_BGR2GRAY);

  dictionary = cv.ArucoDictionary.predefined(
    cv.PredefinedDictionaryType.DICT_6X6_250,
  );
  detectorParams = cv.ArucoDetectorParameters.empty();
  arucoDetector = cv.ArucoDetector.create(dictionary!, detectorParams!);

  arucoMarkers = arucoDetector!.detectMarkers(gray!);

  if (arucoMarkers == null) {
    _disposeResources();
    sendPort.send({'numberOfCorners': 0});
    return;
  }

  final (markerCorners, markerIds, rejectedCandidates) = arucoMarkers!;

  if (markerIds.isEmpty || markerIds.length < 4) {
    _disposeResources();
    sendPort.send({'numberOfCorners': 0});
    return;
  }

  /*
  for (int i = 0; i < ids.length; i++) {

  }
  */

  cv.arucoDrawDetectedMarkers(mat!, markerCorners, markerIds, cv.Scalar.green);

  final (ok, jpg) = await cv.imencodeAsync(".jpg", mat!);
  _disposeResources();
  sendPort.send({'numberOfCorners': 4, 'image': jpg});

  /*
  if (image != null) {
    mat = await cv.imdecodeAsync(image, cv.IMREAD_COLOR);
    if (Platform.isAndroid) {
      mat = await cv.rotateAsync(mat!, cv.ROTATE_90_CLOCKWISE);
    }
    final (ok, jpg) = await cv.imencodeAsync(".jpg", mat!);
    _disposeResources();
    sendPort.send({'numberOfCorners': 4, 'image': jpg});
    return;
  }

  if (image == null) {
    sendPort.send({'numberOfCorners': 0});
    return;
  }

  mat = await cv.imdecodeAsync(image, cv.IMREAD_COLOR);

  if (Platform.isAndroid) {
    mat = await cv.rotateAsync(mat!, cv.ROTATE_90_CLOCKWISE);
  }

  gray = await cv.cvtColorAsync(mat!, cv.COLOR_BGRA2GRAY);

  threshold = await cv.adaptiveThresholdAsync(
    gray!,
    255,
    cv.ADAPTIVE_THRESH_MEAN_C,
    cv.THRESH_BINARY,
    11,
    5,
  );

  threshold = await cv.bitwiseNOTAsync(threshold!);

  final contours = await cv.findContoursAsync(
    threshold!,
    cv.RETR_EXTERNAL,
    cv.CHAIN_APPROX_SIMPLE,
  );

  final cornerContours = <cv.VecPoint>[];

  for (var contour in contours.$1) {
    contour = await _approxPolygon(contour);
    if (await _isSquare(contour) && await _hasAdequateArea(contour)) {
      cornerContours.add(contour);
    }
  }

  // sendPort.send({'numberOfCorners': cornerContours.length});'

  if (cornerContours.length != 4) {
    _disposeResources();
    sendPort.send({'numberOfCorners': cornerContours.length});
    return;
  }

  // Order contours clockwise
  // cornerContours = _orderContoursClockwise(cornerContours);

  // var points = _orderPoints(points);

  // mat = await _fourPointTransform(mat!, points);

  mat = await cv.drawContoursAsync(
    mat!,
    cv.VecVecPoint.generate(1, (i) => cornerContours[0], dispose: false),
    -1,
    cv.Scalar.green,
    thickness: 2,
  );

  final (ok, jpg) = await cv.imencodeAsync(".jpg", mat!);

  _disposeResources();

  sendPort.send({'image': jpg, 'numberOfCorners': cornerContours.length});
  */
}

Future<cv.VecPoint> _approxPolygon(cv.VecPoint contour) async {
  double epsilon = 0.02 * (await cv.arcLengthAsync(contour, true));
  return await cv.approxPolyDPAsync(contour, epsilon, true);
}

Future<bool> _isSquare(cv.VecPoint contour) async {
  if (contour.size() != 4) {
    return false;
  }
  final boundingBox = await cv.boundingRectAsync(contour);
  final aspectRatio = boundingBox.width / boundingBox.height;
  return aspectRatio >= 0.7 && aspectRatio <= 1.3;
}

Future<bool> _hasAdequateArea(cv.VecPoint contour) async {
  final area = await cv.contourAreaAsync(contour);
  return area > 100 && area < 5000;
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

Future<cv.Mat> _fourPointTransform(cv.Mat image, cv.VecPoint points) async {
  final pointsList = points.toList();

  final widthA = math.sqrt(
    math.pow(pointsList[2].x - pointsList[3].x, 2) +
        math.pow(pointsList[2].y - pointsList[3].y, 2),
  );
  final widthB = math.sqrt(
    math.pow(pointsList[1].x - pointsList[0].x, 2) +
        math.pow(pointsList[1].y - pointsList[0].y, 2),
  );

  final heightA = math.sqrt(
    math.pow(pointsList[1].x - pointsList[2].x, 2) +
        math.pow(pointsList[1].y - pointsList[2].y, 2),
  );
  final heightB = math.sqrt(
    math.pow(pointsList[0].x - pointsList[3].x, 2) +
        math.pow(pointsList[0].y - pointsList[3].y, 2),
  );

  final maxWidth = math.max(widthA, widthB).toInt();
  final maxHeight = math.max(heightA, heightB).toInt();

  final destination = cv.VecPoint.fromList([
    cv.Point(0, 0),
    cv.Point(maxWidth - 1, 0),
    cv.Point(maxWidth - 1, maxHeight - 1),
    cv.Point(0, maxHeight - 1),
  ]);

  final perspectiveTransformMatrix = await cv.getPerspectiveTransformAsync(
    points,
    destination,
  );

  final warped = await cv.warpPerspectiveAsync(
    image,
    perspectiveTransformMatrix,
    (maxWidth, maxHeight),
  );

  destination.dispose();
  perspectiveTransformMatrix.dispose();

  return warped;
}

Uint8List? _cameraImageToUint8List(CameraImage image) {
  switch (image.format.group) {
    case ImageFormatGroup.yuv420:
      return _convertYUV420ToImage(image);
    case ImageFormatGroup.bgra8888:
      return _convertBGRA8888ToJpeg(image);
    default:
      return null;
  }
}

Uint8List _convertYUV420ToImage(CameraImage image) {
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

  return Uint8List.fromList(imglib.encodeJpg(rgbImage));
}

Uint8List _convertBGRA8888ToJpeg(CameraImage image) {
  final imglib.Image img = imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: imglib.ChannelOrder.bgra,
  );

  return Uint8List.fromList(imglib.encodeJpg(img));
}

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

// Future<cv.Mat> _convertCameraImageToMat(CameraImage image) async {
//   final planes = image.planes;

//   Uint8List yBuffer = planes[0].bytes;

  // Uint8List? uBuffer;
  // Uint8List? vBuffer;

  // if (Platform.isAndroid) {
  //   uBuffer = planes[1].bytes;
  //   vBuffer = planes[2].bytes;
  // }

  // final ySize = yBuffer.lengthInBytes;
  // final uSize = uBuffer?.lengthInBytes ?? 0;
  // final vSize = vBuffer?.lengthInBytes ?? 0;

  // final totalSize = ySize + uSize + vSize;

  // final bytes = Uint8List(totalSize);

  // bytes.setAll(0, yBuffer);

  // if (!Platform.isAndroid) {
  //   return cv.Mat.fromList(
  //     image.height,
  //     image.width,
  //     cv.MatType.CV_8UC4,
  //     bytes,
  //   );
  // }

  // bytes.setAll(ySize, vBuffer!);
  // bytes.setAll(ySize + vSize, uBuffer!);

  // var yuvMat = cv.Mat.fromList(
  //   image.height + image.height ~/ 2,
  //   image.width,
  //   cv.MatType.CV_8UC1,
  //   bytes,
  // );

  // yuvMat = await cv.cvtColorAsync(yuvMat, cv.COLOR_YUV2BGRA_NV21);

//   return await cv.rotateAsync(yuvMat, cv.ROTATE_90_CLOCKWISE);
// }
