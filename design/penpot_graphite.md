# SHOTBOOK · Graphite (from Penpot)

Source: Penpot file "Новый файл 1" (pages Tokens, Components, Screens RU/EN).
Flat dark minimalism: fill + 1 px line, no gradients, glow or glass. The photo
brings the colour; the UI stays grey; the accent marks only labels and active
states. Shooting data is always monospaced. Big headings Unbounded, the rest
Onest.

## Colours
| token | hex | use |
|---|---|---|
| bg | #131416 | screen |
| surface | #1A1B1E | fields, panels |
| card | #212225 | cards, selected |
| border | #2D2F34 | 1 px lines |
| text.primary | #F1F2F3 | main text, primary button fill |
| text.secondary | #8B8F96 | captions |
| text.tertiary | #5A5D64 | inactive, section labels |
| accent | #F5A623 (amber) | labels, active tab |
| danger | #FF6B6B | errors, delete |
| success | #6BD68F | success |
Photo placeholders: #2A2C30 / #303338 / #26282C.

## Type
| style | font | size |
|---|---|---|
| Display | Unbounded 400, ls −0.3 | 26 (detail title 22) |
| Wordmark | Unbounded 500, ls 1.5 | 16 |
| Title | Onest 600 | 20 (name 18) |
| Body | Onest 400, lh 1.4 | 15 (rows 14) |
| Label | Onest 500 | 13–14 (nav 11) |
| Data | JetBrains Mono 400, ls 0.6 | 11 (handles 12) |

## Shape and spacing
Radius: 10 cards/buttons/search, 8 chips/elements/badges, 2 tags.
Spacing scale 4 · 8 · 12 · 16 · 20 · 28 · 40. Screen gutter 20. Grid gap 12.

## Components
- TopBar 64: wordmark left; streak badge (h28, r8, 1 px border, flame
  amber 14, Onest 500 13) and bookmark right.
- Search 48: surface, border, r10, icon secondary, hint Onest 400 15.
- Chip 36: selected = text.primary fill + bg text; else 1 px border +
  secondary text; Onest 500 14; r8; padding 16.
- Photo card: r10, viewfinder ticks 10×1 px at 8 px inset, white 55 %.
- Meta row 44: label secondary left, value primary right, Onest 400 14,
  1 px rule under. Section label: mono 11 caps, tertiary.
- Primary button 52: text.primary fill, bg text, Onest 600 15, r10.
  Secondary: 1 px border, r10.
- Bottom nav 72: 1 px top rule; amber 28×2 indicator at the top over the
  active item; icons 22; labels Onest 500 11; inactive tertiary.
- Tabs: Onest 500 14, active primary with amber 20×2 underline, inactive
  tertiary, 1 px rule below.
- Language switch: 76×32 r8 border; selected segment card r6; mono 12.
