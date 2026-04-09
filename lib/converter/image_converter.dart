import 'dart:typed_data';
import 'package:camera/camera.dart';

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:image/image.dart' as imglib;

class ImageConverter {
  static const String extension = ".png";

  static Uint8List convertMatToUint8List(cv.Mat image) {
    final (success, png) = cv.imencode(extension, image);
    if (!success) {
      throw Exception('Failed to convert Mat to Uint8List.');
    }
    return png;
  }

  /*
  static Future<Uint8List?> convertMatToUint8ListAsync(cv.Mat image) async {
    final (success, png) = await cv.imencodeAsync(extension, image);
    return success ? png : null;
  }

  static Future<Uint8List> convertMatToUint8ListAsync2(cv.Mat image) async {
    final (success, png) = await cv.imencodeAsync(extension, image);
    if (!success) {
      throw Exception('Failed to convert Mat to Uint8List.');
    }
    return png;
  }

  static cv.Mat convertUint8ListToMat(Uint8List image) {
    cv.Mat? color;
    try {
      color = cv.imdecode(image, cv.IMREAD_COLOR);
      return color;
    } catch (_) {
      color?.dispose();
      rethrow;
    }
  }
  */

  static Uint8List convertCameraImageToUint8List(CameraImage image) {
    return switch (image.format.group) {
      ImageFormatGroup.yuv420 => _convertYUV420ToJpeg(image),
      ImageFormatGroup.bgra8888 => _convertBGRA8888ToJpeg(image),
      _ => throw Exception('Invalid image format'),
    };
  }

  static Uint8List _convertYUV420ToJpeg(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final rgbImage = imglib.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate the indices for Y and UV data.
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // Extract Y, U, and V values.
        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // Convert YUV values to RGB.
        final double yf = yValue.toDouble();
        final double uf = uValue.toDouble() - 128.0;
        final double vf = vValue.toDouble() - 128.0;

        int r = (yf + 1.402 * vf).round();
        int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
        int b = (yf + 1.772 * uf).round();

        // Clamp the results to ensure they remain within the 0-255 range.
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // Set the calculated RGB pixel in the image.
        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return imglib.encodeJpg(rgbImage);
  }

  static Uint8List _convertBGRA8888ToJpeg(CameraImage image) {
    final imageFromBytes = imglib.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: imglib.ChannelOrder.bgra,
    );
    return imglib.encodeJpg(imageFromBytes);
  }
}
