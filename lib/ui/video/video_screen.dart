import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:quick_grader/ui/video/video_viewmodel.dart';

class VideoScreen extends StatefulWidget {
  final VideoViewmodel viewmodel;

  const VideoScreen({super.key, required this.viewmodel});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoViewmodel get viewmodel => widget.viewmodel;

  @override
  void initState() {
    super.initState();
    viewmodel.processCameraImage();
  }

  @override
  void dispose() {
    viewmodel.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Screen')),
      body: ListenableBuilder(
        listenable: viewmodel,
        builder: (ctx, _) {
          if (!viewmodel.isCameraInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctx.mounted && viewmodel.frame != null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: CameraPreview(viewmodel.cameraController!)),
                Expanded(child: Image.memory(viewmodel.frame!)),
              ],
            );
          }

          return Center(
            child: Text(
              'Video content goes here',
              style: TextStyle(fontSize: 24),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for video action
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Video action triggered')));
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
