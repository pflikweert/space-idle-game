# Docs

This folder holds the lightweight source of truth for the prototype.

- `docs/project/*` explains the game direction and MVP scope.
- `docs/dev/*` explains workflow, execution discipline, and temporary session context.
- `docs/project/void-drifter-prototype-plan.md` tracks what the current playable prototype already includes and what remains deliberately out of scope.

Keep docs short, practical, and aligned with the current prototype phase.

To prepare docs for upload to ChatGPT:

```bash
npm run docs:upload
```

The generated upload file is `docs/upload/chatgpt-project-context.md`.

`docs/upload/**` is generated output for ChatGPT upload, not canonical source.
