import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_grader/routing/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child:
            _image == null
                ? Text(
                  'Welcome to the Home Screen',
                  style: TextStyle(fontSize: 24),
                )
                : Image.memory(_image!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final image =
              await GoRouter.of(context).push(Routes.camera3) as Uint8List;

          setState(() {
            _image = image;
          });
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
