import 'package:opencv_dart/opencv.dart' as cv;

class Marker {
  final int id;
  final cv.VecPoint2f points;

  Marker({required this.id, required this.points});
}
