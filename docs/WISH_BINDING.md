# Wish binding

[English](WISH_BINDING.md) · [简体中文](WISH_BINDING.zh-CN.md)

New records default to the current wish. The details area below note and date offers an icon/image binding control, including an unbound option. Editing begins with the record's original binding; cancellation leaves storage unchanged.

Only creating the first wish when no wishes exist adopts all unbound records, in the same transaction. Creating another wish or switching existing wishes does not transfer records. Each record belongs to at most one wish; the total counts it once. Editing amount and binding is atomic. Failed writes retain input; committed writes with failed snapshot reads use the recovery lock and reread without replay.

SQLite schema remains v4 and backup format v2. Explicit `goal_records` assignments determine progress; assigning an older record lowers that destination wish's boundary as needed without changing other assignments. Request tokens, identity and creation time are preserved. Legacy migrations and backup compatibility remain covered by tests.

The approved icon/image implementation, phone/tablet behavior, first-wish adoption, rebinding, backup round trip and persistent storage have acceptance coverage. Further Figma synchronization remains deferred by the owner and is not an outstanding runtime feature. Current verification: [STATUS](STATUS.md). Historical device captures remain local.
