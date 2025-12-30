/// A configuration model representing a standard liquor bottle size.
/// Data derived from industry standard volumes.
class BottleType {
  final String id;
  final String name;
  final int volumeMl;
  final String imperialVol;
  final double aspectRatio; // Width / Height

  const BottleType({
    required this.id,
    required this.name,
    required this.volumeMl,
    required this.imperialVol,
    required this.aspectRatio,
  });

  static List<BottleType> get standards => [
    BottleType(
      id: 'mini',
      name: 'Miniature',
      volumeMl: 50,
      imperialVol: '1.7 oz',
      aspectRatio: 0.6,
    ),
    BottleType(
      id: 'quarter_pint',
      name: 'Quarter Pint',
      volumeMl: 100,
      imperialVol: '3.4 oz',
      aspectRatio: 0.7,
    ),
    BottleType(
      id: 'half_pint',
      name: 'Half Pint',
      volumeMl: 200,
      imperialVol: '6.8 oz',
      aspectRatio: 0.75,
    ),
    BottleType(
      id: 'pint',
      name: 'Pint',
      volumeMl: 375,
      imperialVol: '12.7 oz',
      aspectRatio: 0.6,
    ),
    BottleType(
      id: 'fifth',
      name: 'Standard (Fifth)',
      volumeMl: 750,
      imperialVol: '25.4 oz',
      aspectRatio: 1.0,
    ),
    BottleType(
      id: 'liter',
      name: 'Liter',
      volumeMl: 1000,
      imperialVol: '33.8 oz',
      aspectRatio: 1.0,
    ),
    BottleType(
      id: 'magnum',
      name: 'Magnum',
      volumeMl: 1500,
      imperialVol: '50.7 oz',
      aspectRatio: 1.1,
    ),
    BottleType(
      id: 'half_gallon',
      name: 'Half Gallon',
      volumeMl: 1750,
      imperialVol: '59.2 oz',
      aspectRatio: 1.2,
    ),
    BottleType(
      id: 'double_magnum',
      name: 'Double Magnum',
      volumeMl: 3000,
      imperialVol: '101.4 oz',
      aspectRatio: 1.3,
    ),
    BottleType(
      id: 'rehoboam',
      name: 'Rehoboam',
      volumeMl: 4500,
      imperialVol: '152.2 oz',
      aspectRatio: 1.4,
    ),
  ];
}
