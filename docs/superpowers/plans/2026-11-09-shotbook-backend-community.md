# SHOTBOOK Backend and Community Plan

> **For agentic workers:** Execute inline with `superpowers:executing-plans`. Tasks use checkbox syntax; record test results as each task finishes.

**Goal:** Extend the installable SHOTBOOK Android app with optional real Supabase auth/data/storage, camera recommendations, user feed, publishing, likes, profiles, saved photos, and presets.

**Architecture:** Keep the existing seeded Discover catalog and device-local saves as the no-credentials demo path. Initialize Supabase only when both dart-defines are present, expose repositories through Riverpod, and keep user-facing actions honest about auth/network failures. Add SQL migrations with RLS and Storage policies; preserve the four-tab app shell and current darkroom visual system.

**Tech Stack:** Flutter/Dart, Riverpod, GoRouter, Supabase Flutter, image_picker, SharedPreferences, Flutter tests, PostgreSQL migrations.

**Spec:** User-provided SHOTBOOK MVP brief in conversation; Stage 1 design at `docs/superpowers/specs/2026-11-09-shotbook-stage-1-design.md`.

## Global Constraints

- Android-first Flutter app; keep the app portable to iOS.
- Supabase URL and anon/publishable key are supplied only as `--dart-define` values; never include service-role secrets.
- Missing Supabase configuration means local demo catalog and local saves; never claim that remote auth or publishing succeeded.
- Anonymous users may browse Discover and detail pages; publishing, liking, and remote saved sync require auth.
- Camera tab is a device recommendation catalog, not physical camera control.
- Images accept JPEG, PNG, and WebP only, with a 10 MiB upload limit.
- RLS protects profile writes, community photo writes/deletes, likes, saved rows, and user-owned Storage objects.

## Review Focus

- Empty/malformed backend configuration must select demo mode without a startup crash (configuration test).
- Unauthenticated publish/like/save actions must route to auth and preserve useful error feedback (widget tests).
- Missing optional EXIF fields must remain absent instead of appearing blank (model/detail tests).
- Invalid or oversized image uploads must be rejected before Storage writes (validation tests).
- RLS must block cross-user profile, post, like, saved-row, and object mutations (SQL policy review and migration tests where tooling allows).

---

### Task 1: Supabase configuration, schema, and auth

**Files:** `lib/main.dart`, new `lib/shared/services/supabase_config.dart`, auth feature files, `supabase/migrations/*.sql`, `README.md`, focused tests.

**Interfaces:** `supabaseConfigProvider`, `supabaseReadyProvider`, `authStateProvider`, and an auth repository with sign-up, sign-in, reset, sign-out, and profile update. Supabase initialization is optional and happens before `runApp` only for valid URL/key values.

- [x] Add config tests covering demo, valid client key, `sb_secret_`, and legacy service-role JWT keys; config behavior also passes the Dart smoke check. Flutter widget execution is currently blocked by Windows Application Control before tests run.
- [x] Add migrations for profiles/photos/saved_photos/likes, indexes/uniqueness, profile trigger, RLS policies, explicit least-privilege grants, and restricted future object defaults.
- [x] Add public-read `photos` and `avatars` Storage buckets with ownership policies.
- [x] Add email sign-up/login/password reset/logout UI and profile creation/editing.
- [x] Document required Supabase setup/defines. Live Supabase auth and policy checks remain unavailable because no project credentials or local Supabase CLI/Docker/Postgres are configured.

### Task 2: Remote catalog and synchronized saved photos

**Files:** existing Discover and Saved data/domain/presentation, shared photo mapping, focused tests.

**Interfaces:** Photo JSON conversion; remote catalog provider with loading/error/retry states and seeded fallback when unconfigured; saved repository routes authenticated users to Supabase and anonymous users to SharedPreferences.

- [x] Add model round-trip and config fallback checks; existing local-save widget tests remain in the suite.
- [x] Implement catalog query and per-user saved-photo CRUD, including syncing locally saved UUID/legacy IDs after sign-in.
- [x] Keep Discover, detail, and Saved states consistent after errors and retries.
- [ ] Run focused and full Flutter test suites; blocked by Application Control denying `flutter_tester.exe`.

### Task 3: Camera recommendations and community workflow

**Files:** `lib/features/camera/`, `lib/features/feed/`, `lib/features/profile/`, `lib/features/auth/`, route/shell updates, focused tests.

**Interfaces:** Camera device catalog; feed repository for newest-first posts, likes, upload/create/delete; profile repository for public profile, own posts, saved photos, and presets.

- [x] Add camera navigation and image-upload validation tests. Feed auth and create-post validation have widget coverage; all Flutter test execution is blocked before tests start by Application Control.
- [x] Implement Samsung/Apple/Pixel/Xiaomi/Other recommendation screens with device lenses, guidance, settings, and example images.
- [x] Implement feed cards, author profiles, like/save toggles, pull-to-refresh, and empty/error/retry states.
- [x] Implement create-post form, image picker and signature/size validation, Storage upload, metadata fields, and post creation.
- [x] Implement profile editing, avatar upload, own-post deletion, Saved and My Presets sections, and logout.
- [ ] Run focused and full Flutter test suites; blocked by Application Control denying `flutter_tester.exe`.

### Task 4: Final verification and Android handoff

**Files:** README and plan verification records; no secrets or generated build files in source control.

- [ ] `flutter test` cannot launch `flutter_tester.exe` under the current Windows Application Control policy. `flutter analyze` passes and `dart run tool/verify_core.dart` passes.
- [x] Run `flutter build apk --debug --target-platform android-arm64`; `aapt` confirms package `com.shotbook.shotbook`, version `1.0.0`, min SDK 24, target/compile SDK 36, and arm64 native libraries.
- [x] Review Git status, migration policies, and setup documentation. No credentials, commits, or remote are configured; live backend behavior needs a Supabase project.
- [x] Independent read-only review found two security issues (broad default table privileges and modern secret-key acceptance); explicit least-privilege SQL grants/defaults and secret-key rejection were added, then re-reviewed without remaining Critical/Important findings.

