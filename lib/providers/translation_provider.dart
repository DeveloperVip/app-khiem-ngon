import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/translation_result.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  bool _isServiceInitialized = false;

  List<TranslationResult> _history = [];
  TranslationResult? _currentResult;
  List<double>? _currentKeypoints; // Keypoints hiện tại để vẽ
  bool _isProcessing = false;
  String? _errorMessage;

  List<TranslationResult> get history => _history;
  TranslationResult? get currentResult => _currentResult;
  List<double>? get currentKeypoints => _currentKeypoints; // Getter mới
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get isReady => _translationService.isReady; // Trạng thái ML service

  /// Khởi tạo ML service (gọi một lần khi app start)
  Future<void> initializeService() async {
    if (_isServiceInitialized) return;
    
    try {
      await _translationService.initialize();
      _isServiceInitialized = true;
      debugPrint('✅ TranslationProvider: Service đã được khởi tạo');
    } catch (e) {
      _errorMessage = 'Lỗi khởi tạo ML service: ${e.toString()}';
      debugPrint('❌ TranslationProvider: $e');
      notifyListeners();
    }
  }

  Future<void> translateImage(String imagePath) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _translationService.translateImage(imagePath);
      _currentResult = result;
      _history.insert(0, result);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi dịch ảnh: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> translateVideo(String videoPath) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _translationService.translateVideo(videoPath);
      _currentResult = result;
      _history.insert(0, result);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi dịch video: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> translateCameraFrame(String imagePath) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = File(imagePath);
      final result = await _translationService.translateCameraFrame(file);
      _currentResult = result;
      _history.insert(0, result);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi dịch từ camera: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Xử lý frame từ camera stream trực tiếp (REALTIME CONTINUOUS MODE)
  /// Logic giống realtime_demo.py - threshold 0.8
  Future<void> translateCameraImage(CameraImage cameraImage) async {
    // Đảm bảo service đã được khởi tạo
    if (!_isServiceInitialized) {
      await initializeService();
    }

    // Không set _isProcessing = true để tránh flicker UI
    _errorMessage = null;

    try {
      // Dùng translateCameraImageRealtime với threshold 0.8
      final result = await _translationService.translateCameraImageRealtime(cameraImage);
      
      // result có thể null nếu chưa đủ frames hoặc confidence < 0.8
      if (result != null) {
        _currentResult = result;
        // Chỉ thêm vào history nếu kết quả khác với kết quả trước đó
        if (_history.isEmpty || _history.first.text != result.text) {
          _history.insert(0, result);
          if (_history.length > 50) {
            _history.removeRange(50, _history.length);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error translating camera frame: $e');
    }
  }

  /// Dictionary Mode: Ghi 40 frames rồi predict
  /// Logic giống dictionary_mode.py - threshold 0.6
  Future<void> translateDictionarySequence(List<CameraImage> frames) async {
    if (!_isServiceInitialized) {
      await initializeService();
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _translationService.translateDictionarySequence(frames);
      
      if (result != null) {
        _currentResult = result;
        _history.insert(0, result);
        if (_history.length > 50) {
          _history.removeRange(50, _history.length);
        }
      }
      
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi dịch dictionary sequence: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Reset sequence buffer (gọi khi dừng camera)
  void resetSequence() {
    _translationService.resetSequence();
  }

  void clearHistory() {
    _history.clear();
    _currentResult = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }
}

