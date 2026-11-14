import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';

/// How many poses one run of the screen walks through.
const maxPoseSequence = 5;

/// The photos the pose screen walks through: [photoId] first, then other
/// photos of the same category that have pose notes, at most [limit].
List<PhotoReference> poseSequence(
  List<PhotoReference> catalog,
  String photoId, {
  int limit = maxPoseSequence,
}) {
  final matches = catalog.where((photo) => photo.id == photoId);
  if (matches.isEmpty) return const [];
  final current = matches.first;
  return [
    current,
    ...catalog.where(
      (photo) =>
          photo.id != current.id &&
          photo.category == current.category &&
          photo.poseData.isNotEmpty &&
          !photo.isHidden,
    ),
  ].take(limit).toList();
}

/// "Show pose" (Penpot "8 · Show pose"): big, readable pose notes to show
/// across the room, one photo at a time.
class ShowPoseScreen extends ConsumerStatefulWidget {
  const ShowPoseScreen({required this.photoId, super.key});

  final String photoId;

  @override
  ConsumerState<ShowPoseScreen> createState() => _ShowPoseScreenState();
}

class _ShowPoseScreenState extends ConsumerState<ShowPoseScreen> {
  int _index = 0;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/photos/${widget.photoId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    if (catalogState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final catalog = catalogState.asData?.value ?? seedPhotoReferences;
    final sequence = poseSequence(catalog, widget.photoId);
    final closeButton = IconButton(
      key: const Key('pose-close'),
      tooltip: context.tr('Close'),
      onPressed: _close,
      icon: const Icon(Icons.close, size: 24),
    );
    if (sequence.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: closeButton),
        body: Center(
          child: Text(context.tr('This photo is not in the catalog.')),
        ),
      );
    }

    final index = _index.clamp(0, sequence.length - 1);
    final photo = sequence[index];
    final last = index == sequence.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  closeButton,
                  const Spacer(),
                  Text(
                    context.tr('Pose {i} / {n}', {
                      'i': '${index + 1}',
                      'n': '${sequence.length}',
                    }).toUpperCase(),
                    key: const Key('pose-counter'),
                    style: ShotbookText.data.copyWith(
                      fontSize: 12,
                      color: ShotbookColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: _PoseView(key: ValueKey(photo.id), photo: photo),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(
                      'Show this screen to the person you are photographing',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: ShotbookColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 17),
                  FilledButton(
                    key: const Key('pose-next'),
                    onPressed: last
                        ? _close
                        : () => setState(() => _index = index + 1),
                    child: Text(
                      last ? context.tr('Done') : context.tr('Next pose'),
                    ),
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

/// The photo card and the pose notes of one photo.
class _PoseView extends StatelessWidget {
  const _PoseView({required this.photo, super.key});

  final PhotoReference photo;

  @override
  Widget build(BuildContext context) {
    final entries = photo.poseData.entries.toList();
    if (entries.isEmpty) {
      // Nothing to read out: the photo itself is the reference.
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: _PoseCard(photo: photo),
      );
    }
    final maxCardHeight = MediaQuery.sizeOf(context).height * 0.36;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 40;
        // Penpot: 320×236. Taller photos get more room so a full-length
        // pose is not cut off, but the card never takes more than 36 % of
        // the screen height (landscape, tablets): the notes stay in view.
        final minHeight = math.min(width * 236 / 320, maxCardHeight);
        final height = (width / photo.imageAspectRatio)
            .clamp(minHeight, maxCardHeight)
            .toDouble();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          children: [
            SizedBox(
              height: height,
              child: _PoseCard(photo: photo),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < entries.length; i++)
              _PoseEntry(
                label: context.tr(entries[i].key),
                value: entries[i].value,
                ruled: i < entries.length - 1,
              ),
          ],
        );
      },
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({required this.photo});

  final PhotoReference photo;

  @override
  Widget build(BuildContext context) => ClipRRect(
    key: const Key('pose-photo'),
    borderRadius: shotbookCardRadius,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: ShotbookColors.placeholder,
          child: PhotoReferenceImage(photo: photo),
        ),
        const ViewfinderTicks(inset: 8, length: 14),
      ],
    ),
  );
}

/// Accent mono label over big text, 1 px rule under all but the last.
class _PoseEntry extends StatelessWidget {
  const _PoseEntry({
    required this.label,
    required this.value,
    required this.ruled,
  });

  final String label;
  final String value;
  final bool ruled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: ruled
        ? const BoxDecoration(
            border: Border(bottom: BorderSide(color: ShotbookColors.border)),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: ShotbookText.kicker),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: shotbookBodyFont,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.15,
            color: ShotbookColors.primary,
          ),
        ),
      ],
    ),
  );
}
