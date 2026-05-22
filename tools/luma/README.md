# VOID DRIFTER Luma Tools

Local-only tooling for generating enemy reference images through the Luma Agents API.

These scripts are dev/build tooling. Do not import them from Expo, React Native, Godot, or runtime code.

## Setup

Set the API key in your shell before running real generation:

```bash
export LUMA_AGENTS_API_KEY="..."
```

Use the raw Agents API key only, without a `Bearer ` prefix. Do not commit `.env` files or API keys. This repo already ignores local env files.

The CLI also reads `.env.local` directly, so you can use:

```bash
LUMA_AGENTS_API_KEY="luma-api-..."
```

The Agents API currently documents valid tokens as `luma-api-*`. Keys for another Luma API surface will be rejected by `agents.lumalabs.ai`.

## Dry Run

Dry runs do not require an API key and do not call Luma:

```bash
npm run luma:enemy:dry-run -- --enemy red-scout-drone --template enemy.reference.front
```

Shared enemy death VFX dry run:

```bash
npm run luma:enemy:dry-run -- \
  --enemy shared-vfx \
  --template enemy.vfx.explosion-set \
  --aspect-ratio 16:9
```

List templates:

```bash
node tools/luma/generate-enemy-reference.mjs --list-templates
```

## Real Generation

Real generation calls `POST https://agents.lumalabs.ai/v1/generations`, polls the generation, downloads the output URL immediately, and records local metadata:

```bash
npm run luma:enemy:generate -- --enemy red-fighter --template enemy.sprite.transparent
```

Generate one shared enemy explosion reference sheet:

```bash
npm run luma:enemy:generate -- \
  --enemy shared-vfx \
  --template enemy.vfx.explosion-set \
  --aspect-ratio 16:9
```

Add local references without public hosting:

```bash
npm run luma:enemy:generate -- \
  --enemy red-cruiser \
  --template enemy.reference.turnaround \
  --ref assets/game/enemies/red-cruiser/references/luma/front.png
```

Reference files are sent as base64 `image_ref` data. For image generation, use at most nine references.

## Outputs

- Images: `assets/game/enemies/<enemy>/references/luma/<template-id>-<timestamp>.png`
- Run records: `assets/game/enemies/<enemy>/generation/luma-runs.json`
- Manifest updates: `assets/game/enemies/enemy-assets-manifest.json`

Generated reference images still need human review before creating sheets or changing runtime enemy data.

## Safety

- API keys are read only from `process.env.LUMA_AGENTS_API_KEY`.
- Dry runs print sanitized request bodies and never print secrets.
- `web_search` is disabled by default.
- `image_edit` is intentionally out of scope for this first tool pass.
