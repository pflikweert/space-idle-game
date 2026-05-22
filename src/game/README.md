# Game Module

This folder holds the prototype game foundation.

- `core/` for shared VOID DRIFTER data used by Expo shell screens such as the Enemy Codex
- `state/` for lightweight prototype state
- `ui/` for reusable screen-level game UI

Current VOID DRIFTER playable screen:

- Godot scene under `godot/void-drifter`
- Expo route shell in `ui/void-drifter-godot-screen.tsx`

Keep route files thin. VOID DRIFTER gameplay belongs in Godot; Expo UI owns route shell and overview screens.
