import type { ImageSourcePropType } from 'react-native';

import type { EnemyTypeId } from './enemies';

const PREVIEWS: Record<EnemyTypeId, ImageSourcePropType> = {
  void_boss: require('@/assets/game/enemies/void-dreadnought/preview.png'),
  // Codex previews are generated separately from gameplay frames so dark ships stay readable.
  void_drone: require('@/assets/game/enemies/void-drone-v3/preview.png'),
  red_scout: require('@/assets/game/enemies/red-scout-v3/preview.png'),
  void_tank: require('@/assets/game/enemies/void-tank-v3/preview.png'),
  ranged_shooter: require('@/assets/game/enemies/rift-shooter-v3/preview.png'),
  void_swarm: require('@/assets/game/enemies/void-swarm/preview.png'),
  kamikaze: require('@/assets/game/enemies/kamikaze/preview.png'),
  splitter: require('@/assets/game/enemies/splitter/preview.png'),
  elite_hunter: require('@/assets/game/enemies/elite-hunter/preview.png'),
};

export function getEnemyPreviewSource(enemyTypeId: EnemyTypeId) {
  return PREVIEWS[enemyTypeId];
}
