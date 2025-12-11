import 'dart:collection';

/// Quản lý buffer chứa sequence keypoints (30 frames)
/// Tương tự như deque trong Python realtime_demo.py
class SequenceBuffer {
  final int sequenceLength;
  final Queue<List<double>> _buffer = Queue<List<double>>();

  SequenceBuffer({this.sequenceLength = 30});

  /// Thêm keypoints mới vào buffer
  /// Tự động loại bỏ frame cũ nếu đã đủ sequenceLength
  void addKeypoints(List<double> keypoints) {
    if (_buffer.length >= sequenceLength) {
      _buffer.removeFirst();
    }
    _buffer.addLast(keypoints);
  }

  /// Kiểm tra xem đã đủ frames để dự đoán chưa
  bool isReady() {
    return _buffer.length == sequenceLength;
  }

  /// Lấy sequence hiện tại dạng List[List&lt;double&gt;&gt;
  /// Shape: (sequenceLength, numKeypoints)
  List<List<double>> getSequence() {
    if (!isReady()) {
      throw Exception('Sequence chưa đủ $sequenceLength frames. Hiện tại: ${_buffer.length}');
    }
    return _buffer.toList();
  }

  /// Lấy sequence dạng flattened array (1D)
  /// Shape: (sequenceLength * numKeypoints)
  List<double> getFlattenedSequence() {
    final sequence = getSequence();
    return sequence.expand((keypoints) => keypoints).toList();
  }

  /// Reset buffer
  void clear() {
    _buffer.clear();
  }

  /// Số frames hiện tại trong buffer
  int get currentLength => _buffer.length;

  /// Kiểm tra buffer có rỗng không
  bool get isEmpty => _buffer.isEmpty;
}

