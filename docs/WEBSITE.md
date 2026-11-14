# Product website

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

The buildless product introduction site lives in `website/`: Simplified Chinese at `/` and English at `/en/`. It provides Android downloads, not a browser version of the app. No App source, device records, database or installation is changed.

## Postlaunch growth revision

CEO approved the revision and controlled deployment on 2026-11-14. Branch `codex/website-growth` started at freshly fetched remote `main` (`31d0186`); approved commit `ad036df3239d2cf2f54a285bebb442ff630698f9` was fast-forward integrated into remote `main` and pushed without conflicts or force. Only the reviewed website files and paired website documents were included; the original local main and its seven unrelated commits remain untouched.

The revision emphasizes the approved savings-only positioning and adds three concise Android installation steps. Static desktop QR codes link to the corresponding official language page, never an APK mirror. The approved character, headline, layout, film, App and APKs are unchanged. The accepted website now enters maintenance mode.

The owner-authorized public feedback form is [Wallehog feedback](https://tally.so/r/7XL0ja), managed in the owner’s Tally workspace. Its bilingual questions cover installation / first-record progress, the biggest obstacle (both required), and optional suggestions. It has no name, email, financial-data or upload field; no respondent login or password is required. Save-for-later is disabled; no tracking or forwarding integration was connected. Feedback goes to Tally, as disclosed beside the link and in the privacy FAQ; no automatic deletion or absolute anonymity is promised. Manage retained responses manually in Tally.

### Local QA — 2026-11-14

- **PASS:** Chinese and English at content widths 320, 390, 430 and 1440px have no horizontal document overflow. Hero, installation and feedback copy were checked; mobile QR codes are hidden. New installation body text is 15px, feedback body 16px and mobile auxiliary text 14px. Download / feedback controls are at least 44px high on mobile. Added text contrast is at least 4.53:1; keyboard focus is visible.
- **PASS:** both QR codes decoded from browser-rendered desktop screenshots to the official Chinese / English website. Both unchanged official APK links returned HTTP 206, ZIP signatures and expected total lengths (24,142,018 / 59,770,418 bytes). Version / architecture / full hash verification remains the preceding launch evidence; this revision did not redownload the complete APKs or reinstall the App.
- **PASS:** public Tally URL responds 200 without an authentication cookie. Actual website feedback clicks opened the correct form in a new tab. Two required-choice validations and a successful synthetic submission were observed, followed by its persisted completed response in the owner dashboard. Exclude the one response marked `QA_TEST_DO_NOT_COUNT_20261114` from real-user analysis; it was retained, not silently deleted.
- **PASS:** static download and feedback links remain visible with JavaScript disabled. Both language links, browser back and all ten FAQ disclosures work. Pig click / keyboard activation retained its hop (observed negative image translation). The unchanged film played manually, paused / resumed and reached 42.005s without error; no console warnings / errors were observed. Film checksum remains the asset-provenance value below. Local linked resources exist and both scripts pass syntax checks.
- **FAIL:** no unresolved functional failure found in the tested scope.
- **MANUAL / NOT CERTIFIED:** physical Android installation and touch, Safari / assistive technology, real slow-network performance and native fullscreen were not repeated in this revision. Previous public Edge fullscreen acceptance is recorded below. The Tally form is bilingual in one page; service validation messages currently use Chinese. New production HTTPS acceptance is pending deployment approval.

Evidence is ignored under `.buildlog/website/growth-review/`: `zh-1440-hero.png`, `zh-390-hero.png`, `en-1440-hero.png`, `en-390-hero.png`, language desktop download screenshots, `zh-mobile-download.png`, `zh-mobile-feedback.png`, `form-success.png`, layout / contrast / HTTP results. The change list is the two HTML pages, stylesheet, two static QR SVGs and this bilingual document pair. No new runtime script, SDK, private file, App source or deployment workflow is included. The CEO subsequently approved this revision; see the production acceptance record below.

## Growth deployment and final acceptance — 2026-11-14

[Pages workflow 43580989565](https://github.com/Naclarb/Wallehog/actions/runs/43580989565) completed successfully for deployed SHA `ad036df3239d2cf2f54a285bebb442ff630698f9`. The existing workflow still uploads only `website/`; App code, APKs, domain and workflow configuration were unchanged. Later documentation-only commits do not change the deployed payload.

- **PASS:** both public HTTPS language pages and 16 resources, including the local font, matched approved Git blobs. Both official APKs were downloaded completely and matched the pinned ARM64 / Universal SHA-256 values recorded in STATUS; file sizes remain 24,142,018 / 59,770,418 bytes.
- **PASS:** online QR codes decoded from browser screenshots to the respective official language pages. Feedback clicks opened the actual Tally URL; a request without login cookies returned 200 and the form questions. Both website languages explicitly disclose third-party Tally processing. The existing QA response remains labelled non-user data and excluded from user analysis; no real response was deleted or new test response added.
- **PASS:** Chinese and English layout checks at 320 / 390 / 430 / 1440px found no horizontal overflow. Both language links, download anchors, browser back and all ten FAQ items worked. Pig hopping remained visible. Public video played manually, paused / resumed and reached 42.005s without error; no console warning / error was observed.
- **FAIL:** no unresolved core failure. Command-line verification encountered a transient 403, TLS handshake failure and timeout; subsequent requests and byte/hash checks succeeded without bypassing TLS protections.
- **MANUAL / unchanged limitations:** physical-phone installation/touch, Safari, assistive technology and real low-end / slow-network performance are not certified. Native fullscreen was not repeated; the prior public Edge verification remains below.

Online evidence is ignored in `.buildlog/website/growth-online/`: `http.json`, `workflow.json`, layout results, `zh-desktop.jpg`, `en-desktop.jpg`, `zh-mobile.jpg`, bilingual download / feedback screenshots and video playback screenshot. Website growth optimization is closed and the site is in maintenance mode. Source branches remain available; the original local-main divergence is preserved for separate reconciliation.

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
