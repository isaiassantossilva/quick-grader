import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opencv_dart/opencv.dart' as cv;

class VideoViewmodel extends ChangeNotifier {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  int _cameraRotation = 0;
  int _screenScale = 0;
  Uint8List? _frame;
  bool _isProcessing = false;
  int _lastRun = 0;
  final List<cv.VecPoint> _cornerContours = [];

  CameraController? get cameraController => _cameraController;
  CameraDescription? get cameraDescription => _cameraDescription;
  bool get isCameraInitialized =>
      _cameraController != null && _cameraController!.value.isInitialized;
  Uint8List? get frame => _frame;
  bool get isProcessing => _isProcessing;
  List<cv.VecPoint> get cornerContours => _cornerContours;

  Future<void> initializeCamera() async {
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

    _cameraRotation =
        Platform.isAndroid ? (_cameraDescription?.sensorOrientation ?? 0) : 0;

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
    );

    await _cameraController?.initialize();

    notifyListeners();
  }

  Future<void> processCameraImage() async {
    await initializeCamera();

    if (_cameraController == null) {
      return;
    }

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing ||
        DateTime.now().millisecondsSinceEpoch - _lastRun < 100) {
      return;
    }

    // if (_screenScale == 0) {
    //   final width =
    //       (_cameraRotation == 0 || _cameraRotation == 180)
    //           ? image.width
    //           : image.height;

    //   _screenScale = MediaQuery.of(context).size.width / width;
    // }

    _isProcessing = true;

    // final convertedMat = await _convertCameraImageToMat(image);
    // final encodedImage = await cv.imencodeAsync(".jpg", convertedMat);
    // _frame = encodedImage.$2;

    // var frameMat = await _tack();

    var frameMat = await _convertCameraImageToMat(image);

    final e = await cv.imencodeAsync(".jpg", frameMat);
    _frame = e.$2;

    final grayMat = await cv.cvtColorAsync(frameMat, cv.COLOR_BGRA2GRAY);

    var thresholdMat = await cv.adaptiveThresholdAsync(
      grayMat,
      255,
      cv.ADAPTIVE_THRESH_MEAN_C,
      cv.THRESH_BINARY,
      11,
      5,
    );

    thresholdMat = await cv.bitwiseNOTAsync(thresholdMat);

    // Find corner squares
    final contours = await cv.findContoursAsync(
      thresholdMat,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    _cornerContours.clear();

    for (var contour in contours.$1) {
      try {
        contour = await _approxPolygon(contour);
        if (await _isSquare(contour) && await _hasAdequateArea(contour)) {
          _cornerContours.add(contour);
        }
      } catch (_) {}
    }

    // if (_cornerContours.length != 4) {
    //   return;
    // }

    // if (_cornerContours.isNotEmpty) {
    //   return;
    // }

    frameMat = await cv.drawContoursAsync(
      frameMat,
      cv.VecVecPoint.generate(
        _cornerContours.length,
        (i) => _cornerContours[i],
        dispose: false,
      ),
      -1,
      cv.Scalar.green,
      thickness: 2,
    );

    // final e = await cv.imencodeAsync(".jpg", frameMat);
    // _frame = e.$2;

    // Dispose

    // convertedMat.dispose();
    _isProcessing = false;
    _lastRun = DateTime.now().millisecondsSinceEpoch;

    notifyListeners();
  }

  Future<cv.VecPoint> _approxPolygon(cv.VecPoint contour) async {
    return await cv.approxPolyDPAsync(
      contour,
      0.02 * (await cv.arcLengthAsync(contour, true)),
      true,
    );
  }

  Future<bool> _isSquare(cv.VecPoint contour) async {
    // contour = await cv.approxPolyDPAsync(
    //   contour,
    //   0.02 * (await cv.arcLengthAsync(contour, true)),
    //   true,
    // );
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

  Future<cv.Mat> _tack() async {
    final imagePicker = ImagePicker();

    final picture = await imagePicker.pickImage(source: ImageSource.gallery);

    if (picture != null) {
      final bytes = await picture.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        return await cv.imdecodeAsync(
          img.encodeJpg(decodedImage),
          cv.IMREAD_COLOR,
        );
      }
    }

    return cv.Mat.empty();
  }

  Future<cv.Mat> _convertCameraImageToMat(CameraImage image) async {
    final planes = image.planes;

    Uint8List yBuffer = planes[0].bytes;

    Uint8List? uBuffer;
    Uint8List? vBuffer;

    if (Platform.isAndroid) {
      uBuffer = planes[1].bytes;
      vBuffer = planes[2].bytes;
    }

    final ySize = yBuffer.lengthInBytes;
    final uSize = uBuffer?.lengthInBytes ?? 0;
    final vSize = vBuffer?.lengthInBytes ?? 0;

    final totalSize = ySize + uSize + vSize;

    final bytes = Uint8List(totalSize);

    bytes.setAll(0, yBuffer);

    if (!Platform.isAndroid) {
      return cv.Mat.fromList(
        image.height,
        image.width,
        cv.MatType.CV_8UC4,
        bytes,
      );
    }

    bytes.setAll(ySize, vBuffer!);
    bytes.setAll(ySize + vSize, uBuffer!);

    var yuvMat = cv.Mat.fromList(
      image.height + image.height ~/ 2,
      image.width,
      cv.MatType.CV_8UC1,
      bytes,
    );

    yuvMat = await cv.cvtColorAsync(yuvMat, cv.COLOR_YUV2BGRA_NV21);

    return await cv.rotateAsync(yuvMat, cv.ROTATE_90_CLOCKWISE);
  }

  Future<void> disposeCamera() async {
    if (_cameraController == null) {
      return;
    }

    await _cameraController?.dispose();
    _cameraController = null;

    notifyListeners();
  }
}
