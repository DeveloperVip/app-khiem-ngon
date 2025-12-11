import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../services/frame_processor.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum TranslationMode {
  realtime,    // Realtime continuous (như realtime_demo.py) - threshold 0.8
  dictionary,  // Dictionary mode (như dictionary_mode.py) - nhấn nút ghi 30 frames - threshold 0.6
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _currentTranslation;
  double? _currentConfidence;
  bool _isStreamActive = false;
  final FrameProcessor _frameProcessor = FrameProcessor();
  int _selectedCameraIndex = 0;
  bool _hasInitialized = false; // Flag để chỉ khởi tạo một lần
  bool _isMLReady = false; // Trạng thái ML service
  String? _mlStatusMessage; // Thông báo trạng thái ML
  
  // Translation mode
  TranslationMode _translationMode = TranslationMode.realtime;
  
  // Dictionary mode: ghi 30 frames
  bool _isRecordingDictionary = false;
  List<CameraImage> _dictionaryFrames = [];
  int _dictionaryFrameCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // KHÔNG khởi tạo camera ở đây - sẽ khởi tạo khi screen được hiển thị
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isStreamActive = false;
    
    // Dừng stream an toàn trước khi dispose
    try {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          _controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Lỗi khi dừng stream trong dispose: $e');
    }
    
    _frameProcessor.reset();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Dừng stream an toàn
      try {
        if (_controller != null && 
            _controller!.value.isInitialized && 
            _controller!.value.isStreamingImages) {
          _controller!.stopImageStream();
        }
      } catch (e) {
        print('⚠️ Lỗi khi dừng stream trong lifecycle: $e');
      }
    } else if (state == AppLifecycleState.resumed) {
      // Chỉ resume nếu screen đang được hiển thị
      if (_hasInitialized && _isInitialized) {
        _startImageStream();
      }
    }
  }

  /// Khởi tạo camera khi screen được hiển thị lần đầu
  void _ensureInitialized() {
    if (_hasInitialized) return; // Đã khởi tạo rồi
    
    _hasInitialized = true;
    _initializeMLService();
    _initializeCamera();
  }

  /// Khởi tạo ML service và kiểm tra trạng thái
  Future<void> _initializeMLService() async {
    try {
      final provider = Provider.of<TranslationProvider>(context, listen: false);
      await provider.initializeService();
      
      // Kiểm tra trạng thái ML service
      await Future.delayed(const Duration(milliseconds: 500)); // Đợi initialize xong
      
      if (mounted) {
        setState(() {
          _isMLReady = provider.isReady;
          if (!_isMLReady) {
            _mlStatusMessage = '⚠️ Tính năng dịch AI chưa sẵn sàng.\nCamera vẫn hoạt động nhưng không thể dịch ký hiệu.\nVui lòng kiểm tra native libraries và rebuild app.';
          } else {
            _mlStatusMessage = null;
          }
        });
      }
    } catch (e) {
      print('Error initializing ML service: $e');
      if (mounted) {
        setState(() {
          _isMLReady = false;
          _mlStatusMessage = 'Lỗi khởi tạo tính năng dịch AI. Vui lòng kiểm tra lại.';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission trước
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          _showCameraErrorDialog(
            'Cần cấp quyền camera',
            'Ứng dụng cần quyền truy cập camera để dịch ngôn ngữ ký hiệu. Vui lòng cấp quyền trong Settings.',
          );
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          _showCameraErrorDialog(
            'Không tìm thấy camera',
            'Không tìm thấy camera trên thiết bị này.\n\n'
            'Nếu bạn đang dùng Android Emulator:\n'
            '1. Vào Settings > Extended Controls (⋯)\n'
            '2. Chọn Camera\n'
            '3. Chọn "Webcam0" hoặc "VirtualScene" để dùng webcam máy tính\n'
            '4. Restart emulator và thử lại.\n\n'
            'Hoặc test trên thiết bị thật để có camera thực tế.',
          );
        }
        return;
      }

      _cameras = cameras;
      
      // Chọn camera front để quay người dùng (để học ngôn ngữ ký hiệu)
      CameraDescription? selectedCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }
      // Nếu không có front camera thì dùng back camera
      selectedCamera ??= cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras[0],
      );

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Bắt đầu xử lý realtime với image stream (chỉ nếu ở chế độ realtime)
        if (_translationMode == TranslationMode.realtime) {
          _startImageStream();
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
        _showCameraErrorDialog(
          'Lỗi khởi tạo camera',
          'Không thể khởi tạo camera: $e\n\n'
          'Nguyên nhân có thể:\n'
          '• Camera đang được sử dụng bởi ứng dụng khác\n'
          '• Emulator chưa được cấu hình camera\n'
          '• Thiết bị không hỗ trợ camera\n\n'
          'Giải pháp:\n'
          '• Đóng các ứng dụng khác đang dùng camera\n'
          '• Cấu hình camera cho emulator (xem hướng dẫn)\n'
          '• Test trên thiết bị thật',
        );
      }
    }
  }

  void _showCameraErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeCamera(); // Thử lại
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Bắt đầu xử lý frame từ camera stream
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _isStreamActive = true;
    _controller!.startImageStream((CameraImage image) {
      if (!_isStreamActive) return;
      
      // Kiểm tra xem có nên xử lý frame này không (frame rate control)
      if (!_frameProcessor.shouldProcessFrame()) {
        return;
      }

      // Xử lý frame trong background để không block UI
      if (!_isProcessing) {
        _processFrame(image);
      }
    });
  }

  /// Xử lý frame từ camera stream
  Future<void> _processFrame(CameraImage image) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final provider = Provider.of<TranslationProvider>(context, listen: false);
      
      // Xử lý frame trực tiếp từ CameraImage (không lưu file)
      await provider.translateCameraImage(image);
      
      if (provider.currentResult != null && mounted) {
        setState(() {
          _currentTranslation = provider.currentResult!.text;
          _currentConfidence = provider.currentResult!.confidence;
        });
      }
    } catch (e) {
      print('Error processing frame: $e');
      // Không hiển thị lỗi cho mỗi frame để tránh spam UI
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Đổi camera (front/back)
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isStreamActive = false;
    });
    
    // Dừng stream an toàn trước khi dispose
    try {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Lỗi khi dừng stream khi đổi camera: $e');
    }
    
    await _controller?.dispose();
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    final newCamera = _cameras![_selectedCameraIndex];
    
    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startImageStream();
      }
    } catch (e) {
      print('Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đổi camera: $e')),
        );
      }
    }
  }

  /// Dictionary Mode: Bắt đầu ghi 30 frames
  Future<void> _startDictionaryRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isRecordingDictionary = true;
      _dictionaryFrames.clear();
      _dictionaryFrameCount = 0;
      _isStreamActive = false; // Tạm dừng realtime stream
    });
    
    // Dừng stream an toàn
    try {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Lỗi khi dừng stream cho dictionary mode: $e');
      // Bỏ qua lỗi và tiếp tục
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang ghi 30 frames... Thực hiện ký hiệu ngay!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
    
    // Bắt đầu ghi frames
    _recordDictionaryFrames();
  }
  
  /// Ghi 30 frames cho Dictionary mode
  /// Logic giống dictionary_mode.py: record_one_sequence()
  void _recordDictionaryFrames() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    _dictionaryFrames.clear();
    _dictionaryFrameCount = 0;
    
    // Bắt đầu image stream để lấy frames
    _controller!.startImageStream((CameraImage image) {
      if (!_isRecordingDictionary || !mounted) return;
      
      setState(() {
        // Lưu frame vào list
        _dictionaryFrames.add(image);
        _dictionaryFrameCount++;
      });
      
      // Khi đủ 30 frames, dừng và predict
      if (_dictionaryFrameCount >= 30) {
        _stopDictionaryRecording();
      }
    });
  }
  
  /// Dừng ghi Dictionary mode và predict
  Future<void> _stopDictionaryRecording() async {
    if (!_isRecordingDictionary) return;
    
    setState(() {
      _isRecordingDictionary = false;
    });
    
    // Dừng stream an toàn
    try {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Lỗi khi dừng stream sau khi ghi dictionary: $e');
    }
    
    if (_dictionaryFrames.length == 30) {
      if (!mounted) return;
      final currentContext = context;
      
      setState(() {
        _isProcessing = true;
      });
      
      try {
        final provider = Provider.of<TranslationProvider>(currentContext, listen: false);
        await provider.translateDictionarySequence(_dictionaryFrames);
        
        if (!mounted) return;
        
        if (provider.currentResult != null) {
          setState(() {
            _currentTranslation = provider.currentResult!.text;
            _currentConfidence = provider.currentResult!.confidence;
          });
          
          if (mounted) {
            _showResultDialog(
              provider.currentResult!,
              isVideo: false,
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          // Resume realtime stream nếu đang ở chế độ realtime
          if (_translationMode == TranslationMode.realtime) {
            _startImageStream();
          }
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ghi thất bại. Chỉ ghi được ${_dictionaryFrames.length}/30 frames')),
      );
      // Resume realtime stream
      if (_translationMode == TranslationMode.realtime) {
        _startImageStream();
      }
    }
    
    _dictionaryFrames.clear();
    _dictionaryFrameCount = 0;
  }

  /// Chuyển đổi chế độ translation
  void _switchTranslationMode() {
    setState(() {
      _translationMode = _translationMode == TranslationMode.realtime
          ? TranslationMode.dictionary
          : TranslationMode.realtime;
    });
    
    // Reset sequence khi đổi chế độ
    final provider = Provider.of<TranslationProvider>(context, listen: false);
    provider.resetSequence();
    
    // Nếu chuyển sang realtime, resume stream
    if (_translationMode == TranslationMode.realtime && _isInitialized) {
      _startImageStream();
    } else {
      // Dừng stream an toàn
      try {
        if (_controller != null && 
            _controller!.value.isInitialized && 
            _controller!.value.isStreamingImages) {
          _controller!.stopImageStream();
        }
      } catch (e) {
        print('⚠️ Lỗi khi dừng stream khi đổi chế độ: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translationMode == TranslationMode.realtime
                ? 'Chế độ: Realtime (threshold 80%)'
                : 'Chế độ: Dictionary (nhấn nút để ghi 30 frames, threshold 60%)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  void _showResultDialog(dynamic result, {String? imagePath, String? videoPath, bool isVideo = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.translate, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Kết quả dịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Preview media
              if (imagePath != null || videoPath != null)
                Flexible(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isVideo && videoPath != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                // Video thumbnail placeholder
                                Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Icon(
                                      Icons.videocam,
                                      color: Colors.white70,
                                      size: 64,
                                    ),
                                  ),
                                ),
                                // Play icon overlay
                                Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : imagePath != null
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.contain,
                                )
                              : const Center(
                                  child: Icon(Icons.image, color: Colors.white70, size: 48),
                                ),
                    ),
                  ),
                ),
              
              // Translation result
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Confidence badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: result.confidence > 0.7
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: result.confidence > 0.7 ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            result.confidence > 0.7 ? Icons.check_circle : Icons.warning,
                            size: 16,
                            color: result.confidence > 0.7 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Độ tin cậy: ${(result.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: result.confidence > 0.7 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Translated text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kết quả dịch:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Đóng'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Có thể thêm chức năng lưu vào đây
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget _buildModeButton(String label, TranslationMode mode, IconData icon) {
    final isSelected = _translationMode == mode;
    return InkWell(
      onTap: () => _switchTranslationMode(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ khởi tạo camera khi build được gọi (screen được hiển thị)
    _ensureInitialized();
    
    return Scaffold(
      backgroundColor: Colors.black, // Camera screen nên có background đen
      appBar: AppBar(
        title: Text(_translationMode == TranslationMode.realtime 
            ? 'Dịch Realtime' 
            : 'Chế Độ Từ Điển'),
        centerTitle: true,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // Hiển thị trạng thái ML service
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isMLReady ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isMLReady ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMLReady ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color: _isMLReady ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isMLReady ? 'AI Sẵn sàng' : 'AI Chưa sẵn sàng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isMLReady ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isInitialized && _controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isInitialized ? 'Đang khởi tạo camera...' : 'Đang tải camera...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (!_isInitialized)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Nếu camera không hoạt động trên emulator:\n'
                        'Vào Settings > Extended Controls > Camera\n'
                        'Chọn Webcam0 để dùng webcam máy tính',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Overlay hiển thị kết quả dịch realtime
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thông báo trạng thái ML service
                  if (!_isMLReady && _mlStatusMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _mlStatusMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Kết quả dịch realtime
                  if (_currentTranslation != null && _isMLReady)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ký hiệu được nhận diện:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              if (_currentConfidence != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _currentConfidence! > 0.7
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(_currentConfidence! * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _currentConfidence! > 0.7
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentTranslation!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isMLReady && _translationMode == TranslationMode.realtime)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isProcessing 
                                  ? 'Đang phân tích ký hiệu...'
                                  : 'Hãy thực hiện ký hiệu trước camera',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Mode selector
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(
                          'Realtime',
                          TranslationMode.realtime,
                          Icons.videocam,
                        ),
                        const SizedBox(width: 8),
                        _buildModeButton(
                          'Dictionary',
                          TranslationMode.dictionary,
                          Icons.book,
                        ),
                      ],
                    ),
                  ),
                  
                  // Nút điều khiển camera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút đổi camera
                      FloatingActionButton(
                        onPressed: _isInitialized && !_isRecordingDictionary ? _switchCamera : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: const Icon(Icons.flip_camera_ios, color: Colors.black),
                      ),
                      
                      // Nút Dictionary mode hoặc Realtime indicator
                      if (_translationMode == TranslationMode.dictionary)
                        FloatingActionButton(
                          onPressed: _isRecordingDictionary ? null : _startDictionaryRecording,
                          backgroundColor: _isRecordingDictionary ? Colors.red : Colors.blue,
                          child: _isRecordingDictionary
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_dictionaryFrameCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      '/30',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.fiber_manual_record, color: Colors.white, size: 28),
                        )
                      else
                        // Realtime mode indicator
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Thông tin trạng thái
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRecordingDictionary)
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đang ghi: $_dictionaryFrameCount/30 frames',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        )
                      else if (_translationMode == TranslationMode.realtime)
                        Text(
                          _isMLReady 
                              ? 'Đang phân tích ký hiệu liên tục (độ tin cậy ≥ 80%)'
                              : '⚠️ Tính năng dịch AI chưa sẵn sàng',
                          style: TextStyle(
                            color: _isMLReady ? Colors.white70 : Colors.orange[300],
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          _isMLReady
                              ? 'Nhấn nút để ghi 30 frames và dịch (độ tin cậy ≥ 60%)'
                              : '⚠️ Tính năng dịch AI chưa sẵn sàng',
                          style: TextStyle(
                            color: _isMLReady ? Colors.white70 : Colors.orange[300],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  
                  // Thông tin về realtime processing
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Text(
                        _translationMode == TranslationMode.realtime
                            ? (_isMLReady 
                                ? 'Đang phân tích ký hiệu realtime...'
                                : '⚠️ Tính năng dịch AI chưa sẵn sàng')
                            : (_isMLReady
                                ? 'Nhấn nút để ghi 30 frames và dịch'
                                : '⚠️ Tính năng dịch AI chưa sẵn sàng'),
                        style: TextStyle(
                          color: _isMLReady ? Colors.white70 : Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isProcessing)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đang xử lý...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
