# Representative wish illustrations

[English](WISH_ILLUSTRATIONS.md) · [简体中文](WISH_ILLUSTRATIONS.zh-CN.md)

2026-11-10. Branch: codex/wish-images. Integration target: main. Visual review is ongoing; device delivery, integration and push are pending. Other independent work has not been integrated.

Three new representative categories extend the existing four choices to seven: suitcase for travel and holidays; sweater for clothing and personal style; books for reading, courses and learning. The user removed the sneaker and armchair during review. Existing controller, headphones, camera and gift remain unchanged. Illustration selection is explicit; users supply their own wish name and amount, without automatic category or price inference.

Style follows the existing crisp physical-object 3D renders, soft lighting and refined materials. Pink is optional, not a palette requirement. The revised sweater is muted slate blue, neatly arranged with level shoulders, straight sleeves and an even hem, without rumpled fabric or prominent folds.

Built-in ImageGen produced the original transparent PNGs, copied unchanged into assets/characters with alpha preserved. Travel and books used descriptive prompts without image inputs. The revised sweater used the existing controller, headphones and camera as style references only. No new dependencies, database migration or backup format change is required. The existing editor displays seven choices across two rows.

Validation for the previous checkpoint: formatting, static analysis, 19 focused tests and a release APK build passed. After removing the armchair and revising the sweater, formatting, static analysis and 18 focused tests passed; no APK rebuild/install during individual review annotations. Full prompts follow.

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
