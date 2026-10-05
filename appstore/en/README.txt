SORTUE — ENGLISH APP STORE SCREENSHOTS

DELIVERABLES
  iphone/ — 4 RGB PNG files, 1320 × 2868 px (6.9-inch slot)
  ipad/   — 4 RGB PNG files, 2064 × 2752 px (13-inch slot)
  preview.html — browse the complete set locally
  preview.jpg  — contact sheet; not an App Store upload

ORDER
  01 — A little color. A clearer mind.
  02 — Every shade. In its place.
  03 — Start small. Go deeper.
  04 — A palette for every mood.

EDITABLE SOURCE
  listing.html — HTML/CSS, four slides and separate iPhone/iPad layouts
  assets/ — supplied native screenshots, game font and app icon
  sources.json — original screenshot paths
  render.cjs — Playwright export script; closes its temporary browser

RENDER
  node render.cjs
  Requires Playwright and a browser. CHROME_PATH overrides its executable.
  It uses a fresh temporary browser profile, not the personal Chrome profile.
  No local server is needed. Source assets load from the local filesystem.

SOURCE NOTES
  Supplied screenshots are dated December 3, 2025; these are not new captures.
  No Simulator was started for this delivery.
  iPad screenshots have Turkish UI; only native board crops are used.
  The board crops preserve original tile colors, spacing and arrangement.
  Precision and Pure were not pictured because source screenshots do not show them.
  The English 4×4–12×12 size claim matches the current application code.
  No pricing or advertising claims appear in the artwork.

SIZE REFERENCE
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

READABILITY UPDATE
  Decorative microcopy removed. Supporting copy enlarged.
  All HTML marketing text passes 320px preview thresholds:
  headline 28px, support 18px, label 16px minimum.
  render.cjs enforces these thresholds and exports previews/.
  typography-report.json contains per-text checks.
