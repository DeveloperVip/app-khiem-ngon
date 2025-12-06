import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';
import '../models/user_upload_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============ LESSONS ============
  Stream<List<LessonModel>> getLessons() {
    return _supabase
        .from('lessons')
        .stream(primaryKey: ['id'])
        .order('order')
        .map((data) => data
            .map((json) => LessonModel.fromJson(json))
            .toList());
  }

  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .single();

      return LessonModel.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi lấy lesson: ${e.toString()}');
    }
  }

  // ============ USER UPLOADS ============
  Future<String> uploadMedia({
    required File file,
    required String userId,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final fileBytes = await file.readAsBytes();
      final filePath = '$userId/$mediaType/$fileName';

      await _supabase.storage
          .from('user_media')
          .uploadBinary(filePath, fileBytes);

      // Lấy signed URL hoặc public URL
      final response = _supabase.storage
          .from('user_media')
          .getPublicUrl(filePath);

      return response;
    } catch (e) {
      throw Exception('Lỗi upload media: ${e.toString()}');
    }
  }

  Future<UserUploadModel> saveUserUpload({
    required String userId,
    required String mediaUrl,
    required String mediaType,
    required int fileSize,
    String? fileName,
    String? translation,
    double? confidence,
  }) async {
    try {
      final uploadData = {
        'user_id': userId,
        'video_url': mediaType == 'video' ? mediaUrl : null,
        'image_url': mediaType == 'image' ? mediaUrl : null,
        'media_type': mediaType,
        'translation': translation,
        'confidence': confidence,
        'uploaded_at': DateTime.now().toIso8601String(),
        'file_size': fileSize,
        'file_name': fileName,
      };

      final response = await _supabase
          .from('user_uploads')
          .insert(uploadData)
          .select()
          .single();

      // Cập nhật số lượng uploads và storage của user
      await _updateUserStorage(userId, fileSize, 1);

      return UserUploadModel.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi lưu upload: ${e.toString()}');
    }
  }

  Future<void> _updateUserStorage(String userId, int fileSize, int uploadCount) async {
    try {
      await _supabase.rpc('update_user_storage', params: {
        'user_id': userId,
        'file_size': fileSize,
        'upload_count': uploadCount,
      });
    } catch (e) {
      // Fallback: update manually nếu RPC không tồn tại
      try {
        final userData = await _supabase
            .from('users')
            .select('total_uploads, total_storage_used')
            .eq('id', userId)
            .single();

        await _supabase.from('users').update({
          'total_uploads': (userData['total_uploads'] ?? 0) + uploadCount,
          'total_storage_used': (userData['total_storage_used'] ?? 0) + fileSize,
        }).eq('id', userId);
      } catch (e2) {
        print('Lỗi cập nhật storage: $e2');
      }
    }
  }

  Stream<List<UserUploadModel>> getUserUploads(String userId) {
    return _supabase
        .from('user_uploads')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('uploaded_at', ascending: false)
        .map((data) => data
            .map((json) => UserUploadModel.fromJson(json))
            .toList());
  }

  Future<void> deleteUserUpload(String uploadId, String userId) async {
    try {
      // Lấy thông tin upload trước khi xóa
      final uploadData = await _supabase
          .from('user_uploads')
          .select()
          .eq('id', uploadId)
          .single();

      final fileSize = uploadData['file_size'] ?? 0;

      // Xóa file từ Storage
      final mediaUrl = uploadData['video_url'] ?? uploadData['image_url'];
      if (mediaUrl != null) {
        try {
          // Extract path from URL (format: /storage/v1/object/public/user_media/userId/type/file)
          final uri = Uri.parse(mediaUrl);
          final pathSegments = uri.pathSegments;
          // Tìm index của 'user_media' và lấy phần sau
          final mediaIndex = pathSegments.indexOf('user_media');
          if (mediaIndex != -1 && mediaIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(mediaIndex + 1).join('/');
            await _supabase.storage
                .from('user_media')
                .remove([filePath]);
          }
        } catch (e) {
          print('Lỗi xóa file storage: $e');
        }
      }

      // Xóa record từ database
      await _supabase
          .from('user_uploads')
          .delete()
          .eq('id', uploadId);

      // Cập nhật storage của user
      await _updateUserStorage(userId, -fileSize, -1);
    } catch (e) {
      throw Exception('Lỗi xóa upload: ${e.toString()}');
    }
  }

  // ============ USER PROGRESS ============
  Future<void> saveUserProgress(UserProgressModel progress) async {
    try {
      await _supabase.from('user_progress').upsert({
        'user_id': progress.userId,
        'lesson_id': progress.lessonId,
        'completed': progress.completed,
        'current_content_index': progress.currentContentIndex,
        'completed_at': progress.completedAt?.toIso8601String(),
        'quiz_result': progress.quizResult?.toJson(),
      });
    } catch (e) {
      throw Exception('Lỗi lưu progress: ${e.toString()}');
    }
  }

  Future<UserProgressModel?> getUserProgress(String userId, String lessonId) async {
    try {
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response != null) {
        return UserProgressModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy progress: ${e.toString()}');
    }
  }

  Stream<List<UserProgressModel>> getUserProgressList(String userId) {
    return _supabase
        .from('user_progress')
        .stream(primaryKey: ['user_id', 'lesson_id'])
        .eq('user_id', userId)
        .map((data) => data
            .map((json) => UserProgressModel.fromJson(json))
            .toList());
  }

  // ============ LIMITS ============
  static const int maxFileSizeImage = 5 * 1024 * 1024; // 5MB
  static const int maxFileSizeVideo = 20 * 1024 * 1024; // 20MB
  static const int maxUploadsPerUser = 50;
  static const int maxTotalStorage = 500 * 1024 * 1024; // 500MB
}

