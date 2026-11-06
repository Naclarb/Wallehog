# 文档导航

[English](README.md) · [简体中文](README.zh-CN.md)

先看[当前状态](STATUS.zh-CN.md)，再按任务阅读详细文档。本文只提供入口，不重复其中的规则。

## 工作文档

| 要了解什么 | 阅读入口 |
| --- | --- |
| 完成了什么，还剩什么？ | [当前状态](STATUS.zh-CN.md) |
| 界面语言切换如何工作？ | [界面语言与验证](LANGUAGE.zh-CN.md) |
| agent 应该怎样工作？ | [项目规则与目录职责](../AGENTS.zh-CN.md) |
| 产品解决什么问题？ | [产品意图](INTENT.md) |
| 已经确定了哪些行为？ | [需求与决策](PRODUCT_SPEC.md) |
| 实现应该放在哪里？ | [架构说明](DESIGN.md) |
| 计划如何演变？ | [路线图与里程碑历史](ROADMAP.md) |

INTENT、PRODUCT_SPEC、DESIGN 和 ROADMAP 是历史中文文档。本轮保留其原有内容，导航更新不翻译或重新解释其中的决策。路线图含有历史“当前阶段”标题；现在的交接以 STATUS 为入口，具体结论需对照相关决策和证据。

## 证据与辅助资料

| 位置 | 内容 |
| --- | --- |
| `VERIFICATION.md`、`*_VERIFICATION.md` | 历史交付报告，按具体改动查阅 |
| `screenshots/`、`recordings/` | 配套截图和录像，由对应报告说明是渲染预览还是真机证据 |
| `public/` | 公开预览、来源说明和发布检查 |
| `archive/` | 早期文档快照，不是当前需求 |
| `CHARACTER_IDENTITY.md`、`GAMIFICATION_AND_ANIMATION.md` | 角色与动画的详细设计背景 |
| `SOUND_CREDITS.md`、`PHASE2_VISUAL_REVIEW.md` | 音效来源和历史视觉评审 |

历史报告保留现有路径，避免破坏交叉引用。过去的通过结果只证明当时版本的检查，不代表新一轮已验证。部分辅助资料目前仅存在于本地工作区，仓库限制见 STATUS。

项目另有用于开发辅助的 `tools/`、用于宣传工程的 `marketing/` 和用于独立动画的 `experiments/phase2/`。职责与访问边界由 AGENTS 定义，这些目录不属于应用源码。
