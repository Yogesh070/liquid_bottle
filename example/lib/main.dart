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

class _LiquidBottleShowcaseState extends State<LiquidBottleShowcase> {
  late PageController _pageController;
  int _currentIndex = 4; // Standard Bottle

  final Map<String, double> _fillLevels = {};

  @override
  void initState() {
    super.initState();
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
                itemCount: BottleType.standards.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final type = BottleType.standards[index];
                  final isFocused = index == _currentIndex;

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
                                type.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${type.volumeMl}ml  •  ${type.imperialVol}",
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

                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double width = constraints.maxWidth;
                              double height = width / type.aspectRatio;

                              if (height > constraints.maxHeight) {
                                height = constraints.maxHeight;
                                width = height * type.aspectRatio;
                              }

                              return Center(
                                child: SizedBox(
                                  width: width,
                                  height: height,
                                  child: LiquidBottleSlider(
                                    bottleType: type,
                                    value: _fillLevels[type.id] ?? 0.5,
                                    onChanged: (val) {
                                      setState(() {
                                        _fillLevels[type.id] = val;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Indicator or Controls
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Text(
                "${((_fillLevels[BottleType.standards[_currentIndex].id] ?? 0.5) * 100).toInt()}% FULL",
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
