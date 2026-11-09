class CameraDevice {
  const CameraDevice({
    required this.id,
    required this.brand,
    required this.model,
    required this.cameras,
    required this.recommendations,
    required this.sampleSettings,
  });

  final String id;
  final String brand;
  final String model;
  final List<String> cameras;
  final List<String> recommendations;
  final Map<String, String> sampleSettings;
}

const cameraDevices = <CameraDevice>[
  CameraDevice(
    id: 'samsung-s23-ultra',
    brand: 'Samsung',
    model: 'Galaxy S23 Ultra',
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
    ],
    sampleSettings: {
      'Portrait': '3× · ISO 50–200 · 1/250 s',
      'Street': '1× · ISO Auto · 1/500 s',
      'Night': '1× · Night mode · brace the phone',
    },
  ),
  CameraDevice(
    id: 'apple-iphone-15-pro',
    brand: 'Apple',
    model: 'iPhone 15 Pro',
    cameras: [
      '48 MP main · 24 mm',
      '12 MP ultra-wide · 13 mm',
      '12 MP telephoto · 77 mm',
    ],
    recommendations: [
      'Choose 2× crop for a clean environmental portrait.',
      'Use ProRAW when you plan to make careful color edits.',
      'Expose for highlights in bright window light.',
    ],
    sampleSettings: {
      'Portrait': '2× · Portrait mode · natural light',
      'Street': '1× · Photographic Style: Standard',
      'Night': '1× · Night mode · hold steady',
    },
  ),
  CameraDevice(
    id: 'google-pixel-8-pro',
    brand: 'Google Pixel',
    model: 'Pixel 8 Pro',
    cameras: [
      '50 MP wide · 25 mm',
      '48 MP ultra-wide · 21 mm',
      '48 MP telephoto · 113 mm',
    ],
    recommendations: [
      'Use the 5× telephoto to isolate distant details.',
      'Keep Real Tone enabled for consistent skin tones.',
      'Use Night Sight for static scenes and keep the phone still.',
    ],
    sampleSettings: {
      'Portrait': '2× · Portrait mode · face in soft light',
      'Street': '1× · HDR · tap to focus',
      'Night': '1× · Night Sight · steady support',
    },
  ),
  CameraDevice(
    id: 'xiaomi-14-ultra',
    brand: 'Xiaomi',
    model: '14 Ultra',
    cameras: [
      '50 MP main · 23 mm',
      '50 MP ultra-wide · 12 mm',
      '50 MP telephoto · 75 mm',
      '50 MP periscope · 120 mm',
    ],
    recommendations: [
      'Try the 75 mm camera for compressed portraits.',
      'Use Pro mode to keep white balance consistent across a set.',
      'Leica Authentic keeps contrast and color restrained.',
    ],
    sampleSettings: {
      'Portrait': '75 mm · ISO 50–200 · open shade',
      'Street': '23 mm · Pro mode · 1/500 s',
      'Night': '23 mm · ISO under 800 · steady hands',
    },
  ),
  CameraDevice(
    id: 'other-smartphone',
    brand: 'Other',
    model: 'Other smartphone',
    cameras: [
      'Main / wide camera',
      'Ultra-wide camera (if available)',
      'Telephoto camera (if available)',
    ],
    recommendations: [
      'Use the main camera for the cleanest low-light result.',
      'Step back and use optical zoom for portraits if available.',
      'Avoid digital zoom; move closer or crop after shooting.',
    ],
    sampleSettings: {
      'Portrait': '2× optical zoom · soft window light',
      'Street': 'Main camera · 1/250 s or faster',
      'Night': 'Night mode · keep the phone steady',
    },
  ),
];
