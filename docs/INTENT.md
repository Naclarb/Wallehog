# Product Intent

[English](INTENT.md) · [简体中文](INTENT.zh-CN.md)

Updated: 2026-11-06. Wallehog is a minimal, gamified companion for saving habits, not a bookkeeping tool that requires budgets, categories, or spending details.

The core experience is: open → plus → enter savings → confirm → receive a small response from the pig, with totals and wish progress updated. Recording should take seconds without requiring proof of how the amount was calculated.

Saved Money is self-reported savings, not actual deposits, an account balance, or spendable funds. Good Choices is a secondary internal growth measure: each valid record counts once and does not compete visually with savings or the goal.

Multiple wishes help users look forward to something; swipe vertically to cycle through the current wish. Confirmed on 2026-11-06: new records default to the current card, and binding can be changed when entering or editing a record. Switching preserves each wish's progress; total savings count each record once. Only when there are no wishes does creating the first wish automatically adopt unbound records; creating or switching wishes when others exist does not automatically transfer records. Progress is encouragement, not proof that a purchase is affordable. The pig accompanies users at the upper right of home without a separate corner overlay.

Spending is not failure: no shaming, missed-day penalties, or demands for complete transaction histories. Android first, local SQLite, no accounts, business networking, telemetry, ads, banking, payments, or social features. Start with a static pig and gentle native feedback, without a game engine.

During development, prioritize Chinese documentation and UI. Before public release, add an English entry point and language switching, and confirm licensing, the final app package name, and release signing.
