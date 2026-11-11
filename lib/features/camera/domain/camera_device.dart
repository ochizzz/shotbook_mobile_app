/// Rough camera layout of a phone. It decides which shooting tips and
/// starting points are shown, so similar phones share consistent guidance.
enum CameraClass {
  /// Main + ultra-wide + a long (5x or more) telephoto.
  periscope,

  /// Main + ultra-wide + a short telephoto (2-3.5x).
  telephoto,

  /// Main + ultra-wide.
  dual,

  /// One main camera.
  single,
}

class CameraDevice {
  const CameraDevice({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.cameras,
    required this.recommendations,
    required this.sampleSettings,
  });

  final String id;
  final String brand;
  final String model;

  /// Release year of the earliest model in the group.
  final int year;
  final List<String> cameras;
  final List<String> recommendations;
  final Map<String, String> sampleSettings;
}

CameraDevice _phone({
  required String id,
  required String brand,
  required String model,
  required int year,
  required CameraClass cameraClass,
  required List<String> cameras,
  String portrait = 'the telephoto camera',
  List<String> extraTips = const [],
}) {
  final tips = switch (cameraClass) {
    CameraClass.periscope => [
      'Use $portrait for natural portrait proportions.',
      'Use the longest zoom only in good light and brace the phone.',
      'Keep the main camera at 1× for low-light scenes.',
    ],
    CameraClass.telephoto => [
      'Use $portrait for flattering portraits instead of the wide lens.',
      'Keep the main camera at 1× for low-light scenes.',
      'Tap the subject to lock focus, then lower exposure slightly.',
    ],
    CameraClass.dual => [
      'Use the main camera for most shots; it is the sharpest in low light.',
      'Use the ultra-wide for interiors and architecture, and keep people away from the edges.',
      'Step back and crop later instead of using digital zoom.',
    ],
    CameraClass.single => [
      'Move your feet instead of zooming; digital zoom loses detail.',
      'Use Portrait mode with a subject 1.5–2 m away.',
      'Tap the subject to lock focus, then lower exposure slightly.',
    ],
  };
  final settings = switch (cameraClass) {
    CameraClass.periscope => {
      'Portrait': 'Telephoto · ISO as low as the light allows · open shade',
      'Street': '1× · 1/500 s or faster',
      'Night': '1× · Night mode · brace the phone',
    },
    CameraClass.telephoto => {
      'Portrait': 'Telephoto · soft window light · 1/250 s',
      'Street': '1× · 1/500 s or faster',
      'Night': '1× · Night mode · brace the phone',
    },
    CameraClass.dual => {
      'Portrait': 'Main camera · Portrait mode · soft light',
      'Street': '1× · 1/500 s or faster',
      'Night': '1× · Night mode · brace the phone',
    },
    CameraClass.single => {
      'Portrait': 'Portrait mode · soft window light',
      'Street': '1× · 1/250 s or faster',
      'Night': 'Night mode · keep the phone steady',
    },
  };
  return CameraDevice(
    id: id,
    brand: brand,
    model: model,
    year: year,
    cameras: cameras,
    recommendations: [...tips, ...extraTips],
    sampleSettings: settings,
  );
}

const _appleTip = 'Use Photographic Styles to keep skin tones consistent.';
const _pixelTip = 'Keep Real Tone enabled for consistent skin tones.';
const _samsungTip =
    'Use Pro mode to keep white balance consistent across a set.';
const _leicaTip = 'Leica Authentic keeps contrast and color restrained.';

/// Camera guide catalog: popular phones from 2022 to 2026. Models whose
/// cameras are the same (for example Pro and Pro Max) share one entry.
/// Specs are approximate; the app tells people to check the maker's page.
final cameraDevices = <CameraDevice>[
  // Apple
  _phone(
    id: 'apple-iphone-17-pro',
    brand: 'Apple',
    model: 'iPhone 17 Pro / Pro Max',
    year: 2025,
    cameraClass: CameraClass.periscope,
    portrait: 'the 4× camera (100 mm)',
    cameras: [
      '48 MP main · 24 mm',
      '48 MP ultra-wide · 13 mm',
      '48 MP telephoto · 100 mm',
    ],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-17',
    brand: 'Apple',
    model: 'iPhone 17',
    year: 2025,
    cameraClass: CameraClass.dual,
    cameras: ['48 MP main · 26 mm', '48 MP ultra-wide · 13 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-air',
    brand: 'Apple',
    model: 'iPhone Air',
    year: 2025,
    cameraClass: CameraClass.single,
    cameras: ['48 MP main · 26 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-16-pro',
    brand: 'Apple',
    model: 'iPhone 16 Pro / Pro Max',
    year: 2024,
    cameraClass: CameraClass.periscope,
    portrait: 'the 5× camera (120 mm)',
    cameras: [
      '48 MP main · 24 mm',
      '48 MP ultra-wide · 13 mm',
      '12 MP telephoto · 120 mm',
    ],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-16',
    brand: 'Apple',
    model: 'iPhone 16 / 16 Plus',
    year: 2024,
    cameraClass: CameraClass.dual,
    cameras: ['48 MP main · 26 mm', '12 MP ultra-wide · 13 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-16e',
    brand: 'Apple',
    model: 'iPhone 16e',
    year: 2025,
    cameraClass: CameraClass.single,
    cameras: ['48 MP main · 26 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-15-pro-max',
    brand: 'Apple',
    model: 'iPhone 15 Pro Max',
    year: 2023,
    cameraClass: CameraClass.periscope,
    portrait: 'the 5× camera (120 mm)',
    cameras: [
      '48 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '12 MP telephoto · 120 mm',
    ],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-15-pro',
    brand: 'Apple',
    model: 'iPhone 15 Pro',
    year: 2023,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (77 mm)',
    cameras: [
      '48 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '12 MP telephoto · 77 mm',
    ],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-15',
    brand: 'Apple',
    model: 'iPhone 15 / 15 Plus',
    year: 2023,
    cameraClass: CameraClass.dual,
    cameras: ['48 MP main · 26 mm', '12 MP ultra-wide · 13 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-14-pro',
    brand: 'Apple',
    model: 'iPhone 14 Pro / Pro Max',
    year: 2022,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (77 mm)',
    cameras: [
      '48 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '12 MP telephoto · 77 mm',
    ],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-14',
    brand: 'Apple',
    model: 'iPhone 14 / 14 Plus',
    year: 2022,
    cameraClass: CameraClass.dual,
    cameras: ['12 MP main · 26 mm', '12 MP ultra-wide · 13 mm'],
    extraTips: [_appleTip],
  ),
  _phone(
    id: 'apple-iphone-se-3',
    brand: 'Apple',
    model: 'iPhone SE (3rd gen)',
    year: 2022,
    cameraClass: CameraClass.single,
    cameras: ['12 MP main · 28 mm'],
    extraTips: [_appleTip],
  ),

  // Samsung
  _phone(
    id: 'samsung-s26-ultra',
    brand: 'Samsung',
    model: 'Galaxy S26 Ultra',
    year: 2026,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera',
    cameras: [
      '200 MP main · 23 mm',
      '50 MP ultra-wide · 13 mm',
      '3× telephoto',
      '50 MP periscope · 5×',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s26',
    brand: 'Samsung',
    model: 'Galaxy S26 / S26+',
    year: 2026,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera',
    cameras: ['Main camera', 'Ultra-wide camera', '3× telephoto'],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s25-ultra',
    brand: 'Samsung',
    model: 'Galaxy S25 Ultra',
    year: 2025,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera',
    cameras: [
      '200 MP main · 24 mm',
      '50 MP ultra-wide · 13 mm',
      '10 MP telephoto · 3×',
      '50 MP periscope · 5×',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s25-edge',
    brand: 'Samsung',
    model: 'Galaxy S25 Edge',
    year: 2025,
    cameraClass: CameraClass.dual,
    cameras: ['200 MP main', '12 MP ultra-wide'],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s25',
    brand: 'Samsung',
    model: 'Galaxy S25 / S25+',
    year: 2025,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera',
    cameras: [
      '50 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 3×',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s24-ultra',
    brand: 'Samsung',
    model: 'Galaxy S24 Ultra',
    year: 2024,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera (70 mm)',
    cameras: [
      '200 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 70 mm',
      '50 MP periscope · 111 mm',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s24',
    brand: 'Samsung',
    model: 'Galaxy S24 / S24+',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (70 mm)',
    cameras: [
      '50 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 70 mm',
    ],
    extraTips: [_samsungTip],
  ),
  CameraDevice(
    id: 'samsung-s23-ultra',
    brand: 'Samsung',
    model: 'Galaxy S23 Ultra',
    year: 2023,
    cameras: [
      '200 MP main · 23 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 69 mm',
      '10 MP periscope · 230 mm',
    ],
    recommendations: [
      'Use the 3× camera for natural portrait proportions.',
      'Keep the main camera at 1× for low-light scenes.',
      'Tap the subject to lock focus before lowering exposure slightly.',
      _samsungTip,
    ],
    sampleSettings: {
      'Portrait': '3× · ISO 50–200 · 1/250 s',
      'Street': '1× · ISO Auto · 1/500 s',
      'Night': '1× · Night mode · brace the phone',
    },
  ),
  _phone(
    id: 'samsung-s23',
    brand: 'Samsung',
    model: 'Galaxy S23 / S23+',
    year: 2023,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (69 mm)',
    cameras: [
      '50 MP main · 23 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 69 mm',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s22-ultra',
    brand: 'Samsung',
    model: 'Galaxy S22 Ultra',
    year: 2022,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera (69 mm)',
    cameras: [
      '108 MP main · 23 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 69 mm',
      '10 MP periscope · 230 mm',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-s22',
    brand: 'Samsung',
    model: 'Galaxy S22 / S22+',
    year: 2022,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (69 mm)',
    cameras: [
      '50 MP main · 23 mm',
      '12 MP ultra-wide · 13 mm',
      '10 MP telephoto · 69 mm',
    ],
    extraTips: [_samsungTip],
  ),
  _phone(
    id: 'samsung-galaxy-a',
    brand: 'Samsung',
    model: 'Galaxy A54 / A55 / A56',
    year: 2023,
    cameraClass: CameraClass.dual,
    cameras: ['50 MP main', '12 MP ultra-wide', '5 MP macro'],
  ),

  // Google Pixel
  _phone(
    id: 'google-pixel-10',
    brand: 'Google Pixel',
    model: 'Pixel 10 / 10 Pro / 10 Pro XL',
    year: 2025,
    cameraClass: CameraClass.periscope,
    portrait: 'the 2× camera, or the 5× camera on Pixel 10',
    cameras: [
      'Pro: 50 MP main · 24 mm · Pixel 10: 48 MP main',
      'Pro: 48 MP ultra-wide · 12 mm · Pixel 10: 13 MP',
      '5× telephoto (Pro: 48 MP · 110 mm)',
    ],
    extraTips: [_pixelTip],
  ),
  _phone(
    id: 'google-pixel-9',
    brand: 'Google Pixel',
    model: 'Pixel 9 / 9 Pro / 9 Pro XL',
    year: 2024,
    cameraClass: CameraClass.periscope,
    portrait: 'the 5× camera (Pro models) or the 2× crop',
    cameras: [
      '50 MP main · 25 mm',
      '48 MP ultra-wide (Pixel 9: 48 MP)',
      'Pro models: 48 MP telephoto · 5×',
    ],
    extraTips: [_pixelTip],
  ),
  _phone(
    id: 'google-pixel-8',
    brand: 'Google Pixel',
    model: 'Pixel 8 / 8 Pro',
    year: 2023,
    cameraClass: CameraClass.periscope,
    portrait: 'the 5× camera (Pro) or the 2× crop',
    cameras: [
      '50 MP main · 25 mm',
      '12 MP ultra-wide (Pro: 48 MP)',
      'Pro: 48 MP telephoto · 113 mm',
    ],
    extraTips: [_pixelTip],
  ),
  _phone(
    id: 'google-pixel-7',
    brand: 'Google Pixel',
    model: 'Pixel 7 / 7 Pro',
    year: 2022,
    cameraClass: CameraClass.periscope,
    portrait: 'the 5× camera (Pro) or the 2× crop',
    cameras: [
      '50 MP main · 25 mm',
      '12 MP ultra-wide',
      'Pro: 48 MP telephoto · 120 mm',
    ],
    extraTips: [_pixelTip],
  ),
  _phone(
    id: 'google-pixel-a',
    brand: 'Google Pixel',
    model: 'Pixel 7a / 8a / 9a',
    year: 2023,
    cameraClass: CameraClass.dual,
    cameras: ['64 MP main (9a: 48 MP)', '13 MP ultra-wide'],
    extraTips: [_pixelTip],
  ),

  // Xiaomi
  _phone(
    id: 'xiaomi-17-ultra',
    brand: 'Xiaomi',
    model: '17 Ultra',
    year: 2025,
    cameraClass: CameraClass.periscope,
    portrait: 'the periscope camera at 75–100 mm',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide · 14 mm',
      '200 MP periscope · 75–100 mm',
    ],
    extraTips: [_leicaTip],
  ),
  _phone(
    id: 'xiaomi-15-ultra',
    brand: 'Xiaomi',
    model: '15 Ultra',
    year: 2025,
    cameraClass: CameraClass.periscope,
    portrait: 'the 70 mm camera',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide · 14 mm',
      '50 MP telephoto · 70 mm',
      '200 MP periscope · 100 mm',
    ],
    extraTips: [_leicaTip],
  ),
  _phone(
    id: 'xiaomi-15',
    brand: 'Xiaomi',
    model: '15',
    year: 2025,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 60 mm camera',
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 14 mm',
      '50 MP telephoto · 60 mm',
    ],
    extraTips: [_leicaTip],
  ),
  CameraDevice(
    id: 'xiaomi-14-ultra',
    brand: 'Xiaomi',
    model: '14 Ultra',
    year: 2024,
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 12 mm',
      '50 MP telephoto · 75 mm',
      '50 MP periscope · 120 mm',
    ],
    recommendations: [
      'Try the 75 mm camera for compressed portraits.',
      'Use Pro mode to keep white balance consistent across a set.',
      _leicaTip,
    ],
    sampleSettings: {
      'Portrait': '75 mm · ISO 50–200 · open shade',
      'Street': '23 mm · Pro mode · 1/500 s',
      'Night': '23 mm · ISO under 800 · steady hands',
    },
  ),
  _phone(
    id: 'xiaomi-14',
    brand: 'Xiaomi',
    model: '14',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 75 mm camera',
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 14 mm',
      '50 MP telephoto · 75 mm',
    ],
    extraTips: [_leicaTip],
  ),
  _phone(
    id: 'xiaomi-13-ultra',
    brand: 'Xiaomi',
    model: '13 Ultra',
    year: 2023,
    cameraClass: CameraClass.periscope,
    portrait: 'the 75 mm camera',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide · 12 mm',
      '50 MP telephoto · 75 mm',
      '50 MP periscope · 120 mm',
    ],
    extraTips: [_leicaTip],
  ),
  _phone(
    id: 'xiaomi-13-pro',
    brand: 'Xiaomi',
    model: '13 Pro',
    year: 2023,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 75 mm camera',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide',
      '50 MP telephoto · 75 mm',
    ],
    extraTips: [_leicaTip],
  ),
  _phone(
    id: 'redmi-note-pro',
    brand: 'Xiaomi',
    model: 'Redmi Note 13 Pro / 14 Pro',
    year: 2024,
    cameraClass: CameraClass.dual,
    cameras: ['200 MP main', '8 MP ultra-wide', '2 MP macro'],
  ),

  // OnePlus
  _phone(
    id: 'oneplus-13',
    brand: 'OnePlus',
    model: 'OnePlus 13',
    year: 2025,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera',
    cameras: ['50 MP main · 23 mm', '50 MP ultra-wide', '50 MP periscope · 3×'],
  ),
  _phone(
    id: 'oneplus-12',
    brand: 'OnePlus',
    model: 'OnePlus 12',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera (70 mm)',
    cameras: [
      '50 MP main · 23 mm',
      '48 MP ultra-wide · 14 mm',
      '64 MP periscope · 70 mm',
    ],
  ),
  _phone(
    id: 'oneplus-11',
    brand: 'OnePlus',
    model: 'OnePlus 11',
    year: 2023,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 2× portrait camera (48 mm)',
    cameras: [
      '50 MP main · 24 mm',
      '48 MP ultra-wide · 14 mm',
      '32 MP portrait telephoto · 48 mm',
    ],
  ),
  _phone(
    id: 'oneplus-10-pro',
    brand: 'OnePlus',
    model: 'OnePlus 10 Pro',
    year: 2022,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3.3× camera (77 mm)',
    cameras: [
      '48 MP main · 23 mm',
      '50 MP ultra-wide · 14 mm',
      '8 MP telephoto · 77 mm',
    ],
  ),

  // Oppo
  _phone(
    id: 'oppo-find-x8-pro',
    brand: 'Oppo',
    model: 'Find X8 Pro',
    year: 2024,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera (73 mm)',
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 15 mm',
      '50 MP telephoto · 73 mm',
      '50 MP periscope · 135 mm',
    ],
  ),
  _phone(
    id: 'oppo-find-x7-ultra',
    brand: 'Oppo',
    model: 'Find X7 Ultra',
    year: 2024,
    cameraClass: CameraClass.periscope,
    portrait: 'the 3× camera (65 mm)',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide · 15 mm',
      '50 MP telephoto · 65 mm',
      '50 MP periscope · 135 mm',
    ],
  ),

  // Vivo
  _phone(
    id: 'vivo-x200-pro',
    brand: 'Vivo',
    model: 'X200 Pro',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 85 mm camera',
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 15 mm',
      '200 MP periscope · 85 mm',
    ],
  ),
  _phone(
    id: 'vivo-x100-pro',
    brand: 'Vivo',
    model: 'X100 Pro',
    year: 2023,
    cameraClass: CameraClass.periscope,
    portrait: 'the periscope camera (100 mm)',
    cameras: [
      '50 MP main · 1-inch · 23 mm',
      '50 MP ultra-wide · 15 mm',
      '50 MP periscope · 100 mm',
    ],
  ),

  // Honor
  _phone(
    id: 'honor-magic7-pro',
    brand: 'Honor',
    model: 'Magic7 Pro',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera',
    cameras: ['50 MP main', '50 MP ultra-wide', '200 MP periscope · 3×'],
  ),
  _phone(
    id: 'honor-magic6-pro',
    brand: 'Honor',
    model: 'Magic6 Pro',
    year: 2024,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 2.5× camera',
    cameras: ['50 MP main', '50 MP ultra-wide', '180 MP periscope · 2.5×'],
  ),

  // Nothing
  _phone(
    id: 'nothing-phone-3',
    brand: 'Nothing',
    model: 'Phone (3)',
    year: 2025,
    cameraClass: CameraClass.telephoto,
    portrait: 'the 3× camera',
    cameras: ['50 MP main', '50 MP ultra-wide', '50 MP periscope · 3×'],
  ),
  _phone(
    id: 'nothing-phone-2',
    brand: 'Nothing',
    model: 'Phone (2)',
    year: 2023,
    cameraClass: CameraClass.dual,
    cameras: ['50 MP main', '50 MP ultra-wide'],
  ),

  // Other
  _phone(
    id: 'other-smartphone',
    brand: 'Other',
    model: 'Other smartphone',
    year: 0,
    cameraClass: CameraClass.dual,
    cameras: [
      'Main / wide camera',
      'Ultra-wide camera (if available)',
      'Telephoto camera (if available)',
    ],
  ),
];
