import 'package:flutter/material.dart';

/// Generates Path objects for different bottle geometries.
class BottlePathFactory {
  static Path buildPath(String bottleId, Size size) {
    // Selecting the geometry strategy based on bottle ID
    switch (bottleId) {
      case 'half_gallon':
        return _buildHandlePath(size);
      case 'mini':
      case 'quarter_pint':
      case 'half_pint':
      case 'pint':
        return _buildFlaskPath(size);
      case 'fifth':
      case 'liter':
      case 'magnum':
      case 'double_magnum': // Large standard shape
      case 'rehoboam': // very large standard shape
      default:
        return _buildStandardPath(size);
    }
  }

  /// Constructs a standard "Bordeaux" style high-shoulder bottle.
  /// Used for Fifth, Liter, Magnum.
  static Path _buildStandardPath(Size size) {
    final Path path = Path();
    final w = size.width;
    final h = size.height;

    // Proportions
    final double neckWidth = w * 0.32;
    final double neckHeight = h * 0.28;
    final double shoulderHeight = h * 0.08;
    final double baseCornerRadius = w * 0.05;

    final double centerX = w / 2;
    final double bodySideLeft = 0.0;
    final double bodySideRight = w;
    final double bodyTop = neckHeight + shoulderHeight;

    // 1. Top Finish (Cap area)
    path.moveTo(centerX - (neckWidth / 2) - 2, 0);
    path.lineTo(centerX + (neckWidth / 2) + 2, 0);
    path.lineTo(centerX + (neckWidth / 2), 10); // Slight taper for cap

    // 2. Neck
    path.lineTo(centerX + (neckWidth / 2), neckHeight);

    // 3. Right Shoulder (Cubic Bezier for organic curve)
    path.cubicTo(
      centerX + (neckWidth / 2) + 5,
      neckHeight + (shoulderHeight * 0.5), // Control 1
      bodySideRight - (w * 0.1),
      neckHeight + (shoulderHeight * 0.2), // Control 2
      bodySideRight,
      bodyTop, // Destination
    );

    // 4. Right Body Wall
    path.lineTo(bodySideRight, h - baseCornerRadius);

    // 5. Base (Rounded)
    path.quadraticBezierTo(
      bodySideRight,
      h,
      bodySideRight - baseCornerRadius,
      h,
    );
    path.lineTo(bodySideLeft + baseCornerRadius, h);
    path.quadraticBezierTo(bodySideLeft, h, bodySideLeft, h - baseCornerRadius);

    // 6. Left Body Wall
    path.lineTo(bodySideLeft, bodyTop);

    // 7. Left Shoulder
    path.cubicTo(
      bodySideLeft + (w * 0.1),
      neckHeight + (shoulderHeight * 0.2),
      centerX - (neckWidth / 2) - 5,
      neckHeight + (shoulderHeight * 0.5),
      centerX - (neckWidth / 2),
      neckHeight,
    );

    // Close loop back to cap
    path.lineTo(centerX - (neckWidth / 2), 10);
    path.close();

    return path;
  }

  /// Constructs a "Handle" (1.75L) shape.
  /// Note: Simplified to a wide container for this demo;
  /// true handle geometry involves "Path.combine" which is computationally heavier.
  static Path _buildHandlePath(Size size) {
    final Path path = Path();
    final w = size.width;
    final h = size.height;

    final double neckW = w * 0.22;
    final double neckH = h * 0.18;
    final double handleGapTop = h * 0.25;
    final double handleGapBottom = h * 0.55;

    // Outline
    path.moveTo(w / 2 - neckW / 2, 0);
    path.lineTo(w / 2 + neckW / 2, 0);
    path.lineTo(w / 2 + neckW / 2, neckH);

    path.quadraticBezierTo(w, neckH, w, neckH + 50);
    path.lineTo(w, h - 20);
    path.quadraticBezierTo(w, h, w - 20, h);
    path.lineTo(20, h);
    path.quadraticBezierTo(0, h, 0, h - 20);
    path.lineTo(0, neckH + 50);
    path.quadraticBezierTo(0, neckH, w / 2 - neckW / 2, neckH);
    path.close();

    // Adding the Handle Hole (punch out)
    if (w > 100) {
      final Path hole = Path();
      hole.moveTo(w * 0.75, handleGapTop);
      hole.lineTo(w * 0.75, handleGapBottom);
      hole.quadraticBezierTo(
        w * 0.75,
        handleGapBottom + 10,
        w * 0.85,
        handleGapBottom,
      );
      hole.lineTo(w * 0.90, handleGapBottom - 10);
      hole.lineTo(w * 0.90, handleGapTop + 10);
      hole.quadraticBezierTo(w * 0.90, handleGapTop, w * 0.85, handleGapTop);
      hole.close();

      path.addPath(hole, Offset.zero);
      path.fillType = PathFillType.evenOdd;
    }

    return path;
  }

  /// Constructs a Flask/Nip shape (Miniature).
  static Path _buildFlaskPath(Size size) {
    // Similar to handle but narrower shoulders
    final Path path = Path();
    final w = size.width;
    final h = size.height;
    final neckW = w * 0.3;
    final neckH = h * 0.2;

    path.moveTo(w / 2 - neckW / 2, 0);
    path.lineTo(w / 2 + neckW / 2, 0);
    path.lineTo(w / 2 + neckW / 2, neckH);
    path.lineTo(w, neckH + 20); // Sharp angular shoulder common in minis
    path.lineTo(w, h - 10);
    path.quadraticBezierTo(w, h, w - 10, h);
    path.lineTo(10, h);
    path.quadraticBezierTo(0, h, 0, h - 10);
    path.lineTo(0, neckH + 20);
    path.lineTo(w / 2 - neckW / 2, neckH);
    path.close();
    return path;
  }
}
