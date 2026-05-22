import type { ImageSourcePropType } from 'react-native';

import type { EnemyTypeId } from './enemies';

const PREVIEWS: Record<EnemyTypeId, ImageSourcePropType> = {
  // Codex previews are generated separately from gameplay frames so dark ships stay readable.
  void_drone: require('@/assets/game/enemies/red-scout-drone/preview.png'),
  red_scout: require('@/assets/game/enemies/red-fighter/preview.png'),
  void_tank: require('@/assets/game/enemies/red-cruiser/preview.png'),
};

export function getEnemyPreviewSource(enemyTypeId: EnemyTypeId) {
  return PREVIEWS[enemyTypeId];
}
