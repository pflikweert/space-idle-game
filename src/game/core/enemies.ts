export type EnemyTypeId = 'red_scout_drone';

export type EnemyAbility =
  | 'chase_player'
  | 'contact_damage'
  | 'red_projectile_later';

export type EnemySpawnEdge = 'top' | 'right' | 'bottom' | 'left';

export type EnemyMovementFrame =
  | 'move-down'
  | 'move-up'
  | 'move-left'
  | 'move-right';

export type EnemyDefinition = {
  id: EnemyTypeId;
  name: string;
  role: string;
  description: string;
  baseStats: {
    hp: number;
    speed: number;
    contactDamage: number;
    xpReward: number;
    scoreReward: number;
    radius: number;
  };
  scaling: {
    hpPerLevel: number;
    speedPerLevel: number;
    damagePerLevel: number;
  };
  spawn: {
    weight: number;
    minRunLevel: number;
  };
  abilities: EnemyAbility[];
};

export type EnemyRuntimeStats = EnemyDefinition['baseStats'] & {
  level: number;
};

// TODO: Later: enemy balancing/admin editor can read/write this definition shape.
export const ENEMY_DEFINITIONS = [
  {
    id: 'red_scout_drone',
    name: 'Red Scout Drone',
    role: 'Basic hostile drone',
    description:
      'Fast red hostile scout drone that enters from screen edges and chases the player.',
    baseStats: {
      hp: 16,
      speed: 52,
      contactDamage: 10,
      xpReward: 4,
      scoreReward: 10,
      radius: 18,
    },
    scaling: {
      hpPerLevel: 3,
      speedPerLevel: 1.5,
      damagePerLevel: 1,
    },
    spawn: {
      weight: 100,
      minRunLevel: 1,
    },
    abilities: ['chase_player', 'contact_damage', 'red_projectile_later'],
  },
] as const satisfies EnemyDefinition[];

export function getRunLevel(elapsedSeconds: number) {
  return 1 + Math.floor(elapsedSeconds / 30);
}

export function getEnemyDefinition(enemyTypeId: EnemyTypeId) {
  const definition = ENEMY_DEFINITIONS.find((candidate) => candidate.id === enemyTypeId);

  if (!definition) {
    throw new Error(`Unknown enemy type: ${enemyTypeId}`);
  }

  return definition;
}

export function getEnemyStats(enemyTypeId: EnemyTypeId, level: number): EnemyRuntimeStats {
  const definition = getEnemyDefinition(enemyTypeId);

  const levelOffset = Math.max(0, level - 1);

  return {
    ...definition.baseStats,
    level,
    hp: definition.baseStats.hp + definition.scaling.hpPerLevel * levelOffset,
    speed: definition.baseStats.speed + definition.scaling.speedPerLevel * levelOffset,
    contactDamage:
      definition.baseStats.contactDamage + definition.scaling.damagePerLevel * levelOffset,
  };
}

export function getEnemyMovementFrame(spawnEdge: EnemySpawnEdge): EnemyMovementFrame {
  if (spawnEdge === 'top') {
    return 'move-down';
  }

  if (spawnEdge === 'bottom') {
    return 'move-up';
  }

  if (spawnEdge === 'left') {
    return 'move-right';
  }

  return 'move-left';
}
