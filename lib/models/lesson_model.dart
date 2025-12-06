class LessonModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<LessonContent> contents;
  final QuizModel? quiz;
  final String? thumbnailUrl;
  final int estimatedDuration; // in minutes

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.contents,
    this.quiz,
    this.thumbnailUrl,
    this.estimatedDuration = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'contents': contents.map((c) => c.toJson()).toList(),
      'quiz': quiz?.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'estimatedDuration': estimatedDuration,
    };
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      contents: (json['contents'] as List<dynamic>?)
              ?.map((c) => LessonContent.fromJson(c))
              .toList() ??
          [],
      quiz: json['quiz'] != null ? QuizModel.fromJson(json['quiz']) : null,
      thumbnailUrl: json['thumbnailUrl'],
      estimatedDuration: json['estimatedDuration'] ?? 0,
    );
  }
}

class LessonContent {
  final String id;
  final ContentType type;
  final String? videoUrl;
  final String? imageUrl;
  final String translation;
  final String? description;
  final int order;

  LessonContent({
    required this.id,
    required this.type,
    this.videoUrl,
    this.imageUrl,
    required this.translation,
    this.description,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'translation': translation,
      'description': description,
      'order': order,
    };
  }

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ContentType.image,
      ),
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      translation: json['translation'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
    );
  }
}

enum ContentType {
  image,
  video,
}

class QuizModel {
  final String id;
  final String lessonId;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.id,
    required this.lessonId,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? '',
      lessonId: json['lessonId'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'],
    );
  }
}





