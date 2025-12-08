import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Xử lý frame từ camera trong isolate riêng để không block UI thread
class FrameProcessor {
  static const int _targetFps = 5; // Xử lý 5 frame/giây để cân bằng performance
  static const int _frameSkipCount = 6; // Skip 6 frame giữa mỗi lần xử lý (30fps / 6 = 5fps)
  
  int _frameCount = 0;
  DateTime? _lastProcessedTime;
  final Duration _minProcessingInterval = Duration(milliseconds: 1000 ~/ _targetFps);

  /// Xử lý frame từ camera stream
  /// Trả về true nếu frame được xử lý, false nếu bị skip
  bool shouldProcessFrame() {
    _frameCount++;
    
    // Skip frame để giảm tải xử lý
    if (_frameCount % _frameSkipCount != 0) {
      return false;
    }

    // Kiểm tra interval tối thiểu giữa các lần xử lý
    final now = DateTime.now();
    if (_lastProcessedTime != null) {
      final elapsed = now.difference(_lastProcessedTime!);
      if (elapsed < _minProcessingInterval) {
        return false;
      }
    }

    _lastProcessedTime = now;
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
    _frameCount = 0;
    _lastProcessedTime = null;
  }
}

