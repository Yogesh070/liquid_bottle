import 'package:flutter/material.dart';
import 'package:liquid_bottle/liquid_bottle.dart';

void main() {
  runApp(const LiquidBottleExampleApp());
}

class LiquidBottleExampleApp extends StatelessWidget {
  const LiquidBottleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.amber,
      ),
      home: const LiquidBottleShowcase(),
    );
  }
}

class LiquidBottleShowcase extends StatefulWidget {
  const LiquidBottleShowcase({super.key});

  @override
  State<LiquidBottleShowcase> createState() => _LiquidBottleShowcaseState();
}

class _BottleConfig {
  final String id;
  final String name;
  final String volume;
  final BrandedBottleType type;
  final double defaultFill;
  final Offset labelOffset;
  final double labelScale;

  const _BottleConfig({
    required this.id,
    required this.name,
    required this.volume,
    required this.type,
    required this.defaultFill,
    this.labelOffset = Offset.zero,
    this.labelScale = 1.0,
  });
}

class _LiquidBottleShowcaseState extends State<LiquidBottleShowcase> {
  late PageController _pageController;
  int _currentIndex = 0; // Starts at Bacardi

  final Map<String, double> _fillLevels = {};

  final List<_BottleConfig> _bottles = [
    _BottleConfig(
      id: 'bacardi',
      name: "BACARDÍ",
      volume: "750ml • 25.4 oz",
      type: BrandedBottleType.bacardi,
      defaultFill: 0.75,
    ),
    _BottleConfig(
      id: 'bombay',
      name: "BOMBAY SAPPHIRE",
      volume: "750ml • 25.4 oz",
      type: BrandedBottleType.bombaySapphire,
      defaultFill: 0.65,
      labelOffset: const Offset(0, 10),
      labelScale: 0.5,
    ),
    _BottleConfig(
      id: 'jose',
      name: "JOSE CUERVO",
      volume: "750ml • 25.4 oz",
      type: BrandedBottleType.joseCuervo,
      defaultFill: 0.70,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (var bottle in _bottles) {
      _fillLevels[bottle.id] = bottle.defaultFill;
    }

    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.65,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCurrentId(int index) {
    if (index >= 0 && index < _bottles.length) {
      return _bottles[index].id;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "LIQUID INVENTORY",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2.0,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _bottles.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final isFocused = index == _currentIndex;
                  final bottle = _bottles[index];

                  Widget content = BrandedBottle(
                    type: bottle.type,
                    fillLevel: _fillLevels[bottle.id] ?? bottle.defaultFill,
                    labelOffset: bottle.labelOffset,
                    labelScale: bottle.labelScale,
                    onFillChanged: (val) {
                      setState(() {
                        _fillLevels[bottle.id] = val;
                      });
                    },
                  );

                  // Animate scaling for focus effect
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      } else {
                        value = isFocused ? 1.0 : 0.7;
                      }

                      return Center(
                        child: SizedBox(
                          width: 250 * value,
                          height: 500 * value,
                          child: Opacity(
                            opacity: isFocused ? 1.0 : 0.3,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // info above
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: 1.0,
                          child: Column(
                            children: [
                              Text(
                                bottle.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bottle.volume,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        Expanded(child: content),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Text(
                "${((_fillLevels[_getCurrentId(_currentIndex)] ?? 0.5) * 100).toInt()}% FULL",
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w100,
                  color: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
