# 心愿类别代表物插画

[English](WISH_ILLUSTRATIONS.md) · [简体中文](WISH_ILLUSTRATIONS.zh-CN.md)

2026-11-10。集成目标：main；开发分支：codex/wish-images。视觉验收待完成，此检查点不代表真机交付完成。

新增插画用代表物表达类别，而非具体品牌或型号：旅行箱代表旅行与度假；针织衫代表服装、穿搭与衣橱更新；书本代表阅读、课程与学习；扶手椅代表家具、布置与居家舒适。现有四个选项扩展为八个，原手柄、耳机、相机与礼物不变。用户明确选择图片并填写自己的心愿名称与金额，不按名称推断类别或价格。

原创 PNG 使用内置 ImageGen 生成，原样复制到 assets/characters 并保留 alpha。生成时未输入参考图片；提示词沿用现有相机与礼物的材质、光照描述。无需新增依赖、数据库迁移或备份格式变更。现有编辑器将八个选项自动排列为两行。

待完成：用户视觉反馈、最终真机验证与普通应用覆盖安装、集成及推送。其他进行中的分支尚未集成。以下为完整提示词。

替换运动鞋前的检查点验证：四张 PNG 均为 1254 × 1254 RGBA，含真实透明通道。Dart 格式化、flutter analyze、19 项相关测试、release APK 构建及 git diff --check 通过。

评审更新：用户要求将鞋子换成衣服。新针织衫使用 clothing 样式键及“服饰穿搭”名称。运动鞋已从运行素材移除，之前的源码检查点保留历史。新 PNG 为 1254 × 1254 RGBA。替换后格式化、分析及 19 项相关测试通过。本轮评审迭代未重复构建或安装 APK。

## wish-travel-v1.png

```text
Use case: stylized-concept. Asset type: Wallehog mobile savings wish-card transparent illustration. One compact rounded carry-on suitcase with telescopic handle and small wheels, ivory shell with muted blush trim. Represents travel, holidays and exploring; no destination-specific decoration. Premium satin physical product 3D render matching the existing ivory champagne camera and blush gift assets. Soft upper-left studio lighting, delicate pink reflected light, refined tactile material, calm warm playful mood. Three-quarter view facing slightly left, centered square composition, entire object visible occupying about 78 percent of canvas with generous margins. Gently floating isolated cutout. Actual transparent background. No brand, logos, text, letters, numbers, coins, people, pig, scenery, ground plane, baked drop shadow or watermark. A representative category symbol that remains recognizable at 64px; simple clear silhouette, restrained detail. Save PNG.
```

## wish-clothing-v1.png

```text
undefined
```

## wish-learning-v1.png

```text
Use case: stylized-concept. Asset type: Wallehog mobile savings wish-card transparent illustration. Two beautifully bound books stacked with one slightly rotated, ivory and muted sage covers with a blush ribbon bookmark. Represents reading, courses, study and personal growth; blank covers and spines. Premium satin physical product 3D render matching the existing ivory champagne camera and blush gift assets. Soft upper-left studio lighting, delicate pink reflected light, refined tactile material, calm warm playful mood. Three-quarter view facing slightly left, centered square composition, entire object visible occupying about 78 percent of canvas with generous margins. Gently floating isolated cutout. Actual transparent background. No brand, logos, text, letters, numbers, coins, people, pig, scenery, ground plane, baked drop shadow or watermark. A representative category symbol that remains recognizable at 64px; simple clear silhouette, restrained detail. Save PNG.
```

## wish-home-v1.png

```text
Use case: stylized-concept. Asset type: Wallehog mobile savings wish-card transparent illustration. One inviting rounded upholstered armchair, ivory soft fabric, pale wooden feet and one muted blush cushion. Represents furniture, home decoration and a comfortable living space, not a particular product. Premium satin physical product 3D render matching the existing ivory champagne camera and blush gift assets. Soft upper-left studio lighting, delicate pink reflected light, refined tactile material, calm warm playful mood. Three-quarter view facing slightly left, centered square composition, entire object visible occupying about 78 percent of canvas with generous margins. Gently floating isolated cutout. Actual transparent background. No brand, logos, text, letters, numbers, coins, people, pig, scenery, ground plane, baked drop shadow or watermark. A representative category symbol that remains recognizable at 64px; simple clear silhouette, restrained detail. Save PNG.
```

