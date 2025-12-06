import 'dart:io';
import 'package:flutter/material.dart';
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

