# How to use TOWN FOLK 2

Everything here is a plain transparent PNG. There is no engine project, no
plugin and nothing to install - you copy the folder into your game and go.

If you only read one line, read this one:

> **Turn texture filtering OFF.** Every engine smooths textures by default.
> On pixel art that turns crisp edges into mush. Each section below says
> where the switch is.

---

## What a sheet looks like

Every animation is one PNG laid out as a grid: **four rows, one per
direction**, always in this order.

    row 0   facing down   (towards the camera)
    row 1   facing left
    row 2   facing right
    row 3   facing up     (away from the camera)

Columns are the frames of the loop. `MANIFEST.csv` gives you `columns`,
`frame_w` and `frame_h` for every single file, so you never have to measure
anything or hard-code a rectangle.

Scaling down is fine, scaling **up** is not - it produces soft or uneven
pixels. The figures are drawn at 64 px and cropped to fit, never enlarged.

---

## Godot 4

1. Drag the folder into your project's `res://` tree.
2. Select all imported PNGs, open the **Import** tab and set
   **Filter: Off** and **Mipmaps: Off**, then press **Reimport**.
   (Or set it once for the whole project: *Project Settings > Rendering >
   Textures > Canvas Textures > Default Texture Filter = Nearest*.)
3. Add an `AnimatedSprite2D`, create a `SpriteFrames` resource and use
   *Add frames from sprite sheet*. Set the horizontal count to `columns` and
   the vertical count to 4, then pick the row you need per direction.

## Unity

1. Copy the folder into `Assets/`.
2. Select the PNGs and in the Inspector set
   **Texture Type: Sprite (2D and UI)**, **Sprite Mode: Multiple**,
   **Filter Mode: Point (no filter)**, **Compression: None**.
3. Open the **Sprite Editor**, choose *Slice > Grid By Cell Count* and enter
   `columns` x 4.
4. Set **Pixels Per Unit** to the frame height so one figure equals one world
   unit.

## GameMaker

1. *Create Sprite > Import* the PNG, then *Edit Image > Image > Convert to
   Frames* with the grid from `MANIFEST.csv`.
2. In *Game Options > Graphics*, turn **Interpolate colours between pixels**
   OFF.
3. Set the sprite origin to **bottom centre** - every frame is aligned by the
   feet, so that origin keeps the figure standing still while it animates.

## Web (Phaser, PixiJS, plain canvas)

```css
img, canvas { image-rendering: pixelated; }
```

```js
// Phaser 3
const config = { render: { pixelArt: true } };
this.load.spritesheet('brewer_walk', 'characters/brewer/walk.png',
  { frameWidth: 64, frameHeight: 64 });   // read the numbers from MANIFEST.csv
```

## RPG Maker

The sheets are four-direction grids in the same order RPG Maker uses
(down / left / right / up), so a sheet drops into `img/characters/` once the
column count matches your character template.

---

## Getting it to look right

1. **Align by the feet, not the centre.** Frame size differs between sheets -
   read the grid per file. Draw every
   frame with its bottom edge on the floor line.
2. **Add a soft shadow under each figure.** A blurred dark ellipse at the base.
   Without it, everything floats.
3. **Do not mix frame rates per direction.** All four rows of a sheet have the
   same number of columns, so one timer drives the whole sheet.

---

## Using this pack with a code assistant

`MANIFEST.csv` lists every file with its exact grid: columns, rows, frame size
and row order. Point your assistant at that file and it can wire up animations
without opening a single image.

```
Read MANIFEST.csv in this folder. For every row with state "walk" (and "attack" = the work loop), build a
four-direction animation using columns frames of frame_w x frame_h, rows in
the order given by row_order.
```

---

## Licence

Use it in commercial and free games, modified or as is. No credit required
(though it is always welcome).

What you may not do is resell or redistribute the assets themselves, give them
away as files, or use them as training data. Full text in LICENSE.txt.

Questions or a broken file: leave a comment on the store page - it gets fixed
and everyone gets the update.

More packs: https://gegx.itch.io
