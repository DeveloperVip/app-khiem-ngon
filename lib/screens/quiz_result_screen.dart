import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/lesson_model.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizModel quiz;
  final Map<String, int> userAnswers;
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.score,
    required this.totalQuestions,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  int _currentQuestionIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  void _initializeVideo() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    if (question.videoUrl != null && question.videoUrl!.isNotEmpty) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(question.videoUrl!),
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
    } else {
      _isVideoInitialized = false;
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      
      setState(() {
        _currentQuestionIndex++;
        _isVideoInitialized = false;
      });
      _initializeVideo();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      
      setState(() {
        _currentQuestionIndex--;
        _isVideoInitialized = false;
      });
      _initializeVideo();
    }
  }

  Color _getAnswerColor(int index) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = widget.userAnswers[question.id];

    // Đáp án đúng luôn màu xanh
    if (index == question.correctAnswerIndex) {
      return Colors.green;
    }
    // Đáp án sai của user màu đỏ
    if (userAnswer == index && index != question.correctAnswerIndex) {
      return Colors.red;
    }
    // Các đáp án khác màu xám
    return Colors.grey[300]!;
  }

  IconData _getAnswerIcon(int index) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = widget.userAnswers[question.id];

    if (index == question.correctAnswerIndex) {
      return Icons.check_circle;
    }
    if (userAnswer == index && index != question.correctAnswerIndex) {
      return Icons.cancel;
    }
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = widget.userAnswers[question.id];
    final isCorrect = userAnswer == question.correctAnswerIndex;
    final isFirst = _currentQuestionIndex == 0;
    final isLast = _currentQuestionIndex == widget.quiz.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả chi tiết'),
        actions: [
          // Hiển thị tổng điểm
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${widget.score}/${widget.totalQuestions}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCorrect ? 'Đúng' : 'Sai',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video display
                  if (question.videoUrl != null && question.videoUrl!.isNotEmpty)
                    Container(
                      height: 250,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isVideoInitialized && _videoController != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 48,
                                      color: Colors.white,
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
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  // Question card
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
                  // Options with results
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isUserAnswer = userAnswer == index;
                    final isCorrectAnswer = index == question.correctAnswerIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getAnswerColor(index),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCorrectAnswer
                                ? Colors.green
                                : isUserAnswer
                                    ? Colors.red
                                    : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getAnswerIcon(index),
                              color: isCorrectAnswer
                                  ? Colors.white
                                  : isUserAnswer
                                      ? Colors.white
                                      : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: (isCorrectAnswer || isUserAnswer)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: (isCorrectAnswer || isUserAnswer)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isUserAnswer && !isCorrectAnswer)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Bạn chọn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isCorrectAnswer)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Đáp án đúng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Explanation
                  if (question.explanation != null) ...[
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
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giải thích',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.explanation!,
                                  style: TextStyle(color: Colors.blue[900]),
                                ),
                              ],
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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
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
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLast ? () => Navigator.pop(context) : _nextQuestion,
                    icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                    label: Text(isLast ? 'Hoàn thành' : 'Tiếp theo'),
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
