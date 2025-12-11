import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';

/// Service để load và chạy TensorFlow Lite model
class MLService {
  static const String _modelPath = 'assets/models/tf_lstm_best.tflite';
  static const String _actionsPath = 'assets/models/actions.json';
  static const MethodChannel _channel = MethodChannel('com.example.flutter_application_initial/tflite');
  
  Interpreter? _interpreter;
  Map<String, dynamic>? _actionsData;
  bool _isInitialized = false;

  /// Khởi tạo model và load metadata
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📦 Đang load TensorFlow Lite model...');
      print('   Đường dẫn: $_modelPath');
      
      // Load model bytes từ assets
      ByteData modelBytes;
      try {
        modelBytes = await rootBundle.load(_modelPath);
        print('✅ Đã load model file thành công (${modelBytes.lengthInBytes} bytes)');
      } catch (e) {
        print('❌ Không thể load model file từ assets: $e');
        print('❌ Kiểm tra:');
        print('   1. File có tồn tại tại: $_modelPath');
        print('   2. Đã khai báo trong pubspec.yaml: assets: - assets/models/');
        print('   3. Đã chạy flutter pub get và rebuild app');
        _isInitialized = true;
        return;
      }
      
      // Tạo Interpreter - FlexDelegate đã được load trong MainActivity
      try {
        print('📦 Đang khởi tạo TensorFlow Lite interpreter...');
        print('   Model size: ${modelBytes.lengthInBytes} bytes (${(modelBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
        print('   ⚠️ Model sử dụng SELECT_TF_OPS');
        
        // Kiểm tra FlexDelegate từ native side
        bool flexReady = false;
        try {
          flexReady = await _channel.invokeMethod<bool>('isFlexDelegateReady') ?? false;
          if (flexReady) {
            print('   ✅ FlexDelegate đã được load trong MainActivity');
          } else {
            print('   ⚠️ FlexDelegate chưa sẵn sàng');
          }
        } catch (e) {
          print('   ⚠️ Không thể kiểm tra FlexDelegate: $e');
        }
        
        // QUAN TRỌNG: Đảm bảo FlexDelegate được register trước khi tạo Interpreter
        if (flexReady) {
          print('   ⏳ Đảm bảo FlexDelegate được register...');
          try {
            await _channel.invokeMethod('ensureFlexDelegateReady');
          } catch (e) {
            print('   ⚠️ Không thể ensure FlexDelegate: $e');
          }
          // Đợi thêm để đảm bảo FlexDelegate được link hoàn toàn
          await Future.delayed(const Duration(seconds: 2));
        } else {
          print('   ⚠️ FlexDelegate chưa được load, đợi 5 giây...');
          await Future.delayed(const Duration(seconds: 5));
        }
        
        // Khởi tạo Interpreter - FlexDelegate sẽ tự động được sử dụng nếu đã load
        print('   🔄 Đang tạo interpreter...');
        
        try {
          // Tạo Interpreter với options đơn giản
          final options = InterpreterOptions();
          options.threads = 2;
          
          _interpreter = Interpreter.fromBuffer(
            modelBytes.buffer.asUint8List(),
            options: options,
          );
          print('   ✅ Đã tạo interpreter thành công!');
        } catch (e) {
          print('   ❌ Lỗi khi tạo interpreter: $e');
          print('   ⚠️ FlexDelegate có thể chưa được apply');
          print('   ⚠️ Đang thử lại với options khác...');
          
          // Thử lại không có options
          try {
            await Future.delayed(const Duration(seconds: 1));
            _interpreter = Interpreter.fromBuffer(
              modelBytes.buffer.asUint8List(),
            );
            print('   ✅ Thành công khi thử lại!');
          } catch (e2) {
            print('   ❌ Vẫn thất bại: $e2');
            print('   ⚠️ Model sử dụng SELECT_TF_OPS nhưng FlexDelegate không được apply');
            print('   ⚠️ Kiểm tra:');
            print('      1. libtensorflowlite_flex_jni.so có trong jniLibs/');
            print('      2. Version tensorflow-lite-select-tf-ops: 2.15.0');
            print('      3. Đã rebuild app sau khi thay đổi');
            rethrow;
          }
        }
        
        // Kiểm tra input/output shapes
        final inputTensors = _interpreter!.getInputTensors();
        final outputTensors = _interpreter!.getOutputTensors();
        print('✅ Đã khởi tạo interpreter thành công!');
        print('   Input tensors: ${inputTensors.length}');
        print('   Output tensors: ${outputTensors.length}');
        if (inputTensors.isNotEmpty) {
          print('   Input shape: ${inputTensors[0].shape}');
        }
        if (outputTensors.isNotEmpty) {
          print('   Output shape: ${outputTensors[0].shape}');
        }
      } catch (e, stackTrace) {
        print('❌ Không thể khởi tạo TensorFlow Lite interpreter: $e');
        print('❌ Stack trace: $stackTrace');
        print('❌ Tính năng ML sẽ không hoạt động.');
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
  /// Input: List[List&lt;double&gt;&gt; shape (sequenceLength, numKeypoints)
  /// Output: Map chứa predicted action, confidence, và probabilities
  Future<Map<String, dynamic>> predict(List<List<double>> sequence) async {
    if (!_isInitialized || _interpreter == null) {
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

    if (sequence.length != _actionsData!['sequence_length']) {
      throw Exception(
        'Sequence length không đúng. Cần ${_actionsData!['sequence_length']}, nhận được ${sequence.length}'
      );
    }

    try {
      // Convert sequence thành tensor input
      // Shape: (1, sequenceLength, numKeypoints)
      final numKeypoints = sequence[0].length;
      final inputShape = [1, sequence.length, numKeypoints];
      
      // Tạo input tensor
      final input = List.generate(
        inputShape[0],
        (_) => List.generate(
          inputShape[1],
          (i) => List.generate(
            inputShape[2],
            (j) => sequence[i][j].toDouble(),
          ),
        ),
      );

      // Tạo output tensor
      final numClasses = (_actionsData!['actions'] as List).length;
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

      // Chạy inference
      _interpreter!.run(input, output);

      // Lấy probabilities
      final probabilities = output[0].map<double>((e) => e.toDouble()).toList();
      
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
      
      // Nếu confidence quá thấp, coi như không tìm thấy
      if (maxProb < minConfidenceThreshold) {
        print('⚠️ Confidence quá thấp: ${(maxProb * 100).toStringAsFixed(1)}% < ${(minConfidenceThreshold * 100).toStringAsFixed(0)}%');
        return {
          'action_key': 'unknown',
          'display_text': 'Thao tác ngôn ngữ ký hiệu không được tìm thấy',
          'confidence': maxProb,
          'probabilities': probabilities,
          'all_actions': _actionsData!['actions'] as List,
          'is_unknown': true, // Flag để biết là không tìm thấy
        };
      }

      // Lấy action key và display text
      final actions = _actionsData!['actions'] as List;
      final actionDisplay = _actionsData!['action_display'] as Map<String, dynamic>;
      final predictedKey = actions[maxIdx] as String;
      final displayText = actionDisplay[predictedKey] ?? predictedKey;

      print('✅ Dự đoán thành công: $displayText (${(maxProb * 100).toStringAsFixed(1)}%)');

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
      rethrow;
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
  bool get isReady => _isInitialized && _interpreter != null;

  /// Giải phóng tài nguyên
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

