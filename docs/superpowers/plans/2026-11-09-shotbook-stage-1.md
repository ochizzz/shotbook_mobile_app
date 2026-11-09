# SHOTBOOK Stage 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a runnable Flutter Android app for browsing SHOTBOOK references, filtering/searching them, opening details, and saving references locally.

**Architecture:** Feature-based Flutter app with GoRouter shell navigation, Riverpod state, immutable reference models, a static seed repository, and a SharedPreferences-backed saved repository. Supabase and community workflows are explicitly deferred.

**Tech Stack:** Flutter, Dart, Material 3, flutter_riverpod, go_router, cached_network_image, shared_preferences, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-shotbook-stage-1-design.md`

## Global Constraints

- Primary platform is Android; architecture remains portable to iOS.
- Dark colors: background `#0E0E0E`, surface `#181818`, card `#202020`, primary `#FFFFFF`, secondary `#A0A0A0`, border `#303030`.
- Discover contains 2 columns and categories Portrait, Street, Full Body, Lifestyle, Couple, Car, Product.
- At least 20 seed photographs and at least five categories; unset metadata is omitted.
- No Supabase, auth, feed, publishing, likes, or physical camera control in this stage.
- Save state persists locally; image failures have an intentional fallback.

## Review Focus

- Empty or unmatched search/category combinations should show a useful empty state and reset action (Discover widget test).
- Images that fail or are offline should show a fallback without blocking the catalog (image tile widget test).
- Repeated save toggles should not duplicate IDs or desynchronize Saved/detail/card state (saved repository test).
- Unknown optional photo metadata should not render labels with blank values (photo detail widget test).
- Narrow Android viewport and long titles should remain scrollable without overflow (widget test at narrow logical size).

---

### Task 1: Flutter scaffold, theme, and shell navigation

**Files:**
- Create Flutter app scaffold in repository root.
- Create: `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/theme.dart`, `lib/main.dart`.
- Create: `lib/core/widgets/stage_placeholder.dart`.
- Test: `test/app_navigation_test.dart`.

**Interfaces:**
- Produces `ShotbookApp`, `appRouter`, `shotbookDarkTheme`, and four named shell destinations: Discover, Camera, Feed, Profile.

- [x] Write widget tests that verify all four navigation destinations render and deferred tabs explain their stage-one status.
- [x] Run `flutter test test/app_navigation_test.dart`; it failed because `lib/app/app.dart` did not exist.
- [x] Implement ProviderScope, Material 3 dark theme, GoRouter shell, and informative deferred-tab views.
- [x] Run the focused widget test and confirm it passes.

### Task 2: Catalog model, seed data, and filtering

**Files:**
- Create: `lib/features/discover/domain/photo_reference.dart`.
- Create: `lib/features/discover/data/seed_photo_references.dart`, `lib/features/discover/data/photo_catalog_repository.dart`.
- Create: `lib/features/discover/application/discover_providers.dart`.
- Test: `test/photo_catalog_repository_test.dart`.

**Interfaces:**
- `PhotoReference` stores required `id`, `title`, `description`, `imageUrl`, `category` and optional pose/camera/editing maps/fields.
- `photoCatalogProvider` returns seeded references; category and query filters are separate provider state.
- Produces at least 20 records spanning all seven categories.

- [x] Test seed count/category coverage and case-insensitive category/query filtering, including an unmatched query.
- [x] Run the focused test and confirm missing seed/filter behavior fails; corrected exact-count assertion to the spec's minimum of 20.
- [x] Implement immutable model, seed repository, and filter providers.
- [x] Run the focused test and confirm it passes.

### Task 3: Local saved-photo persistence

**Files:**
- Create: `lib/features/saved/data/saved_photo_repository.dart`.
- Create: `lib/features/saved/application/saved_photo_provider.dart`.
- Test: `test/saved_photo_repository_test.dart`.

**Interfaces:**
- `SavedPhotoRepository` supports `loadIds`, `toggle(id)`, and `contains(id)` using SharedPreferences key `shotbook.saved_photo_ids`.
- Riverpod exposes an asynchronously loaded immutable set and a notifier for toggles.

- [x] Test initially empty state, adding/removing IDs, and persistence across repository instances.
- [x] Run the focused test and confirm missing repository behavior fails.
- [x] Implement SharedPreferences repository and Riverpod notifier.
- [x] Run the focused test and confirm it passes.

### Task 4: Discover and photo detail experience

**Files:**
- Create: `lib/features/discover/presentation/discover_screen.dart`, `photo_grid_tile.dart`, `discover_empty_state.dart`.
- Create: `lib/features/photo_detail/presentation/photo_detail_screen.dart`, `metadata_section.dart`.
- Modify: `lib/app/router.dart`.
- Test: `test/discover_screen_test.dart`, `test/photo_detail_screen_test.dart`.

**Interfaces:**
- Discover consumes catalog/filter/save providers and routes to `/photos/:photoId`.
- Photo detail resolves `photoId`, shows the image/title/category/description, and includes only present pose, camera, and editing values.
- Saved destination is reachable from the Discover top bar and filters to locally saved catalog entries.

- [x] Test search, category selection, card navigation, save action, useful empty state, missing-image fallback, optional metadata omission, and long-title layout.
- [x] Run focused tests before screen implementation; they failed on missing screens/routes, then passed after implementation.
- [x] Implement image-first 2-column Discover grid, search/category controls, Saved view, detail sections, and error/empty/retry states.
- [x] Run focused tests and confirm they pass.

### Task 5: Project documentation and verification

**Files:**
- Create: `README.md`, `.gitignore` (Flutter/Android/Dart exclusions and local config exclusions).
- Verify: `flutter analyze`, `flutter test`, `flutter build apk --debug`.

- [x] Document install/run commands, offline catalog behavior, and deferred Supabase configuration.
- [x] Run all Flutter tests and fix failures.
- [x] Run `flutter analyze` and resolve diagnostics.
- [x] Run `flutter build apk --debug`; succeeded after the user authorized Android SDK license acceptance and package installation. The stage-one APK was later replaced by the Stage 2/3 build at the same output path.
- [x] Review final Git status and scope; there are no remotes, commits, or secret configuration files.

