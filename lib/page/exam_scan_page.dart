import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/scan_controller.dart';

import 'package:quick_grader/model/exam.dart';

class ExamScanPage extends StatefulWidget {
  const ExamScanPage({super.key});

  @override
  State<ExamScanPage> createState() => _ExamScanPage();
}

class _ExamScanPage extends State<ExamScanPage> {
  final scanController = DI.get<ScanController>();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final exam = ModalRoute.of(context)?.settings.arguments as Exam;
    scanController.load(exam);
    scanController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    scanController.removeListener(_onStateChanged);
    scanController.dispose();
    super.dispose();
  }

  Future<void> _onStateChanged() async {
    if (!mounted) {
      return;
    }

    if (scanController.isTimeout) {
      scanController.removeListener(_onStateChanged);
      await _showAlertDialog();
      return;
    }

    if (scanController.extractedAnswers != null) {
      scanController.removeListener(_onStateChanged);
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.examScanned,
        arguments: {
          "exam": scanController.exam,
          "imageBytes": scanController.extractedAnswers?.imageBytes,
          "extractedAnswers": scanController.extractedAnswers?.answers,
        },
      );
    }
  }

  Future<void> _showAlertDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tempo limite atingido'),
          content: Text('Tempo limite de processamento atingido!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    log("Building scan page");
    return Scaffold(
      appBar: AppBar(title: Text('Correção')),
      body: ListenableBuilder(
        listenable: scanController,
        builder: (_, __) {
          if (scanController.isTimeout) {
            return Container();
          }

          if (scanController.isScaning) {
            return LayoutBuilder(
              builder: (_, constraints) {
                return Stack(
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: CameraPreview(scanController.cameraController),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${scanController.secondsElapsed}',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: scanController,
        builder: (_, __) {
          return FloatingActionButton(
            onPressed: scanController.toggleFlashMode,
            child: Icon(
              scanController.isFlashOn ? Icons.flash_on : Icons.flash_off,
            ),
          );
        },
      ),
    );
  }
}
