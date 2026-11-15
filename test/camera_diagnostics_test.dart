import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/pro_camera/camera_diagnostics.dart';

void main() {
  test('the report shows what was asked and what the sensor did', () {
    final text = formatCameraDiagnostics({
      'device': 'samsung SM-S918B',
      'android': '15 (SDK 35)',
      'openCameraId': '0',
      'sessionRaw': true,
      'requested': {
        'autoExposure': false,
        'iso': 100,
        'exposureNs': 4000000,
        'awbAuto': false,
        'kelvin': 5300,
        'autoFocus': true,
        'zoom': 3.0,
        'flash': 'off',
      },
      'live': {
        'iso': 100,
        'exposureNs': 4000000,
        'zoomRatio': 3.0,
        'focalMm': 6.4,
        'activePhysicalId': '2',
      },
      'cameras': [
        {
          'id': '0',
          'facing': 'back',
          'level': 'FULL',
          'logical': true,
          'physicalIds': ['0', '2', '3'],
          'equivMm': [23],
          'zoomMin': 0.6,
          'zoomMax': 10.0,
          'manualSensor': true,
          'raw': true,
          'wbMode': 'cct',
          'iso': '50-3200',
        },
      ],
    });
    expect(text, contains('samsung SM-S918B'));
    expect(text, contains('ISO 100 · 1/250'));
    expect(text, contains('wb: 5300K'));
    expect(text, contains('zoomRatio 3.0'));
    expect(text, contains('physical 2'));
    expect(text, contains('#0 back FULL logical[0, 2, 3]'));
  });

  test('a report without frames or cameras still reads', () {
    final text = formatCameraDiagnostics({'device': 'x', 'live': null});
    expect(text, contains('no frames yet'));
  });
}
