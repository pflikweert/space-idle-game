# space-idle-game

VOID DRIFTER is a Godot 4 web survival/idle-defense prototype embedded in an Expo
web route. The complete current game reference is
[`docs/project/void-drifter-game-reference.md`](docs/project/void-drifter-game-reference.md).

## Local run

```bash
npm install
npm run godot:check
npm run godot:export:web
npm run web
```

Open `http://localhost:8081/void-drifter`. Godot 4 and its Web export templates
are required; set `GODOT_BIN` if Godot is not in `PATH`.

## Checks

```bash
npm run lint
npm run typecheck
npm run godot:check
```

## ChatGPT Project handoff

```bash
npm run docs:upload
npm run docs:bundle:verify
```

Upload only `docs/upload/chatgpt-project-context.md`. It is generated from the
canonical game dossier; do not edit it directly.
