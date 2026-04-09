import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grader/service/entity/marker.dart';
import 'package:quick_grader/converter/image_converter.dart';
import 'package:quick_grader/model/exam.dart';
import 'package:quick_grader/repository/preference_repository.dart';
import 'package:quick_grader/service/answer_sheet_extractor_service.dart';

enum ScanControllerState {
  // idle,
  initializing,
  loading,
  timeout,
  scaning,
  // ready,
  disposing,
  disposed,
}

class ScanController extends ChangeNotifier {
  final PreferenceRepository preferenceRepository;

  Future<void> _synchronizationQueue = Future.value();

  ScanControllerState _state = ScanControllerState.loading;

  Exam? _exam;
  bool _flashOn = false;

  Isolate? _isolate;
  ReceivePort? _workerSpawnPort;
  ReceivePort? _workerResultPort;
  SendPort? _workerSendPort;
  StreamSubscription? _workerStreamSubscription;
  bool _isWorkerProcessing = false;
  DateTime _lastRun = DateTime.now();

  ExtractAnswersOutputDTO? _extractedAnswers;

  Timer? _timer;
  int _secondsElapsed = 30;

  CameraController? _cameraController;

  ScanController({required this.preferenceRepository});

  ScanControllerState get state => _state;
  Exam get exam => _exam!;

  ExtractAnswersOutputDTO? get extractedAnswers => _extractedAnswers;

  bool get isFlashOn => _flashOn;
  int get secondsElapsed => _secondsElapsed;

  CameraController get cameraController => _cameraController!;

  bool get isScaning => _state == ScanControllerState.scaning;
  bool get isTimeout => _state == ScanControllerState.timeout;

  Future<void> _synchronized(Future<void> Function() action) {
    _synchronizationQueue = _synchronizationQueue
        .then((_) => action())
        .catchError((e) => log("Error synchronized call", error: e));
    return _synchronizationQueue;
  }

  Future<void> load(Exam exam) {
    return _synchronized(() async {
      log("State on load: $_state");

      if (_state == ScanControllerState.disposed) {
        throw StateError("Scan controller already disposed");
      }

      if (_state == ScanControllerState.initializing ||
          _state == ScanControllerState.scaning) {
        return;
      }

      _exam = exam;
      _state = ScanControllerState.initializing;

      try {
        await _startWorker();
        await _initializeCamera();
        await _startTimer();

        if (_state == ScanControllerState.disposed) {
          return;
        }

        _state = ScanControllerState.scaning;
        notifyListeners();
      } catch (e) {
        log("Error loading scan controller", error: e);
        _state = ScanControllerState.loading;
        rethrow;
      }
    });
  }

  @override
  Future<void> dispose() {
    return _synchronized(() async {
      if (_state == ScanControllerState.disposed ||
          _state == ScanControllerState.disposing) {
        return;
      }

      _state = ScanControllerState.disposing;

      try {
        _timer?.cancel();
      } catch (e) {
        log("Error closing timer", error: e);
      }

      try {
        await _cameraController?.stopImageStream();
      } catch (e) {
        log("Error closing image stream", error: e);
      }

      try {
        await _cameraController?.dispose();
      } catch (e) {
        log("Error closing camera controller", error: e);
      }

      try {
        _workerSendPort?.send("kill");
      } catch (e) {
        log("Error closing worker send port", error: e);
      }

      try {
        await _workerStreamSubscription?.cancel();
      } catch (e) {
        log("Error closing worker stream subscription", error: e);
      }

      try {
        _workerSpawnPort?.close();
      } catch (e) {
        log("Error closing worker spawn port", error: e);
      }

      try {
        _workerResultPort?.close();
      } catch (e) {
        log("Error closing worker result port", error: e);
      }

      try {
        _isolate?.kill(priority: Isolate.immediate);
      } catch (e) {
        log("Error closing isolate", error: e);
      }

      _exam = null;
      _isolate = null;
      _workerSpawnPort = null;
      _workerResultPort = null;
      _workerSendPort = null;
      _workerStreamSubscription = null;
      _timer = null;
      _cameraController = null;
      _isWorkerProcessing = false;
      _lastRun = DateTime.now();
      _secondsElapsed = 30;
      _flashOn = false;

      // _isExtractingAnswers = false;
      // _isExtractedAnswers = false;
      _extractedAnswers = null;

      _state = ScanControllerState.disposed;
      super.dispose();
    });
  }

  Future<void> _startWorker() async {
    _workerSpawnPort = ReceivePort();
    _workerResultPort = ReceivePort();

    _workerStreamSubscription = _workerResultPort!.listen(_onWorkerResult);

    _isolate = await Isolate.spawn(_worker, {
      "spawnPort": _workerSpawnPort!.sendPort,
      "resultPort": _workerResultPort!.sendPort,
    }, debugName: "camera-stream-worker");

    _workerSendPort = await _workerSpawnPort!.first as SendPort;
  }

  Future<void> _onWorkerResult(dynamic response) async {
    log("Mensage from isolate: $response");

    final data = response['data'];

    if (data is FindAnswerKeyOutputDTO) {
      _state = ScanControllerState.loading;
      notifyListeners();

      _timer?.cancel();
      await _cameraController?.stopImageStream();

      final request = {
        'type': WorkerTaskType.extractAnswers,
        'exam': exam,
        'imageBytes': data.imageBytes,
        'imageGrayBytes': data.imageGrayBytes,
        'markers': data.markers,
      };

      _workerSendPort?.send(request);
    }

    if (data is ExtractAnswersOutputDTO) {
      _extractedAnswers = data;
      // _isExtractedAnswers = true;
      notifyListeners();
    }

    _isWorkerProcessing = false;
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
    );

    await _cameraController?.initialize();

    await _cameraController?.setFlashMode(FlashMode.off);

    _flashOn = await preferenceRepository.isFlashOn();

    await _cameraController?.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );

    await _cameraController?.startImageStream(_onCameraFrame);
  }

  Future<void> _onCameraFrame(CameraImage frame) async {
    if (_isWorkerProcessing ||
        DateTime.now().difference(_lastRun).inMilliseconds < 100) {
      return;
    }

    _isWorkerProcessing = true;

    log('Image size: ${frame.width}x${frame.height}');

    final request = {'type': WorkerTaskType.findAnswerKey, 'frame': frame};

    _workerSendPort?.send(request);

    _lastRun = DateTime.now();
  }

  Future<void> _startTimer() async {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_secondsElapsed > 0) {
        _secondsElapsed--;
        notifyListeners();
        return;
      }

      log("Scan timeout reached");
      _state = ScanControllerState.timeout;
      _timer?.cancel();
      await _cameraController?.stopImageStream();
      notifyListeners();
    });
  }

  Future<void> toggleFlashMode() async {
    try {
      _flashOn = !_flashOn;
      await preferenceRepository.updateFlashPreference(_flashOn);
      await _cameraController?.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      log("Error toggle flash mode", error: e);
    } finally {
      notifyListeners();
    }
  }
}

enum WorkerTaskType { findAnswerKey, extractAnswers }

void _worker(Map<String, dynamic> request) {
  final spawnPort = request['spawnPort'] as SendPort;
  final resultPort = request['resultPort'] as SendPort;

  final workerPort = ReceivePort();
  spawnPort.send(workerPort.sendPort);

  StreamSubscription? streamSubscription;

  final service = AnswerSheetExtractorService();

  streamSubscription = workerPort.listen((request) async {
    if (request == "kill") {
      await streamSubscription?.cancel();
      workerPort.close();
      Isolate.exit();
    }

    final taskType = request['type'] as WorkerTaskType;

    try {
      final dynamic output;

      switch (taskType) {
        case WorkerTaskType.findAnswerKey:
          log("Processing camera frame");

          final frame = request['frame'] as CameraImage;

          final imageBytes = ImageConverter.convertCameraImageToUint8List(
            frame,
          );

          final input = FindAnswerKeyInputDTO(imageBytes: imageBytes);

          output = service.findAnswerKey(input);
        case WorkerTaskType.extractAnswers:
          log("Extracting answers");

          final exam = request['exam'] as Exam;
          final imageBytes = request['imageBytes'] as Uint8List;
          final imageGrayBytes = request['imageGrayBytes'] as Uint8List;
          final markers = request['markers'] as List<Marker>;

          final input = ExtractAnswersInputDTO(
            numberOfQuestions: exam.numberOfQuestions,
            numberOfOptions: exam.numberOfOptions,
            imageBytes: imageBytes,
            imageGrayBytes: imageGrayBytes,
            markers: markers,
          );

          output = service.extractAnswers(input);
      }

      resultPort.send({'success': true, 'data': output});
    } catch (e) {
      log('Error processing camera frame', error: e);
      resultPort.send({'success': false, 'error': '$e'});
    }
  }, onDone: () => Isolate.current.kill());
}
