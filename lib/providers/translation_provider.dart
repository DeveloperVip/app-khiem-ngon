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
  List<double>? _currentKeypoints;
  bool _isProcessing = false;
  String? _errorMessage;
  String _liveTranscript = ""; // Chuỗi tích luỹ kết quả dịch realtime

  List<TranslationResult> get history => _history;
  TranslationResult? get currentResult => _currentResult;
  List<double>? get currentKeypoints => _currentKeypoints;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get isReady => _translationService.isReady;
  String get liveTranscript => _liveTranscript; // Getter cho hội thoại

  void resetTranscript() {
    _liveTranscript = "";
    _currentResult = null;
    notifyListeners();
  }

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
  Future<void> translateCameraImage(CameraImage cameraImage, {bool isFrontCamera = true}) async {
    // Đảm bảo service đã được khởi tạo
    if (!_isServiceInitialized) {
      await initializeService();
    }

    // Không set _isProcessing = true để tránh flicker UI
    _errorMessage = null;

    try {
      // Dùng translateCameraImageRealtime với threshold 0.8
      final result = await _translationService.translateCameraImageRealtime(cameraImage, isFrontCamera: isFrontCamera);
      
      // Cập nhật keypoints để vẽ UI (bao gồm vùng an toàn)
      _currentKeypoints = _translationService.lastKeypoints;
      
      // NOTIFY LẦN 1: Để vẽ lại keypoints ngay lập tức (Xử lý mượt canvas)
      notifyListeners(); 

      // result có thể null nếu chưa đủ frames hoặc confidence < 0.6
      if (result != null) {
        _currentResult = result;
        
        // Tích luỹ vào transcript (hội thoại)
        if (_liveTranscript.isEmpty) {
          _liveTranscript = result.text;
        } else {
          // Chỉ thêm nếu từ mới khác với từ cuối cùng đã thêm (tránh lặp)
          List<String> words = _liveTranscript.trim().split(" ");
          if (words.last != result.text) {
            _liveTranscript += " ${result.text}";
          }
        }

        // Chỉ thêm vào history tab nếu kết quả khác với kết quả trước đó
        if (_history.isEmpty || _history.first.text != result.text) {
          _history.insert(0, result);
          if (_history.length > 50) {
            _history.removeRange(50, _history.length);
          }
        }
        
        // NOTIFY LẦN 2: Khi có kết quả dịch mới
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error translating camera frame: $e');
    }
  }

  /// Dictionary Mode: Ghi 40 frames rồi predict
  /// Logic giống dictionary_mode.py - threshold 0.6
  Future<void> translateDictionarySequence(List<CameraImage> frames, {bool isFrontCamera = true}) async {
    if (!_isServiceInitialized) {
      await initializeService();
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _translationService.translateDictionarySequence(frames, isFrontCamera: isFrontCamera);
      
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

