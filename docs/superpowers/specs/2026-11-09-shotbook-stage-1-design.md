# SHOTBOOK Stage 1 Design

## Intent

Build the first usable Android-first slice of SHOTBOOK: a visual photography reference catalog where people can browse pose ideas, inspect the shooting notes, and keep references locally. This stage is a real Flutter app with working navigation and state, while remote accounts and community publishing remain for later stages.

## Goals

- Scaffold a maintainable Flutter project using the requested feature-based structure.
- Provide four bottom-navigation destinations, a useful Discover catalog, working category/search filters, photo detail pages, and persistent local saves.
- Ship at least 20 curated seed entries spanning at least five categories, with representative pose, camera, and editing notes.
- Keep Camera, Feed, and Profile destinations non-empty while clearly deferring their full workflows.
- Verify with automated Flutter tests, `flutter analyze`, and an Android APK build when the required toolchain is available.

## Non-goals

- Supabase, authentication, publishing, likes, remote saved-photo sync, photo upload, physical camera control, and feed/profile functionality.
- Implementing the full Camera catalog in this first slice.

## Constraints

- Flutter, Dart, Material 3, Riverpod, GoRouter, CachedNetworkImage, and SharedPreferences.
- Dark foundation from the brief: background `#0E0E0E`, surface `#181818`, card `#202020`, primary `#FFFFFF`, secondary `#A0A0A0`, border `#303030`.
- Discover uses a two-column photo grid and the seven named categories.
- Saved state must work offline and persist on the device.
- No secrets or invented remote success states.

## Approaches

1. **Flutter local-first catalog (selected).** Build the requested first slice in Flutter with bundled seed metadata and SharedPreferences. This matches the Android-first choice, keeps browsing useful before Supabase exists, and leaves repository/provider boundaries ready for the later backend stage.
2. **Connect Supabase immediately.** This would entangle the first UI pass with credentials, schema, and account states that the stage explicitly defers.
3. **Build a web prototype first.** This would speed up visual iteration but would not provide the installable Android product requested.

## Visual direction: Darkroom index

Use a quiet charcoal interface that feels like a working photographer's reference index. Color comes from the photographs; controls and metadata stay restrained. The memorable element is a compact two-column image wall with deliberately varied image crops and small white framing marks on the selected category. Avoid gradients, ornamental labels, generic large rounded cards, and all-caps microcopy.

### Tokens

- Color: Ink `#0E0E0E`; Graphite `#181818`; Frame `#202020`; Paper `#FFFFFF`; Silver `#A0A0A0`; Rule `#303030`.
- Type: system sans for controls and readable metadata; platform serif for the SHOTBOOK wordmark and photo titles, evoking printed contact sheets without adding runtime font downloads.
- Shape: 6 px image/card corners, pill-shaped category controls, thin separators only where they clarify grouping.
- Layout: 20 px page gutters; strong left alignment; compact top bar; edge-to-edge horizontal category rail; image-first grid; persistent four-destination bottom navigation.
- Motion: short transitions only for opening a detail and toggling a save.

### Discover layout sketch

```text
┌────────────────────────────────┐
│ SHOTBOOK                 Saved │
│ Find a frame                    │
│ [ Search poses, places...    ◌ ]│
│ All  Portrait  Street  Full body│
│                                │
│ ┌──────────┐ ┌──────────┐       │
│ │          │ │          │       │
│ │  photo   │ │  photo   │       │
│ │          │ └──────────┘       │
│ └──────────┘   title    ♡       │
│   title   ♡   category          │
│                                │
│ Discover    Camera    Feed  Me  │
└────────────────────────────────┘
```

### Photo detail layout sketch

```text
┌────────────────────────────────┐
│ ‹                         Save  │
│                                │
│         full-width photo        │
│                                │
├────────────────────────────────┤
│ Window light                    │
│ Portrait                        │
│ Brief descriptive note          │
│ POSE                            │
│ Body · Hands · Legs · Gaze       │
│ CAMERA SETTINGS                 │
│ Device · Lens · ISO · ...       │
│ COLOR / EDITING                 │
│ Preset · Contrast · Grain · ... │
└────────────────────────────────┘
```

## Data and behavior

- `PhotoReference` is an immutable typed catalog model with optional pose, camera, and editing fields.
- Seed data lives in a small repository and supplies stable identifiers, realistic settings, and Wikimedia Commons image URLs with a visual fallback when an image cannot load. Credits, license names, and source file pages are stored beside each image.
- Discover filtering combines category and case-insensitive title/description search.
- Local saves use a `SavedPhotoRepository` backed by SharedPreferences and are exposed through Riverpod. Failed image/network access must not block local catalog or save behavior.
- Detail pages omit unset settings. Save state is reflected consistently in cards, detail, and Saved.
- Camera, Feed, and Profile show concise stage-one notices with a clear route back to Discover; they must not claim that deferred functionality is live.

## Open implementation choices

- Choose current stable package versions compatible with the available Flutter SDK at implementation time.
- Use GoRouter shell navigation with a nested photo-detail route.
- Keep image URLs remote for this stage; the fallback remains usable when offline.

