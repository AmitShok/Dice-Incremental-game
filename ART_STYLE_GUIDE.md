# Art style guide

## Visual identity
Walnut, deep green felt, worn brass, cream ivory and muted jewel colors. Upper-left highlights, lower-right shadows. Cozy tabletop with ledger, candles, ceramic cup, plant and loose chips. Moss is an original long-eared croupier in a green apron and little cap.

## Resolution and dimensions
Logical viewport 1120×640, integer aspect-preserving scaling; Compatibility renderer. Canvas nearest filtering is set explicitly on the root. Room source: 480×300, displayed at ×2. Dice: 32×32 frames, normal display ×2 and dense tables at ×1; polyhedral silhouettes vary by family. Helper: 24×32, displayed at ×2 with pixel-rounded positions. UI skin sources: 16×16 nine-patch textures, 5px margins. Spark:16×16; shadow:32×12; currency icon:16×16. Temporary squash/stretch uses nearest-filtered transforms intentionally.

## Palette
Ink #171921, panel #242b32, walnut #493530, grain #624337, brass #b98b51, warm highlight #f5db9f, ivory #f0dfbd, felt #254942, felt shadow #203e39, jade #82ad96, rose #c68380. Dice have documented per-family accents in the Aseprite construction script.

## Pixel rules
One-pixel dark outlines at source resolution; restrained 1px top highlights; no antialiased source edges or blurry texture filtering. Readable faces at native frame size. Standard D6 uses pips, polyhedra use compact numerals. Built-in Godot font is retained for readable UI and no external font-license dependency.

## Animation
Face animation: ~11fps source metadata; visual tumbling samples at 19fps during a tween. Helper source:12 frames tagged idle, walk, interact, roll, celebrate at 0.12 seconds/frame. Physical movement is controlled, not result-determining physics. Prioritize anticipation, a readable apex, a clear landing and stable result. Reduced-motion mode removes throw movement/rotation while preserving resolution timing.

## Source of truth
assets/source/aseprite/{dice,helpers,environment,ui,effects,icons} stores editable, layered .aseprite originals. assets/exported stores PNG and frame/tag JSON exports. Creation and export execute in installed Aseprite via its Lua API; there are no ImageGen/stock/ripped assets. tools/export_art.lua is the normal pipeline. Never hand-edit a PNG and treat it as the master.

## Remaining visual gates
Hand-review animation silhouettes and timing in Aseprite and polish dense-table labels. Player art-direction review is still needed before declaring the art commercial-release quality. The original legacy sprite strips are preserved separately by their existing paths and Git history.
