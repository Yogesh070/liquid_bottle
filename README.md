# Liquid Bottle

A Flutter package containing a realistic, physics-based liquid bottle slider widget.

## Features

- **Realistic Liquid Physics**: Simulates liquid movement and levels inside various bottle shapes.
- **Rubber-band Effect**: Interactive cleaning/filling experience with bouncy physics.
- **Customizable Shapes**: Includes standard liquor bottle shapes (Fifth, Liter, Magnum, etc.) via `BottlePathFactory`.
- **Dynamic Resizing**: Bottles adapt to container constraints while maintaining aspect ratios.

## Usage

```dart
import 'package:liquid_bottle/liquid_bottle.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: LiquidBottleSlider(
        bottleType: BottleType.standards.first, // Miniature
        value: 0.5, // 50% full
        onChanged: (val) {
          print("New fill level: $val");
        },
      ),
    );
  }
}
```

## Additional Information

This package was extracted from a larger liquor inventory application to provide reusable bottle UI components.
