import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bottle_type.dart';
import 'bottle_path_factory.dart';

class LiquidBottleSlider extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double>? onChanged;
  final BottleType bottleType;
  final Color liquidColor;
  final CustomPainter Function(
    BuildContext context,
    double visualFill,
    double rawFill,
    Color liquidColor,
  )?
  customPainterBuilder;

  const LiquidBottleSlider({
    super.key,
    required this.value,
    this.onChanged,
    required this.bottleType,
    this.liquidColor = const Color(0xFFC6A984), // Whiskey color
    this.customPainterBuilder,
  });

  @override
  State<LiquidBottleSlider> createState() => _LiquidBottleSliderState();
}

class _LiquidBottleSliderState extends State<LiquidBottleSlider>
    with SingleTickerProviderStateMixin {
  /// The current vertical drag position in local coordinates.
  /// Can exceed 0.0 and 1.0 during overscroll.
  double _currentDragValue = 0.0;

  /// Animation controller for the spring snap-back effect.
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  /// Track if user is actively touching to manage animations.
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentDragValue = widget.value;

    // Configuration for the snap-back physics
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(LiquidBottleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external value changes (e.g. from data sync), update internal state
    if (!_isDragging && !_springController.isAnimating) {
      _currentDragValue = widget.value;
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PHYSICS ENGINE: RUBBER BAND & DAMPING
  // ---------------------------------------------------------------------------

  /// Calculates the visual fill level (0.0 - 1.0+) based on drag input.
  /// Applies a resistance function when out of bounds.
  double _calculateVisualLevel(double rawValue) {
    if (rawValue >= 0.0 && rawValue <= 1.0) {
      return rawValue;
    }

    // Determine how far we are out of bounds (overscroll)
    double overscroll = 0.0;
    if (rawValue < 0.0) overscroll = rawValue;
    if (rawValue > 1.0) overscroll = rawValue - 1.0;

    // Apply Square Root Damping: y = c * sqrt(x)
    // This creates strong resistance that grows with distance.
    // Factor 0.15 controls the "stretchiness" of the rubber band.
    double damped = overscroll.sign * 0.15 * math.sqrt(overscroll.abs());

    if (rawValue < 0.0) return damped; // Visual level below 0
    return 1.0 + damped; // Visual level above 1
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _springController.stop(); // Halt any settling animations
    // Haptic feedback for engagement (optional)
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details, double height) {
    // 1. Normalize drag delta to 0..1 range
    // Note: dy is positive downwards, but slider value 0 is bottom, 1 is top.
    // Actually, usually 0 is bottom. Let's assume standard slider: 0 (empty) -> 1 (full).
    // Dragging UP (negative dy) should INCREASE value.
    double delta = -details.primaryDelta! / height;

    // 2. Apply delta to raw drag value
    double newValue = _currentDragValue + delta;

    // 3. Check for boundary crossing to trigger Haptics
    // If we crossed 0 or 1 boundaries, fire impact.
    bool crossedMin = (_currentDragValue > 0 && newValue <= 0);
    bool crossedMax = (_currentDragValue < 1 && newValue >= 1);

    if (crossedMin || crossedMax) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _currentDragValue = newValue;
    });

    // 4. Report clamped value to parent
    double clamped = newValue.clamp(0.0, 1.0);
    if (clamped != widget.value) {
      widget.onChanged?.call(clamped);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;

    // SPRING DYNAMICS: Snap back if out of bounds
    if (_currentDragValue < 0.0 || _currentDragValue > 1.0) {
      final double target = (_currentDragValue < 0.0) ? 0.0 : 1.0;

      // Setup spring simulation
      _springAnimation = Tween<double>(begin: _currentDragValue, end: target)
          .animate(
            CurvedAnimation(
              parent: _springController,
              // elasticOut is good, but iOS is often 'easeOutBack' or critical spring.
              // We use a custom curve or standard easeOutCubic for a tight snap.
              curve: Curves.easeOutCubic,
            ),
          );

      _springController.reset();
      _springController.forward();

      _springController.addListener(() {
        setState(() {
          _currentDragValue = _springAnimation.value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double visualFill = _calculateVisualLevel(_currentDragValue);

        return Semantics(
          slider: true,
          label: "${widget.bottleType.name} Volume",
          value: "${(widget.value * 100).round()}%",
          onScrollUp: widget.onChanged != null
              ? () {
                  double newVal = (widget.value + 0.1).clamp(0.0, 1.0);
                  widget.onChanged!(newVal);
                  setState(() => _currentDragValue = newVal);
                }
              : null,
          onScrollDown: widget.onChanged != null
              ? () {
                  double newVal = (widget.value - 0.1).clamp(0.0, 1.0);
                  widget.onChanged!(newVal);
                  setState(() => _currentDragValue = newVal);
                }
              : null,
          child: GestureDetector(
            // HitTestBehavior.opaque ensures we capture touches even on empty areas
            // if we were filling a larger container.
            // Here we wrap the CustomPaint which defines the hit area.
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: widget.onChanged != null ? _onDragStart : null,
            onVerticalDragUpdate: widget.onChanged != null
                ? (d) => _onDragUpdate(d, constraints.maxHeight)
                : null,
            onVerticalDragEnd: widget.onChanged != null ? _onDragEnd : null,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: widget.customPainterBuilder != null
                  ? widget.customPainterBuilder!(
                      context,
                      visualFill,
                      _currentDragValue,
                      widget.liquidColor,
                    )
                  : LiquidBottlePainter(
                      path: BottlePathFactory.buildPath(
                        widget.bottleType.id,
                        Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      fillLevel: visualFill,
                      liquidColor: widget.liquidColor,
                      bottleType: widget.bottleType,
                      currentFillPercent: widget.value,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class LiquidBottlePainter extends CustomPainter {
  final Path path;
  final double fillLevel; // Can be > 1.0 or < 0.0
  final Color liquidColor;
  final BottleType bottleType;
  final double currentFillPercent; // 0.0 to 1.0 (clamped usually)

  LiquidBottlePainter({
    required this.path,
    required this.fillLevel,
    required this.liquidColor,
    required this.bottleType,
    required this.currentFillPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paints definition
    final Paint glassFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final Paint glassBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    // 2. Draw Glass Background (Empty Bottle)
    canvas.drawPath(path, glassFill);

    // 3. Draw Liquid
    // We use canvas.save() and clipPath() to constrain liquid to the bottle shape.
    canvas.save();
    canvas.clipPath(path);

    // Calculate Y position of liquid surface.
    // 0 is top, height is bottom.
    // fillLevel 1.0 -> y = 0. fillLevel 0.0 -> y = height.
    // We must handle overscroll (negative y or y > height) for rubber band.
    final double liquidHeight = size.height * fillLevel;
    final double surfaceY = size.height - liquidHeight;

    // Draw the liquid block
    // We draw a Rect that extends downwards.
    // We add extra padding at bottom to handle the "pull up" overscroll.
    canvas.drawRect(
      Rect.fromLTRB(0, surfaceY, size.width, size.height + 200),
      liquidPaint,
    );

    // 4. Gloss/Reflection Overlay
    // Adds a gradient highlight to simulate cylindrical glass reflection.
    final Gradient reflection = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.2),
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.1, 0.2, 0.5, 0.9],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final Paint glossPaint = Paint()
      ..shader = reflection.createShader(Offset.zero & size)
      ..blendMode = BlendMode.srcOver; // Draw on top of liquid

    canvas.drawRect(Offset.zero & size, glossPaint);

    canvas.restore(); // End Clipping

    // 5. Draw Bottle Outline on top
    canvas.drawPath(path, glassBorder);

    // 6. Draw Label
    _drawLabel(canvas, size);
  }

  void _drawLabel(Canvas canvas, Size size) {
    // Label Logic
    final double labelWidth = size.width * 0.6;
    final double labelHeight = size.height * 0.25;
    final double labelX = (size.width - labelWidth) / 2;
    // Position label roughly in the middle-bottom of the body
    // This depends heavily on bottle shape, but 55% down is a safe bet for most
    double labelY = size.height * 0.55 - (labelHeight / 2);

    // Adjust for specific shapes if needed (e.g. handle bottle might need offset)
    if (bottleType.id == 'mini') {
      labelY = size.height * 0.6 - (labelHeight / 2);
    }

    final RRect labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      const Radius.circular(8.0),
    );

    // Label Background
    final Paint labelPaint = Paint()
      ..color =
          const Color(0xFFF5EFE6) // Off-white paper
      ..style = PaintingStyle.fill;

    // Draw shadow manually
    final Path shadowPath = Path()
      ..addRRect(labelRect.shift(const Offset(0, 2)));
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.2),
      4.0,
      true,
    );

    canvas.drawRRect(labelRect, labelPaint);

    // Label Border
    final Paint labelBorder = Paint()
      ..color = const Color(0xFFD6C8B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(labelRect, labelBorder);

    // Calculate Volumes
    // We treat 'value' 0.0 as empty, 1.0 as full.
    // Clamp to 0..1 for display
    double displayPercent = currentFillPercent.clamp(0.0, 1.0);
    int totalMl = bottleType.volumeMl;
    int currentMl = (totalMl * displayPercent).round();

    // Formatting
    String totalStr = _formatVolume(totalMl);
    String currentStr = _formatVolume(currentMl);

    // Text Styling
    const TextStyle labelStyle = TextStyle(
      color: Color(0xFF2C3E50),
      fontSize: 16, // Dynamic sizing could be better but fixed is ok for now
      fontWeight: FontWeight.bold,
      fontFamily: 'Courier', // Monospace-ish looks like printed label
    );

    final TextSpan span = TextSpan(
      children: [
        TextSpan(
          text: "$currentStr \n",
          style: labelStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        TextSpan(
          text: "/ $totalStr",
          style: labelStyle.copyWith(
            fontSize: 14,
            color: const Color(0xFF7F8C8D),
          ),
        ),
      ],
    );

    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    tp.layout(minWidth: labelWidth, maxWidth: labelWidth);

    // Center text in label
    final double textX = labelX;
    final double textY = labelY + (labelHeight - tp.height) / 2;

    tp.paint(canvas, Offset(textX, textY));
  }

  String _formatVolume(int ml) {
    if (ml >= 1000) {
      double liters = ml / 1000;
      // Remove trailing zeros (e.g. 1.0 -> 1L, 1.5 -> 1.5L)
      String lStr = liters.toStringAsFixed(1);
      if (lStr.endsWith('.0')) lStr = lStr.substring(0, lStr.length - 2);
      return "${lStr}L";
    }
    return "${ml}ml";
  }

  @override
  bool shouldRepaint(covariant LiquidBottlePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.path != path;
  }
}
