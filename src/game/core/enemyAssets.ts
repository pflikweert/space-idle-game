import type { ImageSourcePropType } from 'react-native';

import type { EnemyTypeId } from './enemies';
import type { EnemyDirection } from './enemyDirection';
import type { EnemyVisualState } from './types';

type EnemyFrameState = 'idle' | 'thrust' | 'hit';
type EnemyFrameKey = `${EnemyFrameState}-${EnemyDirection}`;
type EnemyFrameMap = Record<EnemyFrameKey, ImageSourcePropType>;

const RED_SCOUT_DRONE_FRAMES = {
  'idle-down': require('@/assets/game/enemies/red-scout-drone/frames-tight/idle-down.png'),
  'idle-up': require('@/assets/game/enemies/red-scout-drone/frames-tight/idle-up.png'),
  'idle-left': require('@/assets/game/enemies/red-scout-drone/frames-tight/idle-left.png'),
  'idle-right': require('@/assets/game/enemies/red-scout-drone/frames-tight/idle-right.png'),
  'thrust-down': require('@/assets/game/enemies/red-scout-drone/frames-tight/thrust-down.png'),
  'thrust-up': require('@/assets/game/enemies/red-scout-drone/frames-tight/thrust-up.png'),
  'thrust-left': require('@/assets/game/enemies/red-scout-drone/frames-tight/thrust-left.png'),
  'thrust-right': require('@/assets/game/enemies/red-scout-drone/frames-tight/thrust-right.png'),
  'hit-down': require('@/assets/game/enemies/red-scout-drone/frames-tight/hit-down.png'),
  'hit-up': require('@/assets/game/enemies/red-scout-drone/frames-tight/hit-up.png'),
  'hit-left': require('@/assets/game/enemies/red-scout-drone/frames-tight/hit-left.png'),
  'hit-right': require('@/assets/game/enemies/red-scout-drone/frames-tight/hit-right.png'),
} as const satisfies EnemyFrameMap;

const RED_FIGHTER_FRAMES = {
  'idle-down': require('@/assets/game/enemies/red-fighter/frames-tight/idle-down.png'),
  'idle-up': require('@/assets/game/enemies/red-fighter/frames-tight/idle-up.png'),
  'idle-left': require('@/assets/game/enemies/red-fighter/frames-tight/idle-left.png'),
  'idle-right': require('@/assets/game/enemies/red-fighter/frames-tight/idle-right.png'),
  'thrust-down': require('@/assets/game/enemies/red-fighter/frames-tight/thrust-down.png'),
  'thrust-up': require('@/assets/game/enemies/red-fighter/frames-tight/thrust-up.png'),
  'thrust-left': require('@/assets/game/enemies/red-fighter/frames-tight/thrust-left.png'),
  'thrust-right': require('@/assets/game/enemies/red-fighter/frames-tight/thrust-right.png'),
  'hit-down': require('@/assets/game/enemies/red-fighter/frames-tight/hit-down.png'),
  'hit-up': require('@/assets/game/enemies/red-fighter/frames-tight/hit-up.png'),
  'hit-left': require('@/assets/game/enemies/red-fighter/frames-tight/hit-left.png'),
  'hit-right': require('@/assets/game/enemies/red-fighter/frames-tight/hit-right.png'),
} as const satisfies EnemyFrameMap;

const RED_CRUISER_FRAMES = {
  'idle-down': require('@/assets/game/enemies/red-cruiser/frames-tight/idle-down.png'),
  'idle-up': require('@/assets/game/enemies/red-cruiser/frames-tight/idle-up.png'),
  'idle-left': require('@/assets/game/enemies/red-cruiser/frames-tight/idle-left.png'),
  'idle-right': require('@/assets/game/enemies/red-cruiser/frames-tight/idle-right.png'),
  'thrust-down': require('@/assets/game/enemies/red-cruiser/frames-tight/thrust-down.png'),
  'thrust-up': require('@/assets/game/enemies/red-cruiser/frames-tight/thrust-up.png'),
  'thrust-left': require('@/assets/game/enemies/red-cruiser/frames-tight/thrust-left.png'),
  'thrust-right': require('@/assets/game/enemies/red-cruiser/frames-tight/thrust-right.png'),
  'hit-down': require('@/assets/game/enemies/red-cruiser/frames-tight/hit-down.png'),
  'hit-up': require('@/assets/game/enemies/red-cruiser/frames-tight/hit-up.png'),
  'hit-left': require('@/assets/game/enemies/red-cruiser/frames-tight/hit-left.png'),
  'hit-right': require('@/assets/game/enemies/red-cruiser/frames-tight/hit-right.png'),
} as const satisfies EnemyFrameMap;

export const SHARED_ENEMY_VFX = {
  deathSmall: require('@/assets/game/enemies/shared-vfx/frames-tight/death-small.png'),
  deathMedium: require('@/assets/game/enemies/shared-vfx/frames-tight/death-medium.png'),
  deathLarge: require('@/assets/game/enemies/shared-vfx/frames-tight/death-large.png'),
} as const;

const ENEMY_FRAMES: Record<EnemyTypeId, EnemyFrameMap> = {
  red_scout_drone: RED_SCOUT_DRONE_FRAMES,
  red_fighter: RED_FIGHTER_FRAMES,
  red_cruiser: RED_CRUISER_FRAMES,
};

const PREVIEWS: Record<EnemyTypeId, ImageSourcePropType> = {
  red_scout_drone: RED_SCOUT_DRONE_FRAMES['idle-down'],
  red_fighter: RED_FIGHTER_FRAMES['idle-down'],
  red_cruiser: RED_CRUISER_FRAMES['idle-down'],
};

function getFrameState(visualState: EnemyVisualState) {
  if (visualState === 'hit') {
    return 'hit';
  }

  if (visualState === 'idle') {
    return 'idle';
  }

  return 'thrust';
}

export function getEnemyPreviewSource(enemyTypeId: EnemyTypeId) {
  return PREVIEWS[enemyTypeId];
}

export function getEnemyFrameSource(
  enemyTypeId: EnemyTypeId,
  visualState: EnemyVisualState,
  direction: EnemyDirection
) {
  const frameKey = `${getFrameState(visualState)}-${direction}` as EnemyFrameKey;
  return ENEMY_FRAMES[enemyTypeId][frameKey] ?? PREVIEWS[enemyTypeId];
}
