# Product website

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

The buildless product introduction site lives in `website/`: Simplified Chinese at `/` and English at `/en/`. It provides Android downloads, not a browser version of the app. No App source, device records, database or installation is changed.

## CEO review

2026-11-13: the CEO formally accepted the 390px mobile visuals and locked both desktop and mobile layouts. Prelaunch QA is complete within the scope below. **The CEO has now approved controlled production launch.** The brand, character, headline and overall structure are retained.

- Hero: keep the original headline, explain manually recorded savings / wish progress / pig encouragement, and display the existing same-source character beside the phone. The existing character art is retained; the user-requested click hop is described below.
- Film: clear 42-second hero link, existing poster, manual play button and native controls. No autoplay. Bilingual text tracks and a readable description support access to the Chinese film; The film script handles play/focus/status. Native controls and the direct file link remain available independently.
- Features: explicitly mention multiple wishes and vertical switching; keep the Android widget presentation. Earlier backspace-font correction and caption removal remain.

## Preview and publication

Run `python -m http.server 4173 --bind 127.0.0.1 --directory website` from the repository root, then open `http://127.0.0.1:4173/`. No dependency installation or build is needed.

Task branch: `codex/product-website`; integration target: `main`. Work began at remote `main` (`9b41625`) in an isolated worktree; the original local `main` had seven unpublished commits, including separate film work. Do not incorporate or publish unrelated work. The CEO has explicitly approved safe integration, GitHub Actions Pages setup, deployment and public HTTPS acceptance. `codex/website-launch` starts from confirmed remote `main` and fast-forwards the approved website and pig interaction only. The original local `main` and its seven unpublished commits remain untouched; none of those commits is an ancestor of the website delivery. The controlled launch and public HTTPS acceptance are complete. See the live deployment record below.

The repository uses GitHub Actions for Pages. `.github/workflows/website.yml` deploys only `website/` from `main`; no domain was purchased and the Android release workflow was not triggered.

## Live deployment and HTTPS acceptance

Published 2026-11-13: [Chinese](https://naclarb.github.io/Wallehog/) · [English](https://naclarb.github.io/Wallehog/en/).

Deployed commit: `98e1d9341586d8ee10961c79ca81f7f7bb412cca`. [Website workflow run 43567567768](https://github.com/Naclarb/Wallehog/actions/runs/43567567768) completed successfully, including configuration, website-only artifact upload and Pages deployment. Later documentation-only commits do not change this deployed website payload.

- Both public HTML responses and 14 linked resources (including CSS, both scripts, PNGs, font, captions and MP4) returned 200 and matched the committed bytes. MP4 byte-range request returned 206 with the expected total size. Windows working-copy CRLF conversion was excluded by comparing against Git blobs.
- Both official Release APK URLs were taken from the public pages and downloaded completely again: ARM64 24,142,018 bytes, only `arm64-v8a`; Universal 59,770,418 bytes, three ABIs. Both retain `1.0.0+1000` and exactly match the previously pinned-signature-verified SHA-256 digests in STATUS. No APK was modified or installed.
- Public-page browser checks passed: Chinese/English switching, hero/header download anchors and separate ARM64/Universal links, navigation/back, all 10 FAQ items, the pig click hop, and mobile widths 320/360/390/430 plus desktop 1280/1440. No horizontal overflow or console warnings/errors were observed.
- Public HTTPS video started manually, paused/resumed and played to 42.005s with no media error. Standalone Microsoft Edge opened the same public site, entered native video fullscreen, continued to the end and exited normally. This resolves the previous standalone-fullscreen verification gap; the Codex embedded viewer's own fullscreen limitation remains host-specific.
- Safety audit: 28 scoped paths and 62 unique new/history blobs scanned without a high-confidence secret or private-user-path finding. The approved film checksum matches. None of the seven unrelated local-main commits was included. Pattern scanning is bounded, not proof of the absence of every possible secret.

Local evidence remains ignored in `.buildlog/website/online/`: HTTP/hash, APK, browser, navigation and layout JSON; `zh-desktop.png`, `en-desktop.png` and `edge-fullscreen.png`. The original local `main` and its seven unpublished commits remain unchanged and need separate later reconciliation; remote `main` contains only the approved website delivery. Website branches are retained.

Remaining coverage: physical Android/iOS touch, Safari, TalkBack/VoiceOver and real low-end/mobile-network performance have not been certified. Core public download and video functions passed; no unresolved core site failure was found.

## Asset provenance

- Hero pig: existing promotional `out/stills/pig-rest.png`, exported from the current App Painter identity. SHA-256 `c7933f8a509680b3c7b8b2a492d530ea7a90926009119a53c7116e9604505874`.
- Movie: existing stage-four `Wallehog_1.0_Final_1080p.mp4`, copied byte for byte as `website/assets/wallehog-1.0.mp4`. 7,162,802 bytes; SHA-256 `47ce095e9ab3357b6526ba3b1e2cfb3eb2408b620667f76d52da0dc05a04d1c9`. 42.005s container, 42.000s H.264 picture, 1920 × 1080 / 30fps, AAC stereo. No second film, edit, re-encode or new audio was created. Its separate film approval/listening record is not changed by website testing.
- Poster: existing final-film `stills/S02-1080p.png`. No reference images are distributed. Screenshots use fictional data. Fonts are served locally with their OFL notice; the existing embedded GitHub mark's MIT notice is included. See [credits](public/CREDITS.md).

## Hero interaction follow-up

User requested the existing homepage pig to hop when tapped, like the App. Source commit `ad78f6e` on `codex/website-pig-bounce` targets `codex/product-website`; the approved follow-up is now fast-forward integrated into the website delivery, whose final target is remote `main`.

The character artwork and positioning are unchanged. A labelled native button covers the visible pig, with keyboard focus and Enter/Space activation. Native Web Animations provide a single 420ms, 10px sine-shaped hop, restarting on repeat clicks without stacking. Reduced-motion mode skips movement and cancels an active hop. Without JavaScript the static artwork remains, without a dead button in the tab order. No audio, data writes or dependencies were added.

Browser checks passed in both languages: click/Enter/Space, five consecutive activations, return to the resting transform, reduced-motion cancellation, and 320/390/1440px content-width layout and button bounds. JavaScript syntax, local asset links and diff checks passed. Existing fullscreen/manual QA limitations and the final launch gate remain unchanged.

## Prelaunch QA (2026-11-13)

| Result | Check and evidence |
| --- | --- |
| PASS | Both complete APKs downloaded from the actual linked URLs. Version `1.0.0`, code `1000`, package `dev.wallehog.wallehog`; ZIP integrity and v1/v2/v3 signatures match the pinned official certificate. ARM64 contains only `arm64-v8a`; Universal contains `arm64-v8a`, `armeabi-v7a`, `x86_64`. Digests match [STATUS](STATUS.md). Hero/header download anchors and both bottom APK links were checked in both languages. |
| PASS | Initial poster is clear, video paused with `preload=none`, no autoplay. User activation restores native controls; play, pause/resume and complete playback work. Existing movie checksum remains unchanged. |
| PASS | Chinese and English layout matrix at content widths 320 / 360 / 390 / 430 / 1024 / 1280 / 1440 / 1920px: no horizontal overflow, clipped interactive elements or overlapping action buttons. Browser scrollbar compensation is used to obtain the requested content widths. |
| PASS | Mobile body 15–17px, FAQ titles 17px, supporting copy 14px. Site-operated mobile links/buttons/summary targets are at least 44px high. Computed visible text contrast, including expanded FAQ answers, is at least 4.53:1 in both languages; no normal/large-text threshold failure. Baked-in movie/image text and browser-owned media controls are excluded. |
| PASS | All 10 bilingual FAQ items open/close; language switching, feature/download/video anchors, back/forward and returning from the actual GitHub external link work. All seven unique external links return HTTP 200. The existing multiple-wish/vertical-switch sentence is retained. |
| PASS | Keyboard interaction and visible focus, semantic heading/language/alt text, bilingual video text tracks and readable description are present. Reduced-motion mode disables smooth scrolling/transitions. With JavaScript disabled, native video controls, content and download links remain available. |
| PASS, bounded | Cache-disabled local mobile first load: approximately 1.73 MB encoded resources observed, no eager 7.16 MB movie request, no network or script errors. Below-fold images load lazily. A 1.6 Mb/s / 150ms simulated-network smoke check loaded the hero resources without observed failures. This is not a calibrated device benchmark or a Web Vitals score; request-start correlation was unavailable for duration reporting. |
| Historical host limitation | The Codex in-app browser did not enter native fullscreen. The public site subsequently passed standalone Edge fullscreen/exit/end playback; physical mobile coverage remains separate. |

### Issues fixed and retested

1. The initial native-control gradient obscured the poster's lower portion. JavaScript now keeps the initial poster clear and enables native controls on explicit play; the HTML no-JavaScript fallback keeps native controls.
2. Mobile supporting text was 12px and several links/FAQ targets were 16–36px high. Supporting copy is now 14px and site touch targets are at least 44px. No brand, headline, structural or character redesign. CSS/JS URLs carry a version query to avoid stale resources during review.

### Still requiring manual verification

- Physical-phone fullscreen, browser-owned touch controls, speaker/headphone experience, rotation and real touch behavior; standalone Edge fullscreen has passed.
- Android Chrome / iOS Safari / desktop-browser coverage, TalkBack/VoiceOver and real slow-device/network Web Vitals. Browser-size simulation does not replace these checks.
- Future changes should repeat public HTTPS/subpath, download and playback smoke checks; the initial controlled launch has passed those checks.

Evidence stays in ignored `.buildlog/website/final-qa/`: APK verification, layout matrix, navigation, external links, contrast and resource JSON; before/after poster screenshots. Downloaded APKs remain local. `node --check website/film.js`, source/asset checks and `git diff --check` passed. No App code, package, data or device installation changed. The authorized controlled launch and public HTTPS acceptance are complete; retain the stated manual-coverage limits.
