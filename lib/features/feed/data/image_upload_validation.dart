class ImageUploadValidation {
  static const maxBytes = 10 * 1024 * 1024;

  static String validate(String fileName, List<int> bytes) {
    if (bytes.isEmpty) throw const FormatException('The image file is empty.');
    if (bytes.length > maxBytes) {
      throw const FormatException('Images must be 10 MB or smaller.');
    }
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const FormatException('Choose a JPEG, PNG, or WebP image.'),
    };
    final hasSignature = switch (mimeType) {
      'image/jpeg' =>
        bytes.length >= 3 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff,
      'image/png' =>
        bytes.length >= 8 &&
            const [
              137,
              80,
              78,
              71,
              13,
              10,
              26,
              10,
            ].indexed.every((entry) => bytes[entry.$1] == entry.$2),
      'image/webp' =>
        bytes.length >= 12 &&
            String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
            String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP',
      _ => false,
    };
    if (!hasSignature) {
      throw const FormatException(
        'The file extension does not match a supported image.',
      );
    }
    return mimeType;
  }
}
