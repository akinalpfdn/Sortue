SORTUE — LOCALIZED APP STORE SCREENSHOTS

LAYOUT
  ../en/              original English set (untouched; its assets are shared)
  ../<locale>/        one folder per App Store Connect locale code (fastlane deliver folder names)
    iphone/           4 RGB PNG, 1320 × 2868 (6.9-inch slot)
    ipad/             4 RGB PNG, 2064 × 2752 (13-inch slot)
    previews/         320px-wide thumbnails
    typography-report.json
  ../preview-all.html browse every locale

SOURCE
  listing.html    en/listing.html layout, with ?locale= support, line auto-fit and RTL
  copy.js         all headline/support copy; edit here, then re-render
  render-all.cjs  Playwright export (same setup as en/render.cjs)

RENDER
  node render-all.cjs              all locales except en-US
  node render-all.cjs de-DE ja     a subset
  node render-all.cjs en-US        English check set; matches ../en pixel-for-pixel
  Fails if any text is under the 320px-preview minimum, if copy overlaps the artwork,
  or if a line has to wrap.

FONTS
  Varela Round (app font) for Latin, Greek, Hebrew, Vietnamese.
  macOS system fonts for other scripts: SF Rounded (Cyrillic), SF Arabic Rounded,
  Hiragino Maru Gothic (ja), PingFang (zh), Apple SD Gothic Neo (ko), Thonburi (th),
  Kohinoor Devanagari (hi). Rendering must run on macOS.
