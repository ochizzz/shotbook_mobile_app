import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../shared/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../application/feed_providers.dart';
import '../data/image_upload_validation.dart';
import '../../profile/application/profile_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _device = TextEditingController();
  final _camera = TextEditingController();
  final _focalLength = TextEditingController();
  final _iso = TextEditingController();
  final _shutterSpeed = TextEditingController();
  final _aperture = TextEditingController();
  final _whiteBalance = TextEditingController();
  final _exposureCompensation = TextEditingController();
  final _preset = TextEditingController();
  final _contrast = TextEditingController();
  final _highlights = TextEditingController();
  final _shadows = TextEditingController();
  final _saturation = TextEditingController();
  final _temperature = TextEditingController();
  final _tint = TextEditingController();
  final _grain = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  String _category = photoCategories[1];
  String? _error;
  bool _busy = false;

  List<TextEditingController> get _controllers => [
    _title,
    _description,
    _device,
    _camera,
    _focalLength,
    _iso,
    _shutterSpeed,
    _aperture,
    _whiteBalance,
    _exposureCompensation,
    _preset,
    _contrast,
    _highlights,
    _shadows,
    _saturation,
    _temperature,
    _tint,
    _grain,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      ImageUploadValidation.validate(image.name, bytes);
      if (!mounted) return;
      setState(() {
        _image = image;
        _imageBytes = bytes;
        _error = null;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not open that image. Please choose another file.',
        );
      }
    }
  }

  Map<String, String?> get _cameraSettings => {
    'device': _device.text,
    'camera': _camera.text,
    'focal_length': _focalLength.text,
    'iso': _iso.text,
    'shutter_speed': _shutterSpeed.text,
    'aperture': _aperture.text,
    'white_balance': _whiteBalance.text,
    'exposure_compensation': _exposureCompensation.text,
  };

  Map<String, String> get _editingSettings => {
    if (_contrast.text.trim().isNotEmpty) 'Contrast': _contrast.text.trim(),
    if (_highlights.text.trim().isNotEmpty)
      'Highlights': _highlights.text.trim(),
    if (_shadows.text.trim().isNotEmpty) 'Shadows': _shadows.text.trim(),
    if (_saturation.text.trim().isNotEmpty)
      'Saturation': _saturation.text.trim(),
    if (_temperature.text.trim().isNotEmpty)
      'Temperature': _temperature.text.trim(),
    if (_tint.text.trim().isNotEmpty) 'Tint': _tint.text.trim(),
    if (_grain.text.trim().isNotEmpty) 'Grain': _grain.text.trim(),
  };

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null || _imageBytes == null) {
      setState(() => _error = 'Choose a photo before publishing.');
      return;
    }
    final repository = ref.read(feedRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (repository == null) {
      setState(
        () => _error = 'Publishing needs a configured Supabase project. See README for setup.',
      );
      return;
    }
    if (user == null) {
      context.push('/auth');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.createPost(
        userId: user.id,
        fileName: _image!.name,
        bytes: _imageBytes!,
        title: _title.text,
        description: _description.text,
        category: _category,
        cameraSettings: _cameraSettings,
        preset: _preset.text,
        editingSettings: _editingSettings,
      );
      ref.invalidate(feedPostsProvider);
      ref.invalidate(remotePhotoCatalogProvider);
      ref.invalidate(profilePostsProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString();
    if (value.contains('SocketException') ||
        value.contains('Failed host lookup')) {
      return 'Could not reach Supabase. Check your connection and try again.';
    }
    return value.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (!ref.watch(supabaseReadyProvider)) ...[
                const _SetupNotice(
                  message: 'Connect a Supabase project to publish posts. You can still browse the local catalog.',
                ),
                const SizedBox(height: 18),
              ],
              _imageBytes == null
                  ? OutlinedButton.icon(
                      key: const Key('select-post-image'),
                      onPressed: _busy ? null : _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Choose a photo'),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
              if (_image != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _pickImage,
                    child: const Text('Change photo'),
                  ),
                ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('post-title'),
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a title for your photo.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: photoCategories
                    .where((value) => value != 'All')
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 22),
              _sectionTitle(context, 'Camera settings'),
              _textField(_device, 'Device'),
              _textField(_camera, 'Camera / Lens'),
              _textField(_focalLength, 'Focal length'),
              _textField(_iso, 'ISO', numeric: true),
              _textField(_shutterSpeed, 'Shutter speed'),
              _textField(_aperture, 'Aperture'),
              _textField(_whiteBalance, 'White balance'),
              _textField(_exposureCompensation, 'Exposure compensation'),
              const SizedBox(height: 14),
              _sectionTitle(context, 'Color / Editing'),
              _textField(_preset, 'Preset name'),
              _textField(_contrast, 'Contrast'),
              _textField(_highlights, 'Highlights'),
              _textField(_shadows, 'Shadows'),
              _textField(_saturation, 'Saturation'),
              _textField(_temperature, 'Temperature'),
              _textField(_tint, 'Tint'),
              _textField(_grain, 'Grain'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  key: const Key('post-error'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('publish-post'),
                onPressed: _busy ? null : _publish,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish'),
              ),
              const SizedBox(height: 8),
              Text(
                'Camera settings are optional. JPEG, PNG and WebP up to 10 MB.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ShotbookColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ShotbookColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: ShotbookColors.secondary),
    ),
  );
}
