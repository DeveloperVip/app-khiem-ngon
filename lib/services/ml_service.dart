import 'package:flutter/services.dart';
import 'dart:convert';

/// Service để load và chạy TensorFlow Lite model
/// Sử dụng native Android inference với Flex Delegate support
class MLService {
  static const String _modelPath = 'assets/models/best_model.tflite';
  static const String _actionsPath = 'assets/models/actions.json';
  static const MethodChannel _channel = MethodChannel('com.example.flutter_application_initial/tflite');
  
  Map<String, dynamic>? _actionsData;
  bool _isInitialized = false;
  bool _modelLoaded = false;

  /// Khởi tạo model và load metadata
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📦 Đang load TensorFlow Lite model...');
      print('   Đường dẫn: $_modelPath');
      
      // Load model qua native Android code
      try {
        print('📦 Đang gọi native loadModel...');
        await _channel.invokeMethod('loadModel', {'modelPath': _modelPath});
        _modelLoaded = true;
        print('✅ Đã load model thành công qua native code!');
        
        // Lấy input/output shapes
        try {
          final inputShape = await _channel.invokeMethod('getInputShape');
          final outputShape = await _channel.invokeMethod('getOutputShape');
          print('   Input shape: $inputShape');
          print('   Output shape: $outputShape');
        } catch (e) {
          print('⚠️ Không thể lấy shapes: $e');
        }
      } catch (e) {
        // print('❌ Không thể load model qua native code: $e');
        print('   Lỗi load model (có thể do chưa setup xong hoặc chạy trên emulator không có GPU delegate): $e');
        _isInitialized = true;
        return;
      }

      // Load metadata (actions)
      try {
        print('📦 Đang load actions metadata...');
        final actionsJson = await rootBundle.loadString(_actionsPath);
        _actionsData = json.decode(actionsJson) as Map<String, dynamic>;
        print('✅ Đã load metadata thành công');
        print('   Actions: ${_actionsData!['actions']}');
      } catch (e) {
        print('❌ Không thể load metadata: $e');
        print('❌ Kiểm tra file: $_actionsPath');
        // Vẫn tiếp tục nếu chỉ thiếu metadata
      }

      _isInitialized = true;
      print('✅ ML Service đã được khởi tạo thành công!');
    } catch (e) {
      print('❌ Lỗi khởi tạo ML Service: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // Không rethrow để app vẫn chạy được, chỉ log error
      _isInitialized = true; // Đánh dấu đã thử để không thử lại
    }
  }

  /// Dự đoán từ sequence keypoints
  /// Input: List[List<double>> shape (sequenceLength, numKeypoints)
  /// Output: Map chứa predicted action, confidence, và probabilities
  Future<Map<String, dynamic>> predict(List<List<double>> sequence) async {
    if (!_isInitialized || !_modelLoaded) {
      // Trả về kết quả mock nếu ML service chưa sẵn sàng (không log mỗi lần)
      return {
        'action_key': 'unknown',
        'display_text': 'ML Service không khả dụng',
        'confidence': 0.0,
        'probabilities': [],
        'all_actions': [],
        'is_unknown': true,
      };
    }

    if (_actionsData == null || sequence.length != _actionsData!['sequence_length']) {
      // Ignore mismatch if it's close enough or just log warning instead of throwing to avoid crash loop
       print(
        '⚠️ Sequence length warning. Config: ${_actionsData?['sequence_length']}, Recieved: ${sequence.length}'
      );
      if (sequence.length != _actionsData!['sequence_length']) {
         return {
          'action_key': 'unknown',
          'display_text': 'Đang chờ đủ frame...',
          'confidence': 0.0,
          'probabilities': [],
          'all_actions': [],
          'is_unknown': true,
        };
      }
    }

    try {
      // Convert sequence thành tensor input shape (1, sequenceLength, numKeypoints)
      final input = [sequence];
      
      // Gọi native inference
      final List<dynamic> rawOutput = await _channel.invokeMethod('runInference', {'input': input});
      final probabilities = rawOutput.map<double>((e) => (e as num).toDouble()).toList();
      
      // Tìm class có probability cao nhất
      double maxProb = 0.0;
      int maxIdx = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIdx = i;
        }
      }

      // Ngưỡng confidence tối thiểu để coi là hợp lệ (60%)
      const double minConfidenceThreshold = 0.6;
      
      // Lấy action key
      final actions = _actionsData!['actions'] as List;
      final predictedKey = actions[maxIdx] as String;

      // Handle 'null' class (index 0 usually, or explicitly named 'null')
      if (predictedKey == 'null') {
         // Nếu dự đoán là 'null' (không làm gì), trả về trạng thái bình thường/unknown
          return {
          'action_key': 'null',
          'display_text': '', // Hoặc '...', hiển thị trống
          'confidence': maxProb,
          'probabilities': probabilities,
          'all_actions': actions,
          'is_unknown': true, // Treat as unknown/nothing to display
        };
      }
      
      // Nếu confidence quá thấp
      if (maxProb < minConfidenceThreshold) {
        return {
          'action_key': 'unknown',
          'display_text': '...',
          'confidence': maxProb,
          'probabilities': probabilities,
          'all_actions': actions,
          'is_unknown': true, 
        };
      }

      // Lấy display text
      final actionDisplay = _actionsData!['action_display'] as Map<String, dynamic>;
      final displayText = actionDisplay[predictedKey] ?? predictedKey;

      // In ít log hơn, chỉ in khi kết quả thay đổi hoặc confidence rất cao
      // print('✅ Dự đoán: $displayText ($predictedKey) - ${(maxProb * 100).toStringAsFixed(1)}%');

      return {
        'action_key': predictedKey,
        'display_text': displayText,
        'confidence': maxProb,
        'probabilities': probabilities,
        'all_actions': actions,
        'is_unknown': false,
      };
    } catch (e) {
      print('❌ Lỗi khi dự đoán: $e');
      return {
          'action_key': 'error',
          'display_text': 'Lỗi nhận diện',
          'confidence': 0.0,
          'probabilities': [],
          'all_actions': [],
          'is_unknown': true,
        };
    }
  }

  /// Lấy danh sách actions
  List<String> getActions() {
    if (_actionsData == null) {
      throw Exception('Actions data chưa được load');
    }
    return List<String>.from(_actionsData!['actions'] as List);
  }

  /// Lấy action display text
  String getActionDisplay(String actionKey) {
    if (_actionsData == null) {
      throw Exception('Actions data chưa được load');
    }
    final actionDisplay = _actionsData!['action_display'] as Map<String, dynamic>;
    return actionDisplay[actionKey] ?? actionKey;
  }

  /// Kiểm tra service đã sẵn sàng chưa
  bool get isReady => _isInitialized && _modelLoaded;

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('disposeModel');
    } catch (e) {
      print('⚠️ Lỗi dispose model: $e');
    }
    _modelLoaded = false;
    _isInitialized = false;
  }
}
