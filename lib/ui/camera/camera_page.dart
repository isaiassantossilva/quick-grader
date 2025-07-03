import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:quick_grader/ui/video/video_viewmodel.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final viewModel = VideoViewmodel();

  @override
  void initState() {
    super.initState();
    viewModel.processCameraImage();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (viewModel.frame != null) {
            GoRouter.of(context).pop(viewModel.frame!);
          }
        },
      ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (ctx, _) {
              if (!viewModel.isCameraInitialized) {
                return const Center(child: CircularProgressIndicator());
              }

              return Stack(
                children: [
                  SizedBox(
                    width: size.width,
                    height: size.height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 100,
                        child: CameraPreview(viewModel.cameraController!),
                      ),
                    ),
                  ),

                  // SizedBox(
                  //   width: size.width,
                  //   height: size.height,
                  //   child: FittedBox(
                  //     fit: BoxFit.cover,
                  //     child: SizedBox(
                  //       width: 100,
                  //       child: Image.memory(viewModel.frame!),
                  //     ),
                  //   ),
                  // ),
                ],
              );
            },
          ),

          Positioned(
            top: size.height / 2,
            child: Container(
              width: size.width / 4,
              height: size.width / 4,
              color: const Color.fromARGB(150, 150, 0, 0),
            ),
          ),

          Positioned(
            top: size.height / 2,
            right: 0,
            child: Container(
              width: size.width / 4,
              height: size.width / 4,
              color: const Color.fromARGB(150, 150, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionLayer extends StatelessWidget {
  final List<cv.VecPoint> contours;

  const DetectionLayer({super.key, required this.contours});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: ContourPainter(contours: contours));
  }
}

class ContourPainter extends CustomPainter {
  final List<cv.VecPoint> contours;

  final _paint =
      Paint()
        ..strokeWidth = 2
        ..color = Colors.red
        ..style = PaintingStyle.stroke;

  ContourPainter({required this.contours});

  @override
  void paint(Canvas canvas, Size size) {
    if (contours.isEmpty) {
      return;
    }

    for (var contour in contours) {
      final points = contour.toList();

      for (var i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = (i + 1 >= points.length) ? points[0] : points[i + 1];

        canvas.drawLine(
          Offset(p1.x.toDouble(), p1.y.toDouble()),
          Offset(p2.x.toDouble(), p2.y.toDouble()),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ContourPainter oldDelegate) {
    if (contours.length != oldDelegate.contours.length) {
      return true;
    }

    for (var i = 0; i < contours.length; i++) {
      if (contours[i] != oldDelegate.contours[i]) {
        return true;
      }
    }

    return false;
  }
}
