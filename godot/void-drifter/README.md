# VOID DRIFTER Godot Runtime

This Godot 4 project is the authoritative gameplay runtime for VOID DRIFTER.
Expo embeds its web export at `/void-drifter`; it is not a native mobile build.

```bash
npm run godot:check
npm run godot:export:web
npm run web
```

The full player-facing feature and balance reference is
[`../../docs/project/void-drifter-game-reference.md`](../../docs/project/void-drifter-game-reference.md).
When changing gameplay values, systems, UI, persistence or runtime assets, update
that dossier and regenerate the ChatGPT upload artifact as part of the same work.

Runtime art belongs under `assets/`. Enemy movement uses stable transparent
`frames-cell` canvases; Codex cards use `preview.png`; tightly cropped frames are
reserved for VFX/debug use.
