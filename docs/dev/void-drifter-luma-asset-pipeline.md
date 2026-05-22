# VOID DRIFTER Luma Asset Pipeline

This document prepares a safe Luma Uni-1.1-ready enemy asset workflow. It does not add API calls, dependencies, backend code, or runtime Luma access.

## Runtime Boundary

VOID DRIFTER runtime uses committed local assets only.

- Godot gameplay loads mirrored PNGs from `godot/void-drifter/assets/enemies/*`.
- Expo shell and Codex screens use shared metadata from `src/game/core/*` and preview PNGs from `assets/game/enemies/*/preview.png`.
- Luma prompts, reference images, generation notes, and future scripts are dev/build tooling only.
- Never call Luma from Expo, React Native, or bundled Godot web runtime.

Recommended structure:

```text
assets/game/enemies/
  enemy-assets-manifest.json
  <enemy-asset-folder>/
    sheets/
    frames-cell/
    frames-tight/
    preview.png
    references/
      luma/
        front.png
        top.png
        side.png
        turnaround-demo.png
    generation/
      luma-runs.json

docs/dev/
  void-drifter-luma-asset-pipeline.md

scripts/assets/
  validate-enemy-assets.mjs

tools/luma/
  README.md
  prompt-templates.ts
```

`scripts/assets/*` is a future optional tooling location. `tools/luma/*` contains the local-only API tooling for dry runs and approved reference generation.

## Enemy Manifest

`assets/game/enemies/enemy-assets-manifest.json` is the canonical asset pipeline manifest. It records source sheets, generated gameplay frame paths, source metadata, and empty Luma generation metadata for the current enemies.

`src/game/core/enemies.ts` remains the runtime gameplay registry for Expo UI. `godot/void-drifter/scripts/void_drifter_game.gd` remains the mirrored Godot gameplay registry. Only update those runtime registries when an enemy should actually appear in the game.

Manifest entries should include:

- `enemyId`: runtime gameplay id, such as `void_drone`.
- `assetKey`: runtime asset key, such as `red_scout_drone`.
- `assetFolder`: folder under `assets/game/enemies/`.
- `displayName`, `archetype`, `role`, `description`, `status`, and `rarityTier`.
- `stats`, `scaling`, `spawn`, and `abilities` copied from the approved runtime definition when the enemy is active.
- `sprites.preview`, `sprites.sheets`, `sprites.framesCell`, and optional `sprites.framesTight`.
- `source.provider`, `source.sourceFiles`, and `source.notes`.
- `generation.provider`, `generation.model`, `generation.promptTemplateIds`, `generation.referenceImagePaths`, and optional Luma generation ids after future API/tooling work.

## Animation And Enemy Guardrails

New enemy animation work must preserve gameplay readability before adding visual variety.

- Gameplay sprites must come from fixed `frames-cell` canvases with stable pivots. Do not use `frames-tight` as a gameplay source.
- Direction labels are semantic: `*-right` means the ship nose points right and thrusters sit on the left; `*-left` means the ship nose points left and thrusters sit on the right. Verify this for every enemy before export.
- Movement silhouettes should remain primary in gameplay. If attack, hit, damaged, or combat frames read like death/explosion art, keep the movement frame visible and render the combat moment as a flash, spark, telegraph, projectile, or death VFX overlay.
- Hit feedback should be short and non-destructive: flash/spark/scorch overlay for roughly 100-150ms, not a death or explosion sprite.
- Death sprites and shared explosion VFX only appear when the enemy is removed/killed.
- Attack feedback should be event-based and timer-driven. Avoid continuous charge flicker or per-frame state flipping.
- Direction changes should use velocity dominance plus hysteresis/lock timing so diagonal chase movement does not swap frames every frame.
- Each generated enemy side frame must be visually checked for cut-off hulls, neighbor sprites, wrong thruster orientation, and baked dark/red background slabs before it enters Godot.
- Codex previews use `preview.png`, not gameplay-tight frames, so dark ships remain readable on dark UI.

## Prompt Templates

Use English prompts for the most consistent output. Keep the ship identity stable across templates and change one major variable per generation pass.

```text
enemy.reference.front
Create a clean front-view reference of a VOID DRIFTER enemy ship named {displayName}. Arcade-readable sci-fi silhouette, dark hull with neon red/cyan accents, transparent or flat neutral background, centered full object, no text, no UI, no pilot, no environment, consistent hard-surface details.

enemy.reference.turnaround
Create a 4-view turnaround reference sheet for {displayName}: front, rear/top, left side, right side. Same ship identity in every view, centered, consistent proportions, arcade-readable silhouette, neutral background, no labels, no text.

enemy.sprite.transparent
Create a transparent-background game sprite of {displayName}, 384x512 canvas, centered stable pivot, readable at {recommendedDisplaySize}px, neon arcade sci-fi material, no shadow baked into background, no cropping, no text.

enemy.animation.attack
Create attack-state sprite references for {displayName}: idle silhouette preserved, weapon glow active, muzzle/charge accents visible, same 384x512 centered canvas, transparent background, no explosion or death damage.

enemy.animation.damaged
Create damaged-state sprite references for {displayName}: same silhouette and pose as the movement sprite, small hull cracks, sparks, scorch marks, readable but not destroyed, transparent background.

enemy.animation.death
Create a death/explosion variant for {displayName}: debris and energy burst matching the ship palette, transparent background, suitable as short overlay VFX, do not replace movement sprite silhouette.

enemy.demo.turnaround
Create a polished 3D/turnaround demo reference for {displayName}, same design language, three-quarter view, cinematic but asset-reference focused, neutral background, no gameplay UI.
```

## Manual Workflow

1. Add or update an enemy entry in `enemy-assets-manifest.json` with `status: "concept"` or `status: "locked"` until it is approved for runtime.
2. Generate prompts from the documented templates manually or inspect them with `npm run luma:enemy:dry-run -- --enemy <enemy-asset-folder> --template <template-id>`.
3. Run Luma outside the app runtime with `npm run luma:enemy:generate -- --enemy <enemy-asset-folder> --template <template-id>` only after explicitly choosing to spend an API call.
4. Save selected references under `assets/game/enemies/<enemy-asset-folder>/references/luma/`.
5. Create or replace movement and combat sheets under `assets/game/enemies/<enemy-asset-folder>/sheets/`.
6. Run the existing enemy extraction flow to regenerate `frames-cell`, `frames-tight`, Godot mirrored PNGs, and `preview.png`.
7. Update manifest `source` and `generation` metadata.
8. Update `src/game/core/enemies.ts`, `src/game/core/enemyAssets.ts`, and the Godot mirrored definitions only when the enemy should become runtime-visible.

## Local API Tooling

Dry runs do not require a key and do not call Luma:

```bash
npm run luma:enemy:dry-run -- --enemy red-scout-drone --template enemy.reference.front
```

Real generation requires `LUMA_AGENTS_API_KEY` in the shell environment:

```bash
npm run luma:enemy:generate -- --enemy red-fighter --template enemy.sprite.transparent
```

Local reference images can be passed without public hosting:

```bash
npm run luma:enemy:generate -- \
  --enemy red-cruiser \
  --template enemy.reference.turnaround \
  --ref assets/game/enemies/red-cruiser/references/luma/front.png
```

The CLI sends local references as base64 `image_ref` data, keeps `web_search` disabled by default, downloads completed output URLs immediately, writes run records to `generation/luma-runs.json`, and updates manifest generation metadata only after successful generation.

Shared enemy death VFX can use the `shared-vfx` asset target:

```bash
npm run luma:enemy:generate -- \
  --enemy shared-vfx \
  --template enemy.vfx.explosion-set \
  --aspect-ratio 16:9
```

Keep VFX requests pixel-game friendly: moderate detail, transparent alpha background, reusable small frames, restrained glow, and subtle debris variants rather than max-fidelity cinematic explosions. If a Dream Machine `luma-*` key returns JPEG without alpha, treat it as a reference sheet and extract/review local PNG candidates before using anything in runtime. Prefer an Agents `luma-api-*` key when true PNG/alpha output is required.

## Security

- Keep `LUMA_AGENTS_API_KEY` local-only, for example in an uncommitted `.env.local` or shell environment.
- Use the raw Agents API key value only; do not include a `Bearer ` prefix in `.env.local`.
- The local CLI supports both documented key families: `luma-api-*` for Luma Agents/Uni and `luma-*` for Dream Machine image generation. Dream Machine defaults to `photon-flash-1` for lower-cost prototype-quality images.
- Do not commit API keys, request logs containing secrets, account ids, or local env files.
- Do not expose Luma calls through Expo, React Native, or client-side Godot web code.
- Commit selected generated assets and metadata, not secret-bearing integration logic.
- Keep Luma `web_search` disabled by default for this asset workflow unless a future task explicitly needs it.
- Do not add a Luma SDK dependency until an approved API-client task requires it; the current local tool uses Node built-ins only.

## Future API Hook

The current API hook is a local dev script under `tools/luma/` using local environment variables. `image_edit`, server-side generation, or a Supabase Edge Function should only be considered after an explicit backend decision, because the current prototype is frontend-only.
