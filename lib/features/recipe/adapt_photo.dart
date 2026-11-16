import '../camera/domain/camera_device.dart';
import '../discover/domain/photo_reference.dart';
import 'phone_profile.dart';
import 'recipe_engine.dart';

/// [photo] with its camera settings worked out for [phone] from the
/// original shot. Photos without original data are returned unchanged.
PhotoReference adaptToPhone(
  PhotoReference photo,
  String phoneId, {
  required bool russian,
}) {
  final original = photo.original;
  if (original == null) return photo;
  final profile = phoneProfile(phoneId);
  final r = adaptShot(original, profile, category: photo.category);
  final device = cameraDevices.where((d) => d.id == profile.id).firstOrNull;
  final deviceName = profile.id == fallbackPhoneId || device == null
      ? (russian ? 'Ваш смартфон' : 'Your phone')
      : '${device.brand} ${device.model}';
  final zoom = formatZoom(r.zoom, russian: russian);
  final lens = lensName(r.lens.kind, russian: russian);
  final mm = (r.zoom * profile.main.mm).round();
  final tripod = r.notes.contains(RecipeNote.tripod);
  final shutter = formatSeconds(r.seconds);
  return photo.copyWith(
    deviceId: profile.id,
    device: deviceName,
    camera: russian ? 'Режим Pro, $lens, $zoom' : 'Pro mode, $lens, $zoom',
    focalLength: russian ? '$mm мм ($zoom)' : '$mm mm ($zoom)',
    iso: '${r.iso}',
    shutterSpeed: russian
        ? '$shutter с${tripod ? ', со штатива или опоры' : ''}'
        : '$shutter s${tripod ? ', on a tripod or support' : ''}',
    aperture: russian
        ? 'f/${_num(r.lens.aperture)} (фикс.)'
        : 'f/${_num(r.lens.aperture)} (fixed)',
    phoneNotes: [
      for (final note in RecipeNote.values)
        if (r.notes.contains(note))
          noteText(note, r, original, profile, russian: russian),
    ],
  );
}

String _num(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : '${(v * 100).round() / 100}';

/// "3×", "1,5×" (RU) / "1.5×".
String formatZoom(double zoom, {required bool russian}) {
  final text = zoom == zoom.roundToDouble()
      ? '${zoom.round()}'
      : zoom.toStringAsFixed(1);
  return '${russian ? text.replaceAll('.', ',') : text}×';
}

String lensName(LensKind kind, {required bool russian}) => switch (kind) {
  LensKind.ultraWide => russian ? 'сверхширокий' : 'ultra-wide',
  LensKind.main => russian ? 'основной объектив' : 'main lens',
  LensKind.tele => russian ? 'телеобъектив' : 'telephoto',
  LensKind.periscope => russian ? 'перископ' : 'periscope',
};

String noteText(
  RecipeNote note,
  PhoneRecipe r,
  OriginalShot original,
  PhoneProfile phone, {
  required bool russian,
}) {
  final need = formatZoom(
    double.parse((original.equivMm / phone.main.mm).toStringAsFixed(1)),
    russian: russian,
  );
  final max = formatZoom(
    double.parse(phone.maxZoom.toStringAsFixed(1)),
    russian: russian,
  );
  final ev = r.evShortfall.abs().toStringAsFixed(1);
  final evText = russian ? ev.replaceAll('.', ',') : ev;
  return switch (note) {
    RecipeNote.zoomShort =>
      russian
          ? 'Для такого кадра нужен зум $need, у телефона максимум $max — подойдите ближе или обрежьте кадр потом.'
          : 'This shot needs $need zoom and the phone tops out at $max: step closer or crop later.',
    RecipeNote.digitalCrop =>
      russian
          ? 'Это цифровой зум дальше самого длинного объектива: деталей будет меньше. Если можно, подойдите ближе.'
          : 'That is digital zoom past the longest lens, so some detail is lost. Step closer if you can.',
    RecipeNote.zoomWide =>
      russian
          ? 'Оригинал снят шире, чем ваш самый широкий объектив, — отойдите назад.'
          : 'The original is wider than your widest lens: step back.',
    RecipeNote.portraitMode =>
      russian
          ? 'У оригинала фон размыт сильнее, чем может объектив телефона: включите режим «Портрет» или подойдите к объекту ближе, а фон оставьте подальше.'
          : 'The original background is blurrier than a phone lens can manage: use Portrait mode, or get closer to the subject with the background far behind.',
    RecipeNote.tripod =>
      russian
          ? 'Выдержка длиннее безопасной с рук — поставьте телефон на опору или штатив.'
          : 'The shutter is slower than is safe handheld: rest the phone on something or use a tripod.',
    RecipeNote.nightMode =>
      russian
          ? 'Даже на пределе телефона кадр выйдет темнее оригинала на $evText EV: включите ночной режим или добавьте света.'
          : 'Even at the phone\'s limits the shot comes out $evText EV darker: use Night mode or add light.',
    RecipeNote.tooBright =>
      russian
          ? 'Даже на минимальных ISO и выдержке будет светлее оригинала: уменьшите экспозицию на $evText EV.'
          : 'Even at the lowest ISO and fastest shutter it is brighter than the original: lower exposure by $evText EV.',
    RecipeNote.proLensOnly =>
      russian
          ? 'Этот объектив есть только у Pro-версий; на обычной модели снимайте с основной камеры и обрежьте кадр.'
          : 'Only the Pro models have this lens; on the base model use the main camera and crop.',
  };
}
