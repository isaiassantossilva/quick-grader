import 'package:flutter/material.dart';
import 'package:quick_grader/app.dart';
import 'package:quick_grader/config/dependecy_injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DI.configureDependencies();
  runApp(const App());
}
