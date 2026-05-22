# Local Browser Testing

Use the Codex Browser Use in-app browser for local visual verification whenever a task asks to test, inspect, click, or screenshot a localhost route.

## Preferred Flow

1. Confirm the app is running or start it only when requested.
2. Use Browser Use with the in-app browser backend for `localhost`, `127.0.0.1`, or Expo web routes.
3. If the Browser Use command is not visible, search tools for:
   - `node_repl js`
   - `mcp__node_repl__js`
   - `browser-client`
4. Bootstrap the Browser Use runtime with the plugin `browser-client.mjs` and backend `iab`.
5. Navigate to the target route, then inspect at least one of:
   - screenshot
   - DOM snapshot
   - browser console logs

## VOID DRIFTER Checks

Primary route:

```text
http://localhost:8081/void-drifter
```

Fallback route:

```text
http://localhost:8081/void-drifter/enemies
```

For gameplay UI work, verify that the Godot embed loads, the start overlay is visible, HUD text is readable, controls respond, and console logs do not show runtime errors.
For VOID DRIFTER sprite/HUD work, also check a wide desktop viewport, a mobile-sized viewport, and a short-height viewport. Confirm enemy sprites are not cropped or pivot-shifted, Codex previews are inspectable, and bottom HUD/weapon UI does not overlap the player playfield.

## Fallback Rule

If the local browser runtime is unavailable, say so plainly. Then use fallback checks such as:

```bash
curl -I http://localhost:8081/void-drifter
curl -I http://localhost:8081/void-drifter/enemies
npm run godot:export:web
npm run typecheck
npm run lint
```

Do not describe fallback checks as a visual browser test.
