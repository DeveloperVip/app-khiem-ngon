import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../services/media_service.dart';
import '../services/translation_service.dart';
import '../models/user_upload_model.dart';
import 'auth/login_screen.dart';
import 'upload_detail_screen.dart';
import 'storage_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Cá nhân')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Vui lòng đăng nhập để sử dụng tính năng này',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ),
          );
        }

        return _ProfileContent(user: authProvider.user!);
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final dynamic user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final SupabaseService _supabaseService = SupabaseService();
  final MediaService _mediaService = MediaService();
  final TranslationService _translationService = TranslationService();

  @override
  Widget build(BuildContext context) {
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User info card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: widget.user.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              widget.user.photoUrl!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          )
                        : Text(
                            widget.user.displayName?[0].toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.displayName ?? widget.user.email,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        'Uploads',
                        widget.user.totalUploads.toString(),
                        Icons.cloud_upload,
                      ),
                      _buildStatItem(
                        context,
                        'Storage',
                        formatBytes(widget.user.totalStorageUsed),
                        Icons.storage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Upload section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tải lên Media',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Giới hạn: ${formatBytes(SupabaseService.maxFileSizeImage)} (ảnh), ${formatBytes(SupabaseService.maxFileSizeVideo)} (video)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Tối đa: ${SupabaseService.maxUploadsPerUser} files, ${formatBytes(SupabaseService.maxTotalStorage)} tổng',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _uploadMedia(context, isImage: true),
                                  icon: const Icon(Icons.image),
                                  label: const Text('Chọn ảnh'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _uploadMedia(context, isImage: false),
                                  icon: const Icon(Icons.video_library),
                                  label: const Text('Chọn video'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lưu trữ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StorageScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        label: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<UserUploadModel>>(
                    stream: _supabaseService.getUserUploads(widget.user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Lỗi: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final uploads = snapshot.data ?? [];

                      if (uploads.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có file nào được lưu',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload ảnh hoặc video để dịch và lưu trữ',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Hiển thị 3 uploads gần nhất
                      final recentUploads = uploads.take(3).toList();
                      return Column(
                        children: [
                          ...recentUploads.map((upload) => _buildUploadCard(context, upload)),
                          if (uploads.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StorageScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: Text('Xem thêm ${uploads.length - 3} file'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context, UserUploadModel upload) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: upload.mediaType == 'video'
            ? const Icon(Icons.video_library, size: 40)
            : upload.imageUrl != null
                ? Image.network(
                    upload.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 40),
        title: Text(upload.fileName ?? 'File'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(upload.uploadedAt)),
            if (upload.translation != null) ...[
              const SizedBox(height: 4),
              Text(
                upload.translation!,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (upload.confidence != null)
              Text(
                'Độ tin cậy: ${(upload.confidence! * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteUpload(context, upload),
        ),
        onTap: () => _showUploadDetail(context, upload),
      ),
    );
  }

  Future<void> _uploadMedia(BuildContext context, {required bool isImage}) async {
    // Kiểm tra giới hạn
    if (widget.user.totalUploads >= SupabaseService.maxUploadsPerUser) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã đạt giới hạn số lượng uploads'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.user.totalStorageUsed >= SupabaseService.maxTotalStorage) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã đạt giới hạn dung lượng lưu trữ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final XFile? file = isImage
          ? await _mediaService.pickImage()
          : await _mediaService.pickVideo();

      if (file == null) return;

      final fileSize = await File(file.path).length();
      final maxSize = isImage
          ? SupabaseService.maxFileSizeImage
          : SupabaseService.maxFileSizeVideo;

      if (!mounted) return;
      final currentContext = context;
      
      if (fileSize > maxSize) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'File quá lớn. Giới hạn: ${(maxSize / (1024 * 1024)).toStringAsFixed(1)} MB',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      final navigator = Navigator.of(currentContext);
      final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
      
      try {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Upload to Firebase Storage
        final mediaUrl = await _supabaseService.uploadMedia(
          file: File(file.path),
          userId: widget.user.uid,
          mediaType: isImage ? 'image' : 'video',
        );

        // Translate
        final translationResult = isImage
            ? await _translationService.translateImage(file.path)
            : await _translationService.translateVideo(file.path);

        // Save to database
        final savedUpload = await _supabaseService.saveUserUpload(
          userId: widget.user.uid,
          mediaUrl: mediaUrl,
          mediaType: isImage ? 'image' : 'video',
          fileSize: fileSize,
          fileName: file.path.split('/').last,
          translation: translationResult.text,
          confidence: translationResult.confidence,
        );

        // Refresh user data
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
        await authProvider.refreshUser();

        if (!mounted) return;
        navigator.pop(); // Đóng loading dialog
        
        // Mở màn hình chi tiết để hiển thị kết quả
        if (mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => UploadDetailScreen(upload: savedUpload),
            ),
          );
        }
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload thành công! Độ tin cậy: ${(translationResult.confidence * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle outer try-catch if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUpload(BuildContext context, UserUploadModel upload) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa upload'),
        content: const Text('Bạn có chắc muốn xóa upload này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    
    try {
      await _supabaseService.deleteUserUpload(upload.id, widget.user.uid);
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
      await authProvider.refreshUser();
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadDetail(BuildContext context, UserUploadModel upload) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadDetailScreen(upload: upload),
      ),
    );
  }
}

