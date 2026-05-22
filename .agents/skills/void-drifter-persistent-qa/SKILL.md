---
name: void-drifter-persistent-qa
description: Use for VOID DRIFTER end-user QA involving Godot web screenshots, menu/shop/codex flows, persistent profile checks, stale export detection, and evidence-backed local browser testing.
---

# VOID DRIFTER Persistent QA

Use this when asked to verify VOID DRIFTER as an end user, especially menu/start flow, Upgrade Ship, Enemy Codex, XP choices, death summary, persistent coins/upgrades/codex state, or screenshots.

## Evidence Rules

- Prefer Browser Use / in-app browser for `http://localhost:8081/void-drifter`.
- A visual QA claim requires at least one screenshot, DOM snapshot, or browser console inspection.
- Do not use macOS `open` as evidence.
- Do not describe `curl`, build, export, or type/lint checks as visual browser testing.
- If browser automation is unavailable, say that plainly and report only fallback evidence.

## Before Browser QA

1. Run `npm run godot:check`.
2. Check whether the Godot web export is stale:
   - compare `public/godot/void-drifter/build-info.json` and `public/godot/void-drifter/index.html`
   - against relevant sources such as `godot/void-drifter/scripts/*.gd` and `godot/void-drifter/scenes/main.tscn`
3. Run `npm run godot:export:web` only if the export is stale, missing, or the user asks for a fresh export.
4. Confirm the route responds with `curl -I http://localhost:8081/void-drifter`.
5. Do not start a long-lived dev server unless the user asks or no server is running and browser QA is impossible without it.

## Browser Tool Discovery

If browser tools are not visible:

1. Use tool discovery for `browser-client`, `node_repl js`, `mcp__node_repl__js`, and `in-app browser`.
2. If available, bootstrap Browser Use with `browser-client.mjs` and the `iab` backend.
3. Navigate to `http://localhost:8081/void-drifter`.
4. Capture screenshots and console logs from the same browser session/origin used for persistence checks.

## Required End-User QA Flow

Collect evidence for each reachable state:

1. Main menu:
   - screenshot shows `Start Run`, `Upgrade Ship`, and `Enemy Codex`
   - console has no blocking Godot/runtime errors
2. Upgrade Ship:
   - click `Upgrade Ship`
   - screenshot shows permanent upgrades and coin total
   - if coins are insufficient, confirm buttons are disabled or unaffordable
3. Enemy Codex:
   - open from Godot UI, not only the Expo wrapper route
   - screenshot shows discovered/locked enemy state and stats
4. Running state:
   - start a run
   - screenshot shows HUD with wave/time/score/kills/coins/XP or level signal
   - confirm ship control responds where possible
5. XP choice:
   - trigger naturally when feasible
   - if not feasible in time, state that it was not reached instead of pretending
   - screenshot the 3-choice level-up overlay when reached
6. Death summary:
   - reach death naturally or through an explicit debug/test method if one exists
   - screenshot score, wave, kills, time, coins, records, and `Upgrade Ship` / `Run Again` / `Main Menu`
7. Persistence:
   - earn coins or buy an upgrade if feasible
   - reload the route in the same browser origin
   - screenshot or inspect that coins/upgrades/codex discovered state persists

## Fallback Report Shape

When full browser QA cannot run, report:

- what checks did run: `godot:check`, export freshness, `curl`, `typecheck`, `lint`
- why screenshots were unavailable
- which required end-user states remain unverified
- do not call the fallback a visual or persistent browser test
