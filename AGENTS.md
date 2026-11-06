# Wallehog — Project Instructions

[English](AGENTS.md) · [简体中文](AGENTS.zh-CN.md)

## Scope

These instructions apply only to Wallehog. Do not modify global agent instructions as part of project work. This English file is the authoritative agent entry point; its Chinese companion is a synchronized translation, not a separate rule set.

Keep durable agreements here and progress, version status, and delivery history in project documentation. Communicate in Simplified Chinese and use clear English code identifiers. Commit messages follow the Git section below.

## Start Here

- Before substantive work, check the repository root, scoped working-tree status, branch, and remotes. Preserve existing user changes.
- Read the README and [current status](docs/STATUS.md). Use the [documentation index](docs/README.md) to find task-specific context without requiring the user to name the documents.
- Read [INTENT](docs/INTENT.md) for product boundaries, then the task-relevant requirements and acceptance criteria in [PRODUCT_SPEC](docs/PRODUCT_SPEC.md) and architecture in [DESIGN](docs/DESIGN.md). Read historical reports only when needed as evidence.
- Distinguish approved decisions, proposals, and historical statements. Verify conflicting status claims against user instructions and evidence. An old “completed” heading is not acceptance of a later iteration. Follow the protected-document process when a core rule must change.

## Repository Layout

| Path | Responsibility |
| --- | --- |
| `lib/main.dart`, `lib/app/` | App entry point, dependency composition, theme, and design tokens |
| `lib/domain/` | Pure Dart business rules for amounts, records, and goals |
| `lib/data/` | SQLite persistence, migrations, and backup implementation |
| `lib/application/` | Coordinate operations and publish consistent application state |
| `lib/features/` | Screens and feature-specific UI |
| `lib/character/`, `lib/shared/` | Character presentation and shared UI capabilities |
| `test/`, `integration_test/` | Automated rule, storage, widget, and integration tests |
| `android/` | Android configuration and native integration |
| `assets/` | Runtime assets and attribution |
| `docs/` | [Documentation index](docs/README.md), current status, product rules, architecture, and verification evidence |
| `tools/` | Development environment and build helpers; not application runtime code |
| `marketing/` | Promotional source projects and exports; separate from runtime assets and test evidence |
| `experiments/phase2/` | Isolated animation experiments; follow the boundary below |

Root Flutter configuration files stay at the project root. Generated directories such as `build/`, `.dart_tool/`, `.buildlog/`, and local IDE metadata are ignored working files, not source folders to relocate or commit. This map describes responsibilities, not an exhaustive allowlist of filenames.

## Task Workflow

- Identify the requested outcome, relevant requirements, and acceptance criteria before editing. Avoid unrelated refactors, cleanup, and dependencies for hypothetical future needs.
- When design review is requested, iterate on annotations in the preview. Wait for the user's confirmation that design review is complete before final device validation; silence is not approval. If tools cannot retrieve comments, explain the limitation and work from feedback supplied by the user.
- Carry a clearly authorized task through implementation, required checks, applicable device validation, and Git delivery. Progress updates do not end the task. Do not stop at an intermediate step or ask whether to perform an already requested next step.
- Pause only for user interruption, required feedback/approval, or a genuine blocker such as an unavailable device or permission. Complete independent work where possible, then explain the remaining work and precise blocker. Never report partial work as complete.

## Documentation

- Maintain English and Simplified Chinese versions of human-authored project documents. Whichever language changes first, synchronize corresponding content in the other language in the same commit. Preserve meaning, decisions, and status; translation must not introduce rules.
- Keep existing pair naming and cross-links. For new pairs, use `NAME.md` for English and `NAME.zh-CN.md` for Chinese. Preserve legacy Chinese sources and add an English counterpart instead of silently replacing their language. Pair legacy documents when they are changed; do not expand unrelated tasks into whole-archive translation.
- Generated logs, third-party license text, and code identifiers do not need duplicate translation.
- Write plainly and briefly. Give each rule one authoritative home and link to it elsewhere. A bilingual pair represents one document. Replace obsolete wording instead of repeatedly appending the same correction across files and comments.
- Do not turn every correction into a permanent prohibition. Record a pitfall only when recurring, non-obvious, and useful to future work; prefer meaningful automated checks where practical.
- Keep progress and verification records concise. Update a suitable existing record instead of creating a report for every minor change. Label proposals as proposals, never as user approval.

## Protected Documents

- Protect `AGENTS.md`, `AGENTS.zh-CN.md`, `docs/INTENT.md`, and all language counterparts of INTENT. Do not implicitly extend protection to every document.
- Do not change protected content without explicit user approval. When a request conflicts with it, identify the conflict and proposed change; obtain approval before changing the document or implementing the conflicting rule. Continue unaffected work where possible.
- An explicit request to edit a protected document authorizes that edit and its faithful translation; do not request the same approval again. Otherwise, cleanup and translation-driven changes to protected content also require approval.
- Maintain current status, ordinary documentation, and verification records within the authorized task. Keep changing project status out of protected instructions.

## Engineering and Experiment Boundaries

- Follow DESIGN's lightweight layers and dependency direction. Keep domain rules in pure Dart. Prefer SDK capabilities; explain the concrete need for a new dependency.
- Validate inputs and store money in integer minor units. Do not use `eval` or dynamic expression execution. Test business-rule changes and database migrations; never repair an upgrade by deleting the database.
- Keep animation experiments isolated from the daily app's code, data, and runtime assets. Integrate only specific assets or behavior approved by the user. Experiment tasks do not authorize replacing the daily installation.
- Start animation work from [the laboratory entry](experiments/phase2/README.md) and current active candidates. Preserve rejected rounds' complete source, exports, and feedback under `experiments/phase2/_discarded`. Do not read, recursively search, index, summarize, or reuse that directory unless the user explicitly requests a specified scope. Exclude it from default searches. Do not reclassify approved or undecided candidates as discarded.
- Reference images are inspiration; do not distribute them as app assets without confirmed rights.

## Validation and Delivery

- Run checks appropriate to the change. For application code, format touched Dart files, run `flutter analyze` and relevant tests, and build the Android artifact needed for delivery. Add meaningful regression coverage for bug fixes and business-rule changes. Documentation-only tasks require content, translation, link, and diff checks, not an APK or device installation.
- Automated checks may run during implementation. Begin physical-device validation after the full requested change and design-review cycle have converged, before final delivery. Do not build/install for each annotation. A specific bug fix is ready after implementation and regression checks. Fix and retest device failures. Earlier device diagnosis requires an explicit user request or approval.
- Validate phone-sized layout and core interaction first, even on a tablet. Record original resolution/density before temporary changes and restore them afterward.
- For a completed daily-app development task, validate safely, then update the connected user's ordinary Wallehog installation with `adb install -r`, preserving records and settings, and launch it to confirm startup. Do not uninstall or clear data. An isolated `.uitest` run does not replace ordinary-app delivery. Isolated experiments retain their separate package boundary.
- If a device is disconnected or system confirmation is required, report device delivery as pending and continue when available. Never claim checks, builds, installation, or startup succeeded without evidence.
- Before final handoff, complete the requested scope, necessary verification, relevant bilingual documentation, and Git steps below. Briefly report the outcome, checks, commit ID, push status, and material remaining limitations.

## Git

- Use English [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `<type>[optional scope][!]: <description>`. Use `feat` for features, `fix` for bug fixes, and an appropriate type such as `docs`, `refactor`, `test`, `build`, `ci`, or `chore` for other changes. Keep the subject concise; write any explanatory body in English. Mark breaking changes with `!` or a `BREAKING CHANGE:` footer. Examples: `feat(goals): add wish selection`, `docs: organize project navigation`. Apply this to new commits; do not rewrite existing history merely to change its language or format.
- Before Git changes, check `git rev-parse --show-toplevel`, scoped `git status`, branch, and remotes. If Wallehog remains inside the `C:/blog` parent repository, stage/commit only explicit Wallehog task paths. Do not read or commit sibling projects or credentials, use unscoped `git add .` / `git add -A`, or push the parent repository.
- Use a separate `codex/` task branch for each independent feature or fix, and record its integration target before implementation. Use `git worktree` for concurrent tasks so they do not share a working tree or index; small, related documentation follow-ups may stay on the current task branch.
- Use `git status`, `git diff`, and `git log` to check scope and branch divergence before commits and integration. Fetch from a confirmed remote when available, integrate target-branch changes regularly without rewriting shared history, and resolve conflicts by preserving the intended behavior of both changes. Rerun relevant checks after conflict resolution.
- After a task passes required checks and any requested review, promptly merge its commits into the established integration branch and verify the combined result. This rule authorizes routine local task integration; release publication and pushes to protected branches still require corresponding authorization. If the target is unclear, another task is unfinished, or integration is blocked, record the branch, commit IDs, target, and remaining action in current status and report integration as pending. Do not leave completed features only on forgotten branches or delete their branches/worktrees before confirming integration.
- Every delivery that changes project files must include a local Git commit after required checks. Pure discussion needs no empty commit. Long tasks may use clearly labeled checkpoint commits; these are not completed delivery.
- Commit only task-related changes; preserve unrelated working-tree and staged changes. Use `codex/` for new development branches. Do not amend, rewrite history, force-push, or discard user work without explicit authorization.
- Once a dedicated Wallehog repository and remote are confirmed, push completed delivery commits to the task's development branch and report success or failure. Do not change the parent repository, replace its `.git`, select an unconfirmed remote, or merge/publish a release without corresponding authorization.
- Commits preserve source history; they do not back up device records or replace remote backup. Do not claim that source rollback safely reverses a database migration.
