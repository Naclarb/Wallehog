# 心愿类别代表物插画

[English](WISH_ILLUSTRATIONS.md) · [简体中文](WISH_ILLUSTRATIONS.zh-CN.md)

2026-11-10。分支：codex/wish-images；集成目标：main。视觉评审进行中；真机交付、集成及推送待完成，其他独立工作尚未集成。

新增三类代表物，现有四个选项扩展为七个：旅行箱代表旅行与度假；针织衫代表服装与穿搭；书本代表阅读、课程与学习。用户在评审中移除了运动鞋与扶手椅。现有手柄、耳机、相机和礼物不变。用户明确选择图片，自己填写心愿名称和金额，不自动推断类别或价格。

风格遵循现有素材清晰的实体物件立体效果、柔和光照与精致材质。粉色可选，并非配色要求。新版针织衫采用低饱和灰蓝色，肩线水平、袖子平直、下摆齐整，避免凌乱衣形和明显褶皱。

原创透明 PNG 由内置 ImageGen 生成，原样复制到 assets/characters 并保留 alpha。旅行箱与书本使用文字描述，未输入图片；新版针织衫以现有手柄、耳机和相机作为风格参考。无需新增依赖、数据库迁移或备份格式变更。现有编辑器分两行显示七个选项。

此前检查点的格式化、静态分析、19 项相关测试及 release APK 构建通过。移除扶手椅并重做衣服后，格式化、静态分析与 18 项相关测试通过，不针对单条批注重复构建或安装 APK。以下为完整提示词。

## wish-travel-v1.png

```text
Use case: stylized-concept. Asset type: Wallehog mobile savings wish-card transparent illustration. One compact rounded carry-on suitcase with telescopic handle and small wheels, ivory shell with muted blush trim. Represents travel, holidays and exploring; no destination-specific decoration. Premium satin physical product 3D render matching the existing ivory champagne camera and blush gift assets. Soft upper-left studio lighting, delicate pink reflected light, refined tactile material, calm warm playful mood. Three-quarter view facing slightly left, centered square composition, entire object visible occupying about 78 percent of canvas with generous margins. Gently floating isolated cutout. Actual transparent background. No brand, logos, text, letters, numbers, coins, people, pig, scenery, ground plane, baked drop shadow or watermark. A representative category symbol that remains recognizable at 64px; simple clear silhouette, restrained detail. Save PNG.
```

## wish-clothing-v1.png

```text
Use case: stylized-concept. Create a new Wallehog savings app wish illustration. Input images 1-3 are STYLE REFERENCES ONLY: existing controller, headphones and camera. Match their premium realistic physical-object 3D product render, crisp silhouette, restrained material detailing, soft upper-left studio lighting and clean isolated presentation; do not copy their subjects. Subject: ONE unbranded gender-neutral classic fine-knit crew-neck pullover in muted slate blue, with matching tonal ribbed collar, cuffs and hem, no pink trim. The sweater represents clothing and personal style generally. Neat product catalog display, pressed and meticulously arranged, frontal view with extremely subtle depth, straight horizontal hem, balanced level shoulders, both sleeves straight and neatly angled downward symmetrically, no bent cuffs. Smooth even body and sleeves, NO wrinkles, rumples, draped folds, sagging fabric, bunching, creases or wavy hem. Fine subtle knit texture is visible but shape is structured and tidy, not inflated or puffy. Garment empty, no mannequin, person, hanger or body. Single centered object fully visible within square canvas with 10 percent transparent margins. Actual transparent background with clean antialiasing. No text, labels, brands, logos, decorations, coins, pig, props, scenery, ground, baked drop shadow or watermark. This is a clothing category representative, not a fashion advertisement. Keep it readable as a small wish-card icon.
```

## wish-learning-v1.png

```text
Use case: stylized-concept. Asset type: Wallehog mobile savings wish-card transparent illustration. Two beautifully bound books stacked with one slightly rotated, ivory and muted sage covers with a blush ribbon bookmark. Represents reading, courses, study and personal growth; blank covers and spines. Premium satin physical product 3D render matching the existing ivory champagne camera and blush gift assets. Soft upper-left studio lighting, delicate pink reflected light, refined tactile material, calm warm playful mood. Three-quarter view facing slightly left, centered square composition, entire object visible occupying about 78 percent of canvas with generous margins. Gently floating isolated cutout. Actual transparent background. No brand, logos, text, letters, numbers, coins, people, pig, scenery, ground plane, baked drop shadow or watermark. A representative category symbol that remains recognizable at 64px; simple clear silhouette, restrained detail. Save PNG.
```
