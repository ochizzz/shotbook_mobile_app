import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import 'pro_camera_view.dart';

/// The Camera tab: SHOTBOOK's manual camera on its own, full screen.
class ShootScreen extends StatelessWidget {
  const ShootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android
        ? ProCameraView(fallback: _unavailable)
        : _unavailable(context);
  }

  static Widget _unavailable(BuildContext context) => Scaffold(
    key: const Key('camera-unavailable'),
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 30,
              color: ShotbookColors.secondary,
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(
                'The SHOTBOOK camera works on Android for now. Open a photo and use "Repeat this shot" to shoot with a guide.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: ShotbookColors.secondary),
            ),
          ],
        ),
      ),
    ),
  );
}
