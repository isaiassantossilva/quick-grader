import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_grader/service/correction_service.dart';

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

  final CorrectionService _correctionService = CorrectionService();

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
      ResolutionPreset.high,
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

    _isolate = await Isolate.spawn(
      _correctionService.handleCameraImage,
      request,
    );
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

/*
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
*/
