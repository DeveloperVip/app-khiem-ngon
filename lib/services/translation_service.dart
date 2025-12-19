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
  
  List<double>? _lastKeypoints; // Lưu keypoints mới nhất
  List<double>? get lastKeypoints => _lastKeypoints;

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
    
    // Xử lý video thực sự
    try {
      // 1. Extract frames & keypoints (Giả lập: Hiện tại Native chưa hỗ trợ extract từ file, nên sẽ trả về dummy)
      // Trong tương lai cần implement Native Video Processor
      final keypoints = await _keypointsExtractor.extractKeypointsFromFile(videoPath);
      
      // 2. Tạo sequence (Lặp lại keypoints để đủ sequence length cho model)
      // Nếu keypoints rỗng hoặc toàn 0, model sẽ trả về confidence thấp hoặc unknown
      final sequence = List.generate(30, (_) => keypoints);
      
      // 3. Dự đoán
      final prediction = await _mlService.predict(sequence);
      
      final isUnknown = prediction['is_unknown'] as bool? ?? false;
      final actionKey = prediction['action_key'] as String;
      final confidence = prediction['confidence'] as double;
      
      if (isUnknown || actionKey == 'unknown' || confidence < 0.5) {
        return TranslationResult(
          text: 'Không thể nhận diện hành động trong video này (Độ tin cậy thấp hoặc chưa hỗ trợ định dạng video).',
          confidence: confidence,
          timestamp: DateTime.now(),
          mediaPath: videoPath,
          mediaType: MediaType.video,
        );
      }
      
      return TranslationResult(
        text: prediction['display_text'] as String,
        confidence: confidence,
        timestamp: DateTime.now(),
        mediaPath: videoPath,
        mediaType: MediaType.video,
      );
    } catch (e) {
      print('❌ Lỗi dịch video: $e');
      return TranslationResult(
        text: 'Lỗi xử lý video: $e',
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

  int _realtimeFrameCount = 0; // Đếm số frame để skip prediction

  // ... (giữ nguyên các hàm khác)

  // List lưu lịch sử dự đoán để kiểm tra tính ổn định (Consistency)
  final List<String> _predictionHistory = [];
  static const int _consistencyFrames = 5; // Giống config.py (logic Python dùng 15 nhưng ở đây model chạy stride 3, nên 5 lần predict = 15 frame)

  Future<TranslationResult?> translateCameraImageRealtime(
    CameraImage cameraImage, {
    int? maxWidth,
    int? maxHeight,
    bool isFrontCamera = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Kiểm tra ML service có sẵn sàng không
    if (!_mlService.isReady) {
      return null;
    }

    try {
      // 1. Extract keypoints: BẮT BUỘC mỗi frame để vẽ UI mượt mà
      final keypoints = await _keypointsExtractor.extractKeypoints(cameraImage, isFrontCamera: isFrontCamera);
      
      if (keypoints.length != 1662) {
        return null;
      }

      _lastKeypoints = keypoints; // Lưu lại để vẽ UI ngay lập tức

      // --- KIỂM TRA SỰ HIỆN DIỆN CỦA TAY (Gỡ lỗi dịch ngẫu nhiên) ---
      int leftHandPoints = 0;
      int rightHandPoints = 0;
      
      // Đếm số lượng điểm tay có toạ độ khác 0
      for (int i = 1536; i < 1599; i += 3) {
        if (keypoints[i] != 0 || keypoints[i + 1] != 0) leftHandPoints++;
      }
      for (int i = 1599; i < 1662; i += 3) {
        if (keypoints[i] != 0 || keypoints[i + 1] != 0) rightHandPoints++;
      }

      // Chỉ coi là có tay nếu tìm thấy ít nhất 5 khớp (giảm nhiễu từ các điểm giả)
      bool hasHand = leftHandPoints >= 5 || rightHandPoints >= 5;

      if (!hasHand) {
        _realtimeFrameCount = 0; // Reset stride counter
        _sequenceBuffer.clear(); 
        _predictionHistory.clear();
        return null;
      }
      
      // 2. Thêm vào sequence buffer
      _sequenceBuffer.addKeypoints(keypoints);
      
      // 3. Tối ưu Prediction: Chỉ dự đoán mỗi 3 frames (Stride = 3)
      _realtimeFrameCount++;
      if (_realtimeFrameCount % 3 != 0) {
         return null; 
      }

      // Chỉ predict khi đủ 30 frames
      if (!_sequenceBuffer.isReady()) {
        return null; 
      }
      
      // 4. Predict
      final sequence = _sequenceBuffer.getSequence();
      final prediction = await _mlService.predict(sequence);
      
      final confidence = prediction['confidence'] as double;
      final isUnknown = prediction['is_unknown'] as bool? ?? false;
      final actionKey = prediction['action_key'] as String;
      
      // Tăng threshold lên 0.65 để lọc kết quả sai (Accuracy++)
      const double realtimeThreshold = 0.65; 

      _predictionHistory.add(actionKey);
      if (_predictionHistory.length > _consistencyFrames) {
        _predictionHistory.removeAt(0);
      }
      
      bool isStable = false;
      if (_predictionHistory.length >= _consistencyFrames) {
        isStable = _predictionHistory.every((element) => element == actionKey);
      }
      
      // LOGIC XỬ LÝ KẾT QUẢ:
      // 1. Nếu ổn định và tự tin (Confidence >= 0.65) -> Trả về từ đã học
      if (!isUnknown && actionKey != 'unknown' && confidence >= realtimeThreshold && isStable) {
        return TranslationResult(
          text: prediction['display_text'] as String,
          confidence: confidence,
          timestamp: DateTime.now(),
          mediaPath: '',
          mediaType: MediaType.camera,
        );
      }
      
      // 2. Nếu ổn định nhưng không tự tin (Confidence thấp) hoặc Model báo Unknown -> Báo "Ký hiệu chưa được học"
      // Điều này giúp người dùng biết là họ đang làm ký hiệu nhưng máy chưa nhận diện được
      if (isStable && (isUnknown || actionKey == 'unknown' || confidence < realtimeThreshold)) {
        return TranslationResult(
          text: "Ký hiệu chưa được học",
          confidence: confidence,
          timestamp: DateTime.now(),
          mediaPath: '',
          mediaType: MediaType.camera,
        );
      }

      return null;
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
    List<CameraImage> frames, {
    bool isFrontCamera = true,
  }) async {
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

    if (frames.length != 40) {
      return TranslationResult(
        text: 'Cần đúng 40 frames để dịch. Nhận được: ${frames.length}',
        confidence: 0.0,
        timestamp: DateTime.now(),
        mediaPath: '',
        mediaType: MediaType.camera,
      );
    }

    try {
      // Reset buffer trước khi ghi sequence mới
      _sequenceBuffer.clear();
      
      // Resample frames: Chỉ lấy đúng 30 frames (sequenceLength) được chia đều từ input
      // Ví dụ: Input 40 frames -> Lấy frame 0, 1, 2... (bỏ bớt 10 frame xen kẽ)
      // Điều này giúp:
      // 1. Giảm số lượng lần gọi extractKeypoints từ 40 xuống 30 -> Giảm 25% lag
      // 2. Đảm bảo sequence gửi vào model luôn đúng length 30 -> Fix lỗi model reject
      List<CameraImage> framesToProcess = [];
      if (frames.length > 30) {
        double step = frames.length / 30;
        for (int i = 0; i < 30; i++) {
          int index = (i * step).floor();
          if (index < frames.length) {
            framesToProcess.add(frames[index]);
          }
        }
      } else {
        framesToProcess = frames; // Nếu ít hơn hoặc bằng 30 (hiếm khi xảy ra nếu logic capture đúng)
      }

      // Extract keypoints từ từng frame đã lọc
      for (final frame in framesToProcess) {
        final keypoints = await _keypointsExtractor.extractKeypoints(frame, isFrontCamera: isFrontCamera);
        
        // Kiểm tra số lượng keypoints
        if (keypoints.length != 1662) {
          return TranslationResult(
            text: 'Lỗi extract keypoints từ frame',
            confidence: 0.0,
            timestamp: DateTime.now(),
            mediaPath: '',
            mediaType: MediaType.camera,
          );
        }
        
        _lastKeypoints = keypoints; // Cập nhật (frame cuối cùng sẽ được giữ)
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
      
      // Threshold 0.5 như yêu cầu
      const double dictionaryThreshold = 0.5;
      
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






