import 'package:flutter/material.dart';
import 'package:quick_grader/ui/count/count_viewmodel.dart';

class CountScreen extends StatelessWidget {
  final CountViewmodel viewmodel;

  const CountScreen({super.key, required this.viewmodel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Count Screen')),
      body: ListenableBuilder(
        listenable: viewmodel,
        builder: (context, snapshot) {
          return Center(
            child: Text(
              'Count: ${viewmodel.count}',
              style: TextStyle(fontSize: 24),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewmodel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
