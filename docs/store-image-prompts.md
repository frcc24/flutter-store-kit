# Store image prompts — Mini Sudoku

Prompts for an image model (Imagen, DALL·E, Midjourney, Stable Diffusion,
ComfyUI). Keep one art direction across every asset: paste the style block
into every prompt.

## Style block (paste in every prompt)

```
Art style: flat, minimal, modern mobile game key art. Dark navy background
(#0B1A3D), electric cyan accents (#18E4FF), lime highlights (#B9FF3F), soft
white text. Clean geometric shapes, generous spacing, subtle glow, no
gradients heavier than 10%, no photorealism, no 3D render, no characters,
no clutter. Marketing quality, sharp edges, centered composition.
```

Negative prompt: `photorealistic, blurry, low-res, watermark, signature,
text errors, lorem ipsum, extra UI, busy background, neon overload`.

## Icon (1024×1024 PNG, exported to 512×512 for the listing)

```
App icon for a sudoku game. A 3×3 grid of rounded squares, one square lit
in lime, thin cyan grid lines, dark navy background with a faint radial
glow. No text. Reads at 48 pixels.
```

The kit's placeholder (`app/tool/make_icon.dart`) is this same idea drawn
in code; replace `app/assets/icon/icon.png` and run
`dart run flutter_launcher_icons` inside `app/`.

## Feature graphic (1024×500 PNG or JPG)

```
Wide banner for a sudoku app. Left third: the words "Mini Sudoku" in a clean
geometric sans-serif, white, with "Clean. Three levels. One free hint." in
smaller cyan text below. Right two thirds: a partially filled 9×9 sudoku
board seen straight on, thick lines every three cells in cyan, a few lime
digits, dark navy background.
```

Google overlays the play button on the center; keep text in the left third.

## Screenshots (4 to 8; phone 9:16, e.g. 1080×1920 PNG)

Take them from the app on a phone or the emulator (`adb exec-out screencap
-p > shot.png`), then add a caption band at the top in the same style. One
sentence per screenshot, present tense, no exclamation marks:

1. Game screen mid-puzzle — "A clean board. Nothing in the way."
2. Difficulty dialog — "Easy, Medium, Hard. Every puzzle has one solution."
3. Hint sheet — "One free hint per game. More if you want them."
4. Statistics — "Your best time per level, on your phone only."
5. Settings in Portuguese — "Português, English, Español."
6. Home screen — "No account. No e-mail. Just play."

Caption prompt for the band, if generated rather than composed:
```
Add a top caption band, 220 px tall, dark navy, white sans-serif text
"<caption>", left aligned, 56 px, subtle cyan underline. Keep the
screenshot untouched below the band.
```

## Checklist before upload

- Icon has no alpha (Play accepts it, iOS does not), 512×512, ≤ 1 MB.
- Feature graphic 1024×500, ≤ 15 MB, no rounded corners.
- Screenshots: same aspect ratio across the set, ≤ 8 MB each, min 320 px on
  the short side, max 3840 px on the long side.
- No claims the app cannot back ("#1", "best", "free forever").
