# Representative wish illustrations

[English](WISH_ILLUSTRATIONS.md) · [简体中文](WISH_ILLUSTRATIONS.zh-CN.md)

2026-11-10. Integration target: main; development branch: codex/wish-images. Visual acceptance is pending. Do not treat this checkpoint as completed device delivery.

New illustrations represent categories rather than particular brands or models: suitcase for travel and holidays; sweater for clothing, personal style and wardrobe upgrades; books for reading, courses and learning; armchair for furniture, decoration and home comfort. These extend the existing four choices to eight. Existing controller, headphones, camera and gift remain unchanged. Users select an illustration explicitly and supply their own wish name and amount; names do not infer categories or prices.

Original PNGs were generated using the built-in ImageGen tool, copied unchanged into assets/characters, with alpha preserved. No reference image was supplied to generation. Prompts use the existing camera and gift's material and lighting description. No dependency, database migration or backup format change is required. The existing editor wraps the eight options into two rows.

Pending: user visual feedback, final device validation and ordinary-app installation, integration and push. Other ongoing branches have not been integrated. Full prompts follow.

Previous checkpoint validation (before replacing the sneaker): all four PNGs are 1254 × 1254 RGBA with genuine alpha. Dart formatting, flutter analyze, 19 focused tests, release APK build and git diff --check passed.

Review update: the user requested replacing the sneaker with clothing. The new sweater uses style key clothing and label Clothing and style. The sneaker is removed from runtime assets; the earlier source checkpoint preserves its history. The new PNG is 1254 × 1254 RGBA. Formatting, analysis and 19 focused tests pass after replacement. No APK rebuild/install during this review iteration.

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

