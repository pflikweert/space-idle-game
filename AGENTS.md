# AGENTS.md

## Sources

Use this order:

1. `README.md`
2. relevant docs in `docs/project/*`
3. relevant workflow notes in `docs/dev/*`
4. a matching skill in `.agents/skills/*`

Read only task-relevant files. Do not adopt a "read everything" workflow.

`docs/upload/**` is generated upload output for ChatGPT handoff, not canonical source.

## Scope guardrails

- This repo is a lightweight prototype foundation for `space-idle-game`.
- Prefer the smallest working step.
- Avoid feature creep and avoid re-deciding documented choices without a reason.
- MVP scope stays narrow: one playable prototype screen, placeholder progression, no production systems.
- Do not add backend, Supabase, OpenAI, monetization, account systems, analytics, live ops, or store-release work unless explicitly requested in a later phase.
- Do not swap to a heavy game engine without an explicit decision.

## Working style

- Analyze the existing code before changing structure.
- Reuse existing Expo and React Native patterns before adding new ones.
- Keep route files thin and let `src/game/*` hold prototype-specific UI, state, and core helpers.
- For larger changes, start with a short plan or checklist.
- Prefer small, reviewable edits over broad refactors.

## Verification

- Do not start a long-lived dev server unless explicitly asked.
- After relevant code changes, run `npm run lint` and `npm run typecheck` when available.
- If a verification command does not exist, say so clearly instead of pretending it ran.
- After docs changes that affect ChatGPT handoff context, run `npm run docs:upload` and optionally `npm run docs:bundle:verify`.

## Security

- Never commit secrets, tokens, or local env files.
- Keep this repo frontend-only unless a later phase explicitly introduces more.
