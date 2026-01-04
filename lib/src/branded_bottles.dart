import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'bottle_type.dart';
import 'liquid_bottle_slider.dart';

enum BrandedBottleType { bacardi, bombaySapphire, joseCuervo, patron }

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
    } else if (widget.type == BrandedBottleType.joseCuervo &&
        _labelImage == null) {
      _loadImage(
        'assets/logo/jose_cuervo.png',
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
                JoseCuervoPainter(
                  fillLevel: visualLevel,
                  liquidColor: color,
                  labelImage: _labelImage,
                  labelScale: widget.labelScale,
                  labelOffset: widget.labelOffset,
                );
            break;
          case BrandedBottleType.patron:
            // Patron is squat: width is nearly equal to body height
            bottleWidth = bottleHeight * 0.85;
            liquidColor = const Color(0xFFE3F2FD).withValues(alpha: 0.5);
            painterFactory = (visualLevel, rawLevel, color) =>
                PatronBottlePainter(
                  fillLevel: visualLevel,
                  liquidColor: liquidColor,
                );
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
    final double scale = h / 600.0;

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

    canvas.restore();

    // Glass Border
    final Paint borderPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // --- 3. Labels & Details ---

    _drawCap(canvas, centerX, neckWidth, neckHeight, w, scale);
    _drawNeckLabel(canvas, centerX, neckWidth, neckHeight, scale);
    _drawMainLabel(canvas, centerX, shoulderEnd, w, h, scale);
    _drawBottomLabel(canvas, centerX, w, h, scale);
  }

  void _drawCap(
    Canvas canvas,
    double centerX,
    double neckW,
    double neckH,
    double w,
    double scale,
  ) {
    final double capH = neckH * 0.4;
    final Rect capRect = Rect.fromLTWH(
      centerX - neckW / 2 - 1 * scale,
      0,
      neckW + 2 * scale,
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
      ..strokeWidth = 1 * scale;
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
    double scale,
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
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawLine(labelRect.topLeft, labelRect.topRight, goldPaint);
    canvas.drawLine(labelRect.bottomLeft, labelRect.bottomRight, goldPaint);

    // "WHITE RUM" text
    _drawText(
      canvas,
      "WHITE RUM",
      offset: labelRect.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 8 * scale,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );

    // "Facundo Bacardi" signature rough approximation above it
    // Just a squiggly line or small text
    _drawText(
      canvas,
      "Facundo Bacardi",
      offset: Offset(centerX, labelTop - 10 * scale),
      style: TextStyle(
        color: Colors.black54,
        fontSize: 6 * scale,
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
    double scale,
  ) {
    // Main Body Label
    // Starts a bit below shoulder
    final double labelTop = shoulderEndY + 20 * scale;
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

  void _drawBottomLabel(
    Canvas canvas,
    double centerX,
    double w,
    double h,
    double scale,
  ) {
    // Silver rectangular label at the very bottom
    final double labelH = 40 * scale;
    final double labelW = w * 0.7;
    final double labelY = h - 60 * scale;

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
      RRect.fromRectAndRadius(rect, Radius.circular(4 * scale)),
      bgPaint,
    );

    // Text
    _drawText(
      canvas,
      "ESTABLECIDO EN 1862",
      offset: Offset(centerX, labelY - 8 * scale),
      style: TextStyle(fontSize: 6 * scale, color: Colors.black54),
    );

    _drawText(
      canvas,
      "SANTIAGO DE CUBA",
      offset: Offset(centerX, labelY + 2 * scale),
      style: TextStyle(
        fontSize: 10 * scale,
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
    final double scale = h / 600.0;
    final centerX = w / 2;

    // --- Dimensions ---
    final double neckW = w * 0.25;
    final double neckH = h * 0.22;
    // Cap
    final double capH = 25 * scale; // Black screw cap

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

    canvas.restore();

    // --- Facet Highlights (Vertical Lines) ---
    // Bombay Sapphire bottles have flat sides (facets).
    // Draw vertical highlight lines to suggest the edges of the facets.
    final Paint facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * scale;

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
      ..strokeWidth = 1.5 * scale;
    canvas.drawPath(path, borderPaint);

    // --- 3. Details ---

    // Cap (Black with gold bands)
    _drawCap(canvas, centerX, neckW, capH, scale);

    // Neck Label (The vertical strip down the neck)
    _drawNeckLabel(canvas, centerX, neckW, capH, neckH, scale);

    // Main Label
    _drawMainLabel(canvas, centerX, shoulderEnd, w, h, scale);
  }

  void _drawCap(
    Canvas canvas,
    double centerX,
    double neckW,
    double capH,
    double scale,
  ) {
    final double capW = neckW + 2 * scale;
    final Rect capRect = Rect.fromLTWH(centerX - capW / 2, 0, capW, capH);

    canvas.drawRect(capRect, Paint()..color = const Color(0xFF1A1A1A)); // Black

    // Gold rings
    canvas.drawRect(
      Rect.fromLTWH(capRect.left, capH - 5 * scale, capW, 2 * scale),
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  void _drawNeckLabel(
    Canvas canvas,
    double centerX,
    double neckW,
    double capH,
    double neckH,
    double scale,
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
    _drawGem(canvas, Offset(centerX, stripRect.bottom + 5 * scale), 5 * scale);
  }

  void _drawMainLabel(
    Canvas canvas,
    double centerX,
    double shoulderBottom,
    double w,
    double h,
    double scale,
  ) {
    // Rectangular Label with Gold Border
    final double labelW = w * 0.75 * labelScale;
    final double labelTop = shoulderBottom + 20 * scale;
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
        rect: labelRect.inflate(20 * scale), // Padding inside inner border
        image: labelImage!,
        fit: BoxFit.contain,
      );
    } else {
      _drawText(
        canvas,
        "IMAGE LOADING...",
        offset: labelRect.center,
        style: TextStyle(fontSize: 10 * scale, color: Colors.grey),
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
  final ui.Image? labelImage;
  final double labelScale;
  final Offset labelOffset;

  JoseCuervoPainter({
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
    final double scale = h / 600.0;
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

    canvas.restore();

    // Glass Border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawPath(path, borderPaint);

    // --- 3. Details ---

    // Embossed "1795" on shoulder (Center)
    _drawEmbossedText(
      canvas,
      "1795",
      centerX,
      shoulderBottomY - (shoulderHeight * 0.5) + 8 * scale,
      scale,
    );

    _drawCap(canvas, centerX, neckTopW, neckHeight, scale);
    _drawMainLabel(canvas, centerX, shoulderBottomY, w, h, baseHeight, scale);
    _drawBottomLabel(canvas, centerX, w, h, baseHeight, scale);
  }

  void _drawCap(
    Canvas canvas,
    double centerX,
    double neckW,
    double neckH,
    double scale,
  ) {
    final double capH = neckH * 0.7; // Covers most of neck
    final Rect capRect = Rect.fromLTWH(
      centerX - neckW / 2 - 1 * scale,
      0,
      neckW + 2 * scale,
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
      Offset(capRect.left, 5 * scale),
      Offset(capRect.right, 5 * scale),
      Paint()..color = Colors.black12,
    );
    canvas.drawLine(
      Offset(capRect.left, 15 * scale),
      Offset(capRect.right, 15 * scale),
      Paint()..color = Colors.black12,
    );

    // Red Crest
    canvas.drawCircle(
      Offset(centerX, capH * 0.55),
      8 * scale,
      Paint()..color = const Color(0xFF8B0000).withValues(alpha: 0.8),
    );
    // Tiny text
    _drawText(
      canvas,
      "ESTB.",
      offset: Offset(centerX, capH * 0.55 - 2 * scale),
      style: TextStyle(color: Colors.white, fontSize: 3 * scale),
    );

    // Bottom trim of cap
    canvas.drawRect(
      Rect.fromLTWH(
        capRect.left,
        capRect.bottom - 4 * scale,
        capRect.width,
        4 * scale,
      ),
      Paint()..color = const Color(0xFF8B0000),
    );
  }

  void _drawEmbossedText(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    double scale,
  ) {
    final TextStyle style = TextStyle(
      fontSize: 14 * scale,
      fontWeight: FontWeight.w900,
      fontFamily: 'serif',
      color: Colors.transparent,
    );
    // Drop Shadow (Bottom Right)
    _drawText(
      canvas,
      text,
      offset: Offset(cx + 1 * scale, cy + 1 * scale),
      style: style.copyWith(color: Colors.black.withValues(alpha: 0.2)),
    );
    // Highlight (Top Left)
    _drawText(
      canvas,
      text,
      offset: Offset(cx - 1 * scale, cy - 1 * scale),
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
    double scale,
  ) {
    // Positioning
    final double labelTop = bodyTopY + 15 * scale;
    // Leave space for red label at bottom
    final double labelBottom = h - baseH - 45 * scale;
    final double labelH = labelBottom - labelTop;
    final double labelW = w * 0.82;

    final Rect rect = Rect.fromCenter(
      center: Offset(centerX, labelTop + labelH / 2) + labelOffset,
      width: labelW * labelScale,
      height: labelH * labelScale,
    );

    if (labelImage != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: labelImage!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else {
      // Fallback placeholder
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  void _drawBottomLabel(
    Canvas canvas,
    double centerX,
    double w,
    double h,
    double baseH,
    double scale,
  ) {
    // Red Band
    final double labelH = 50 * scale;
    // Sits in the middle of the base ridges roughly
    final double labelY = h - baseH - 10 * scale;

    Rect rect = Rect.fromLTWH(0, labelY, w, labelH);

    // Background Red Gradient
    Paint redPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF8B0000), Color(0xFFB71C1C), Color(0xFF8B0000)],
      ).createShader(rect);
    canvas.drawRect(rect, redPaint);

    // Gold stripes top/bottom
    canvas.drawRect(
      Rect.fromLTWH(0, labelY, w, 2 * scale),
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, labelY + labelH - 2 * scale, w, 2 * scale),
      Paint()..color = const Color(0xFFFFD700),
    );

    // Text Group
    // "JALISCO • MEXICO"
    _drawText(
      canvas,
      "JALISCO • MEXICO",
      offset: Offset(centerX, labelY + 10 * scale),
      style: TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 6 * scale,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );

    // "HECHO CON"
    _drawText(
      canvas,
      "HECHO CON",
      offset: Offset(centerX, labelY + 18 * scale),
      style: TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 5 * scale,
        letterSpacing: 1.0,
      ),
    );

    // "AGAVE AZUL" - Big
    _drawText(
      canvas,
      "AGAVE AZUL",
      offset: Offset(centerX, labelY + 28 * scale),
      style: TextStyle(
        color: Colors.white,
        fontSize: 13 * scale,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );

    // "TEQUILA REPOSADO"
    _drawText(
      canvas,
      "TEQUILA REPOSADO",
      offset: Offset(centerX, labelY + 38 * scale),
      style: TextStyle(
        color: Color(0xFFFFB74D),
        fontSize: 5 * scale,
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

class PatronBottlePainter extends CustomPainter {
  final double fillLevel;
  final Color liquidColor;

  PatronBottlePainter({required this.fillLevel, required this.liquidColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final double scale = h / 600.0;
    final centerX = w / 2;

    // --- Dimensions ---
    final double neckTopY = 0;

    // Neck
    final double neckW = w * 0.28;
    final double neckH = h * 0.18;
    final double shoulderStart = neckTopY + neckH;

    // Body
    // Patron body is bulbous.
    // It widens from shoulder, then tapers slightly to base.
    final double bodyMaxW = w;
    final double bodyBottomW = w * 0.92;
    // Base is heavy glass
    final double baseH = 20 * scale;

    // --- 1. Path Definition ---
    final path = Path();

    // Top of Neck (Lip)
    final double lipW = neckW * 1.2;
    final double lipH = 8 * scale;

    // Start at Top Left of neck lip
    path.moveTo(centerX - lipW / 2, neckTopY);
    path.lineTo(centerX + lipW / 2, neckTopY);

    // Resize to regular neck width
    path.lineTo(centerX + neckW / 2, neckTopY + lipH);

    // Neck down
    path.lineTo(centerX + neckW / 2, shoulderStart);

    // Shoulder Curve (Smooth convex)
    path.cubicTo(
      centerX + neckW / 2 + 20,
      shoulderStart + 10,
      bodyMaxW,
      shoulderStart + 40,
      bodyMaxW,
      shoulderStart + (h - shoulderStart) * 0.4,
    );

    // Body Side (Taper to bottom)
    // It's bumpy in the photo (horizontal ripples?). The image shows slight wave/ripples on the side.
    // Let's do a subtle wave
    double sideY = shoulderStart + (h - shoulderStart) * 0.4;
    double bottomY = h - baseH;

    // Let's just do a smooth curve for now, maybe add ripple detail in "glass" pass
    path.quadraticBezierTo(bodyMaxW, bottomY - 30, bodyBottomW, bottomY);

    // Bottom Corner
    path.quadraticBezierTo(bodyBottomW, h, bodyBottomW - 20, h);

    // Bottom Center
    path.lineTo(w - (bodyBottomW - 20), h);

    // Bottom Left Corner
    path.quadraticBezierTo(w - bodyBottomW, h, w - bodyBottomW, bottomY);

    // Left Side
    path.quadraticBezierTo(
      0,
      bottomY - 30,
      0,
      sideY, // Approx symmetrical
    );

    // Left Shoulder
    path.cubicTo(
      0,
      shoulderStart + 40,
      centerX - neckW / 2 - 20,
      shoulderStart + 10,
      centerX - neckW / 2,
      shoulderStart,
    );

    // Left Neck
    path.lineTo(centerX - neckW / 2, neckTopY + lipH);
    path.lineTo(centerX - lipW / 2, neckTopY);
    path.close();

    // --- 2. Glass & Liquid ---

    // Glass Fill
    final glassPaint = Paint()
      ..color = const Color(0xFFF0F4F8)
          .withValues(alpha: 0.2) // Clear glass
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glassPaint);

    // Liquid
    canvas.save();
    canvas.clipPath(path);

    // Liquid Level
    final double liquidH = (h - 20 * scale) * fillLevel; // Subtract base
    final double surfaceY = h - 20 * scale - liquidH;

    final Paint liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTRB(0, surfaceY, w, h + 100), liquidPaint);

    canvas.restore();

    // Glass Border
    final Paint borderPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawPath(path, borderPaint);

    // Add side ripple lines for that "blown glass" look on the sides
    _drawGlassRipples(canvas, path, w, h, shoulderStart, scale);

    // --- 3. Details ---

    // Neck Label (Green Ribbon)
    _drawNeckLabel(canvas, centerX, neckW, neckTopY, neckH, scale);

    // Main Logo & Text
    _drawMainLabel(canvas, centerX, h, shoulderStart, scale);
  }

  void _drawNeckLabel(
    Canvas canvas,
    double centerX,
    double neckW,
    double neckTopY,
    double neckH,
    double scale,
  ) {
    // Green band
    final double bandH = neckH * 0.5;
    final double bandY = neckTopY + (neckH * 0.2);

    final Rect rect = Rect.fromCenter(
      center: Offset(centerX, bandY + bandH / 2),
      width: neckW,
      height: bandH,
    );

    // Bright lime-ish green
    final Paint greenPaint = Paint()
      //..color = const Color(0xFF76FF03).withValues(alpha: 0.8);
      // Actually ref image is more of a grassy lively green
      ..color = const Color(0xFF64DD17);

    canvas.drawRect(rect, greenPaint);

    // Ornate Pattern (darker green swirls)
    // tough to draw procedurally perfectly, we'll do some loops
    final Paint patternPaint = Paint()
      ..color = const Color(0xFF33691E).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    final Path p = Path();
    // Simple wave pattern
    for (double x = rect.left; x < rect.right; x += 10 * scale) {
      p.moveTo(x, rect.top + 5 * scale);
      p.quadraticBezierTo(
        x + 5 * scale,
        rect.top + 15 * scale,
        x + 10 * scale,
        rect.top + 5 * scale,
      );

      p.moveTo(x, rect.bottom - 5 * scale);
      p.quadraticBezierTo(
        x + 5 * scale,
        rect.bottom - 15 * scale,
        x + 10 * scale,
        rect.bottom - 5 * scale,
      );
    }
    canvas.drawPath(p, patternPaint);

    // Center Bee on neck? (Sometimes is there)
    // Image shows a bee
    _drawBee(canvas, Offset(centerX, rect.center.dy), 10 * scale, scale);
  }

  void _drawMainLabel(
    Canvas canvas,
    double centerX,
    double h,
    double shoulderEnd,
    double scale,
  ) {
    // "PATRÓN"
    // "SILVER"
    // Bee Logo

    double currentY = shoulderEnd + (h - shoulderEnd) * 0.25;

    // 1. BEE LOGO
    _drawBee(canvas, Offset(centerX, currentY), 25 * scale, scale);

    currentY += 40 * scale;

    // 2. PATRÓN
    _drawText(
      canvas,
      "PATRÓN",
      offset: Offset(centerX, currentY),
      style: TextStyle(
        fontFamily: 'Serif',
        fontSize: 32 * scale,
        fontWeight: FontWeight.w400, // Usually fairly thin but sharp serifs
        color: Colors.black,
        letterSpacing: 2.0,
      ),
    );
    // Small 'circle R' trademark
    _drawText(
      canvas,
      "®",
      offset: Offset(
        centerX + 75 * scale,
        currentY - 5 * scale,
      ), // Rough offset
      style: TextStyle(fontSize: 8 * scale, color: Colors.black54),
    );

    currentY += 30 * scale;

    // 3. SILVER (Greenish font style?)
    // Actually usually black or dark grey with green accent line?
    // Image shows "SILVER" in semi-handwritten or specific font, dark color.
    // Wait, let's look at the image provided by user... "SILVER" is GREEN.
    _drawText(
      canvas,
      "SILVER",
      offset: Offset(centerX, currentY),
      style: TextStyle(
        fontSize: 24 * scale,
        fontWeight: FontWeight.bold,
        color: Color(0xFF33691E), // Dark Green
        fontFamily: 'Sans', // Looks slightly organic
      ),
    );

    currentY += 30 * scale;

    // 4. TEQUILA 100% DE AGAVE
    _drawText(
      canvas,
      "TEQUILA 100% DE AGAVE",
      offset: Offset(centerX, currentY),
      style: TextStyle(
        fontSize: 10 * scale,
        color: Colors.black87,
        letterSpacing: 1.0,
      ),
    );

    currentY += 20 * scale;

    // 5. HECHO EN MEXICO (Green background pill)
    // Lime green background
    final Rect tagRect = Rect.fromCenter(
      center: Offset(centerX, currentY),
      width: 100 * scale,
      height: 16 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, Radius.circular(8 * scale)),
      Paint()..color = const Color(0xFF76FF03),
    );
    _drawText(
      canvas,
      "HECHO EN MEXICO",
      offset: Offset(centerX, currentY),
      style: TextStyle(
        fontSize: 8 * scale,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B5E20),
      ),
    );

    // Bottom text (750ml ... 40% alc)
    double bottomTxtY = h - 30 * scale;
    _drawText(
      canvas,
      "750 ml",
      offset: Offset(centerX - 60 * scale, bottomTxtY),
      style: TextStyle(fontSize: 10 * scale, color: Colors.black54),
    );
    _drawText(
      canvas,
      "40% alc./vol.",
      offset: Offset(centerX + 60 * scale, bottomTxtY),
      style: TextStyle(fontSize: 10 * scale, color: Colors.black54),
    );
  }

  void _drawBee(Canvas canvas, Offset center, double size, double scale) {
    // Gold/Bronze Bee
    final Paint beePaint = Paint()
      ..color = const Color(0xFFCDA434); // Metallic gold

    // Body (Oval)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size, height: size * 1.5),
      beePaint,
    );

    // Wings (Two circles/ovals on sides)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Right Wing
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size * 0.8, -size * 0.2),
        width: size * 1.2,
        height: size * 0.6,
      ),
      beePaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Left Wing
    canvas.rotate(0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-size * 0.8, -size * 0.2),
        width: size * 1.2,
        height: size * 0.6,
      ),
      beePaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    canvas.restore();

    // Head
    canvas.drawCircle(
      center - Offset(0, size * 0.6),
      size * 0.4,
      beePaint..style = PaintingStyle.fill,
    );
  }

  void _drawGlassRipples(
    Canvas canvas,
    Path clipPath,
    double w,
    double h,
    double shoulderY,
    double scale,
  ) {
    // Subtle white highlights on the sides to simulate the "rippled glass" surface
    canvas.save();
    canvas.clipPath(clipPath);

    final Paint ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale);

    // Left ripples
    for (double y = shoulderY; y < h; y += 40 * scale) {
      canvas.drawLine(
        Offset(0, y),
        Offset(w * 0.2, y + 10 * scale),
        ripplePaint,
      );
    }

    // Right ripples
    for (double y = shoulderY + 20 * scale; y < h; y += 40 * scale) {
      canvas.drawLine(
        Offset(w, y),
        Offset(w * 0.8, y + 10 * scale),
        ripplePaint,
      );
    }

    canvas.restore();
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
  bool shouldRepaint(covariant PatronBottlePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}
