import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/translation_provider.dart';
import '../services/media_service.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final MediaService _mediaService = MediaService();
  File? _selectedFile;
  VideoPlayerController? _videoController;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await _mediaService.requestPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  Future<void> _pickImage() async {
    final file = await _mediaService.pickImage();
    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _mediaService.pickVideo();
    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_selectedFile!)
          ..initialize().then((_) {
            setState(() {});
          });
      });
    }
  }

  Future<void> _translate() async {
    if (_selectedFile == null) return;
    
    // Check limit
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabaseService = SupabaseService();
    if (authProvider.user != null) {
      final uploads = await supabaseService.getUserUploads(authProvider.user!.uid).first;
      if (uploads.length >= 20) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu trữ online đã đầy (20/20). Vui lòng xóa bớt file trong kho lưu trữ.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final provider = Provider.of<TranslationProvider>(context, listen: false);
    
    if (_videoController != null) {
      await provider.translateVideo(_selectedFile!.path);
    } else {
      await provider.translateImage(_selectedFile!.path);
    }

    if (provider.currentResult != null && mounted) {
      _showResultDialog(provider.currentResult!);
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
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TranslationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải lên Video/Ảnh'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_permissionsGranted)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cần cấp quyền truy cập để sử dụng tính năng này',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkPermissions,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Chọn phương thức tải lên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectButton(
                            icon: Icons.image,
                            label: 'Chọn ảnh',
                            onTap: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectButton(
                            icon: Icons.video_library,
                            label: 'Chọn video',
                            onTap: _pickVideo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null) ...[
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: _videoController != null &&
                              _videoController!.value.isInitialized
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          : Image.file(
                              _selectedFile!,
                              fit: BoxFit.contain,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File đã chọn: ${_selectedFile!.path.split('/').last}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_videoController != null &&
                              _videoController!.value.isInitialized) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                  },
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: provider.isProcessing ? null : _translate,
                  icon: provider.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate),
                  label: Text(
                    provider.isProcessing ? 'Đang xử lý...' : 'Dịch ngay',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}







