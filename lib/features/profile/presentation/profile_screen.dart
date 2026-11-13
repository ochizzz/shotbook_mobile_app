import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../l10n/language_picker.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/image_prep.dart';
import '../../../shared/services/supabase_providers.dart';
import '../../../shared/widgets/photo_actions_sheet.dart';
import '../../safety/presentation/safety_actions.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../auth/application/auth_providers.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/domain/photo_reference.dart';
import '../../feed/application/feed_providers.dart';
import '../../feed/data/image_upload_validation.dart';
import '../../saved/application/saved_photo_provider.dart';
import '../application/profile_providers.dart';
import '../domain/shotbook_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({this.profileId, super.key});

  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final targetId = profileId ?? user?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileId == null
              ? context.tr('Profile')
              : context.tr('Photographer'),
        ),
        actions: [
          if (targetId != null && targetId == user?.id)
            IconButton(
              key: const Key('sign-out'),
              tooltip: context.tr('Sign out'),
              onPressed: () async {
                await ref.read(authRepositoryProvider)?.signOut();
                ref.invalidate(authStateProvider);
              },
              icon: const Icon(Icons.logout),
            ),
          if (targetId != null && targetId == user?.id)
            IconButton(
              key: const Key('open-settings'),
              tooltip: context.tr('Settings'),
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          if (targetId != null && targetId != user?.id)
            PopupMenuButton<String>(
              key: const Key('profile-menu'),
              onSelected: (value) async {
                final name =
                    ref
                        .read(profileProvider(targetId))
                        .asData
                        ?.value
                        ?.displayName ??
                    context.tr('this author');
                if (value == 'report') {
                  await showReportSheet(context, ref, userId: targetId);
                } else if (value == 'block') {
                  final blocked = await confirmAndBlock(
                    context,
                    ref,
                    userId: targetId,
                    name: name,
                  );
                  if (blocked && context.mounted) context.pop();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: Text(context.tr('Report user')),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Text(context.tr('Block user')),
                ),
              ],
            ),
        ],
      ),
      body: targetId == null
          ? _SignedOutProfile(supabaseReady: ref.watch(supabaseReadyProvider))
          : _ProfileContent(userId: targetId, isOwn: targetId == user?.id),
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile({required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline,
            size: 30,
            color: ShotbookColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            supabaseReady
                ? context.tr('Sign in to open your profile')
                : context.tr('Your profile starts with an account'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            supabaseReady
                ? context.tr(
                    'See your posts, saved photos and presets in one place.',
                  )
                : context.tr(
                    'Add Supabase settings to enable accounts and community features.',
                  ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ShotbookColors.secondary),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.push('/auth'),
            child: Text(context.tr('Sign in or create account')),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('Settings'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const LanguageSettingsTile(),
          const _MoreSettingsTile(),
        ],
      ),
    ),
  );
}

class _MoreSettingsTile extends StatelessWidget {
  const _MoreSettingsTile();

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('more-settings'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.settings_outlined),
    title: Text(context.tr('Privacy, rules and account')),
    trailing: const Icon(Icons.arrow_forward_ios, size: 15),
    onTap: () => context.push('/settings'),
  );
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.userId, required this.isOwn});

  final String userId;
  final bool isOwn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(userId));
    final postsState = ref.watch(profilePostsProvider(userId));
    final savedState = ref.watch(savedPhotoIdsProvider);
    final presetsState = ref.watch(profilePresetsProvider(userId));
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _ProfileError(onRetry: () => ref.invalidate(profileProvider(userId))),
      data: (profile) {
        if (profile == null) {
          return _ProfileError(
            onRetry: () => ref.invalidate(profileProvider(userId)),
          );
        }
        final posts = postsState.asData?.value ?? const <PhotoReference>[];
        final savedIds = savedState.asData?.value ?? const <String>{};
        final catalog = catalogState.asData?.value ?? const <PhotoReference>[];
        final saved = catalog
            .where(
              (photo) =>
                  savedIds.contains(photo.id) ||
                  (photo.remoteId != null && savedIds.contains(photo.remoteId)),
            )
            .toList();
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: ShotbookColors.surface,
                          backgroundImage: profile.avatarUrl == null
                              ? null
                              : NetworkImage(profile.avatarUrl!),
                          child: profile.avatarUrl == null
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '@${profile.username}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: ShotbookColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        if (isOwn)
                          IconButton(
                            key: const Key('edit-profile'),
                            tooltip: context.tr('Edit profile'),
                            onPressed: () =>
                                _showEditSheet(context, ref, profile),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                      ],
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(profile.bio),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Count(label: context.tr('Posts'), count: posts.length),
                        const SizedBox(width: 22),
                        _Count(
                          label: context.tr('Saved'),
                          count: savedIds.length,
                        ),
                      ],
                    ),
                    if (isOwn) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('Settings'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const LanguageSettingsTile(),
                      const _MoreSettingsTile(),
                    ],
                  ],
                ),
              ),
              TabBar(
                tabs: isOwn
                    ? [
                        Tab(text: context.tr('My Posts')),
                        Tab(text: context.tr('Saved')),
                        Tab(text: context.tr('My Presets')),
                      ]
                    : [Tab(text: context.tr('Posts'))],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    postsState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => _InlineRetry(
                        onRetry: () =>
                            ref.invalidate(profilePostsProvider(userId)),
                      ),
                      data: (items) => items.isEmpty
                          ? _EmptyTab(
                              message: context.tr(
                                'Your posts will appear here.',
                              ),
                            )
                          : _ProfilePhotoGrid(
                              photos: items,
                              onDelete: isOwn
                                  ? (photo) => _deletePost(context, ref, photo)
                                  : null,
                            ),
                    ),
                    if (isOwn)
                      savedState.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => _InlineRetry(
                          onRetry: () => ref.invalidate(savedPhotoIdsProvider),
                        ),
                        data: (_) => catalogState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => _InlineRetry(
                            onRetry: () =>
                                ref.invalidate(photoCatalogSourceProvider),
                          ),
                          data: (_) => saved.isEmpty
                              ? _EmptyTab(
                                  message: context.tr(
                                    'Save a photo and it will be waiting here.',
                                  ),
                                )
                              : _ProfilePhotoGrid(photos: saved),
                        ),
                      ),
                    if (isOwn)
                      presetsState.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => _InlineRetry(
                          onRetry: () =>
                              ref.invalidate(profilePresetsProvider(userId)),
                        ),
                        data: (items) => items.isEmpty
                            ? _EmptyTab(
                                message: context.tr(
                                  'Presets from your posts will appear here.',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  24,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final preset = items[index];
                                  final details = Map<String, String>.from(
                                    preset.settings,
                                  )..remove('Preset');
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.tune),
                                    title: Text(preset.name),
                                    subtitle: Text(
                                      details.entries
                                          .map(
                                            (entry) =>
                                                '${context.tr(entry.key)}: ${entry.value}',
                                          )
                                          .join(' · '),
                                    ),
                                    trailing: Text('${preset.photoCount}'),
                                  );
                                },
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost(
    BuildContext context,
    WidgetRef ref,
    PhotoReference photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete this post?')),
        content: Text(context.tr('The photo will be removed from the feed.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(feedRepositoryProvider)!.deletePost(photo);
      ref.invalidate(profilePostsProvider(userId));
      ref.invalidate(feedPostsProvider);
      ref.invalidate(photoCatalogSourceProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr(error.toString()))));
      }
    }
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    ShotbookProfile profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditProfileSheet(profile: profile),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final ShotbookProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _username = TextEditingController(text: widget.profile.username);
  late final _displayName = TextEditingController(
    text: widget.profile.displayName,
  );
  late final _bio = TextEditingController(text: widget.profile.bio);
  final _picker = ImagePicker();
  XFile? _avatar;
  Uint8List? _avatarBytes;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _chooseAvatar() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final original = await file.readAsBytes();
      ImageUploadValidation.validate(file.name, original);
      final bytes = await prepareImageForUpload(original, maxSide: 512);
      const mime = 'image/jpeg';
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Avatar images must be 5 MB or smaller.');
      }
      if (!mounted) return;
      setState(() {
        _avatar = file;
        _avatarBytes = Uint8List.fromList(bytes);
        _avatarMime = mime;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = context.tr(
            error.toString().replaceFirst('FormatException: ', ''),
          ),
        );
      }
    }
  }

  String? _avatarMime;

  Future<void> _save() async {
    if (_username.text.trim().length < 3 || _displayName.text.trim().isEmpty) {
      setState(
        () => _error = context.tr(
          'Enter a display name and a username with at least 3 characters.',
        ),
      );
      return;
    }
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (client == null || user == null) {
      setState(
        () => _error = context.tr('Sign in again to edit your profile.'),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      if (_avatar != null && _avatarBytes != null && _avatarMime != null) {
        final extension = _avatarMime == 'image/jpeg'
            ? 'jpg'
            : _avatarMime!.split('/').last;
        final path = '${user.id}/avatar.$extension';
        await client.storage
            .from('avatars')
            .uploadBinary(
              path,
              _avatarBytes!,
              fileOptions: FileOptions(contentType: _avatarMime, upsert: true),
            );
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      }
      await ref
          .read(profileRepositoryProvider)!
          .updateProfile(
            userId: user.id,
            username: _username.text,
            displayName: _displayName.text,
            bio: _bio.text,
            avatarUrl: avatarUrl,
          );
      ref.invalidate(profileProvider(user.id));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = context.tr(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Edit profile'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Center(
            child: InkWell(
              onTap: _busy ? null : _chooseAvatar,
              child: CircleAvatar(
                radius: 38,
                backgroundColor: ShotbookColors.surface,
                backgroundImage: _avatarBytes != null
                    ? MemoryImage(_avatarBytes!)
                    : widget.profile.avatarUrl == null
                    ? null
                    : NetworkImage(widget.profile.avatarUrl!),
                child: _avatarBytes == null && widget.profile.avatarUrl == null
                    ? const Icon(Icons.add_a_photo_outlined)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _displayName,
            decoration: InputDecoration(labelText: context.tr('Display name')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _username,
            decoration: InputDecoration(labelText: context.tr('Username')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.tr('Bio')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(
              _busy ? context.tr('Saving…') : context.tr('Save changes'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfilePhotoGrid extends StatelessWidget {
  const _ProfilePhotoGrid({required this.photos, this.onDelete});

  final List<PhotoReference> photos;

  /// Set for the owner's own posts; adds "Delete post" to the long-press menu.
  final ValueChanged<PhotoReference>? onDelete;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: photos.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.8,
    ),
    itemBuilder: (context, index) {
      final photo = photos[index];
      return ClipRRect(
        borderRadius: shotbookBorderRadius,
        child: Material(
          color: ShotbookColors.card,
          child: InkWell(
            key: Key('profile-photo-${photo.id}'),
            onTap: () => context.push('/photos/${photo.id}'),
            onLongPress: () => showPhotoActions(
              context,
              photo: photo,
              extraActions: [
                if (onDelete != null)
                  PhotoSheetAction(
                    key: Key('delete-post-${photo.id}'),
                    icon: Icons.delete_outline,
                    label: context.tr('Delete post'),
                    onSelected: () => onDelete!(photo),
                  ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoReferenceImage(photo: photo, thumbnail: true),
                if (photo.isHidden)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Tooltip(
                      message: context.tr('Hidden after reports, under review'),
                      child: const Icon(
                        Icons.visibility_off_outlined,
                        size: 18,
                        color: ShotbookColors.primary,
                        shadows: [Shadow(blurRadius: 6)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('$count', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(width: 5),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: ShotbookColors.secondary),
      ),
    ],
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('Could not load this profile.')),
        TextButton(onPressed: onRetry, child: Text(context.tr('Try again'))),
      ],
    ),
  );
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onRetry,
      child: Text(context.tr('Could not load. Try again.')),
    ),
  );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: ShotbookColors.secondary),
      ),
    ),
  );
}
