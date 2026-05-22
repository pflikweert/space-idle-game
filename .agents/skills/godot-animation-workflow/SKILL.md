---
name: godot-animation-workflow
description: Use for Godot 4.x animation work involving AnimationPlayer, AnimationTree, blend spaces, animation state machines, AnimatedSprite2D, Tween-driven motion, Skeleton3D, IKModifier3D, BoneConstraint3D, retargeting, or procedural animation in GDScript/C#.
---

# Godot Animation Workflow

# Use when
Use for Godot 4.x tasks that touch animation playback, sprite animation, AnimationTree graphs, blend spaces, animation state machines, IK, constraints, retargeting, or procedural motion.

If GodotPrompter skill files such as `skills/animation-system/SKILL.md`, `skills/tween-animation/SKILL.md`, `skills/2d-essentials/SKILL.md`, `skills/3d-essentials/SKILL.md`, `skills/state-machine/SKILL.md`, or `skills/godot-debugging/SKILL.md` exist in the active workspace, read only the relevant ones before designing or editing animation code.

# Workflow
1. Clarify the animation target: 2D sprite, 3D skeletal, UI motion, procedural motion, or a layered combination.
2. Inspect the existing scene/script setup before changing node structure.
3. Pick the simplest playback node and state the choice:
   - Use `AnimationPlayer` for fixed clips, one-shots, cutscenes, hit flashes, and simple sequence playback.
   - Use `AnimationTree` when clips need blending, state transitions, blend spaces, layered playback, or parameter-driven locomotion.
   - Use `Tween` for code-driven property motion that complements authored clips, such as UI pulses, camera nudges, fades, scale pops, or short procedural offsets.
   - Use `AnimatedSprite2D` or `Sprite2D` frame swapping for lightweight 2D sprite animation when no timeline or blending is needed.
4. For `AnimationTree`, sketch the graph before code: state machine states, transitions, blend spaces, blend layers, and the parameters gameplay will drive.
5. Keep animation FSM and gameplay FSM separate. Animation transitions live in `AnimationTree`; gameplay states such as `Idle`, `Combat`, `Dead`, or `Paused` live in normal game state code and drive animation parameters.
6. Prefer keyframed animation when the motion target is the animation itself. Use IK or procedural motion when the target is dynamic, such as terrain contact, cursor aim, pickup reach, or a moving attachment point.

# 2D notes
1. Use the existing VOID DRIFTER sprite asset conventions before inventing new folders or frame names.
2. Keep sprite pivots and frame canvases stable so direction changes, hit frames, and thrust frames do not jitter.
3. Use direction/state naming consistently, such as `idle-*`, `thrust-*`, `attack-*`, and `hit-*`.
4. For current VOID DRIFTER gameplay, prefer small GDScript helpers and data-driven state over editor-heavy animation graphs unless blending is actually needed.
5. For VOID DRIFTER enemies, use short visual timers and direction hysteresis; do not drive frame changes directly from every-frame velocity noise or stack separate hit/attack sprites over the primary sprite.

# 3D notes
1. Use `Skeleton3D` with `AnimationPlayer`/`AnimationTree` for skeletal playback.
2. Choose IK only when authored clips cannot know the final target:
   - `CCDIK3D`: cheap and simple for short chains.
   - `FABRIK3D`: good default for legs, arms, and spine-like chains.
   - `JacobianIK3D`: higher fidelity and more expensive; reserve for cases that need it.
3. Use `BoneConstraint3D` for constrained follow/aim/limit behavior instead of burying constraint math in gameplay code.
4. Use retargeting when multiple compatible rigs should share animation clips; re-animate only when retargeting fails or produces unacceptable motion.

# Output format
For animation implementation tasks, include:

1. Animation node choice with a one-line rationale.
2. Scene tree fragment showing where `AnimationPlayer`, `AnimationTree`, `AnimatedSprite2D`, `Skeleton3D`, IK, or constraints attach.
3. GDScript setup/runtime control first.
4. C# parity when the project or user asks for C#.
5. Verification notes: which animation, frame, tree parameter, blend value, or node property to scrub/watch, plus the project command to run, usually `npm run godot:check` after Godot scene or script edits.

# Do not
- Do not put gameplay rules inside animation graph nodes.
- Do not upgrade from `AnimationPlayer` to `AnimationTree` unless blending, layered playback, or transition management is needed.
- Do not use IK for motion that can be cleanly keyframed.
- Do not add 3D skeletal systems to this prototype unless the task explicitly calls for them.
- Do not treat UI `Control` motion as gameplay animation; use lightweight tweens and keep UI scope narrow.
