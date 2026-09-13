# Contributor Workflow

Keep changes small and verify the affected layer. Gameplay lives in Godot; Expo
owns routing, the web embed shell and the secondary Codex. Do not add backend,
accounts, monetization or live services without an explicit scope decision.

## Baseline checks

```bash
npm run lint
npm run typecheck
```

For Godot gameplay/UI/assets, also run:

```bash
npm run godot:check
npm run godot:export:web
```

Use `local-browser-testing.md` for web-facing changes. Do not start a long-lived
server unless requested.

## Documentation

`../project/void-drifter-game-reference.md` is the only canonical product
document. Update it with every player-visible change, then run:

```bash
npm run docs:upload
npm run docs:bundle:verify
```

The generated `docs/upload/chatgpt-project-context.md` is the sole file intended
for manual ChatGPT Project upload.
