import 'dart:io';
import 'package:camera/camera.dart';
import '../models/translation_result.dart';
import 'ml_service.dart';
import 'keypoints_extractor.dart';
import 'sequence_buffer.dart';

class TranslationService {
  final MLService _mlService = MLService();
  final KeypointsExtractor _keypointsExtractor = KeypointsExtractor();
  final SequenceBuffer _sequenceBuffer = SequenceBuffer(sequenceLength: 30);
  
  bool _isInitialized = false;
  bool _isInitializing = false; // Flag để tránh initialize đồng thời

  /// Khởi tạo service (load model)
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    try {
      await _mlService.initialize();
      _isInitialized = true; // Đánh dấu đã thử initialize (dù thành công hay không)
      
      // Chỉ log nếu ML service thực sự ready
      if (_mlService.isReady) {
      // print('✅ TranslationService đã được khởi tạo thành công');
      }
      // Nếu không ready, đã log trong MLService rồi, không cần log lại
    } catch (e) {
      // print('❌ Lỗi khởi tạo TranslationService: $e');
      // Không rethrow để app vẫn chạy được
      _isInitialized = true; // Đánh dấu đã thử để không thử lại
    } finally {
      _isInitializing = false;
    }
  }

  /// Dịch từ ảnh (single image) - DISABLED
  /// Model chỉ train cho realtime, không hỗ trợ snapshot
  @Deprecated('Model chỉ hỗ trợ realtime translation, không hỗ trợ snapshot')
  Future<TranslationResult> translateImage(String imagePath) async {
    return TranslationResult(
      text: 'Tính năng chụp ảnh tạm thời bị vô hiệu hóa.\nModel chỉ hỗ trợ dịch realtime (video stream).\nVui lòng sử dụng chế độ realtime hoặc dictionary.',
      confidence: 0.0,
      timestamp: DateTime.now(),
      mediaPath: imagePath,
      mediaType: MediaType.image,
    );
  }

  /// Dịch từ video (frame by frame)
  Future<TranslationResult> translateVideo(String videoPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Kiểm tra ML service có sẵn sàng không
    if (!_mlService.isReady) {
      return TranslationResult(
        text: 'ML Service không khả dụng. Vui lòng test trên thiết bị thật.',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: videoPath,
        mediaType: MediaType.video,
      );
    }

    try {
      // TODO: Implement video frame extraction và xử lý
      // Hiện tại: Extract một số frames từ video và dự đoán
      // Tạm thời dùng frame đầu tiên hoặc frame giữa video
      
      // Lấy keypoints từ video (tạm thời dùng dummy, cần implement thực tế)
      final keypoints = await _keypointsExtractor.extractKeypointsFromFile(videoPath);
      
      // Tạo sequence từ keypoints (lặp lại để đủ 30 frames)
      final sequence = List.generate(30, (_) => keypoints);
      
      // Dự đoán
      final prediction = await _mlService.predict(sequence);
      
      // Kiểm tra nếu không tìm thấy thao tác
      final isUnknown = prediction['is_unknown'] as bool? ?? false;
      final actionKey = prediction['action_key'] as String;
      
      if (isUnknown || actionKey == 'unknown') {
        return TranslationResult(
          text: 'undefined',
          confidence: prediction['confidence'] as double,
          timestamp: DateTime.now(),
          mediaPath: videoPath,
          mediaType: MediaType.video,
        );
      }
      
      return TranslationResult(
        text: prediction['display_text'] as String,
        confidence: prediction['confidence'] as double,
        timestamp: DateTime.now(),
        mediaPath: videoPath,
        mediaType: MediaType.video,
      );
    } catch (e) {
      // print('❌ Lỗi dịch video: $e');
      return TranslationResult(
        text: 'undefined',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: videoPath,
        mediaType: MediaType.video,
      );
    }
  }

  /// Xử lý frame từ camera (cũ - dùng File)
  Future<TranslationResult> translateCameraFrame(File imageFile) async {
    return translateImage(imageFile.path);
  }

  /// Xử lý frame từ camera stream trực tiếp (REALTIME CONTINUOUS MODE)
  /// Logic giống realtime_demo.py:
  /// - Dùng deque để giữ 30 frames gần nhất
  /// - Mỗi frame extract keypoints và thêm vào buffer
  /// - Khi đủ 30 frames → predict
  /// - Threshold 0.8 để hiển thị (như Python)
  Future<TranslationResult?> translateCameraImageRealtime(
    CameraImage cameraImage, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Kiểm tra ML service có sẵn sàng không
    if (!_mlService.isReady) {
      return null;
    }

    try {
      // Extract keypoints từ camera frame (giống mediapipe_detection + extract_keypoints)
      final keypoints = await _keypointsExtractor.extractKeypoints(cameraImage);
      
      // Kiểm tra số lượng keypoints (phải = 1662)
      if (keypoints.length != 1662) {
        // print('⚠️ Keypoints size không đúng: ${keypoints.length} != 1662. Bỏ qua frame này.');
        return null;
      }
      
      // Thêm vào sequence buffer (tự động loại bỏ frame cũ nếu đủ 30)
      _sequenceBuffer.addKeypoints(keypoints);
      
      // Chỉ predict khi đủ 30 frames (giống Python: if len(sequence) == SEQUENCE_LENGTH)
      if (!_sequenceBuffer.isReady()) {
        return null; // Chưa đủ frames
      }
      
      // Lấy sequence và dự đoán (giống Python: np.expand_dims(sequence, axis=0))
      final sequence = _sequenceBuffer.getSequence();
      final prediction = await _mlService.predict(sequence);
      
      final confidence = prediction['confidence'] as double;
      final isUnknown = prediction['is_unknown'] as bool? ?? false;
      final actionKey = prediction['action_key'] as String;
      
      // Threshold 0.8 như realtime_demo.py
      const double realtimeThreshold = 0.8;
      
      // Chỉ hiển thị nếu confidence >= 0.8 và không phải unknown
      if (isUnknown || actionKey == 'unknown' || confidence < realtimeThreshold) {
        return null; // Không đủ tự tin, không hiển thị
      }
      
      return TranslationResult(
        text: prediction['display_text'] as String,
        confidence: confidence,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    } catch (e) {
      // print('❌ Lỗi xử lý frame camera: $e');
      return null;
    }
  }

  /// Dictionary Mode: Ghi 30 frames liên tiếp rồi predict
  /// Logic giống dictionary_mode.py: record_one_sequence()
  /// - Reset buffer trước khi ghi
  /// - Ghi đúng 30 frames
  /// - Predict ngay sau khi ghi xong
  /// - Threshold 0.6 (như Python)
  Future<TranslationResult?> translateDictionarySequence(
    List<CameraImage> frames,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_mlService.isReady) {
      return TranslationResult(
        text: 'ML Service không khả dụng',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    }

    if (frames.length != 30) {
      return TranslationResult(
        text: 'Cần đúng 30 frames để dịch. Nhận được: ${frames.length}',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    }

    try {
      // Reset buffer trước khi ghi sequence mới
      _sequenceBuffer.clear();
      
      // Extract keypoints từ từng frame và thêm vào buffer
      for (final frame in frames) {
        final keypoints = await _keypointsExtractor.extractKeypoints(frame);
        
        // Kiểm tra số lượng keypoints
        if (keypoints.length != 1662) {
          // print('⚠️ Keypoints size không đúng: ${keypoints.length} != 1662');
          return TranslationResult(
            text: 'Lỗi extract keypoints từ frame',
            confidence: 0.0,
            timestamp: DateTime.now(),
            mediaPath: '',
            mediaType: MediaType.camera,
          );
        }
        
        _sequenceBuffer.addKeypoints(keypoints);
      }
      
      // Kiểm tra đã đủ 30 frames chưa
      if (!_sequenceBuffer.isReady()) {
        return TranslationResult(
          text: 'Ghi sequence thất bại',
          confidence: 0.0,
          timestamp: DateTime.now(),
          mediaPath: '',
          mediaType: MediaType.camera,
        );
      }
      
      // Predict (giống Python: model.predict(input_data, verbose=0)[0])
      final sequence = _sequenceBuffer.getSequence();
      final prediction = await _mlService.predict(sequence);
      
      final confidence = prediction['confidence'] as double;
      final isUnknown = prediction['is_unknown'] as bool? ?? false;
      final actionKey = prediction['action_key'] as String;
      
      // Threshold 0.6 như dictionary_mode.py
      const double dictionaryThreshold = 0.6;
      
      if (isUnknown || actionKey == 'unknown' || confidence < dictionaryThreshold) {
        return TranslationResult(
          text: 'Thao tác ngôn ngữ ký hiệu không được tìm thấy',
          confidence: confidence,
          timestamp: DateTime.now(),
          mediaPath: '',
          mediaType: MediaType.camera,
        );
      }
      
      return TranslationResult(
        text: prediction['display_text'] as String,
        confidence: confidence,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    } catch (e) {
      // print('❌ Lỗi dịch dictionary sequence: $e');
      return TranslationResult(
        text: 'Lỗi: $e',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    }
  }

  /// Alias cho backward compatibility
  @Deprecated('Dùng translateCameraImageRealtime() thay thế')
  Future<TranslationResult?> translateCameraImage(
    CameraImage cameraImage, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    return translateCameraImageRealtime(cameraImage, maxWidth: maxWidth, maxHeight: maxHeight);
  }

  /// Reset sequence buffer (gọi khi dừng camera hoặc bắt đầu mới)
  void resetSequence() {
    _sequenceBuffer.clear();
  }

  /// Kiểm tra service đã sẵn sàng chưa
  bool get isReady => _isInitialized && _mlService.isReady;

  /// Giải phóng tài nguyên
  void dispose() {
    _mlService.dispose();
    _sequenceBuffer.clear();
    _isInitialized = false;
  }
}






