import 'package:flutter/widgets.dart';

import '../../../l10n/tr.dart';

/// Plural categories used here: English has one/many, Russian one/few/many
/// ("1 день", "3 дня", "5 дней").
enum PluralForm { one, few, many }

/// Russian plural category of [n].
PluralForm russianPluralForm(int n) {
  final mod10 = n.abs() % 10, mod100 = n.abs() % 100;
  if (mod10 == 1 && mod100 != 11) return PluralForm.one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return PluralForm.few;
  }
  return PluralForm.many;
}

/// Plural category of [n] in the interface language. English never returns
/// [PluralForm.few], so the "few" keys below only ever show in Russian.
PluralForm pluralForm(BuildContext context, int n) => context.isRussian
    ? russianPluralForm(n)
    : (n == 1 ? PluralForm.one : PluralForm.many);

/// "CHALLENGE · 5 DAYS" / "ЧЕЛЛЕНДЖ · 5 ДНЕЙ".
String challengeKicker(BuildContext context, int days) {
  final args = {'n': '$days'};
  final text = switch (pluralForm(context, days)) {
    PluralForm.one => context.tr('Challenge · {n} day', args),
    PluralForm.few => context.tr('Challenge · {n} days (2–4)', args),
    PluralForm.many => context.tr('Challenge · {n} days', args),
  };
  return text.toUpperCase();
}

/// "128 participant photos" / "128 фото участников"; "Be the first" for 0.
String participantPhotos(BuildContext context, int count) {
  if (count <= 0) return context.tr('Be the first');
  final args = {'n': '$count'};
  return pluralForm(context, count) == PluralForm.one
      ? context.tr('{n} participant photo', args)
      : context.tr('{n} participant photos', args);
}
