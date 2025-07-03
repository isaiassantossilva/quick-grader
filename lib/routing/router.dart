import 'package:go_router/go_router.dart';
import 'package:quick_grader/routing/routes.dart';
import 'package:quick_grader/ui/camera/camera_page.dart';
import 'package:quick_grader/ui/camera/camera_page_2.dart';
import 'package:quick_grader/ui/camera/camera_page_3.dart';
import 'package:quick_grader/ui/home/home_page.dart';

GoRouter router() => GoRouter(
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        return HomePage();
      },
      routes: [
        // Add nested routes here if needed
      ],
    ),
    GoRoute(
      path: Routes.camera,
      builder: (context, state) {
        return const CameraPage();
      },
      routes: [
        // Add nested routes here if needed
      ],
    ),

    GoRoute(
      path: Routes.camera2,
      builder: (context, state) {
        return const CameraPage2();
      },
      routes: [
        // Add nested routes here if needed
      ],
    ),

    GoRoute(
      path: Routes.camera3,
      builder: (context, state) {
        return const CameraPage3();
      },
      routes: [
        // Add nested routes here if needed
      ],
    ),
  ],
);
