import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/lesson_model.dart';
import '../models/user_upload_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Kiểm tra lỗi network và trả về message thân thiện
  String _getNetworkErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('failed host lookup') || 
        errorStr.contains('no address associated with hostname') ||
        errorStr.contains('socketexception')) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra:\n'
          '• Thiết bị có internet (WiFi/4G/5G)\n'
          '• Supabase project đang hoạt động (không bị pause)\n'
          '• Thử restart app hoặc đổi mạng';
    }
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Kết nối quá chậm hoặc timeout. Vui lòng thử lại sau.';
    }
    
    if (errorStr.contains('authretryablefetchexception')) {
      return 'Lỗi xác thực. Vui lòng đăng nhập lại.';
    }
    
    return 'Lỗi kết nối: ${error.toString()}';
  }

  // ============ LESSONS ============
  Stream<List<LessonModel>> getLessons() {
    try {
      return _supabase
          .from('lessons')
          .stream(primaryKey: ['id'])
          .order('order', ascending: true) // Sắp xếp từ nhỏ đến lớn (1, 2, 3...)
          .asyncMap((lessons) async {
            try {
              print('📚 Loading ${lessons.length} lessons...');
              // Load contents và quiz cho mỗi lesson từ các bảng riêng
              final List<LessonModel> result = [];
              for (var lesson in lessons) {
                try {
                  final fullLesson = await getLesson(lesson['id']);
                  if (fullLesson != null) {
                    result.add(fullLesson);
                    print('✅ Loaded lesson: ${fullLesson.title} (${fullLesson.contents.length} contents)');
                  }
                } catch (e) {
                  print('❌ Error loading lesson ${lesson['id']}: $e');
                  // Tiếp tục với lesson khác thay vì dừng lại
                }
              }
              print('✅ Total loaded: ${result.length} lessons');
              return result;
            } catch (e) {
              print('❌ Error in asyncMap: $e');
              rethrow;
            }
          }).handleError((error) {
            print('❌ Stream error in getLessons: $error');
            final friendlyMessage = _getNetworkErrorMessage(error);
            print('💡 $friendlyMessage');
            // Trả về empty list thay vì throw để app không crash
            return <LessonModel>[];
          });
    } catch (e) {
      print('❌ Error creating stream: $e');
      // Return empty stream với error
      return Stream.value(<LessonModel>[]);
    }
  }

  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      print('📖 Loading lesson: $lessonId');
      
      // 1. Lấy lesson
      final lesson = await _supabase
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .single();
      print('✅ Loaded lesson data: ${lesson['title']}');

      // 2. Lấy contents từ bảng lesson_contents
      final contentsData = await _supabase
          .from('lesson_contents')
          .select()
          .eq('lesson_id', lessonId)
          .order('order');
      print('✅ Loaded ${contentsData.length} contents');

      // 3. Lấy quiz và questions từ các bảng riêng
      QuizModel? quiz;
      final quizData = await _supabase
          .from('quizzes')
          .select()
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (quizData != null) {
        print('✅ Found quiz: ${quizData['id']}');
        final questionsData = await _supabase
            .from('quiz_questions')
            .select()
            .eq('quiz_id', quizData['id'])
            .order('order');
        print('✅ Loaded ${questionsData.length} questions');

        // Load options cho mỗi question
        final List<Map<String, dynamic>> questions = [];
        for (var question in questionsData) {
          final optionsData = await _supabase
              .from('quiz_options')
              .select()
              .eq('question_id', question['id'])
              .order('order');

          final options = optionsData.map((opt) => opt['option_text'] as String).toList();

          questions.add({
            'id': question['id'],
            'question': question['question'],
            'videoUrl': question['video_url'],
            'options': options,
            'correctAnswerIndex': question['correct_answer_index'],
            'explanation': question['explanation'],
          });
        }

        quiz = QuizModel(
          id: quizData['id'],
          lessonId: lessonId,
          questions: questions.map((q) => QuizQuestion.fromJson(q)).toList(),
        );
      } else {
        print('ℹ️ No quiz found for this lesson');
      }

      // 4. Build LessonModel từ dữ liệu normalized
      final lessonModel = LessonModel(
        id: lesson['id'],
        title: lesson['title'],
        description: lesson['description'],
        order: lesson['order'],
        thumbnailUrl: lesson['thumbnail_url'],
        estimatedDuration: lesson['estimated_duration'] ?? 0,
        contents: (contentsData as List)
            .map((c) => LessonContent(
                  id: c['id'],
                  type: c['content_type'] == 'video' ? ContentType.video : ContentType.image,
                  videoUrl: c['video_url'],
                  imageUrl: c['image_url'],
                  translation: c['translation'],
                  description: c['description'],
                  order: c['order'],
                ))
            .toList(),
        quiz: quiz,
      );
      
      print('✅ Built LessonModel: ${lessonModel.title} with ${lessonModel.contents.length} contents');
      return lessonModel;
    } catch (e, stackTrace) {
      print('❌ Error loading lesson $lessonId: $e');
      print('Stack trace: $stackTrace');
      final friendlyMessage = _getNetworkErrorMessage(e);
      throw Exception(friendlyMessage);
    }
  }

  // ============ USER UPLOADS ============
  Future<String> uploadMedia({
    required File file,
    required String userId,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      // Dùng p.basename để lấy tên file chính xác trên mọi OS (Fix lỗi đường dẫn Windows)
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final fileBytes = await file.readAsBytes();
      final filePath = '$userId/$mediaType/$fileName';

      // Upload file với options (quan trọng để tránh lỗi cache và server xử lý đúng)
      await _supabase.storage
          .from('user_media')
          .uploadBinary(
            filePath, 
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Lấy Signed URL (có token) thay vì Public URL để fix lỗi 400 Access Denied
      // Thời hạn: 10 năm (315360000 giây) - coi như vĩnh viễn cho demo
      final response = await _supabase.storage
          .from('user_media')
          .createSignedUrl(filePath, 315360000);

      print('✅ Signed URL tạo thành công: $response');
      return response;
    } catch (e) {
      print('❌ Lỗi upload media: $e');
      throw Exception('Lỗi upload media: $e');
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

