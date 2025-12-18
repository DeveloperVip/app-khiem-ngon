import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/user_upload_model.dart';
import '../providers/translation_provider.dart';

class UploadDetailScreen extends StatefulWidget {
  final UserUploadModel upload;

  const UploadDetailScreen({super.key, required this.upload});

  @override
  State<UploadDetailScreen> createState() => _UploadDetailScreenState();
}

class _UploadDetailScreenState extends State<UploadDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isRetranslating = false;

  @override
  void initState() {
    super.initState();
    if (widget.upload.mediaType == 'video' && widget.upload.videoUrl != null) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.upload.videoUrl!),
    );
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    }).catchError((error) {
      print('Error initializing video: $error');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });
  }

  Future<void> _reTranslate() async {
    if (_isRetranslating) return;
    
    setState(() {
      _isRetranslating = true;
    });

    try {
      final mediaUrl = widget.upload.mediaType == 'video' 
          ? widget.upload.videoUrl 
          : widget.upload.imageUrl;

      if (mediaUrl == null) throw Exception('Không tìm thấy link media');

      // 1. Download file về temp
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse(mediaUrl));
      final HttpClientResponse response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Lỗi tải file: ${response.statusCode}');
      }
      
      final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      final Directory tempDir = await getTemporaryDirectory();
      final String extension = widget.upload.mediaType == 'video' ? 'mp4' : 'jpg';
      final File tempFile = File('${tempDir.path}/temp_retranslate.$extension');
      await tempFile.writeAsBytes(bytes);

      // 2. Gọi Provider dịch
      final provider = Provider.of<TranslationProvider>(context, listen: false);
      if (widget.upload.mediaType == 'video') {
        await provider.translateVideo(tempFile.path);
      } else {
        await provider.translateImage(tempFile.path);
      }

      // 3. Cập nhật UI nếu có kết quả mới
      // (Lưu ý: Provider sẽ cập nhật kết quả vào currentResult, ta có thể show dialog hoặc reload)
      if (provider.currentResult != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Dịch lại hoàn tất!'), backgroundColor: Colors.green),
        );
        // Refresh lại trang này có thể phức tạp vì nó nhận Model từ ngoài.
        // Tốt nhất hiển thị kết quả mới trong Dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kết quả dịch mới'),
            content: Text(provider.currentResult!.text, style: const TextStyle(fontSize: 18)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))
            ],
          ),
        );
      } else {
        throw Exception('Không nhận được kết quả dịch');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetranslating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Phần UI build giữ nguyên, chỉ sửa nút bấm bên dưới)
    final isVideo = widget.upload.mediaType == 'video';
    final mediaUrl = isVideo ? widget.upload.videoUrl : widget.upload.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media preview
            Container(
              height: 400,
              width: double.infinity,
              color: Colors.black,
              child: isVideo && mediaUrl != null
                  ? _isVideoInitialized && _videoController != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                  : mediaUrl != null
                      ? CachedNetworkImage(
                          imageUrl: mediaUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.error, size: 64, color: Colors.white70),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image, size: 64, color: Colors.white70),
                        ),
            ),

            // Translation result section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence badge & Text (Giữ nguyên logic hiển thị cũ)
                  if (widget.upload.confidence != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.upload.confidence! > 0.7
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.upload.confidence! > 0.7 ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.upload.confidence! > 0.7 ? Icons.check_circle : Icons.warning,
                            size: 20,
                            color: widget.upload.confidence! > 0.7 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Độ tin cậy: ${(widget.upload.confidence! * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.upload.confidence! > 0.7 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.translate, color: Theme.of(context).colorScheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Kết quả dịch:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.upload.translation != null && widget.upload.translation!.isNotEmpty 
                              ? widget.upload.translation! 
                              : 'Chưa có kết quả dịch',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: widget.upload.translation != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Metadata Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMetadataRow(Icons.calendar_today, 'Ngày upload', _formatDate(widget.upload.uploadedAt)),
                          if (widget.upload.fileName != null) ...[
                            const Divider(),
                            _buildMetadataRow(Icons.description, 'Tên file', widget.upload.fileName!),
                          ],
                          const Divider(),
                          _buildMetadataRow(Icons.storage, 'Kích thước', _formatBytes(widget.upload.fileSize)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nút Dịch lại MỚI
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isRetranslating ? null : _reTranslate,
                      icon: _isRetranslating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isRetranslating ? 'Đang tải & Dịch...' : 'Dịch lại Video này'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}



