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

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map<String, String>((key, item) => MapEntry('$key', '$item'));
  }
}
