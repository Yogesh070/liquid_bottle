import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'bottle_type.dart';
import 'liquid_bottle_slider.dart';

enum BrandedBottleType { bacardi, bombaySapphire, joseCuervo }

class BrandedBottle extends StatefulWidget {
  final BrandedBottleType type;
  final double fillLevel;
  final ValueChanged<double>? onFillChanged;
  final double labelScale;
  final Offset labelOffset;

  const BrandedBottle({
    super.key,
    required this.type,
    this.fillLevel = 0.5,
    this.onFillChanged,
    this.labelScale = 1.0,
    this.labelOffset = Offset.zero,
  });

  @override
  State<BrandedBottle> createState() => _BrandedBottleState();
}

class _BrandedBottleState extends State<BrandedBottle> {
  ui.Image? _labelImage;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void didUpdateWidget(covariant BrandedBottle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _labelImage = null; // Reset on type change
      _loadAssets();
    }
  }

  Future<void> _loadAssets() async {
    if (widget.type == BrandedBottleType.bacardi && _labelImage == null) {
      _loadImage(
        'assets/logo/bacardi_logo.png',
        (img) => _labelImage = img,
        package: 'liquid_bottle',
      );
    } else if (widget.type == BrandedBottleType.bombaySapphire &&
        _labelImage == null) {
      _loadImage(
        'assets/logo/sapphire_logo.png',
        (img) => _labelImage = img,
        package: 'liquid_bottle',
      );
    }
  }

  Future<void> _loadImage(
    String path,
    Function(ui.Image) onLoaded, {
    String? package,
  }) async {
    try {
      final Completer<ui.Image> completer = Completer();
      final ImageStream stream = AssetImage(
        path,
        package: package,
      ).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      });
      stream.addListener(listener);
      final image = await completer.future;
      if (mounted) {
        setState(() {
          onLoaded(image);
        });
      }
    } catch (e) {
      debugPrint("Error loading image $path: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight == double.infinity
            ? 600.0
            : constraints.maxHeight;
        final double bottleHeight = math.min(maxHeight, 600.0);

        double bottleWidth;
        Color liquidColor;
        CustomPainter Function(double, double, Color) painterFactory;

        switch (widget.type) {
          case BrandedBottleType.bacardi:
            bottleWidth = bottleHeight * 0.38;
            liquidColor = const Color(0xFFD6EAF8).withValues(alpha: 0.4);
            painterFactory = (visualLevel, rawLevel, color) =>
                BacardiBottlePainter(
                  fillLevel: visualLevel,
                  liquidColor: color,
                  labelImage: _labelImage,
                  labelScale: widget.labelScale,
                  labelOffset: widget.labelOffset,
                );
            break;
          case BrandedBottleType.bombaySapphire:
            bottleWidth = bottleHeight * 0.35;
            liquidColor = Colors.white;
            painterFactory = (visualLevel, rawLevel, color) =>
                BombaySapphirePainter(
                  fillLevel: visualLevel,
                  labelImage: _labelImage,
                  labelScale: widget.labelScale,
                  labelOffset: widget.labelOffset,
                );
            break;
          case BrandedBottleType.joseCuervo:
            bottleWidth = bottleHeight * 0.35;
            liquidColor = const Color(0xFFFFC107).withValues(alpha: 0.85);
            painterFactory = (visualLevel, rawLevel, color) =>
                JoseCuervoPainter(fillLevel: visualLevel, liquidColor: color);
            break;
        }

        return Center(
          child: SizedBox(
            width: bottleWidth,
            height: bottleHeight,
            child: LiquidBottleSlider(
              value: widget.fillLevel,
              onChanged: widget.onFillChanged ?? (val) {},
              bottleType: BottleType.standards.first, // Placeholder
              liquidColor: liquidColor,
              customPainterBuilder:
                  (context, visualFill, rawFill, liquidColor) {
                    return painterFactory(visualFill, rawFill, liquidColor);
                  },
            ),
          ),
        );
      },
    );
  }
}

class BacardiBottlePainter extends CustomPainter {
  final double fillLevel;
  final Color liquidColor;
  final ui.Image? labelImage;
  final double labelScale;
  final Offset labelOffset;

  BacardiBottlePainter({
    required this.fillLevel,
    required this.liquidColor,
    this.labelImage,
    this.labelScale = 1.0,
    this.labelOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- 1. Path Definition (Bacardi Shape) ---
    final path = Path();
    final double centerX = w / 2;

    // Dimensions
    final double neckWidth = w * 0.28;
    final double neckHeight = h * 0.28;
    final double shoulderStart = neckHeight;
    final double shoulderEnd = h * 0.38;
    final double bodyWidth = w;
    final double baseHeight = h * 0.05;

    // Cap/Top
    path.moveTo(centerX - neckWidth / 2, 0);
    path.lineTo(centerX + neckWidth / 2, 0);

    // Neck
    path.lineTo(
      centerX + neckWidth / 2 + 2,
      neckHeight,
    ); // Slight taper outwards? No, usually inwards or straight.
    // Actually standard bottles flare slightly at the shoulder ring.

    // Shoulder Curve
    path.cubicTo(
      centerX + neckWidth / 2 + 5,
      shoulderStart + (shoulderEnd - shoulderStart) * 0.5,
      bodyWidth - (w * 0.1),
      shoulderStart + (shoulderEnd - shoulderStart) * 0.1,
      bodyWidth,
      shoulderEnd,
    );

    // Right Side (Taper slightly to bottom)
    path.lineTo(bodyWidth - (w * 0.05), h - baseHeight);

    // Base Corner
    path.quadraticBezierTo(
      bodyWidth - (w * 0.05),
      h,
      bodyWidth - (w * 0.15),
      h,
    );

    // Bottom
    path.lineTo(w * 0.15, h);

    // Left Base Corner
    path.quadraticBezierTo(w * 0.05, h, w * 0.05, h - baseHeight);

    // Left Side
    path.lineTo(0, shoulderEnd);

    // Left Shoulder
    path.cubicTo(
      w * 0.1,
      shoulderStart + (shoulderEnd - shoulderStart) * 0.1,
      centerX - neckWidth / 2 - 5,
      shoulderStart + (shoulderEnd - shoulderStart) * 0.5,
      centerX - neckWidth / 2 - 2,
      shoulderStart,
    );

    // Neck back to top
    path.lineTo(centerX - neckWidth / 2, 0);
    path.close();

    // --- 2. Glass / Liquid Rendering ---

    // Glass Tint (Light Greenish/Blueish like the image)
    final glassColor = const Color(
      0xFFE0F7FA,
    ).withValues(alpha: 0.3); // Very subtle
    final Paint glassPaint = Paint()
      ..color = glassColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, glassPaint);

    // Liquid
    canvas.save();
    canvas.clipPath(path);

    final double liquidH = h * fillLevel;
    final double surfaceY = h - liquidH;

    final Paint liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    // Draw Liquid Rect
    canvas.drawRect(Rect.fromLTRB(0, surfaceY, w, h + 100), liquidPaint);

    // Liquid Surface (Ellipse)
    if (fillLevel > 0 && fillLevel < 1.0) {
      final surfacePaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, surfaceY),
          width: w * 0.9,
          height: 10,
        ),
        surfacePaint,
      );
    }

    canvas.restore();

    // Glass Border
    final Paint borderPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // --- 3. Labels & Details ---

    _drawCap(canvas, centerX, neckWidth, neckHeight, w);
    _drawNeckLabel(canvas, centerX, neckWidth, neckHeight);
    _drawMainLabel(canvas, centerX, shoulderEnd, w, h);
    _drawBottomLabel(canvas, centerX, w, h);
  }

  void _drawCap(
    Canvas canvas,
    double centerX,
    double neckW,
    double neckH,
    double w,
  ) {
    final double capH = neckH * 0.4;
    final Rect capRect = Rect.fromLTWH(
      centerX - neckW / 2 - 1,
      0,
      neckW + 2,
      capH,
    );

    final Paint capPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey[300]!, Colors.white, Colors.grey[400]!],
      ).createShader(capRect);

    canvas.drawRect(capRect, capPaint);

    // Horizontal lines on cap
    final Paint linePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      double y = capH * (i / 4);
      canvas.drawLine(
        Offset(capRect.left, y),
        Offset(capRect.right, y),
        linePaint,
      );
    }
  }

  void _drawNeckLabel(
    Canvas canvas,
    double centerX,
    double neckW,
    double neckH,
  ) {
    // The black band with "WHITE RUM"
    // Located roughly below the cap logic, midway down neck
    final double labelTop = neckH * 0.55;
    final double labelH = neckH * 0.15;
    final Rect labelRect = Rect.fromLTWH(
      centerX - neckW / 2,
      labelTop,
      neckW,
      labelH,
    );

    // Draw Black Background
    canvas.drawRect(labelRect, Paint()..color = const Color(0xFF1A1A1A));

    // Golden borders
    final Paint goldPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(labelRect.topLeft, labelRect.topRight, goldPaint);
    canvas.drawLine(labelRect.bottomLeft, labelRect.bottomRight, goldPaint);

    // "WHITE RUM" text
    _drawText(
      canvas,
      "WHITE RUM",
      offset: labelRect.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );

    // "Facundo Bacardi" signature rough approximation above it
    // Just a squiggly line or small text
    _drawText(
      canvas,
      "Facundo Bacardi",
      offset: Offset(centerX, labelTop - 10),
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 6,
        fontStyle: FontStyle.italic,
        fontFamily: 'Times',
      ),
    );
  }

  void _drawMainLabel(
    Canvas canvas,
    double centerX,
    double shoulderEndY,
    double w,
    double h,
  ) {
    // Main Body Label
    // Starts a bit below shoulder
    final double labelTop = shoulderEndY + 20;
    final double labelW = w * 0.75 * labelScale; // Apply scale
    final double labelH = h * 0.35 * labelScale; // Apply scale

    final Rect area = Rect.fromCenter(
      center: Offset(centerX, labelTop + labelH / 2) + labelOffset,
      width: labelW,
      height: labelH,
    );

    if (labelImage != null) {
      paintImage(
        canvas: canvas,
        rect: area,
        image: labelImage!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else {
      // Fallback placeholder if image is not loaded yet
      canvas.drawRect(
        area,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawBottomLabel(Canvas canvas, double centerX, double w, double h) {
    // Silver rectangular label at the very bottom
    final double labelH = 40;
    final double labelW = w * 0.7;
    final double labelY = h - 60;

    final Rect rect = Rect.fromCenter(
      center: Offset(centerX, labelY),
      width: labelW,
      height: labelH,
    );

    // Silver gradient background
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      bgPaint,
    );

    // Text
    _drawText(
      canvas,
      "ESTABLECIDO EN 1862",
      offset: Offset(centerX, labelY - 8),
      style: const TextStyle(fontSize: 6, color: Colors.black54),
    );

    _drawText(
      canvas,
      "SANTIAGO DE CUBA",
      offset: Offset(centerX, labelY + 2),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required TextStyle style,
  }) {
    final TextSpan span = TextSpan(text: text, style: style);
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BacardiBottlePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}

class BombaySapphirePainter extends CustomPainter {
  final double fillLevel;
  final ui.Image? labelImage;
  final double labelScale;
  final Offset labelOffset;

  BombaySapphirePainter({
    required this.fillLevel,
    this.labelImage,
    this.labelScale = 1.0,
    this.labelOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // --- Dimensions ---
    final double neckW = w * 0.25;
    final double neckH = h * 0.22;
    // Cap
    final double capH = 25; // Black screw cap

    // Shoulders
    // They are faceted/angled
    final double shoulderStart = neckH;
    final double shoulderEnd = h * 0.33;

    final double bodyBottomY = h - 20;

    // --- 1. Path Definition ---
    final path = Path();

    // Top of Neck
    path.moveTo(centerX - neckW / 2, 0);
    path.lineTo(centerX + neckW / 2, 0);

    // Neck Down
    path.lineTo(centerX + neckW / 2, shoulderStart);

    // Shoulder Slide (Linear slope, not curved, indicative of facets)
    // Actually slight curve at base of neck, then straight slope
    path.quadraticBezierTo(
      centerX + neckW / 2 + 5,
      shoulderStart + 10,
      w * 0.85,
      shoulderEnd * 0.9,
    );
    path.lineTo(w, shoulderEnd);

    // Body Down (Straight)
    path.lineTo(w - 5, bodyBottomY); // Mild taper

    // Bottom Corner
    path.quadraticBezierTo(w - 5, h, w - 20, h);

    // Bottom
    path.lineTo(20, h);

    // Bottom Left Corner
    path.quadraticBezierTo(5, h, 5, bodyBottomY);

    // Body Up
    path.lineTo(0, shoulderEnd);

    // Left Shoulder slope
    path.lineTo(centerX - neckW / 2 - 5, shoulderStart + 10);
    path.quadraticBezierTo(
      centerX - neckW / 2 - 5,
      shoulderStart + 10,
      centerX - neckW / 2,
      shoulderStart,
    );

    // Neck Up
    path.lineTo(centerX - neckW / 2, 0);
    path.close();

    // --- 2. Glass & Liquid ---

    // THE BLUE GLASS:
    final Color glassBlue = const Color(0xFF00BFFF); // Deep Sky Blue / Cyan

    // Fill the whole bottle with translucent blue
    // Slightly darker to represent empty glass
    final Paint glassPaint = Paint()
      ..color = glassBlue.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glassPaint);

    // Liquid Level
    canvas.save();
    canvas.clipPath(path);
    final double liquidH = h * fillLevel;
    final double surfaceY = h - liquidH;

    // Liquid: MUch lighter/whiter to clearly show "filled" state vs empty blue glass
    // The "Silver/Clear" spirit brightens the blue glass considerably.
    final Paint liquidPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, surfaceY, w, h + 100), liquidPaint);

    // Surface Line
    if (fillLevel > 0 && fillLevel < 1.0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: w * 0.9,
          height: 8,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: w * 0.9,
          height: 8,
        ),
        Paint()
          ..color = glassBlue.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();

    // --- Facet Highlights (Vertical Lines) ---
    // Bombay Sapphire bottles have flat sides (facets).
    // Draw vertical highlight lines to suggest the edges of the facets.
    final Paint facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Left Facet Edge
    canvas.drawLine(
      Offset(w * 0.15, shoulderEnd),
      Offset(w * 0.15, bodyBottomY),
      facetPaint,
    );
    // Right Facet Edge
    canvas.drawLine(
      Offset(w * 0.85, shoulderEnd),
      Offset(w * 0.85, bodyBottomY),
      facetPaint,
    );

    // Shoulder Facets
    canvas.drawLine(
      Offset(centerX - neckW / 2, shoulderStart),
      Offset(w * 0.15, shoulderEnd),
      facetPaint,
    );
    canvas.drawLine(
      Offset(centerX + neckW / 2, shoulderStart),
      Offset(w * 0.85, shoulderEnd),
      facetPaint,
    );

    // Border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // --- 3. Details ---

    // Cap (Black with gold bands)
    _drawCap(canvas, centerX, neckW, capH);

    // Neck Label (The vertical strip down the neck)
    _drawNeckLabel(canvas, centerX, neckW, capH, neckH);

    // Main Label
    _drawMainLabel(canvas, centerX, shoulderEnd, w, h);
  }

  void _drawCap(Canvas canvas, double centerX, double neckW, double capH) {
    final double capW = neckW + 2;
    final Rect capRect = Rect.fromLTWH(centerX - capW / 2, 0, capW, capH);

    canvas.drawRect(capRect, Paint()..color = const Color(0xFF1A1A1A)); // Black

    // Gold rings
    canvas.drawRect(
      Rect.fromLTWH(capRect.left, capH - 5, capW, 2),
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  void _drawNeckLabel(
    Canvas canvas,
    double centerX,
    double neckW,
    double capH,
    double neckH,
  ) {
    // Vertical Gold Strip hanging from cap
    final double stripW = neckW * 0.4;
    final double stripH = neckH * 0.6;

    final Rect stripRect = Rect.fromCenter(
      center: Offset(centerX, capH + stripH / 2),
      width: stripW,
      height: stripH,
    );

    // Gold background
    canvas.drawRect(stripRect, Paint()..color = const Color(0xFFFFD700));

    // Text "PREMIUM" vertical?
    // Too small, simulate with lines or blue rectangle
    canvas.drawRect(
      Rect.fromCenter(
        center: stripRect.center,
        width: stripW * 0.6,
        height: stripH * 0.8,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.blue[900]!,
    );

    // Little Blue Gem at bottom of strip
    _drawGem(canvas, Offset(centerX, stripRect.bottom + 5), 5);
  }

  void _drawMainLabel(
    Canvas canvas,
    double centerX,
    double shoulderBottom,
    double w,
    double h,
  ) {
    // Rectangular Label with Gold Border
    final double labelW = w * 0.75 * labelScale;
    final double labelTop = shoulderBottom + 20;
    final double labelH = h * 0.45 * labelScale; // Tall label

    final Rect labelRect = Rect.fromCenter(
      center: Offset(centerX, labelTop + labelH / 1.7) + labelOffset,
      width: labelW,
      height: labelH,
    );

    // --- CONTENT ---

    // The image contains all details (Logo + Text).
    // It should fill the label area (inside the gold border).
    if (labelImage != null) {
      paintImage(
        canvas: canvas,
        rect: labelRect.inflate(20), // Padding inside inner border
        image: labelImage!,
        fit: BoxFit.contain,
      );
    } else {
      _drawText(
        canvas,
        "IMAGE LOADING...",
        offset: labelRect.center,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }
  }

  void _drawGem(Canvas canvas, Offset center, double radius) {
    // Sapphire gem
    final Paint gemPaint = Paint()
      ..color = const Color(0xFF0D47A1); // Dark blue
    canvas.drawCircle(center, radius, gemPaint);

    // Highlight
    canvas.drawCircle(
      center - Offset(radius * 0.3, radius * 0.3),
      radius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  void _drawText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required TextStyle style,
  }) {
    final TextSpan span = TextSpan(text: text, style: style);
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BombaySapphirePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}

class JoseCuervoPainter extends CustomPainter {
  final double fillLevel;
  final Color liquidColor;

  JoseCuervoPainter({required this.fillLevel, required this.liquidColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Dimensions derived from the image
    // Neck is about 25-30% of height
    final double neckTopW = w * 0.28;
    final double neckBottomW = w * 0.32;
    final double neckHeight = h * 0.28;

    // Shoulders are angled sharply
    final double shoulderHeight = h * 0.07;
    final double shoulderBottomY = neckHeight + shoulderHeight;

    // Base has ridges
    final double baseHeight = h * 0.12; // The stacked bottom part
    final double bodyBottomY = h - baseHeight;

    // --- 1. Path Definition ---
    final path = Path();

    // Top center
    path.moveTo(centerX - neckTopW / 2, 0);
    path.lineTo(centerX + neckTopW / 2, 0);

    // Neck Right
    path.lineTo(centerX + neckBottomW / 2, neckHeight);

    // Shoulder Right (Angled out)
    path.lineTo(w - (w * 0.02), shoulderBottomY);

    // Body Right (Straight down)
    path.lineTo(w - (w * 0.04), bodyBottomY);

    // Base Ridges Right (Simulating the stacked glass tiers)
    // Tier 1 (Out)
    path.lineTo(w, bodyBottomY + (baseHeight * 0.1));
    // Tier 1 (Down)
    path.lineTo(w, bodyBottomY + (baseHeight * 0.4));
    // Tier 2 (In)
    path.lineTo(w - (w * 0.03), bodyBottomY + (baseHeight * 0.45));
    // Tier 2 (Down)
    path.lineTo(w - (w * 0.03), h - 5);
    // Bottom Corner
    path.quadraticBezierTo(w - (w * 0.03), h, w - (w * 0.1), h);

    // Bottom Center
    path.lineTo(w * 0.1, h);

    // Bottom Left Corner
    path.quadraticBezierTo(w * 0.03, h, w * 0.03, h - 5);

    // Base Ridge Left
    // Tier 2 (Up)
    path.lineTo(w * 0.03, bodyBottomY + (baseHeight * 0.45));
    // Tier 1 (Out)
    path.lineTo(0, bodyBottomY + (baseHeight * 0.4));
    // Tier 1 (Up)
    path.lineTo(0, bodyBottomY + (baseHeight * 0.1));

    // Body Left
    path.lineTo(w * 0.04, bodyBottomY);

    // Shoulder Left
    path.lineTo(w * 0.02, shoulderBottomY);

    // Neck Left
    path.lineTo(centerX - neckBottomW / 2, neckHeight);

    // Close
    path.lineTo(centerX - neckTopW / 2, 0);
    path.close();

    // --- 2. Glass & Liquid ---

    // Glass Tint (Warm/Golden glass)
    final glassPaint = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glassPaint);

    // Liquid
    canvas.save();
    canvas.clipPath(path);

    // Liquid Rect
    final double liquidH = h * fillLevel;
    final double surfaceY = h - liquidH;

    final Paint liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, surfaceY, w, h + 100), liquidPaint);

    // Surface Ellipse
    if (fillLevel > 0 && fillLevel < 1.0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: w * 0.7,
          height: 6,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
      // Darker rim line
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: w * 0.7,
          height: 6,
        ),
        Paint()
          ..color = Colors.amber[900]!.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.restore();

    // Glass Border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    // --- 3. Details ---

    // Embossed "1795" on shoulder (Center)
    _drawEmbossedText(
      canvas,
      "1795",
      centerX,
      shoulderBottomY - (shoulderHeight * 0.5) + 8,
    );

    _drawCap(canvas, centerX, neckTopW, neckHeight);
    _drawMainLabel(canvas, centerX, shoulderBottomY, w, h, baseHeight);
    _drawBottomLabel(canvas, centerX, w, h, baseHeight);
  }

  void _drawCap(Canvas canvas, double centerX, double neckW, double neckH) {
    final double capH = neckH * 0.7; // Covers most of neck
    final Rect capRect = Rect.fromLTWH(
      centerX - neckW / 2 - 1,
      0,
      neckW + 2,
      capH,
    );

    // Gold Foil Gradient
    final Paint goldPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFB8860B),
          const Color(0xFFFFD700),
          const Color(0xFFDAA520),
          const Color(0xFFB8860B),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(capRect);

    canvas.drawRect(capRect, goldPaint);

    // Cap ridges (top part)
    canvas.drawLine(
      Offset(capRect.left, 5),
      Offset(capRect.right, 5),
      Paint()..color = Colors.black12,
    );
    canvas.drawLine(
      Offset(capRect.left, 15),
      Offset(capRect.right, 15),
      Paint()..color = Colors.black12,
    );

    // Red Crest
    canvas.drawCircle(
      Offset(centerX, capH * 0.55),
      8,
      Paint()..color = const Color(0xFF8B0000).withValues(alpha: 0.8),
    );
    // Tiny text
    _drawText(
      canvas,
      "ESTB.",
      offset: Offset(centerX, capH * 0.55 - 2),
      style: const TextStyle(color: Colors.white, fontSize: 3),
    );

    // Bottom trim of cap
    canvas.drawRect(
      Rect.fromLTWH(capRect.left, capRect.bottom - 4, capRect.width, 4),
      Paint()..color = const Color(0xFF8B0000),
    );
  }

  void _drawEmbossedText(Canvas canvas, String text, double cx, double cy) {
    const TextStyle style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      fontFamily: 'serif',
      color: Colors.transparent,
    );
    // Drop Shadow (Bottom Right)
    _drawText(
      canvas,
      text,
      offset: Offset(cx + 1, cy + 1),
      style: style.copyWith(color: Colors.black.withValues(alpha: 0.2)),
    );
    // Highlight (Top Left)
    _drawText(
      canvas,
      text,
      offset: Offset(cx - 1, cy - 1),
      style: style.copyWith(color: Colors.white.withValues(alpha: 0.4)),
    );
  }

  void _drawMainLabel(
    Canvas canvas,
    double centerX,
    double bodyTopY,
    double w,
    double h,
    double baseH,
  ) {
    // Positioning
    final double labelTop = bodyTopY + 15;
    // Leave space for red label at bottom
    final double labelBottom = h - baseH - 45;
    final double labelH = labelBottom - labelTop;
    final double labelW = w * 0.82;

    final Rect rect = Rect.fromCenter(
      center: Offset(centerX, labelTop + labelH / 2),
      width: labelW,
      height: labelH,
    );

    // --- Label Shape (Arch) ---
    final Path labelPath = Path();
    // Top Arch (Medallions area)
    // The arch is more of a rounded rectangle top
    final double archH = 30.0;
    labelPath.moveTo(rect.left, rect.top + archH);
    labelPath.quadraticBezierTo(
      centerX,
      rect.top - 10,
      rect.right,
      rect.top + archH,
    );
    // Right side
    labelPath.lineTo(rect.right, rect.bottom - 5);
    // Bottom (Curved slightly)
    labelPath.quadraticBezierTo(
      centerX,
      rect.bottom + 5,
      rect.left,
      rect.bottom - 5,
    );
    labelPath.close();

    // Background (Parchment Yellow)
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFFFECB3), const Color(0xFFFFD54F)],
      ).createShader(rect);
    canvas.drawPath(labelPath, bgPaint);

    // Inner Border Line (Gold/Orange)
    canvas.drawPath(
      labelPath,
      Paint()
        ..color = const Color(0xFFFF6F00).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      labelPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // --- Medallions (Top Arch) ---
    // 7 coins
    double coinY = rect.top + 15;
    for (int i = -3; i <= 3; i++) {
      // Arch the coins slightly
      double yOff = (i.abs() * 2).toDouble();
      Offset coinPos = Offset(centerX + (i * 14), coinY + yOff);
      canvas.drawCircle(
        coinPos,
        6,
        Paint()..color = const Color(0xFFD7CCC8),
      ); // Silver/Grey
      canvas.drawCircle(
        coinPos,
        6,
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // --- Text Content ---

    // "Jose" - Gothic/Blackletterish
    _drawText(
      canvas,
      "Jose",
      offset: Offset(centerX, rect.top + 60),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontFamily: 'serif',
        fontWeight: FontWeight.bold, // Fallback to serif bold
      ),
    );

    // "Cuervo" - Big and Bold
    _drawText(
      canvas,
      "Cuervo",
      offset: Offset(centerX, rect.top + 90),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 34,
        fontFamily: 'serif',
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
      ),
    );

    // "Especial" - Serif
    _drawText(
      canvas,
      "Especial",
      offset: Offset(centerX, rect.top + 120),
      style: const TextStyle(
        color: Color(0xFFBF360C),
        fontSize: 18, // Rust color
        fontFamily: 'serif',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    // Red Wax Seal (Bottom Left)
    Offset sealPos = Offset(rect.left + 25, rect.bottom - 30);
    // Outer crimped edge
    canvas.drawCircle(sealPos, 16, Paint()..color = const Color(0xFFB71C1C));
    // Inner circle
    canvas.drawCircle(sealPos, 12, Paint()..color = const Color(0xFFD32F2F));
    // Details
    canvas.drawCircle(
      sealPos,
      12,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBottomLabel(
    Canvas canvas,
    double centerX,
    double w,
    double h,
    double baseH,
  ) {
    // Red Band
    final double labelH = 50;
    // Sits in the middle of the base ridges roughly
    final double labelY = h - baseH - 10;

    Rect rect = Rect.fromLTWH(0, labelY, w, labelH);

    // Background Red Gradient
    Paint redPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF8B0000), Color(0xFFB71C1C), Color(0xFF8B0000)],
      ).createShader(rect);
    canvas.drawRect(rect, redPaint);

    // Gold stripes top/bottom
    canvas.drawRect(
      Rect.fromLTWH(0, labelY, w, 2),
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, labelY + labelH - 2, w, 2),
      Paint()..color = const Color(0xFFFFD700),
    );

    // Text Group
    // "JALISCO • MEXICO"
    _drawText(
      canvas,
      "JALISCO • MEXICO",
      offset: Offset(centerX, labelY + 10),
      style: const TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 6,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );

    // "HECHO CON"
    _drawText(
      canvas,
      "HECHO CON",
      offset: Offset(centerX, labelY + 18),
      style: const TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 5,
        letterSpacing: 1.0,
      ),
    );

    // "AGAVE AZUL" - Big
    _drawText(
      canvas,
      "AGAVE AZUL",
      offset: Offset(centerX, labelY + 28),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );

    // "TEQUILA REPOSADO"
    _drawText(
      canvas,
      "TEQUILA REPOSADO",
      offset: Offset(centerX, labelY + 38),
      style: const TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required TextStyle style,
  }) {
    final TextSpan span = TextSpan(text: text, style: style);
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant JoseCuervoPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}
