import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';

/// "Repeat this shot": the live camera with the reference photo laid over it
/// as a see-through guide, so the angle and framing can be matched.
class RepeatShotScreen extends ConsumerWidget {
  const RepeatShotScreen({required this.photoId, super.key});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog =
        ref.watch(remotePhotoCatalogProvider).asData?.value ??
        seedPhotoReferences;
    final photo = catalog.where((photo) => photo.id == photoId).firstOrNull;
    if (photo == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(context.tr('This photo is not in the catalog.')),
        ),
      );
    }
    return _RepeatShotView(photo: photo);
  }
}

class _RepeatShotView extends StatefulWidget {
  const _RepeatShotView({required this.photo});

  final PhotoReference photo;

  @override
  State<_RepeatShotView> createState() => _RepeatShotViewState();
}

class _RepeatShotViewState extends State<_RepeatShotView>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _controller;
  String? _error;
  double _opacity = 0.4;
  bool _showGuide = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  Future<void> _start() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera was found on this device.');
        return;
      }
      _cameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _openCamera();
    } on CameraException catch (error) {
      _handleCameraError(error);
    }
  }

  Future<void> _openCamera() async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      _handleCameraError(error);
    }
  }

  void _handleCameraError(CameraException error) {
    if (!mounted) return;
    final denied =
        error.code.contains('AccessDenied') ||
        error.code.contains('AccessRestricted');
    setState(
      () => _error = denied
          ? 'Allow camera access in your phone settings to repeat a shot.'
          : 'The camera could not be started.',
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _busy) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _openCamera();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || _busy || controller.value.isTakingPicture) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final savedText = context.tr('Saved to your gallery.');
    final failedText = context.tr('The photo could not be saved.');
    try {
      final file = await controller.takePicture();
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(file.path, album: 'SHOTBOOK');
      messenger.showSnackBar(SnackBar(content: Text(savedText)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failedText)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('repeat-close'),
                  tooltip: context.tr('Close'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(
                    widget.photo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('repeat-toggle-guide'),
                  tooltip: _showGuide
                      ? context.tr('Hide guide')
                      : context.tr('Show guide'),
                  onPressed: () => setState(() => _showGuide = !_showGuide),
                  icon: Icon(
                    _showGuide ? Icons.layers : Icons.layers_clear_outlined,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          context.tr(_error!),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : controller == null
                    ? const CircularProgressIndicator()
                    : CameraPreview(
                        controller,
                        child: _showGuide
                            ? IgnorePointer(
                                child: Opacity(
                                  opacity: _opacity,
                                  child: SizedBox.expand(
                                    child: PhotoReferenceImage(
                                      photo: widget.photo,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.opacity,
                    size: 18,
                    color: ShotbookColors.secondary,
                  ),
                  Expanded(
                    child: Slider(
                      key: const Key('repeat-opacity'),
                      value: _opacity,
                      min: 0.1,
                      max: 0.9,
                      label: context.tr('Guide opacity'),
                      onChanged: _showGuide
                          ? (value) => setState(() => _opacity = value)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  GestureDetector(
                    key: const Key('repeat-shutter'),
                    onTap: controller == null ? null : _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _busy ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('repeat-switch-camera'),
                    tooltip: context.tr('Switch camera'),
                    onPressed: _cameras.length < 2 ? null : _switchCamera,
                    icon: const Icon(Icons.cameraswitch_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
