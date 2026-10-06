# App Store listing text

One file per App Store Connect locale: `<locale>.md`. These files are the source of truth; `fastlane/prepare.py` turns them into `fastlane/metadata/<locale>/*.txt` (git-ignored).

Sections in every file: Name (30), Subtitle (30), Promotional Text (170), Description (4000), Keywords (100), What's New (4000).

## Pipeline

```bash
# 1. fill support_url / privacy_url in fastlane/listing-config.json (once)
python3 fastlane/prepare.py                                          # md -> fastlane/metadata
python3 ~/.claude/skills/appstore-localized-upload/scripts/link_screenshots.py \
  --map fastlane/screenshot_map.json --out fastlane/screenshots      # appstore/<locale>/{iphone,ipad} -> fastlane/screenshots
fastlane deliver download_metadata --metadata_path /tmp/asc_live --force   # read-only snapshot of what is live
python3 ~/.claude/skills/appstore-localized-upload/scripts/validate_metadata.py fastlane/metadata --live /tmp/asc_live
python3 ~/.claude/skills/appstore-localized-upload/scripts/diff_metadata.py /tmp/asc_live fastlane/metadata
fastlane deliver --force                                             # only after reviewing the diff
```

`fastlane/Deliverfile`: `app_version` must be the version that is editable in App Store Connect. `overwrite_screenshots(true)` deletes every existing screenshot of that version, including device sizes not re-uploaded here. No binary is uploaded, nothing is submitted.

## Decisions (2026-10-06)

- **Name uses "color sort"** rather than "gradient" alone: `Sortue: Gradient Color Sort`. Search volume over precision; the subtitle and description make clear it is a gradient puzzle, not a water-sort game.
- Every locale's name starts with `Sortue:` so it stays close to the home-screen name (guideline 2.3.8), followed by the local phrase for sorting colors.
- Keywords never repeat words from that locale's name or subtitle (Apple combines the three fields). Unaccented spellings are added where people type without diacritics (`mantik`, `logica`, `mosaique`…).
- English variants (en-GB, en-AU, en-CA) use "colour" in the name and get "color" as a keyword; they reuse the English screenshots.
- es-MX uses "rompecabezas", pt-PT "puzzle", pt-BR "quebra-cabeça", fr-CA "casse-tête" — the local word for the concept, not a literal translation.
- Mode names in every description match the in-app names from `Sortue/Localizable.xcstrings` (e.g. Entspannt / Präzision / Pur).
- Keyword sets are a starting set based on ASO principles, not measured search volume. Check candidate terms against Apple Search Ads keyword popularity before a big push.

## Apple rules checked (2026-10-06)

- **Prices and ads:** guideline 2.3.7 restricts price information in name, subtitle, screenshots and previews. No price, "free", ad or subscription wording is used anywhere in the listing or the artwork. Official rules do not explicitly ban "no ads" in the description, but it is left out by choice.
- **Promotional text** is not used for search ranking (Apple App Store search guide); it is written for conversion.
- **Competitor names** (Blendoku, I Love Hue…) are not used as keywords; 2.3.7 forbids trademarked terms and other apps' names in metadata.
- **Accuracy:** every claim in the description was checked against the app code: offline (no networking), grid sizes 4x4–12x12, three modes, fixed corners, hints and solution preview in Casual only, music and haptic settings.

Links: [Accurate Metadata](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata) · [Product page](https://developer.apple.com/app-store/product-page/) · [Search](https://developer.apple.com/app-store/search/)

## Caveats

Translations were written by Claude and not reviewed by native speakers. Before a big launch, have Arabic, Hebrew, Hindi, Thai, Vietnamese, Japanese, Korean and Chinese checked.
