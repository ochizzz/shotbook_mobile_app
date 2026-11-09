# SHOTBOOK

SHOTBOOK is an Android-first photography reference and community app built with Flutter. The app works as a local demo without a Supabase project; accounts, feed, publishing, likes, and remote saves turn on when public Supabase client settings are supplied at build/run time.

## Features

- Discover: 21 curated photography references across seven categories, search, category filters, detail metadata, and locally saved photos.
- Camera: device recommendations for Samsung Galaxy S23 Ultra, Apple iPhone 15 Pro, Google Pixel 8 Pro, Xiaomi 14 Ultra, and other phones. This is a guide, not a camera controller.
- Accounts: email sign-up, sign-in, password reset deep link, profile editing, avatar upload, and sign-out.
- Community: newest-first feed, profile links, likes, saved posts, image upload, camera and editing notes, post deletion, and personal presets.
- Supabase: SQL schema and curated seed migrations, RLS policies, and `photos` / `avatars` Storage buckets.
- Uploads accept JPEG, PNG, and WebP after checking extension, file signature, and size (10 MiB for photos, 5 MiB for avatars).

## Requirements

- Flutter 3.47.9 stable (Dart 3.13.7) or a compatible newer stable release.
- Android SDK, JDK 17, and an Android device or emulator.

## Run in demo mode

```powershell
flutter pub get
flutter run -d <android-device-id>
```

Without Supabase settings, the curated catalog and local saves work. Auth, community feed, likes, publishing, and remote synchronization display setup guidance and do not fake successful writes.

## Configure Supabase

1. Create a Supabase project.
2. In the Supabase SQL Editor, run both files in `supabase/migrations/` in filename order. They create the tables, indexes, profile-on-sign-up trigger, RLS policies, public image buckets, and 21 curated catalog records.
3. In Authentication settings, enable email/password sign-in. Add this native redirect URL to the allowed redirect URLs: `com.shotbook.shotbook://login-callback`.
4. Use the project URL and its public anon/publishable client key. Pass them as Dart defines; never use a service-role key in the app:

```powershell
flutter run -d <android-device-id> `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-client-key>
```

```powershell
flutter build apk --debug --target-platform android-arm64 `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-client-key>
```

The Android manifest registers the password-reset callback scheme. If Supabase initialization fails, the app continues in local demo mode. With credentials configured, Supabase must be reachable and both migrations must have been applied for remote features to work.

## Verify and build

```powershell
flutter test
flutter analyze
flutter build apk --debug --target-platform android-arm64
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. A Supabase-configured APK embeds only the public client key supplied at build time; do not share a build configured with a project you do not control.

## Build a signed release APK

Release builds use the ignored `android/key.properties` file and an ignored keystore under `android/app/`. Never commit either file. Back up the keystore and its credentials securely; losing the signing key prevents updates signed with that key.

```powershell
flutter build apk --release --target-platform android-arm64 `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-client-key>
```

The signed release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Project map

```text
lib/
  app/                      theme, routes, shell
  core/widgets/             shared UI states
  features/
    auth/                   auth repository, sign-in and recovery
    camera/                 device recommendations
    discover/                catalog, filters, photo model
    feed/                   feed, uploads, likes, create post
    photo_detail/            reference and post metadata
    profile/                 profiles, saved, posts, presets
    saved/                  local and remote save state
  shared/                   Supabase configuration and image widgets
supabase/migrations/        schema, RLS, storage, curated seed data
test/                       Flutter unit and widget tests
tool/                       seed generator and environment-safe smoke check
docs/superpowers/           design and implementation plans
```

Curated image URLs, credits, licenses, and source pages are kept with the local catalog. Check each source file page before redistributing a modified catalog, especially when an image includes identifiable people, private property, or trademarks.
