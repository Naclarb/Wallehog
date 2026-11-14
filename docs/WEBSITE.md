# Product website

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

The buildless product introduction site lives in `website/`: Simplified Chinese at `/` and English at `/en/`. It provides Android downloads, not a browser version of the app. No App source, device records, database or installation is changed.

## CEO review

2026-11-13: the CEO conditionally accepted the desktop visual direction and requested bounded round-one changes. The existing layout, palette, typography, widget, privacy and download sections are retained. This revision is ready for **second-round review**, not accepted for publication.

- Hero: keep the original headline, explain manually recorded savings / wish progress / pig encouragement, and display the existing same-source character beside the phone. No new character design or animation was generated.
- Film: clear 42-second hero link, existing poster, manual play button and native controls. No autoplay. Bilingual text tracks and a readable description support access to the Chinese film; JavaScript only handles play/focus/status. Native controls and the direct file link remain available independently.
- Features: explicitly mention multiple wishes and vertical switching; keep the Android widget presentation. Earlier backspace-font correction and caption removal remain.

## Preview and publication

Run `python -m http.server 4173 --bind 127.0.0.1 --directory website` from the repository root, then open `http://127.0.0.1:4173/`. No dependency installation or build is needed.

Task branch: `codex/product-website`; integration target: `main`. Work began at remote `main` (`9b41625`) in an isolated worktree; the original local `main` had seven unpublished commits, including separate film work. Do not incorporate or publish unrelated work. The CEO explicitly requires stopping for second-round review: **no push, merge or production deployment for this revision**.

After approval and safe integration, choose **GitHub Actions** in repository Settings → Pages. The existing `.github/workflows/website.yml` deploys only `website/` from `main` and supports manual dispatch on `main`. Verify the deployment and both language URLs before marking publication complete. The intended address is `https://naclarb.github.io/Wallehog/`; no domain purchase is required. Pages configuration/permissions and production have not been changed. The workflow has not run remotely.

## Asset provenance

- Hero pig: existing promotional `out/stills/pig-rest.png`, exported from the current App Painter identity. SHA-256 `c7933f8a509680b3c7b8b2a492d530ea7a90926009119a53c7116e9604505874`.
- Movie: existing stage-four `Wallehog_1.0_Final_1080p.mp4`, copied byte for byte as `website/assets/wallehog-1.0.mp4`. 7,162,802 bytes; SHA-256 `47ce095e9ab3357b6526ba3b1e2cfb3eb2408b620667f76d52da0dc05a04d1c9`. 42.005s container, 42.000s H.264 picture, 1920 × 1080 / 30fps, AAC stereo. No second film, edit, re-encode or new audio was created. Its separate film approval/listening record is not changed by website testing.
- Poster: existing final-film `stills/S02-1080p.png`. No reference images are distributed. Screenshots use fictional data. Fonts are served locally with their OFL notice; the existing embedded GitHub mark's MIT notice is included. See [credits](public/CREDITS.md).

## Verification for second-round review

| Check | Observed result |
| --- | --- |
| ARM64 / Universal APK | Both anonymous HEAD 200; GET Range 206; ZIP/APK prefix `504b0304`. Sizes 24,142,018 / 59,770,418 bytes. The links still target official GitHub Releases. This does not repeat package signature or installation acceptance. |
| Movie | Initially paused, no autoplay; Enter/click starts playback. Chinese desktop played to `ended=true`, 42.005s, no media error. English and mobile playback also progressed without media errors. Space pauses/resumes native controls. |
| Navigation / language | Chinese and English feature/download anchors, film entry and both language directions passed. |
| FAQ / description | All five FAQ items in each language open/close with Enter; the readable film description opens/closes. |
| Text contrast / keyboard | Computed text/background checks: Chinese 72 and English 70 visible text elements, minimum 4.53:1, no failures against 4.5:1 normal / 3:1 large text. Skip-link focus outline, the actual Tab sequence through the page and out of native media controls (no keyboard trap), and keyboard-operated links, FAQ and media controls checked. This excludes text baked into screenshots/video and is not a full screen-reader audit. |
| Responsive layout | Desktop 1440px viewport; Chinese/English mobile content widths 390px and 345px showed no horizontal overflow. The requested full-page screenshot is exactly 390px wide; the browser's 15px classic scrollbar is excluded. |
| Content / source | No testimonials, download counts, banking/automatic-transfer claims, login, subscriptions or analytics. Native controls, local assets/anchors, video/caption paths, JavaScript syntax, original-film checksum and diff whitespace checked. |

Local review artifacts (ignored): `.buildlog/website/ceo-round2/desktop-hero.png`, `mobile-390-full.png`, `video-playing.png`, download and contrast JSON evidence. The existing local preview stays available for annotations. Website-only changes require no APK build or device installation. Production deployment, physical-phone browser/audio checks and final CEO acceptance are not claimed.
