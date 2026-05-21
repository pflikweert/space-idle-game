# Workflow

## Role split

- ChatGPT: strategy, prompt design, design review, and planning support
- Cline or Codex: repo analysis, implementation, verification, and git work

## Execution rules

- prefer the smallest working step
- avoid feature creep
- keep routes thin and put prototype logic in `src/game/*`
- verify before commit
- do not start a long-lived dev server unless explicitly asked

## Baseline verification

- `npm run lint`
- `npm run typecheck`

If a command does not exist, note that clearly and keep the next change cheap.
