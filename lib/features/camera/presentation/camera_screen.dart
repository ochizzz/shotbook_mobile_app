import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/data/seed_photo_references.dart';
import '../domain/camera_device.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String _brand = 'All';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = [
      'All',
      ...cameraDevices.map((device) => device.brand).toSet(),
    ];
    final query = _search.text.trim().toLowerCase();
    final devices = cameraDevices.where((device) {
      final matchesBrand = _brand == 'All' || device.brand == _brand;
      final matchesQuery =
          query.isEmpty ||
          '${device.brand} ${device.model} ${device.year}'
              .toLowerCase()
              .contains(query);
      return matchesBrand && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Camera guide'))),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'Find a better frame with the camera you have.',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: context.tr('Search a phone model'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: brands.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) => ChoiceChip(
                          label: Text(context.tr(brands[index])),
                          selected: _brand == brands[index],
                          onSelected: (_) =>
                              setState(() => _brand = brands[index]),
                          showCheckmark: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(
                        'Phones from 2022 to today · guidance only, not camera controls. Specs are approximate; check the maker for exact figures.',
                      ),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
            if (devices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(context.tr('No matching phone models.')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: devices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      color: ShotbookColors.surface,
                      child: ListTile(
                        key: Key('camera-device-${device.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.camera_alt_outlined),
                        title: Text(context.tr(device.model)),
                        subtitle: Text(
                          device.year == 0
                              ? context.tr(device.brand)
                              : '${context.tr(device.brand)} · ${device.year}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                        onTap: () => context.push('/camera/${device.id}'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CameraDeviceScreen extends StatelessWidget {
  const CameraDeviceScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final matches = cameraDevices.where((device) => device.id == deviceId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(context.tr('This device is not in the guide.')),
        ),
      );
    }
    final device = matches.first;
    final examples = seedPhotoReferences
        .where(
          (photo) => photo.category == 'Portrait' || photo.category == 'Street',
        )
        .take(4)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(device.model))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Text(
            context.tr(device.brand).toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: ShotbookColors.secondary, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(device.model),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          _CameraSection(
            title: context.tr('Cameras'),
            children: device.camerasFor(russian: context.isRussian),
          ),
          _CameraSection(
            title: context.tr('Shooting tips'),
            children: device.recommendationsFor(russian: context.isRussian),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('Starting points'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...device
              .sampleSettingsFor(russian: context.isRussian)
              .entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr(entry.key)),
                  subtitle: Text(entry.value),
                ),
              ),
          const SizedBox(height: 20),
          Text(
            context.tr('Photo examples'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: examples.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = examples[index];
                return SizedBox(
                  width: 124,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: shotbookBorderRadius,
                          child: PhotoReferenceImage(photo: photo),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        photo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraSection extends StatelessWidget {
  const _CameraSection({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: ShotbookColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
