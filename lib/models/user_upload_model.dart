import '../models/translation_result.dart';

class UserUploadModel {
  final String id;
  final String userId;
  final String? videoUrl;
  final String? imageUrl;
  final MediaType mediaType;
  final String? translation;
  final double? confidence;
  final DateTime uploadedAt;
  final int fileSize; // in bytes
  final String? fileName;

  UserUploadModel({
    required this.id,
    required this.userId,
    this.videoUrl,
    this.imageUrl,
    required this.mediaType,
    this.translation,
    this.confidence,
    required this.uploadedAt,
    this.fileSize = 0,
    this.fileName,
  });

  Map<String, dynamic> toJson() {
    // Supabase sử dụng snake_case
    return {
      'id': id,
      'user_id': userId,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'media_type': mediaType.toString().split('.').last,
      'translation': translation,
      'confidence': confidence,
      'uploaded_at': uploadedAt.toIso8601String(),
      'file_size': fileSize,
      'file_name': fileName,
    };
  }

  factory UserUploadModel.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả camelCase và snake_case
    final mediaTypeStr = json['media_type'] ?? json['mediaType'] ?? 'image';
    MediaType mediaType;
    try {
      mediaType = MediaType.values.firstWhere(
        (e) => e.toString().split('.').last == mediaTypeStr.toLowerCase() ||
               e.toString() == mediaTypeStr,
        orElse: () => MediaType.image,
      );
    } catch (e) {
      mediaType = MediaType.image;
    }

    return UserUploadModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      videoUrl: json['video_url'] ?? json['videoUrl'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      mediaType: mediaType,
      translation: json['translation'],
      confidence: json['confidence']?.toDouble(),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : json['uploadedAt'] != null
              ? DateTime.parse(json['uploadedAt'])
              : DateTime.now(),
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      fileName: json['file_name'] ?? json['fileName'],
    );
  }
}

class UserProgressModel {
  final String userId;
  final String lessonId;
  final bool completed;
  final int currentContentIndex;
  final DateTime? completedAt;
  final QuizResult? quizResult;

  UserProgressModel({
    required this.userId,
    required this.lessonId,
    this.completed = false,
    this.currentContentIndex = 0,
    this.completedAt,
    this.quizResult,
  });

  Map<String, dynamic> toJson() {
    // Supabase sử dụng snake_case
    return {
      'user_id': userId,
      'lesson_id': lessonId,
      'completed': completed,
      'current_content_index': currentContentIndex,
      'completed_at': completedAt?.toIso8601String(),
      'quiz_result': quizResult?.toJson(),
    };
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả camelCase và snake_case
    return UserProgressModel(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? json['lessonId']?.toString() ?? '',
      completed: json['completed'] ?? false,
      currentContentIndex: json['current_content_index'] ?? json['currentContentIndex'] ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      quizResult: json['quiz_result'] != null
          ? QuizResult.fromJson(json['quiz_result'])
          : json['quizResult'] != null
              ? QuizResult.fromJson(json['quizResult'])
              : null,
    );
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final Map<String, int> answers; // questionId -> selectedAnswerIndex

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
      'answers': answers,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      answers: Map<String, int>.from(json['answers'] ?? {}),
    );
  }
}





