class PhotoReference {
  const PhotoReference({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.sourcePage,
    required this.credit,
    required this.license,
    this.sourceType = 'curated',
    this.authorId,
    this.storagePath,
    this.createdAt,
    this.remoteId,
    this.poseData = const {},
    this.device,
    this.camera,
    this.focalLength,
    this.iso,
    this.shutterSpeed,
    this.aperture,
    this.whiteBalance,
    this.exposureCompensation,
    this.presetName,
    this.editingData = const {},
    this.imageAspectRatio = 0.82,
    this.viewCount = 0,
    this.thumbUrl,
    this.deviceId,
    this.creatorUrl,
    this.licenseUrl,
    this.translations = const {},
    this.isHidden = false,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String sourcePage;
  final String credit;
  final String license;
  final String sourceType;
  final String? authorId;
  final String? storagePath;
  final DateTime? createdAt;
  final String? remoteId;
  final Map<String, String> poseData;
  final String? device;
  final String? camera;
  final String? focalLength;
  final String? iso;
  final String? shutterSpeed;
  final String? aperture;
  final String? whiteBalance;
  final String? exposureCompensation;
  final String? presetName;
  final Map<String, String> editingData;
  final double imageAspectRatio;

  /// How many times the photo was opened. Shown instead of likes.
  final int viewCount;

  /// Small image for grids (~640 px). Falls back to [imageUrl].
  final String? thumbUrl;

  /// Phone from the camera guide this recipe is written for.
  final String? deviceId;
  final String? creatorUrl;
  final String? licenseUrl;

  /// Other-language versions, e.g. {'en': {'title': …, 'pose_data': {…}}}.
  /// The base fields are Russian for the curated catalog.
  final Map<String, dynamic> translations;

  /// Hidden by moderation; only its author still sees it.
  final bool isHidden;

  String get gridImageUrl =>
      thumbUrl != null && thumbUrl!.isNotEmpty ? thumbUrl! : imageUrl;

  /// This photo with text in [languageCode] when a translation exists.
  PhotoReference localized(String languageCode) {
    final t = translations[languageCode];
    if (t is! Map) return this;
    String? text(String key, String? fallback) {
      final value = t[key];
      return value is String && value.trim().isNotEmpty ? value : fallback;
    }

    Map<String, String> map(String key, Map<String, String> fallback) {
      final value = t[key];
      return value is Map ? _stringMap(value) : fallback;
    }

    return PhotoReference(
      id: id,
      title: text('title', title)!,
      description: text('description', description)!,
      imageUrl: imageUrl,
      category: category,
      sourcePage: sourcePage,
      credit: credit,
      license: license,
      sourceType: sourceType,
      authorId: authorId,
      storagePath: storagePath,
      createdAt: createdAt,
      remoteId: remoteId,
      poseData: map('pose_data', poseData),
      device: text('device', device),
      camera: text('camera', camera),
      focalLength: text('focal_length', focalLength),
      iso: text('iso', iso),
      shutterSpeed: text('shutter_speed', shutterSpeed),
      aperture: text('aperture', aperture),
      whiteBalance: text('white_balance', whiteBalance),
      exposureCompensation: text('exposure_compensation', exposureCompensation),
      presetName: null,
      editingData: map('editing_data', editingData),
      imageAspectRatio: imageAspectRatio,
      viewCount: viewCount,
      thumbUrl: thumbUrl,
      deviceId: deviceId,
      creatorUrl: creatorUrl,
      licenseUrl: licenseUrl,
      translations: translations,
      isHidden: isHidden,
    );
  }

  PhotoReference copyWith({int? viewCount}) => PhotoReference(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    category: category,
    sourcePage: sourcePage,
    credit: credit,
    license: license,
    sourceType: sourceType,
    authorId: authorId,
    storagePath: storagePath,
    createdAt: createdAt,
    remoteId: remoteId,
    poseData: poseData,
    device: device,
    camera: camera,
    focalLength: focalLength,
    iso: iso,
    shutterSpeed: shutterSpeed,
    aperture: aperture,
    whiteBalance: whiteBalance,
    exposureCompensation: exposureCompensation,
    presetName: presetName,
    editingData: editingData,
    imageAspectRatio: imageAspectRatio,
    viewCount: viewCount ?? this.viewCount,
    thumbUrl: thumbUrl,
    deviceId: deviceId,
    creatorUrl: creatorUrl,
    licenseUrl: licenseUrl,
    translations: translations,
    isHidden: isHidden,
  );

  factory PhotoReference.fromJson(Map<String, dynamic> json) {
    return PhotoReference(
      id: json['legacy_id'] as String? ?? json['id'] as String,
      remoteId: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled frame',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? 'Lifestyle',
      sourcePage: json['source_page'] as String? ?? '',
      credit: json['credit'] as String? ?? 'SHOTBOOK community',
      license: json['license'] as String? ?? 'User submitted',
      sourceType: json['source_type'] as String? ?? 'community',
      authorId: json['author_id'] as String?,
      storagePath: json['storage_path'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      device: json['device'] as String?,
      camera: json['camera'] as String?,
      focalLength: json['focal_length'] as String?,
      iso: json['iso']?.toString(),
      shutterSpeed: json['shutter_speed'] as String?,
      aperture: json['aperture'] as String?,
      whiteBalance: json['white_balance'] as String?,
      exposureCompensation: json['exposure_compensation'] as String?,
      poseData: _stringMap(json['pose_data']),
      presetName: _stringMap(json['editing_data'])['Preset'],
      editingData: _stringMap(json['editing_data']),
      viewCount: (json['views_count'] as num?)?.toInt() ?? 0,
      thumbUrl: json['thumb_url'] as String?,
      deviceId: json['device_id'] as String?,
      creatorUrl: json['creator_url'] as String?,
      licenseUrl: json['license_url'] as String?,
      translations: json['translations'] is Map
          ? Map<String, dynamic>.from(json['translations'] as Map)
          : const {},
      isHidden: json['is_hidden'] as bool? ?? false,
      imageAspectRatio: _aspectRatio(json['aspect_ratio']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': remoteId ?? id,
    'legacy_id': id,
    'title': title,
    'description': description,
    'image_url': imageUrl,
    'source_page': sourcePage,
    'credit': credit,
    'license': license,
    'category': category,
    'source_type': sourceType,
    'author_id': authorId,
    'storage_path': storagePath,
    'device': device,
    'camera': camera,
    'focal_length': focalLength,
    'iso': iso,
    'shutter_speed': shutterSpeed,
    'aperture': aperture,
    'white_balance': whiteBalance,
    'exposure_compensation': exposureCompensation,
    'pose_data': poseData,
    'editing_data': {
      ...editingData,
      if (presetName != null && presetName!.trim().isNotEmpty)
        'Preset': presetName!,
    },
    'created_at': createdAt?.toIso8601String(),
    'views_count': viewCount,
    'thumb_url': thumbUrl,
    'aspect_ratio': imageAspectRatio,
    'device_id': deviceId,
    'creator_url': creatorUrl,
    'license_url': licenseUrl,
    'translations': translations,
  };

  Map<String, String> get cameraSettings => {
    if (_hasValue(device)) 'Device': device!,
    if (_hasValue(camera)) 'Camera / Lens': camera!,
    if (_hasValue(focalLength)) 'Focal length': focalLength!,
    if (_hasValue(iso)) 'ISO': iso!,
    if (_hasValue(shutterSpeed)) 'Shutter speed': shutterSpeed!,
    if (_hasValue(aperture)) 'Aperture': aperture!,
    if (_hasValue(whiteBalance)) 'White balance': whiteBalance!,
    if (_hasValue(exposureCompensation))
      'Exposure compensation': exposureCompensation!,
  };

  Map<String, String> get editingSettings => {
    if (_hasValue(presetName)) 'Preset': presetName!,
    ...editingData,
  };

  static double _aspectRatio(Object? value) {
    final ratio = (value as num?)?.toDouble();
    // Keep extreme panoramas or strips from breaking the grid.
    if (ratio == null || ratio <= 0) return 0.82;
    return ratio.clamp(0.5, 1.8);
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map<String, String>((key, item) => MapEntry('$key', '$item'));
  }
}
