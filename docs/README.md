# Documentation

[English](README.md) · [简体中文](README.zh-CN.md)

Start with [current status](STATUS.md). Read the detailed documents only for the task at hand; this page routes to them rather than repeating their rules.

## Working documents

| Question | Read |
| --- | --- |
| What is complete, and what remains? | [Current status](STATUS.md) |
| How does interface language switching work? | [Interface language and verification](LANGUAGE.md) |
| How does the home-screen widget work? | [Widget scope, implementation and verification](HOME_WIDGET.md) |
| How should an agent work here? | [Project instructions and repository layout](../AGENTS.md) |
| What is the product for? | [Product intent](INTENT.md) |
| What behavior has been agreed? | [Requirements and decisions](PRODUCT_SPEC.md) |
| Where does implementation belong? | [Architecture](DESIGN.md) |
| How did the plan evolve? | [Roadmap and milestone history](ROADMAP.md) |

PRODUCT_SPEC, DESIGN, and ROADMAP are legacy Chinese documents; INTENT now has English and Chinese counterparts. Their existing content is preserved; this navigation update does not translate or reinterpret their decisions. The roadmap contains historical “current” headings; use STATUS for the present handoff and verify detailed claims against the relevant decisions and evidence.

## Evidence and supporting material

| Location | Contents |
| --- | --- |
| `VERIFICATION.md`, `*_VERIFICATION.md` | Historical delivery reports; consult the report for the specific change |
| `screenshots/`, `recordings/` | Supporting captures; the associated report explains whether they are rendered previews or device evidence |
| `public/` | Public previews, credits, and publication checks |
| `archive/` | Earlier documentation snapshots, not current requirements |
| `CHARACTER_IDENTITY.md`, `GAMIFICATION_AND_ANIMATION.md` | Detailed character and animation design context |
| `SOUND_CREDITS.md`, `PHASE2_VISUAL_REVIEW.md` | Sound attribution and historical visual review |

Historical reports retain their existing paths so their cross-links remain valid. A past passing result is evidence about that version, not a new validation result. Some supporting material currently exists only in the local working tree; see STATUS for repository limitations.

The project also has `tools/` for development helpers, `marketing/` for promotional projects, and `experiments/phase2/` for isolated animation work. Their responsibilities and access boundaries are defined in AGENTS; they are not application source directories.
