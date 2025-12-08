import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/translation_result.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();

  List<TranslationResult> _history = [];
  TranslationResult? _currentResult;
  bool _isProcessing = false;
  String? _errorMessage;

  List<TranslationResult> get history => _history;
  TranslationResult? get currentResult => _currentResult;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

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

  /// Xử lý frame từ camera stream trực tiếp (hiệu quả hơn)
  Future<void> translateCameraImage(CameraImage cameraImage) async {
    // Không set _isProcessing = true để tránh flicker UI
    // Chỉ update khi có kết quả
    _errorMessage = null;

    try {
      final result = await _translationService.translateCameraImage(cameraImage);
      _currentResult = result;
      // Chỉ thêm vào history nếu kết quả khác với kết quả trước đó
      if (_history.isEmpty || _history.first.text != result.text) {
        _history.insert(0, result);
        // Giới hạn history để tránh memory leak
        if (_history.length > 50) {
          _history.removeRange(50, _history.length);
        }
      }
      notifyListeners();
    } catch (e) {
      // Không hiển thị lỗi cho mỗi frame để tránh spam
      debugPrint('Error translating camera frame: $e');
    }
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
}

