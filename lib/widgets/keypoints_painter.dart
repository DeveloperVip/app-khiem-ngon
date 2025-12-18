import 'package:flutter/material.dart';

class KeypointsPainter extends CustomPainter {
  final List<double> keypoints;
  final Size sourceSize; // Kích thước gốc của ảnh (vd: 320x240)
  final bool isFrontCamera;

  KeypointsPainter({
    required this.keypoints,
    required this.sourceSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty || keypoints.length != 1662) return;

    // --- ĐỊNH NGHĨA MÀU SẮC THEO YÊU CẦU ---
    final paintBody = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintArm = Paint()
      ..color = Colors.redAccent // Khuỷu tay/cánh tay màu đỏ
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintHandPoint = Paint()
      ..color = Colors.greenAccent // Bàn tay màu xanh
      ..style = PaintingStyle.fill;
    
    final paintHandLine = Paint()
      ..color = Colors.green // Đường nối tay màu xanh
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintFace = Paint()
      ..color = Colors.yellowAccent // Gương mặt màu vàng
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    // Tính tỷ lệ scale
    final double scaleX = size.width;
    final double scaleY = size.height;

    // Helper: Map toạ độ (0-1) -> Screen
    Offset getPoint(double x, double y) {
      double finalX = isFrontCamera ? (1 - x) : x;
      return Offset(finalX * scaleX, y * scaleY);
    }

    // ==========================================================
    // 1. POSE (33 points) - Index 0->131
    // ==========================================================
    List<Offset> posePoints = List.filled(33, Offset.zero);
    for (int i = 0; i < 33; i++) {
      int idx = i * 4;
      double x = keypoints[idx];
      double y = keypoints[idx + 1];
      double vis = keypoints[idx + 3]; // Visibility

      if (x != 0 && y != 0 && vis > 0.5) {
        posePoints[i] = getPoint(x, y);
      }
    }

    // --- Vẽ Thân Người (Body) ---
    // Vai trái (11) - Vai phải (12)
    _drawLine(canvas, posePoints[11], posePoints[12], paintBody);
    // Vai - Hông (11-23, 12-24)
    _drawLine(canvas, posePoints[11], posePoints[23], paintBody);
    _drawLine(canvas, posePoints[12], posePoints[24], paintBody);
    // Hông trái - Hông phải (23-24)
    _drawLine(canvas, posePoints[23], posePoints[24], paintBody);

    // --- Vẽ Cánh Tay (Arms) - Màu Đỏ ---
    // Trái: Vai (11) -> Khuỷu (13) -> Cổ tay (15)
    _drawLine(canvas, posePoints[11], posePoints[13], paintArm);
    _drawLine(canvas, posePoints[13], posePoints[15], paintArm);
    
    // Phải: Vai (12) -> Khuỷu (14) -> Cổ tay (16)
    _drawLine(canvas, posePoints[12], posePoints[14], paintArm);
    _drawLine(canvas, posePoints[14], posePoints[16], paintArm);

    // Vẽ điểm khớp khuỷu tay to hơn
    if (posePoints[13] != Offset.zero) canvas.drawCircle(posePoints[13], 5.0, paintFace..color = Colors.red);
    if (posePoints[14] != Offset.zero) canvas.drawCircle(posePoints[14], 5.0, paintFace..color = Colors.red);


    // --- Vẽ Mặt (Face) - Màu Vàng ---
    // MediaPipe Pose landmarks cho mặt:
    // 0: Mũi, 1-3: Mắt trái/má, 4-6: Mắt phải/má, 9-10: Miệng
    // Vẽ các điểm chính đại diện cho khuôn mặt từ Pose (nhẹ hơn vẽ 468 điểm Face Mesh)
    List<int> faceIndices = [0, 1, 2, 3, 4, 5, 6, 9, 10];
    for (int idx in faceIndices) {
      if (posePoints[idx] != Offset.zero) {
        canvas.drawCircle(posePoints[idx], 4.0, paintFace); // Chấm vàng
      }
    }
    // Nối mắt đơn giản
    _drawLine(canvas, posePoints[2], posePoints[5], paintFace..strokeWidth=1.5); // Mắt trái - phải


    // ==========================================================
    // 2. HANDS (21 points each) - Màu Xanh
    // ==========================================================
    int leftHandStart = 1536;
    int rightHandStart = 1599;

    _drawHand(canvas, leftHandStart, paintHandPoint, paintHandLine, getPoint);
    _drawHand(canvas, rightHandStart, paintHandPoint, paintHandLine, getPoint);
  }

  void _drawHand(
    Canvas canvas, 
    int startIndex, 
    Paint paintPoint, 
    Paint paintLine,
    Offset Function(double, double) getPoint
  ) {
    List<Offset> handPoints = [];
    for (int i = 0; i < 21; i++) {
      int idx = startIndex + (i * 3);
      double x = keypoints[idx];
      double y = keypoints[idx + 1];
      
      if (x != 0 && y != 0) {
        handPoints.add(getPoint(x, y));
      } else {
        handPoints.add(Offset.zero);
      }
    }

    if (handPoints.isEmpty || handPoints.length < 21) return;

    // Vẽ khung xương tay (Lines)
    // Các ngón: Gốc -> Đốt 1 -> Đốt 2 -> Đầu ngón
    // Cổ tay (0) -> Các gốc ngón (1, 5, 9, 13, 17)
    final fingers = [
      [0, 1, 2, 3, 4],       // Thumb
      [0, 5, 6, 7, 8],       // Index
      [0, 9, 10, 11, 12],    // Middle
      [0, 13, 14, 15, 16],   // Ring
      [0, 17, 18, 19, 20],   // Pinky
    ];

    for (var finger in fingers) {
      for (int i = 0; i < finger.length - 1; i++) {
        _drawLine(canvas, handPoints[finger[i]], handPoints[finger[i+1]], paintLine);
      }
    }

    // Vẽ đầu các ngón tay to hơn chút
    for (int i = 0; i < 21; i++) {
      if (handPoints[i] != Offset.zero) {
        // Đầu ngón (4, 8, 12, 16, 20) vẽ to hơn, còn lại nhỏ
        double r = (i % 4 == 0 && i > 0) ? 4.0 : 2.5; 
        canvas.drawCircle(handPoints[i], r, paintPoint);
      }
    }
  }

  void _drawLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    if (p1 != Offset.zero && p2 != Offset.zero) {
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant KeypointsPainter oldDelegate) {
    // Chỉ repaint khi keypoints thực sự thay đổi
    // Để tối ưu, có thể so sánh hash hoặc check length/null
    if (oldDelegate.keypoints.length != keypoints.length) return true;
    
    // Check sơ bộ điểm đầu tiên để quyết định update (giảm chi phí so sánh full list)
    if (keypoints.isNotEmpty && oldDelegate.keypoints.isNotEmpty) {
      return oldDelegate.keypoints[0] != keypoints[0];
    }
    return true;
  }
}
