import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_model.dart';
import '../models/user_upload_model.dart';

/// Service mới để query từ database normalized
class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============ LESSONS ============
  
  /// Lấy tất cả lessons với contents và quiz
  Stream<List<LessonModel>> getLessons() {
    return _supabase
        .from('lessons')
        .stream(primaryKey: ['id'])
        .order('order')
        .asyncMap((lessons) async {
          // Load contents và quiz cho mỗi lesson
          final List<LessonModel> result = [];
          for (var lesson in lessons) {
            final fullLesson = await getLesson(lesson['id']);
            if (fullLesson != null) {
              result.add(fullLesson);
            }
          }
          return result;
        });
  }

  /// Lấy một lesson với đầy đủ contents và quiz
  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      // 1. Lấy lesson
      final lesson = await _supabase
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .single();

      // 2. Lấy contents
      final contentsData = await _supabase
          .from('lesson_contents')
          .select()
          .eq('lesson_id', lessonId)
          .order('order');

      // 3. Lấy quiz và questions
      QuizModel? quiz;
      final quizData = await _supabase
          .from('quizzes')
          .select()
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (quizData != null) {
        final questionsData = await _supabase
            .from('quiz_questions')
            .select()
            .eq('quiz_id', quizData['id'])
            .order('order');

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
      }

      // 4. Build LessonModel
      return LessonModel(
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
        .map((data) => data.map((json) => UserUploadModel.fromJson(json)).toList());
  }

  Future<void> deleteUserUpload(String uploadId) async {
    try {
      await _supabase.from('user_uploads').delete().eq('id', uploadId);
    } catch (e) {
      throw Exception('Lỗi xóa upload: ${e.toString()}');
    }
  }

  // ============ USER PROGRESS ============
  Future<UserProgressModel?> getUserProgress(String userId, String lessonId) async {
    try {
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (response == null) return null;

      return UserProgressModel.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi lấy progress: ${e.toString()}');
    }
  }

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
}






