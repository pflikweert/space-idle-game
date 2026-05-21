---
name: local-browser-testing
description: Verify localhost or Expo web routes through the Codex Browser Use in-app browser before falling back to HTTP smoke checks.
---

# Use When

Use when asked to test, inspect, open, screenshot, or click a local web route such as `localhost`, `127.0.0.1`, Expo web, or `/void-drifter`.

# Workflow

1. Prefer the Browser Use plugin/in-app browser for visual checks.
2. If the Browser Use runtime is not already callable, run tool discovery for `node_repl js`, `mcp__node_repl__js`, and `browser-client`.
3. Bootstrap Browser Use with the plugin `browser-client.mjs` and the `iab` backend when the Node REPL `js` tool is available.
4. Navigate to the local URL, collect a DOM snapshot or screenshot, and check browser console logs when relevant.
5. For VOID DRIFTER, verify both routes when relevant:
   - `http://localhost:8081/void-drifter`
   - `http://localhost:8081/void-drifter-expo`
   Prefer `/void-drifter` for primary gameplay checks because it embeds the Godot game.
6. If the local browser runtime is unavailable, state that explicitly and use fallback checks such as `curl`, export/build commands, and route availability. Do not call that a visual browser check.

# Do Not

- Do not claim a browser/manual check happened unless a browser DOM snapshot, screenshot, or console log was actually inspected.
- Do not use macOS `open` as a substitute for Codex-visible browser verification.
- Do not start a long-lived dev server unless the user asks for it or no server is already running.
