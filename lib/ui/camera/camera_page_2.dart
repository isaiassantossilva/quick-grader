import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;

class CameraPage2 extends StatefulWidget {
  const CameraPage2({super.key});

  @override
  State<CameraPage2> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage2> {
  String _text = '';
  bool _isProcessing = false;

  cv.VideoCapture? _cap;
  Uint8List? _lastFrame;

  final _receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {}),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            ElevatedButton(
              onPressed: () async {
                var total = await complexTask1();
                setState(() {
                  _text = 'Result 1: $total';
                });
              },
              child: Text('Button 1'),
            ),

            ElevatedButton(
              onPressed: () async {
                final receivePort = ReceivePort();

                await Isolate.spawn((sendPort) async {
                  var total = await complexTask2();
                  sendPort.send(total);
                }, receivePort.sendPort);

                receivePort.listen((total) {
                  setState(() {
                    _text = 'Result 2: $total';
                  });
                });
              },
              child: Text('Button 2'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (_isProcessing) {
                  return;
                }

                _isProcessing = true;

                final total = await Isolate.run(() async {
                  var total = 0.0;
                  for (var i = 0; i < 1000000000; i++) {
                    total += i;
                  }
                  return total;
                });

                setState(() {
                  _text = 'Result 3: $total';
                  _isProcessing = false;
                });
              },
              child: Text('Button 3'),
            ),

            Text(_text),
          ],
        ),
      ),
    );
  }

  Future<double> complexTask1() async {
    var total = 0.0;
    for (var i = 0; i < 1000000000; i++) {
      total += i;
    }
    return total;
  }
}

Future<double> complexTask2() async {
  var total = 0.0;
  for (var i = 0; i < 1000000000; i++) {
    total += i;
  }
  return total;
}

class SendData {
  final SendPort sendPort;
  final cv.VideoCapture capture;

  SendData({required this.sendPort, required this.capture});
}

void processImage(SendData sendData) {
  final (ok, mat) = sendData.capture.read();
  if (!ok) {
    sendData.sendPort.send(null);
  }
  final buf = cv.imencode('.jpg', mat).$2;
  sendData.sendPort.send(buf);
}
