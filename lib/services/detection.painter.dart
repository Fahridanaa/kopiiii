import 'package:flutter/material.dart';

class DetectionPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size previewSize;
  final Size screenSize;

  DetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      try {
        final bbox = detection['bbox'] as List<dynamic>;
        final label = detection['class'] as String;
        final confidence = detection['confidence'] as double;

        // Convert normalized coordinates (0-1) to screen coordinates
        final rect = Rect.fromLTRB(
          bbox[0] * size.width,
          bbox[1] * size.height,
          bbox[2] * size.width,
          bbox[3] * size.height,
        );

        // Choose color based on class
        final Color color = _getColorForClass(label);

        // Draw bounding box
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = color;

        canvas.drawRect(rect, paint);

        // Draw background for text
        final textBgPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black54;

        const textPadding = 4.0;
        final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';
        final textStyle = TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(
          text: text,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Draw text background
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.top - textPainter.height - textPadding * 2,
            textPainter.width + textPadding * 2,
            textPainter.height + textPadding * 2,
          ),
          textBgPaint,
        );

        // Draw text
        textPainter.paint(
          canvas,
          Offset(rect.left + textPadding,
              rect.top - textPainter.height - textPadding),
        );
      } catch (e) {
        print('Error drawing detection: $e');
      }
    }
  }

  Color _getColorForClass(String label) {
    switch (label.toLowerCase()) {
      case 'ripe':
        return Colors.green;
      case 'unripe':
        return Colors.red;
      case 'semi_ripe':
        return Colors.yellow;
      case 'overripe':
        return Colors.brown;
      case 'dry':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) => true;
}
