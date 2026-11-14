# Product website

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

The buildless product introduction site lives in `website/`: Simplified Chinese at `/` and English at `/en/`. It provides Android downloads, not a browser version of the app. No App source, device records, database or installation is changed.

## CEO review

2026-11-13: the CEO formally accepted the 390px mobile visuals and locked both desktop and mobile layouts. Prelaunch QA is complete within the scope below. **Final launch approval remains pending.** The brand, character, headline and overall structure are retained.

- Hero: keep the original headline, explain manually recorded savings / wish progress / pig encouragement, and display the existing same-source character beside the phone. The existing character art is retained; the user-requested click hop is described below.
- Film: clear 42-second hero link, existing poster, manual play button and native controls. No autoplay. Bilingual text tracks and a readable description support access to the Chinese film; The film script handles play/focus/status. Native controls and the direct file link remain available independently.
- Features: explicitly mention multiple wishes and vertical switching; keep the Android widget presentation. Earlier backspace-font correction and caption removal remain.

## Preview and publication

Run `python -m http.server 4173 --bind 127.0.0.1 --directory website` from the repository root, then open `http://127.0.0.1:4173/`. No dependency installation or build is needed.

Task branch: `codex/product-website`; integration target: `main`. Work began at remote `main` (`9b41625`) in an isolated worktree; the original local `main` had seven unpublished commits, including separate film work. Do not incorporate or publish unrelated work. The CEO requires stopping after QA for final launch approval: **no push, merge or production deployment for this revision**.

After approval and safe integration, choose **GitHub Actions** in repository Settings → Pages. The existing `.github/workflows/website.yml` deploys only `website/` from `main` and supports manual dispatch on `main`. Verify the deployment and both language URLs before marking publication complete. The intended address is `https://naclarb.github.io/Wallehog/`; no domain purchase is required. Pages configuration/permissions and production have not been changed. The workflow has not run remotely.

## Asset provenance

- Hero pig: existing promotional `out/stills/pig-rest.png`, exported from the current App Painter identity. SHA-256 `c7933f8a509680b3c7b8b2a492d530ea7a90926009119a53c7116e9604505874`.
- Movie: existing stage-four `Wallehog_1.0_Final_1080p.mp4`, copied byte for byte as `website/assets/wallehog-1.0.mp4`. 7,162,802 bytes; SHA-256 `47ce095e9ab3357b6526ba3b1e2cfb3eb2408b620667f76d52da0dc05a04d1c9`. 42.005s container, 42.000s H.264 picture, 1920 × 1080 / 30fps, AAC stereo. No second film, edit, re-encode or new audio was created. Its separate film approval/listening record is not changed by website testing.
- Poster: existing final-film `stills/S02-1080p.png`. No reference images are distributed. Screenshots use fictional data. Fonts are served locally with their OFL notice; the existing embedded GitHub mark's MIT notice is included. See [credits](public/CREDITS.md).

## Hero interaction follow-up

User requested the existing homepage pig to hop when tapped, like the App. Source commit `ad78f6e` on `codex/website-pig-bounce` targets `codex/product-website`; integration is pending the website’s final acceptance, then the website still targets `main`. No push or deployment.

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
| FAIL / blocked validation | The native fullscreen action did not enter fullscreen in the available Codex in-app browser. Fullscreen is **not signed off**; verify with standalone desktop Chrome/Edge and physical Android Chrome. |

### Issues fixed and retested

1. The initial native-control gradient obscured the poster's lower portion. JavaScript now keeps the initial poster clear and enables native controls on explicit play; the HTML no-JavaScript fallback keeps native controls.
2. Mobile supporting text was 12px and several links/FAQ targets were 16–36px high. Supporting copy is now 14px and site touch targets are at least 44px. No brand, headline, structural or character redesign. CSS/JS URLs carry a version query to avoid stale resources during review.

### Still requiring manual verification

- Standalone-browser and physical-phone fullscreen, browser-owned touch controls, speaker/headphone experience, rotation and real touch behavior.
- Android Chrome / iOS Safari / desktop-browser coverage, TalkBack/VoiceOver and real slow-device/network Web Vitals. Browser-size simulation does not replace these checks.
- After final approval and deployment: public HTTPS, project-subpath URLs, cache/range/content-type behavior and an online download/playback smoke check. Production has not been changed to obtain these results.

Evidence stays in ignored `.buildlog/website/final-qa/`: APK verification, layout matrix, navigation, external links, contrast and resource JSON; before/after poster screenshots. Downloaded APKs remain local. `node --check website/film.js`, source/asset checks and `git diff --check` passed. No App code, package, data or device installation changed. **Stop for CEO final launch approval.**
