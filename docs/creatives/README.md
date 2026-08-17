# Advertisement creatives — the deposited record

The pre-registration commits to depositing the verbatim advertisement content
for all arms before launch. Google App campaigns do not contain discrete ads:
each ad group holds an **asset set** — up to 5 headlines (30 characters), up to
5 descriptions (90 characters), and up to 20 image assets — and Google
assembles the served ads from these combinatorially. The deposited record is
therefore the complete asset inventory, per ad group, per arm.

## What ran

- **Framed arm** (`MA2026_framed_01` … `_10`): six ad groups, identical across
  all ten campaigns — the two regulatory-focus orientations (prevention /
  promotion) crossed with three motivational themes (personal experience,
  community action, scientific contribution). See `framed/text.md`.
- **Neutral arm** (`MA2026_neutral_01` … `_10`): one ad group, identical
  across all ten campaigns, describing the application without either
  orientation. See `neutral/text.md`.
- **Every ad group carries exactly 20 image assets** (Google's maximum):
  **17 shared assets identical across all seven ad groups in both arms**,
  plus three crops of one arm/orientation-specific image. The
  orientation-specific images track the ad group's orientation exactly: the
  prevention image appears only in the three Prevention ad groups, the
  promotion image only in the three Promotion ad groups, the neutral image
  only in the neutral ad group.
- All text is Spanish. No video and no HTML5 assets. No custom App URL.
- Status at export (15 August 2026, pre-launch): campaigns *Pending*
  (scheduled start 17 August), ad groups and ads *Enabled*, approval status
  **Approved** for all 70 ad rows. Upload timestamps embedded in some asset
  filenames show final image edits were made 14–15 August 2026, before
  these exports.

The framed arm necessarily carries more distinct creatives than the neutral
arm (six ad groups against one); this structural difference is part of the
framed treatment as implemented and is noted in the pre-registration.

## Launch-day re-export

`ad_assets_export_with_images_2026_08_17_1413.zip` (md5
`90721043c51eb559837fa446f53d3ca7`) is the same export taken at 14:13 on
launch day, 17 August 2026, about 14 hours after the campaigns started. A
content-level comparison against the pre-launch zip found **one difference
across all 70 ad rows, all columns and all 28 image files**: `Campaign Status`
changed from `Pending` to `Enabled` on every row — the launch itself. No
text, image, or approval status changed. This is the record that the
creatives which launched are the creatives that were registered.

## Contents

```
docs/creatives/
├── README.md                          this file
├── ad_assets_export_with_images_2026_08_17_1413.zip
│                                      launch-day re-export (see above)
├── ad_assets_export_with_images.zip   AUTHORITATIVE record (md5
│                                      55f1fd42535815197d898dd2be3f934c):
│                                      Google Ads Editor export containing
│                                      data.csv (every ad row — headlines,
│                                      descriptions, statuses, and its Image
│                                      1–20 columns; UTF-16LE, tab-separated)
│                                      and images/ (the account's stored image
│                                      assets, all crop variants)
├── shared_images/                     author-supplied source files for shared
│                                      assets (see mapping below)
├── framed/
│   ├── text.md                        headlines + descriptions per ad group,
│   │                                  verbatim, with orientation labels and
│   │                                  English glosses
│   ├── Aedes-albopictus-macro-2.jpg   source of the prevention-only image
│   └── prommosq.jpg                   source of the promotion-only image
└── neutral/
    ├── text.md                        same structure
    └── Aedes_albopictus_on_the_wall_-_2.jpg   source of the neutral-only image
```

## Image map

The authoritative image-to-ad-group mapping is `data.csv` inside the zip
(columns `Image 1`–`Image 20` per ad row, referencing the zip's `images/`
tree). The table below summarizes it. "Source file" points to the
author-supplied original in this directory where one exists; the account
stores its own crops (aspect ratios in the filenames: `1-1`, `1.91-1`,
`4-5`/`0.8` — the last two are the same 4:5 portrait ratio).

| Live asset (in zip) | Account crops | Ad groups | Source file here | Content |
|---|---|---|---|---|
| `Aedes-albopictus-macro-2` | 1.91:1, 1:1, 4:5 | the 3 **Prevention** groups only | `framed/Aedes-albopictus-macro-2.jpg` | tiger mosquito on skin — prevention |
| `prommosq` | 1.91:1, 1:1, 4:5 | the 3 **Promotion** groups only | `framed/prommosq.jpg` | tiger mosquito on leaf — promotion |
| `Aedes_albopictus_on_the_wall_-_2` | base, 1.91:1, 4:5 | **neutral** group only | `neutral/Aedes_albopictus_on_the_wall_-_2.jpg` | mosquito on white wall — neutral |
| `Website image - 2026-08-04…` | one file | all 7 | — (zip only) | Mosquito Alert wordmark banner on red |
| `LOGO_MosquitoAlert_cuadrado…` | 1:1 | all 7 | — (zip only) | square Mosquito Alert logo |
| `map 1 191` | 1.91:1 | all 7 | `shared_images/Map.png` (different crop of the same map) | Spain participation map |
| `App4_ENG` | 1:1, 1.91:1, 4:5-crop | all 7 | `shared_images/App4_ENG.png` | app screenshot |
| `Untitled-design-4-800x600` | 430×537, 480×480 crops | all 7 | `shared_images/Untitled-design-4-800x600.jpg` | shared asset |
| `unnamed-5wide` | 1:1, 4:5 | all 7 | `shared_images/unnamed-5.jpg` | app screenshot (wide recrop) |
| `unnamed-6wide` | base, 1:1 | all 7 | `shared_images/unnamed-6.jpg` (recrop uploaded 15 Aug 21:32) | app screenshot (wide recrop) |
| `unnamed-7 wide` | 4:5 | all 7 | — (zip only) | app screenshot, "Report bites" screen |
| `unnamed-8wide` | 1:1, 4:5 | all 7 | `shared_images/unnamed-8.jpg` | app screenshot (wide recrop) |
| `6-2back2` | base, 1.91:1 | all 7 | derived from `shared_images/6-2.png` (white background re-set dark, uploaded 15 Aug 21:45) | laptop + phone product shot, dark background |

Notes:

- One promotion group (`Promotion - Community Action`) references the stored
  file `prommosq_4-5` where the other two reference `prommosq_0.8`; both are
  the same 4:5 portrait ratio, so the creative surface is identical across
  the three promotion groups.
- `shared_images/logo.png` and `shared_images/logo_long.png` are
  white-on-transparent logo variants supplied as source material; they do
  **not** appear in any ad group's image list in the account export, and are
  kept only as provenance for the brand assets.
- `shared_images/6-2.png` (white background) and `shared_images/Map.png`
  (different crop) are the sources of live assets rather than live assets
  themselves.
- Two live assets (`Website image`, `unnamed-7 wide`) have no author-supplied
  source file in this directory; the zip's copies are the record for these.

### Source-file checksums

| File | md5 |
|---|---|
| `framed/Aedes-albopictus-macro-2.jpg` | `5d3e16f7b44797be42a49d2edd11f155` |
| `framed/prommosq.jpg` | `1908afce1fccdbabc93d7a4cadaa2e96` |
| `neutral/Aedes_albopictus_on_the_wall_-_2.jpg` | `3580b6aef4c9223235bef9f7ce571c25` |
| `shared_images/6-2.png` | `09121667c7f05f2a2110069ae069edc5` |
| `shared_images/App4_ENG.png` | `a6a6ea8b9b5bd2ff4dc4f5291a40cde7` |
| `shared_images/Map.png` | `c351adc855081080218f74ac3fcf1601` |
| `shared_images/logo.png` | `ba55608d7b753e67a68b82752a6882cc` |
| `shared_images/logo_long.png` | `47b349c18ca33834b3a4b5f08a18c944` |
| `shared_images/unnamed-5.jpg` | `1e36c805b1c0aeb0e7793eb8e3103c45` |
| `shared_images/unnamed-6.jpg` | `662d784445441ab2b03c7e60b0877868` |
| `shared_images/unnamed-8.jpg` | `ce59a71121b62af6dc32b8a736f31f46` |
| `shared_images/Untitled-design-4-800x600.jpg` | `2adc5ccf86e191697d8850ee4f75f819` |

## Provenance rules

1. `ad_assets_export_with_images.zip` is exported from Google Ads Editor
   **after** the final creative build and is the authoritative verbatim
   record for both text and images. The per-arm `text.md` files are
   transcriptions verified string-for-string against the export's `data.csv`,
   not independent sources. If they ever disagree, the zip wins and the
   transcriptions are corrected.
2. Source image files in this directory are the originals supplied by the
   authors; the account's stored versions (in the zip) are Google-side crops
   of these, plus a small number of assets edited or created directly in the
   account, for which the zip is the only record.
3. If any asset is added, removed, or edited after launch — including edits
   forced by ad review (see the pre-registration's *Ad review contingency*) —
   re-export and commit a new zip alongside the old one with the date in the
   filename, and archive both the original and revised asset. The record
   must show what ran when.
4. Google may auto-generate additional formats (e.g. video from images) at
   serve time; the deposited record covers the configured assets, and this
   is stated in the pre-registration's description of the manipulated
   variable.
