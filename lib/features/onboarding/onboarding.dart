import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../l10n/language_picker.dart';
import '../../l10n/tr.dart';
import '../../shared/widgets/photo_reference_image.dart';
import '../discover/data/seed_photo_references.dart';
import '../discover/domain/photo_reference.dart';

const onboardingPreferenceKey = 'shotbook.onboarded';

/// True once the welcome screens were shown. `main` reads it from storage;
/// the default keeps tests and previews out of the welcome flow.
final initialOnboardingDoneProvider = Provider<bool>((ref) => true);

class OnboardingDoneNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialOnboardingDoneProvider);

  Future<void> complete() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingPreferenceKey, true);
    } catch (_) {
      // Shown again next launch if storage is unavailable; nothing breaks.
    }
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDoneNotifier, bool>(
  OnboardingDoneNotifier.new,
);

Future<bool> loadOnboardingDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingPreferenceKey) ?? false;
  } catch (_) {
    return true;
  }
}

class _Page {
  const _Page(this.category, this.title, this.body, this.icon);

  final String category;
  final String title;
  final String body;
  final IconData icon;
}

const _pages = [
  _Page(
    'Portrait',
    'Find your frame',
    '100 striking photos, each with settings to repeat it on a phone.',
    Icons.grid_view_outlined,
  ),
  _Page(
    'Night',
    'Hold for more',
    'Press and hold any photo to save it, open it or repeat the shot.',
    Icons.touch_app_outlined,
  ),
  _Page(
    'Street',
    'Repeat the shot',
    'The camera shows the reference as a see-through guide. Line it up and shoot.',
    Icons.filter_center_focus,
  ),
];

/// Three calm welcome screens on first launch, in the app's own style:
/// a full-bleed photo, a serif title, one line of text.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  late final List<PhotoReference> _photos = [
    for (final page in _pages)
      seedPhotoReferences.firstWhere(
        (photo) =>
            photo.category == page.category &&
            photo.imageAspectRatio < 0.9, // tall photos fill the screen
        orElse: () => seedPhotoReferences.first,
      ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index == _pages.length - 1) {
      ref.read(onboardingDoneProvider.notifier).complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: ShotbookColors.background,
      body: Stack(
        children: [
          PageView.builder(
            key: const Key('onboarding-pages'),
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                PhotoReferenceImage(photo: _photos[index]),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.35, 0.62, 1],
                      colors: [
                        Color(0x990E0E0E),
                        Color(0x000E0E0E),
                        Color(0xCC0E0E0E),
                        ShotbookColors.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SHOTBOOK',
                        style: textTheme.labelLarge?.copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        key: const Key('onboarding-language'),
                        tooltip: context.tr('Interface language'),
                        onPressed: () => showLanguageSheet(context, ref),
                        icon: const Icon(Icons.language, size: 20),
                      ),
                      if (!last)
                        TextButton(
                          key: const Key('onboarding-skip'),
                          onPressed: () => ref
                              .read(onboardingDoneProvider.notifier)
                              .complete(),
                          child: Text(context.tr('Skip')),
                        ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      key: ValueKey(_index),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_pages[_index].icon, size: 26),
                        const SizedBox(height: 14),
                        Text(
                          context.tr(_pages[_index].title),
                          style: textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr(_pages[_index].body),
                          style: textTheme.bodyLarge?.copyWith(
                            color: ShotbookColors.primary.withValues(
                              alpha: 0.86,
                            ),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 26 : 10,
                          height: 3,
                          color: i == _index
                              ? ShotbookColors.primary
                              : ShotbookColors.border,
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('onboarding-next'),
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(132, 48),
                        ),
                        child: Text(
                          last ? context.tr('Start') : context.tr('Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
