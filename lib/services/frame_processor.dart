import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Xử lý frame từ camera trong isolate riêng để không block UI thread
class FrameProcessor {
  /// Xử lý frame từ camera stream
  /// Trả về true nếu frame được cho phép xử lý
  bool shouldProcessFrame() {
    // Không giới hạn FPS cứng để đảm bảo video mượt nhất có thể (30-60 FPS)
    // Việc throttling sẽ do flag _isProcessing ở CameraScreen đảm nhận
    // (Nếu frame trước chưa xong -> Frame sau tự động bị drop)
    return true;
  }

  /// Convert CameraImage thành Uint8List để xử lý
  /// Giảm resolution để tăng tốc độ xử lý
  static Future<Uint8List?> convertCameraImageToBytes(
    CameraImage image, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Lấy plane đầu tiên (Y plane trong YUV format)
      final plane = image.planes[0];
      final bytes = plane.bytes;
      
      // Nếu không cần resize, trả về bytes trực tiếp
      if (maxWidth == null && maxHeight == null) {
        return bytes;
      }

      // Convert CameraImage thành ui.Image để resize
      // CameraImage sử dụng YUV420 format, nhưng decodeImageFromPixels cần RGB
      // Với YUV, ta cần convert sang RGB trước
      // Tạm thời skip resize cho YUV, chỉ resize nếu là RGB
      // TODO: Implement YUV to RGB conversion nếu cần resize
      // Hiện tại trả về bytes trực tiếp từ Y plane (đủ cho xử lý ML)
      return bytes;
    } catch (e) {
      debugPrint('Error converting CameraImage: $e');
      return null;
    }
  }

  /// Reset frame counter (gọi khi dừng xử lý)
  void reset() {
    // Không còn state để reset vì đã bỏ throttling
    // _frameCount = 0;
    // _lastProcessedTime = null;
  }
}

