import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../models/user_upload_model.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  Map<String, int> _answers = {};
  bool _isSubmitted = false;

  QuizResult? _result;

  void _selectAnswer(int answerIndex) {
    if (!_isSubmitted) {
      setState(() {
        _answers[widget.quiz.questions[_currentQuestionIndex].id] =
            answerIndex;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    int score = 0;
    for (var question in widget.quiz.questions) {
      final selectedAnswer = _answers[question.id];
      if (selectedAnswer == question.correctAnswerIndex) {
        score++;
      }
    }

    setState(() {
      _isSubmitted = true;
      _result = QuizResult(
        score: score,
        totalQuestions: widget.quiz.questions.length,
        completedAt: DateTime.now(),
        answers: _answers,
      );
    });

    // Lưu kết quả vào Firebase
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final supabaseService = SupabaseService();
      final progress = UserProgressModel(
        userId: authProvider.user!.uid,
        lessonId: widget.lessonId,
        completed: true,
        currentContentIndex: 0,
        completedAt: DateTime.now(),
        quizResult: _result,
      );
      await supabaseService.saveUserProgress(progress);
    }
  }

  Color _getAnswerColor(int index) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[question.id];

    if (!_isSubmitted) {
      return selectedAnswer == index
          ? Theme.of(context).colorScheme.primary
          : Colors.grey[300]!;
    }

    if (index == question.correctAnswerIndex) {
      return Colors.green;
    }
    if (selectedAnswer == index && index != question.correctAnswerIndex) {
      return Colors.red;
    }
    return Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[question.id];
    final isFirst = _currentQuestionIndex == 0;
    final isLast = _currentQuestionIndex == widget.quiz.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài kiểm tra'),
      ),
      body: Column(
        children: [
          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) /
                        widget.quiz.questions.length,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu hỏi ${_currentQuestionIndex + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.question,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getAnswerColor(index),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedAnswer == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedAnswer == index
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: selectedAnswer == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: selectedAnswer == index
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isSubmitted &&
                                            (index ==
                                                question.correctAnswerIndex ||
                                                (selectedAnswer == index &&
                                                    index !=
                                                        question
                                                            .correctAnswerIndex))
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: selectedAnswer == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_isSubmitted && question.explanation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question.explanation!,
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _isSubmitted && isLast
                ? Column(
                    children: [
                      if (_result != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _result!.score >= _result!.totalQuestions / 2
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Kết quả: ${_result!.score}/${_result!.totalQuestions}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _result!.score >= _result!.totalQuestions / 2
                                    ? 'Chúc mừng! Bạn đã vượt qua bài kiểm tra!'
                                    : 'Bạn cần cải thiện thêm. Hãy học lại bài học!',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hoàn thành'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (!isFirst)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previousQuestion,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Trước'),
                          ),
                        ),
                      if (!isFirst) const SizedBox(width: 16),
                      Expanded(
                        flex: isFirst ? 1 : 2,
                        child: ElevatedButton.icon(
                          onPressed: isLast && !_isSubmitted
                              ? _submitQuiz
                              : isLast
                                  ? null
                                  : _nextQuestion,
                          icon: Icon(
                            isLast && !_isSubmitted
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            isLast && !_isSubmitted
                                ? 'Nộp bài'
                                : isLast
                                    ? 'Đã nộp'
                                    : 'Tiếp theo',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}





