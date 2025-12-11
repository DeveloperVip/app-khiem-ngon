import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../models/user_upload_model.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import 'quiz_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int _currentContentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _initializeVideo();
  }

  Future<void> _loadProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final supabaseService = SupabaseService();
      final progress = await supabaseService.getUserProgress(
        authProvider.user!.uid,
        widget.lesson.id,
      );
      if (progress != null && mounted) {
        setState(() {
          _currentContentIndex = progress.currentContentIndex;
        });
      }
    }
  }

  void _initializeVideo() {
    final currentContent = widget.lesson.contents[_currentContentIndex];
    if (currentContent.type == ContentType.video && currentContent.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(currentContent.videoUrl!),
      );
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Pause và dispose video controller đúng cách
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  void _nextContent() {
    if (_currentContentIndex < widget.lesson.contents.length - 1) {
      // Dispose video controller trước khi chuyển content
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      
      setState(() {
        _currentContentIndex++;
        _isVideoInitialized = false;
      });
      _initializeVideo();
      _saveProgress();
    } else {
      _showCompleteDialog();
    }
  }

  void _previousContent() {
    if (_currentContentIndex > 0) {
      // Dispose video controller trước khi chuyển content
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      
      setState(() {
        _currentContentIndex--;
        _isVideoInitialized = false;
      });
      _initializeVideo();
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final supabaseService = SupabaseService();
      final progress = UserProgressModel(
        userId: authProvider.user!.uid,
        lessonId: widget.lesson.id,
        currentContentIndex: _currentContentIndex,
        completed: _currentContentIndex >= widget.lesson.contents.length - 1,
      );
      await supabaseService.saveUserProgress(progress);
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành bài học!'),
        content: Text(
          widget.lesson.quiz != null
              ? 'Bạn đã hoàn thành bài học. Bạn có muốn làm bài kiểm tra không?'
              : 'Chúc mừng bạn đã hoàn thành bài học này!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (widget.lesson.quiz != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      quiz: widget.lesson.quiz!,
                      lessonId: widget.lesson.id,
                    ),
                  ),
                );
              },
              child: const Text('Làm kiểm tra'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentContent = widget.lesson.contents[_currentContentIndex];
    final isFirst = _currentContentIndex == 0;
    final isLast = _currentContentIndex == widget.lesson.contents.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          if (widget.lesson.quiz != null)
            IconButton(
              icon: const Icon(Icons.quiz),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      quiz: widget.lesson.quiz!,
                      lessonId: widget.lesson.id,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentContentIndex + 1) / widget.lesson.contents.length,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentContentIndex + 1}/${widget.lesson.contents.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Content display
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Media display
                  if (currentContent.type == ContentType.video &&
                      currentContent.videoUrl != null)
                    Container(
                      height: 300,
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
                    )
                  else if (currentContent.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: currentContent.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Translation
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bản dịch:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentContent.translation,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (currentContent.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              currentContent.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation buttons
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
                      onPressed: _previousContent,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Trước'),
                    ),
                  ),
                if (!isFirst) const SizedBox(width: 16),
                Expanded(
                  flex: isFirst ? 1 : 2,
                  child: ElevatedButton.icon(
                    onPressed: _nextContent,
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

