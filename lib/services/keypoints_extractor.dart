import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Service để extract keypoints từ camera frames
/// Sử dụng Native (Android/iOS) MediaPipe implementation
class KeypointsExtractor {
  static const int numKeypoints = 1662; 
  static const MethodChannel _channel = MethodChannel('com.example.flutter_application_initial/tflite');
  
  /// Extract keypoints từ CameraImage bằng MediaPipe chạy dưới native
  Future<List<double>> extractKeypoints(CameraImage cameraImage, {bool isFrontCamera = true}) async {
    try {
      // Chuẩn bị data YUV
      // CameraImage trên Android thường là YUV420
      
      if (cameraImage.planes.length < 3) {
        print('⚠️ Camera image format không hợp lệ, yêu cầu 3 planes (YUV)');
        return List.filled(numKeypoints, 0.0);
      }
      
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];
      
      // Gọi Native code để xử lý (tránh convert byte trên Flutter thread)
      final List<dynamic> result = await _channel.invokeMethod('processFrame', {
        'yBytes': yPlane.bytes,
        'uBytes': uPlane.bytes,
        'vBytes': vPlane.bytes,
        'width': cameraImage.width,
        'height': cameraImage.height,
        'yRowStride': yPlane.bytesPerRow,
        'uvRowStride': uPlane.bytesPerRow,
        'uvPixelStride': uPlane.bytesPerPixel,
        'isFrontCamera': isFrontCamera,
      });
      
      final List<double> keypoints = result.cast<double>();
      
      // DEBUG: Kiểm tra số lượng keypoints khác 0
      // int nonZeroCount = 0;
      // for (var val in keypoints) {
      //   if (val != 0.0) nonZeroCount++;
      // }
      // print('🔍 Native Keypoints: $nonZeroCount / ${keypoints.length} values khác 0');
      // if (nonZeroCount == 0) {
      //   print('⚠️ Cảnh báo: Native trả về toàn số 0 (Không tìm thấy Pose/Hand/Face)');
      // }
      
      return keypoints;
      
    } catch (e) {
      print('❌ Lỗi extract keypoints: $e');
      // Trả về zeros nếu lỗi, tránh crash app
      return List.filled(numKeypoints, 0.0);
    }
  }

  /// Extract keypoints từ image file (Not implemented for Native bridge yet)
  /// Extract keypoints từ video/image file (Gọi xuống Native)
  Future<List<double>> extractKeypointsFromFile(String filePath) async {
    try {
      print('📦 Gọi Native processVideoFile với path: $filePath');
      final result = await _channel.invokeMethod('processVideoFile', {
        'filePath': filePath,
      });
      
      if (result != null) {
        final List<dynamic> list = result;
        return list.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      print('❌ Native processVideoFile failed (có thể chưa support platform này hoặc lỗi file): $e');
    }
    
    // Fallback nếu lỗi
    return List.filled(numKeypoints, 0.0);
  }

  /// Extract keypoints từ video frame (Not implemented for Native bridge yet)
  Future<List<double>> extractKeypointsFromVideoFrame(
    Uint8List frameBytes,
    int width,
    int height,
  ) async {
    return List.filled(numKeypoints, 0.0);
  }
}

