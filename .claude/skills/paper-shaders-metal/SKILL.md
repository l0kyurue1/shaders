---
name: paper-shaders-metal
description: Param semantics for the 29 Paper Shaders Metal shaders — drives the preview app via the MCP tools set_shader/set_params.
---

# Paper Shaders (Metal) — param reference

Drive the preview app in two steps:

1. `set_shader` with a shader `id` (the backticked id in each heading below).
2. `set_params` with a name-keyed object, e.g. `{ "softness": 0.8 }`.

Params are keyed by **name**, not uniform slot. Enum values are the **option label string** (e.g. `"shape": "stripes"`), single colors are hex strings (`"#rrggbbaa"`), `colors` is an array of hex strings. `speed` and `frame` are host-driven motion params.

## Color Panels (`color-panels`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 7 RGBA colors used to color the panels
- `colorBack` (string) — Background color in RGBA
- `angle1` (number, range -1–1) — Skew angle applied to all panes
- `angle2` (number, range -1–1) — Skew angle applied to all panes
- `length` (number, range 0–3) — Panel length relative to total height
- `edges` (boolean) — Color highlight on the panels edges
- `blur` (number, range 0–0.5) — Side blur, 0 for sharp edges
- `fadeIn` (number, range 0–1) — Transparency near central axis
- `fadeOut` (number, range 0–1) — Transparency near viewer
- `gradient` (number, range 0–1) — Color mixing within a panel, 0 = solid, 1 = gradient
- `density` (number, range 0.25–7) — Angle between every 2 panels

## Dithering (`dithering`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorFront` (string) — Foreground (ink) color in RGBA
- `shape` (string, options: simplex/warp/dots/wave/ripple/swirl/sphere) — Shape pattern type (1 = simplex, 2 = warp, 3 = dots, 4 = wave, 5 = ripple, 6 = swirl, 7 = sphere)
- `type` (string, options: random/2x2/4x4/8x8) — Dithering type (1 = random, 2 = 2x2 Bayer, 3 = 4x4 Bayer, 4 = 8x8 Bayer)
- `size` (number, range 0.5–20) — Pixel size of dithering grid

## Dot Grid (`dot-grid`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `colorBack` (string) — Background color in RGBA
- `colorFill` (string) — Shape fill color in RGBA
- `colorStroke` (string) — Shape stroke color in RGBA
- `size` (number, range 1–100) — Base size of each shape in pixels
- `gapX` (number, range 2–500) — Pattern horizontal spacing in pixels
- `gapY` (number, range 2–500) — Pattern vertical spacing in pixels
- `strokeWidth` (number, range 0–50) — Outline stroke width in pixels
- `sizeRange` (number, range 0–1) — Random variation in shape size, 0 = uniform, higher = random up to base size
- `opacityRange` (number, range 0–1) — Random variation in shape opacity, 0 = opaque, higher = semi-transparent
- `shape` (string, options: circle/diamond/square/triangle) — Shape type (0 = circle, 1 = diamond, 2 = square, 3 = triangle)

## Dot Orbit (`dot-orbit`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 10 base colors in RGBA
- `size` (number, range 0–1) — Dot radius relative to cell size
- `sizeRange` (number, range 0–1) — Random variation in shape size, 0 = uniform, higher = random up to base size
- `spreading` (number, range 0–1) — Maximum orbit distance around cell center
- `stepsPerColor` (number, range 1–4) — Number of extra colors between base colors, 1 = N colors, 2 = 2×N, etc.

## Fluted Glass (`fluted-glass`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number)
- `worldHeight` (number)
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorShadow` (string) — Shadows color in RGBA
- `colorHighlight` (string) — Highlights color in RGBA
- `shadows` (number, range 0–1) — Color gradient added over image and background, following distortion shape
- `size` (number, range 0–1) — Size of the distortion shape grid
- `angle` (number, range 0–180) — Direction of the grid relative to the image in degrees
- `distortionShape` (string, options: prism/lens/contour/cascade/flat) — Shape of distortion (1 = prism, 2 = lens, 3 = contour, 4 = cascade, 5 = flat)
- `highlights` (number, range 0–1) — Thin strokes along distortion shape, useful for antialiasing on small grid
- `shape` (string, options: lines/linesIrregular/wave/zigzag/pattern) — Grid shape (1 = lines, 2 = linesIrregular, 3 = wave, 4 = zigzag, 5 = pattern)
- `distortion` (number, range 0–1) — Power of distortion applied within each stripe
- `shift` (number, range -1–1) — Texture shift in direction opposite to the grid
- `blur` (number, range 0–1) — One-directional blur over the image and extra blur around edges
- `edges` (number, range 0–1) — Glass distortion and softness on the image edges
- `stretch` (number, range 0–1) — Extra distortion along the grid lines
- `margin` (number)
- `marginLeft` (number, range 0–1) — Distance from the left edge to the effect
- `marginRight` (number, range 0–1) — Distance from the right edge to the effect
- `marginTop` (number, range 0–1) — Distance from the top edge to the effect
- `marginBottom` (number, range 0–1) — Distance from the bottom edge to the effect
- `grainMixer` (number, range 0–1) — Strength of grain distortion applied to shape edges
- `grainOverlay` (number, range 0–1) — Post-processing black/white grain overlay

## Gem Smoke (`gem-smoke`, Logo Animations)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorInner` (string) — Additional color inside the input shape, mixing with smoke (RGBA)
- `colors` (colors) — Up to 6 smoke colors in RGBA
- `outerGlow` (number, range 0–1) — Visibility of smoke shape outside the input shape
- `innerGlow` (number, range 0–1) — Visibility of smoke shape inside the input shape
- `innerDistortion` (number, range 0–1) — Power of smoke distortion inside the input shape
- `outerDistortion` (number, range 0–1) — Power of smoke distortion outside the input shape
- `offset` (number, range -1–1) — Vertical offset of smoke inside the shape
- `angle` (number, range 0–360) — Smoke direction in degrees
- `size` (number, range 0–1) — Size of smoke shape relative to the image box
- `shape` (string, options: none/circle/daisy/diamond/metaballs)

## God Rays (`god-rays`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `colorBack` (string) — Background color in RGBA
- `colorBloom` (string) — Color overlay blended with the rays in RGBA
- `colors` (colors) — Up to 5 ray colors in RGBA
- `density` (number, range 0–1) — The number of rays
- `spotty` (number, range 0–1) — The length of the rays, higher = more spots/shorter rays
- `midIntensity` (number, range 0–1) — Brightness/intensity of the central glow
- `midSize` (number, range 0–1) — Size of the circular glow shape in the center
- `intensity` (number, range 0–1) — Visibility/strength of the rays
- `bloom` (number, range 0–1) — Strength of the bloom/overlay effect, 0 = alpha blend, 1 = additive blend
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)

## Grain Gradient (`grain-gradient`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 7 gradient colors in RGBA
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `intensity` (number, range 0–1) — Distortion between color bands
- `noise` (number, range 0–1) — Grainy noise overlay
- `shape` (string, options: wave/dots/truchet/corners/ripple/blob/sphere) — Shape type (1 = wave, 2 = dots, 3 = truchet, 4 = corners, 5 = ripple, 6 = blob, 7 = sphere)

## Halftone Cmyk (`halftone-cmyk`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number)
- `worldHeight` (number)
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background (paper) color in RGBA
- `colorC` (string) — Cyan ink color in RGBA
- `colorM` (string) — Magenta ink color in RGBA
- `colorY` (string) — Yellow ink color in RGBA
- `colorK` (string) — Black ink color in RGBA
- `size` (number, range 0–1) — Halftone cell size
- `contrast` (number, range 0–2) — Image contrast adjustment
- `softness` (number, range 0–1) — Edge softness of dots
- `grainSize` (number, range 0–1) — Size of grain overlay texture
- `grainMixer` (number, range 0–1) — Strength of grain affecting dot size
- `grainOverlay` (number, range 0–1) — Strength of grain overlay on final output
- `gridNoise` (number, range 0–1) — Strength of smooth noise applied to both dot positions and color sampling
- `floodC` (number, range -1–1) — Flat cyan dot size adjustment applied uniformly
- `floodM` (number, range -1–1) — Flat magenta dot size adjustment applied uniformly
- `floodY` (number, range -1–1) — Flat yellow dot size adjustment applied uniformly
- `floodK` (number, range -1–1) — Flat black dot size adjustment applied uniformly
- `gainC` (number, range -1–1) — Proportional cyan dot size gain (enhances existing dots)
- `gainM` (number, range -1–1) — Proportional magenta dot size gain (enhances existing dots)
- `gainY` (number, range -1–1) — Proportional yellow dot size gain (enhances existing dots)
- `gainK` (number, range -1–1) — Proportional black dot size gain (enhances existing dots)
- `type` (string, options: dots/ink/sharp) — Dot shape style (0 = dots, 1 = ink, 2 = sharp)

## Halftone Dots (`halftone-dots`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number)
- `worldHeight` (number)
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorFront` (string) — Foreground color in RGBA
- `size` (number, range 0–1) — Grid size relative to the image box
- `radius` (number, range 0–2) — Maximum dot size relative to grid cell
- `contrast` (number, range 0–1) — Contrast applied to the sampled image
- `originalColors` (boolean) — Use sampled image's original colors instead of colorFront
- `inverted` (boolean) — Inverts the image luminance, doesn't affect the color scheme; not effective at zero contrast
- `grainMixer` (number, range 0–1) — Strength of grain distortion applied to shape edges
- `grainOverlay` (number, range 0–1) — Post-processing black/white grain overlay
- `grainSize` (number, range 0–1) — Scale applied to both grain distortion and grain overlay
- `grid` (string, options: square/hex) — Grid type (0 = square, 1 = hex)
- `type` (string, options: classic/gooey/holes/soft) — Dot style (0 = classic, 1 = gooey, 2 = holes, 3 = soft)

## Heatmap (`heatmap`, Logo Animations)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `contour` (number, range 0–1) — Heat intensity near the edges of the input shape
- `angle` (number, range 0–360) — Direction of the heatwaves in degrees
- `noise` (number, range 0–1) — Grain applied across the entire graphic
- `innerGlow` (number, range 0–1) — Size of the heated area inside the input shape
- `outerGlow` (number, range 0–1) — Size of the heated area outside the input shape
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 10 heatmap colors in RGBA

## Image Dithering (`image-dithering`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorFront` (string) — Foreground color in RGBA
- `colorBack` (string) — Background color in RGBA
- `colorHighlight` (string) — Secondary foreground color in RGBA (set same as colorFront for classic 2-color dithering)
- `type` (string, options: random/2x2/4x4/8x8) — Dithering type (1 = random, 2 = 2x2 Bayer, 3 = 4x4 Bayer, 4 = 8x8 Bayer)
- `size` (number, range 0.5–20) — Pixel size of dithering grid
- `colorSteps` (number, range 1–7) — Number of colors to use, applies to both color modes
- `originalColors` (boolean) — Use the original colors of the image instead of the color palette
- `inverted` (boolean) — Inverts the image luminance, doesn't affect the color scheme; not effective at zero contrast

## Liquid Metal (`liquid-metal`, Logo Animations)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorTint` (string) — Overlay color in RGBA (color burn blending used)
- `distortion` (number, range 0–1) — Noise distortion over the stripes pattern
- `repetition` (number, range 1–10) — Density of pattern stripes
- `shiftRed` (number, range -1–1) — R-channel dispersion
- `shiftBlue` (number, range -1–1) — B-channel dispersion
- `contour` (number, range 0–1) — Strength of the distortion on the shape edges
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `angle` (number, range 0–360) — Direction of pattern animation in degrees
- `shape` (string, options: none/circle/daisy/diamond/metaballs) — Predefined shape when no image provided (0 = none, 1 = circle, 2 = daisy, 3 = diamond, 4 = metaballs)

## Mesh Gradient (`mesh-gradient`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 10 color spots in RGBA
- `distortion` (number, range 0–1) — Power of organic noise distortion
- `swirl` (number, range 0–1) — Power of vortex distortion
- `grainMixer` (number, range 0–1) — Strength of grain distortion applied to shape edges
- `grainOverlay` (number, range 0–1) — Post-processing black/white grain overlay

## Metaballs (`metaballs`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 8 base colors in RGBA
- `count` (number, range 1–20) — Number of balls
- `size` (number, range 0–1) — Size of the balls

## Neuro Noise (`neuro-noise`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorFront` (string) — Graphics highlight color in RGBA
- `colorMid` (string) — Graphics main color in RGBA
- `colorBack` (string) — Background color in RGBA
- `brightness` (number, range 0–1) — Luminosity of the crossing points
- `contrast` (number, range 0–1) — Sharpness of the bright-dark transition

## Paper Texture (`paper-texture`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorFront` (string) — Foreground color in RGBA
- `colorBack` (string) — Background color in RGBA
- `contrast` (number, range 0–1) — Blending behavior, sharper vs smoother color transitions
- `roughness` (number, range 0–1) — Pixel noise, related to canvas and not scalable
- `fiber` (number, range 0–1) — Curly-shaped noise intensity
- `fiberSize` (number, range 0–1) — Curly-shaped noise scale
- `crumples` (number, range 0–1) — Cell-based crumple pattern intensity
- `crumpleSize` (number, range 0–1) — Cell-based crumple pattern scale
- `folds` (number, range 0–1) — Depth of the folds
- `foldCount` (number, range 1–15) — Number of folds
- `fade` (number, range 0–1) — Big-scale noise mask applied to the pattern
- `drops` (number, range 0–1) — Visibility of speckle pattern
- `seed` (number, range 0–1000) — Seed applied to folds, crumples and dots

## Perlin Noise (`perlin-noise`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorFront` (string) — Foreground color in RGBA
- `proportion` (number, range 0–1) — Blend point between 2 colors, 0.5 = equal distribution
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `octaveCount` (number, range 1–8) — Perlin noise octaves number, more octaves for more detailed patterns
- `persistence` (number, range 0.3–1) — Roughness, falloff between octaves
- `lacunarity` (number, range 1.5–10) — Frequency step, defines how compressed the pattern is

## Pulsing Border (`pulsing-border`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 5 spot colors in RGBA
- `roundness` (number, range 0–1) — Border radius
- `thickness` (number, range 0–1) — Border base width
- `margin` (number)
- `marginLeft` (number, range 0–1) — Distance from the left edge to the effect
- `marginRight` (number, range 0–1) — Distance from the right edge to the effect
- `marginTop` (number, range 0–1) — Distance from the top edge to the effect
- `marginBottom` (number, range 0–1) — Distance from the bottom edge to the effect
- `aspectRatio` (string, options: auto/square) — Aspect ratio mode (0 = auto, 1 = square)
- `softness` (number, range 0–1) — Border edge sharpness, 0 = hard edge, 1 = smooth gradient
- `intensity` (number, range 0–1) — Thickness of individual color spots
- `bloom` (number, range 0–1) — Power of glow, 0 = normal blending, 1 = additive blending
- `spots` (number, range 1–20) — Number of spots added for each color
- `spotSize` (number, range 0–1) — Angular size of spots
- `pulse` (number, range 0–1) — Optional pulsing animation intensity
- `smoke` (number, range 0–1) — Optional noisy shape extending the border
- `smokeSize` (number, range 0–1) — Size of the smoke effect

## Simplex Noise (`simplex-noise`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 10 base colors in RGBA
- `stepsPerColor` (number, range 1–10) — Number of extra colors between base colors, 1 = N colors, 2 = 2×N, etc.
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient

## Smoke Ring (`smoke-ring`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 10 gradient colors in RGBA
- `noiseScale` (number, range 0.01–5) — Noise frequency
- `noiseIterations` (number, range 1–8) — Number of noise layers, more layers gives more details
- `radius` (number, range 0–1) — Radius of the ring shape
- `thickness` (number, range 0.01–1) — Thickness of the ring shape
- `innerShape` (number, range 0–4) — Ring inner fill amount

## Spiral (`spiral`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `colorBack` (string) — Background color in RGBA
- `colorFront` (string) — Foreground (ink) color in RGBA
- `density` (number, range 0–1) — Spacing falloff simulating perspective, 0 = flat spiral
- `distortion` (number, range 0–1) — Power of shape distortion applied along the spiral
- `strokeWidth` (number, range 0–1) — Thickness of spiral curve
- `strokeTaper` (number, range 0–1) — How much stroke loses width away from center, 0 = full visibility
- `strokeCap` (number, range 0–1) — Extra stroke width at the center, no effect with strokeWidth = 0.5
- `noise` (number, range 0–1) — Noise distortion applied over the canvas, no effect with noiseFrequency = 0
- `noiseFrequency` (number, range 0–1) — Noise frequency, no effect with noise = 0
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)

## Static Mesh Gradient (`static-mesh-gradient`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 10 gradient colors in RGBA
- `positions` (number, range 0–100) — Color spots placement seed
- `waveX` (number, range 0–1) — Strength of sine wave distortion along X axis
- `waveXShift` (number, range 0–1) — Phase offset applied to the X-axis wave
- `waveY` (number, range 0–1) — Strength of sine wave distortion along Y axis
- `waveYShift` (number, range 0–1) — Phase offset applied to the Y-axis wave
- `mixing` (number, range 0–1) — Blending behavior, 0 = hard stripes, 0.5 = smooth, 1 = gradual blend
- `grainMixer` (number, range 0–1) — Strength of grain distortion applied to shape edges
- `grainOverlay` (number, range 0–1) — Post-processing black/white grain overlay

## Static Radial Gradient (`static-radial-gradient`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 10 gradient colors in RGBA
- `radius` (number, range 0–3) — Size of the shape
- `focalDistance` (number, range 0–3) — Distance of the focal point from center
- `focalAngle` (number, range 0–360) — Angle of the focal point in degrees, effective with focalDistance > 0
- `falloff` (number, range -1–1) — Gradient decay, 0 = linear gradient
- `mixing` (number, range 0–1) — Blending behavior, 0 = hard stripes, 1 = smooth gradient
- `distortion` (number, range 0–1) — Strength of radial distortion
- `distortionShift` (number, range -1–1) — Radial distortion offset, effective with distortion > 0
- `distortionFreq` (number, range 0–20) — Radial distortion frequency, effective with distortion > 0
- `grainMixer` (number, range 0–1) — Strength of grain distortion applied to shape edges
- `grainOverlay` (number, range 0–1) — Post-processing black/white grain overlay

## Swirl (`swirl`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colors` (colors) — Up to 10 stripe colors in RGBA
- `bandCount` (number, range 0–15) — Number of color bands, 0 = concentric ripples
- `twist` (number, range 0–1) — Vortex power, 0 = straight sectoral shapes
- `center` (number, range 0–1) — How far from the center the swirl colors begin to appear
- `proportion` (number, range 0–1) — Blend point between colors, 0.5 = equal distribution
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `noiseFrequency` (number, range 0–1) — Noise frequency, no effect with noise = 0
- `noise` (number, range 0–1) — Strength of noise distortion, no effect with noiseFrequency = 0

## Voronoi (`voronoi`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 5 base cell colors in RGBA
- `stepsPerColor` (number, range 1–3) — Number of extra colors between base colors, 1 = N colors, 2 = 2×N, etc.
- `colorGlow` (string) — Color tint for radial inner shadow inside cells in RGBA, effective with glow > 0
- `colorGap` (string) — Color used for cell borders/gaps in RGBA
- `distortion` (number, range 0–0.5) — Strength of noise-driven displacement of cell centers
- `gap` (number, range 0–0.1) — Width of the border/gap between cells
- `glow` (number, range 0–1) — Strength of the radial inner shadow inside cells

## Warp (`warp`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colors` (colors) — Up to 10 gradient colors in RGBA
- `proportion` (number, range 0–1) — Blend point between colors, 0.5 = equal distribution
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient
- `distortion` (number, range 0–1) — Strength of noise-based distortion
- `swirl` (number, range 0–1) — Strength of the swirl distortion
- `swirlIterations` (number, range 0–20) — Number of layered swirl passes, effective with swirl > 0
- `shapeScale` (number, range 0–1) — Zoom level of the base pattern
- `shape` (string, options: checks/stripes/edge) — Base pattern type (0 = checks, 1 = stripes, 2 = edge)

## Water (`water`, Image Filters)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `speed` (number) — host-driven motion (not UBO-packed)
- `frame` (number) — host-driven motion (not UBO-packed)
- `colorBack` (string) — Background color in RGBA
- `colorHighlight` (string) — Highlight color in RGBA
- `highlights` (number, range 0–1) — Coloring added over image/background following caustic shape
- `layering` (number, range 0–1) — Power of 2nd layer of caustic distortion
- `edges` (number, range 0–1) — Caustic distortion power on the image edges
- `waves` (number, range 0–1) — Additional distortion based on simplex noise, independent from caustic
- `caustic` (number, range 0–1) — Power of caustic distortion
- `size` (number, range 0.01–7) — Pattern scale relative to the image

## Waves (`waves`, Effects)

- `fit` (string, options: none/contain/cover) — How to fit the rendered shader into the canvas dimensions (0 = none, 1 = contain, 2 = cover)
- `scale` (number, range 0.01–4) — Overall zoom level of the graphics
- `rotation` (number, range 0–360) — Overall rotation angle of the graphics in degrees
- `offsetX` (number, range -1–1) — Horizontal offset of the graphics center
- `offsetY` (number, range -1–1) — Vertical offset of the graphics center
- `originX` (number, range 0–1) — Reference point for positioning world width in the canvas
- `originY` (number, range 0–1) — Reference point for positioning world height in the canvas
- `worldWidth` (number) — Virtual width of the graphic before it's scaled to fit the canvas
- `worldHeight` (number) — Virtual height of the graphic before it's scaled to fit the canvas
- `colorFront` (string) — Foreground color in RGBA
- `colorBack` (string) — Background color in RGBA
- `shape` (number, range 0–3) — Line shape, 0 = zigzag, 1 = sine, 2-3 = irregular waves, fractional values morph between shapes
- `frequency` (number, range 0–2) — Wave frequency
- `amplitude` (number, range 0–1) — Wave amplitude
- `spacing` (number, range 0–2) — Space between every two wavy lines
- `proportion` (number, range 0–1) — Blend point between front and back colors, 0.5 = equal distribution
- `softness` (number, range 0–1) — Color transition sharpness, 0 = hard edge, 1 = smooth gradient

## Common intents → param

- softer / smoother gradient → `softness`
- bigger / zoom → `scale`
- slower / faster motion → `speed`
- rotate → `rotation`
- more distortion → `distortion` / `swirl`
