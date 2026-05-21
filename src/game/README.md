# Game Module

This folder holds the prototype game foundation.

- `core/` for pure helpers and content constants
- `state/` for lightweight prototype state
- `ui/` for reusable screen-level game UI

Current VOID DRIFTER playable screen:

- `ui/void-drifter-prototype-screen.tsx`

Keep route files thin. Prototype gameplay can stay in a single UI file while the loop is still small; extract only when it improves readability or testing.
