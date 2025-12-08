import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../services/frame_processor.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _currentTranslation;
  double? _currentConfidence;
  bool _isStreamActive = false;
  final FrameProcessor _frameProcessor = FrameProcessor();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Dùng medium thay vì high để tăng tốc độ
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420, // Format tối ưu cho xử lý
        );

        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });

          // Bắt đầu xử lý realtime với image stream
          _startImageStream();
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo camera: $e')),
        );
      }
    }
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

  /// Chụp ảnh và dịch (manual capture)
  Future<void> _captureAndTranslate() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      final provider = Provider.of<TranslationProvider>(context, listen: false);
      
      await provider.translateImage(image.path);
      
      if (provider.currentResult != null && mounted) {
        _showResultDialog(provider.currentResult!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultDialog(dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Độ tin cậy: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isStreamActive = false;
    _controller?.stopImageStream();
    _frameProcessor.reset();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch Realtime'),
        centerTitle: true,
        actions: [
          // Hiển thị trạng thái xử lý
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
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
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kết quả dịch realtime
                  if (_currentTranslation != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                                'Kết quả dịch:',
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
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Nút chụp ảnh manual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: _isProcessing ? null : _captureAndTranslate,
                        backgroundColor: Colors.white,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.black),
                        label: const Text(
                          'Chụp & Dịch',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  
                  // Thông tin về realtime processing
                  const SizedBox(height: 8),
                  Text(
                    'Đang xử lý realtime (~5 fps)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
