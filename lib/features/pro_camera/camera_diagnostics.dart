import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import 'pro_camera_controller.dart';

/// Plain-text camera report: the phone, every camera Android exposes to
/// apps, what SHOTBOOK asked for and what the sensor really did. Meant to
/// be screenshotted or copied and sent to the developer.
String formatCameraDiagnostics(Map<Object?, Object?> d) {
  final b = StringBuffer();
  String v(Object? x) => x == null ? '—' : '$x';
  String shutter(Object? ns) =>
      ns is num && ns > 0 ? formatShutter(ns.toInt()) : '—';
  b.writeln('${v(d['device'])} · Android ${v(d['android'])}');
  b.writeln(
    'open camera: ${v(d['openCameraId'])} · RAW stream: ${v(d['sessionRaw'])}',
  );
  final req = (d['requested'] as Map?) ?? const {};
  b.writeln('\nREQUESTED');
  b.writeln(
    'exposure: ${req['autoExposure'] == true ? 'auto, EV steps ${v(req['ev'])}' : 'ISO ${v(req['iso'])} · ${shutter(req['exposureNs'])}'}',
  );
  b.writeln('wb: ${req['awbAuto'] == true ? 'auto' : '${v(req['kelvin'])}K'}');
  b.writeln(
    'focus: ${req['autoFocus'] == true ? 'auto' : 'manual ${v(req['focusDiopters'])} D'}',
  );
  b.writeln('zoom: ${v(req['zoom'])}× · flash: ${v(req['flash'])}');
  final live = d['live'] as Map?;
  b.writeln('\nSENSOR (last frame)');
  if (live == null) {
    b.writeln('no frames yet');
  } else {
    b.writeln('ISO ${v(live['iso'])} · ${shutter(live['exposureNs'])}');
    b.writeln(
      'aeMode ${v(live['aeMode'])} · ev ${v(live['ev'])} · awbMode ${v(live['awbMode'])} · afMode ${v(live['afMode'])}',
    );
    b.writeln(
      'zoomRatio ${v(live['zoomRatio'])} · lens ${v(live['focalMm'])} mm · physical ${v(live['activePhysicalId'])}',
    );
  }
  b.writeln('\nCAMERAS');
  for (final c in (d['cameras'] as List?) ?? const []) {
    if (c is! Map) continue;
    b.writeln(
      '#${v(c['id'])} ${v(c['facing'])} ${v(c['level'])}'
      '${c['logical'] == true ? ' logical${v(c['physicalIds'])}' : ''}',
    );
    b.writeln(
      '  ${v(c['equivMm'])} mm · zoom ${v(c['zoomMin'])}–${v(c['zoomMax'])}',
    );
    b.writeln(
      '  manual ${v(c['manualSensor'])} · post ${v(c['manualPost'])} · raw ${v(c['raw'])} · wb ${v(c['wbMode'])}',
    );
    b.writeln('  ISO ${v(c['iso'])}');
  }
  return b.toString().trimRight();
}

Future<void> showCameraDiagnostics(
  BuildContext context,
  ProCameraController camera,
) async {
  final data = await camera.diagnostics();
  if (!context.mounted) return;
  final text = data == null
      ? context.tr('Diagnostics are not available on this phone.')
      : formatCameraDiagnostics(data);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Camera diagnostics'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const Key('diagnostics-copy'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(context.tr('Copy')),
                ),
              ],
            ),
            Text(
              context.tr(
                'Send this text or a screenshot to the developer if the camera misbehaves.',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: ShotbookColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: SelectableText(
                  text,
                  key: const Key('diagnostics-text'),
                  style: const TextStyle(
                    fontFamily: shotbookMonoFont,
                    fontSize: 11.5,
                    height: 1.45,
                    color: ShotbookColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
