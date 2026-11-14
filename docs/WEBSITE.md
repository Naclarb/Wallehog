# Product website

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

The buildless product introduction site lives in `website/`: Simplified Chinese at `/` and English at `/en/`. It uses local screenshots with fictional data, the approved app icon, generated gift illustration and Nunito with its bundled OFL notice. It provides Android download links, not a browser version of the app. No app source, records, database or Android package is changed.

## Preview

From the repository root, run `python -m http.server 4173 --bind 127.0.0.1 --directory website`, then open `http://127.0.0.1:4173/`. The language switch uses ordinary links and the FAQ uses native HTML details. JavaScript and a build step are unnecessary.

## Publication

Integration target: `main`; task branch: `codex/product-website`. The intended public URL is `https://naclarb.github.io/Wallehog/`. It is not live yet. Integration is pending because the original local `main` has seven unpublished commits including motion work awaiting review. This task starts at remote `main` (`9b41625`) in an isolated worktree so that it cannot publish those changes accidentally.

Once integration is unblocked, merge the website branch into `main` while preserving the pending work. In repository Settings → Pages, choose **GitHub Actions** as the source. Push the website integration to confirmed `origin/main`; `.github/workflows/website.yml` uploads only `website/` and deploys it to Pages. The workflow also supports manual dispatch from `main`. Verify the deployment result and both public language URLs before marking publication complete. No domain purchase is required. GitHub Pages access and repository permissions have not been changed by this task.

## Verification (2026-11-13)

- Local Chinese and English pages served successfully; all local assets and anchors resolve, and each page has one primary heading.
- Browser checks: 360 × 800 and 390 × 844 phone widths and 1440 × 1000 desktop; no horizontal overflow observed. Screenshots loaded, language navigation in both directions and FAQ expansion passed.
- Both official APK download links, the release page, repository, bilingual credits and hosting privacy link returned HTTP 200. The intended Pages language URLs returned 404 before publication.
- No JavaScript, analytics, cookies, remote font requests or user-data forms were added. Website copy distinguishes app privacy from GitHub hosting IP logs and explains that savings are self-reported and backups are unencrypted.
- `git diff --check` is required before commit. Website-only work does not require Flutter analysis, an APK build or physical-device installation. Browser captures stay in ignored `.buildlog/website/`.

The Pages workflow has not run remotely yet. Public deployment and integration remain pending; local preview is not proof of publication.
