export type EnemyTypeId = 'void_drone' | 'red_scout' | 'void_tank';

export type EnemyAssetKey = 'red_scout_drone' | 'red_fighter' | 'red_cruiser';

export type EnemyAbility =
  | 'chase_player'
  | 'contact_damage'
  | 'red_projectile_later'
  | 'flank_player_later'
  | 'spread_fire_later';

export type EnemyStatus = 'active' | 'locked';

export type EnemyDefinition = {
  id: EnemyTypeId;
  assetKey: EnemyAssetKey;
  name: string;
  role: string;
  description: string;
  status: EnemyStatus;
  unlockWave: number;
  recommendedDisplaySize: number;
  baseStats: {
    hp: number;
    speed: number;
    contactDamage: number;
    xpReward: number;
    coinReward: number;
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

export const ENEMY_DEFINITIONS = [
  {
    id: 'void_drone',
    assetKey: 'red_scout_drone',
    name: 'Void Drone',
    role: 'Basic chase enemy',
    description:
      'Standard void-skimmer that enters from screen edges and pushes the player out of position.',
    status: 'active',
    unlockWave: 1,
    recommendedDisplaySize: 48,
    baseStats: {
      hp: 16,
      speed: 52,
      contactDamage: 10,
      xpReward: 4,
      coinReward: 2,
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
  {
    id: 'red_scout',
    assetKey: 'red_fighter',
    name: 'Red Scout',
    role: 'Fast low-HP enemy',
    description: 'Fast red scout craft that arrives early and punishes slow movement.',
    status: 'active',
    unlockWave: 2,
    recommendedDisplaySize: 68,
    baseStats: {
      hp: 22,
      speed: 72,
      contactDamage: 12,
      xpReward: 7,
      coinReward: 3,
      scoreReward: 24,
      radius: 22,
    },
    scaling: {
      hpPerLevel: 4,
      speedPerLevel: 1.2,
      damagePerLevel: 1.4,
    },
    spawn: {
      weight: 35,
      minRunLevel: 2,
    },
    abilities: ['chase_player', 'contact_damage', 'flank_player_later'],
  },
  {
    id: 'void_tank',
    assetKey: 'red_cruiser',
    name: 'Void Tank',
    role: 'Slow high-HP enemy',
    description: 'Armored void hull that soaks fire and compresses safe space later in a run.',
    status: 'active',
    unlockWave: 4,
    recommendedDisplaySize: 96,
    baseStats: {
      hp: 90,
      speed: 25,
      contactDamage: 24,
      xpReward: 18,
      coinReward: 8,
      scoreReward: 60,
      radius: 38,
    },
    scaling: {
      hpPerLevel: 11,
      speedPerLevel: 0.4,
      damagePerLevel: 2.2,
    },
    spawn: {
      weight: 12,
      minRunLevel: 4,
    },
    abilities: ['chase_player', 'contact_damage', 'spread_fire_later'],
  },
] as const satisfies EnemyDefinition[];

export const ACTIVE_ENEMY_TYPE_ID: EnemyTypeId = 'void_drone';

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
    coinReward: definition.baseStats.coinReward + Math.floor(levelOffset * 0.5),
  };
}

export function getSpawnableEnemyDefinitions(runLevel: number) {
  return ENEMY_DEFINITIONS.filter(
    (enemy) =>
      enemy.status === 'active' && enemy.spawn.minRunLevel <= runLevel && enemy.spawn.weight > 0
  );
}

export function chooseEnemyTypeIdForSpawn(runLevel: number, seed: number): EnemyTypeId {
  const spawnableEnemies = getSpawnableEnemyDefinitions(runLevel);

  if (spawnableEnemies.length === 0) {
    return ACTIVE_ENEMY_TYPE_ID;
  }

  const totalWeight = spawnableEnemies.reduce((total, enemy) => total + enemy.spawn.weight, 0);
  let roll = Math.abs(seed) % totalWeight;

  for (const enemy of spawnableEnemies) {
    if (roll < enemy.spawn.weight) {
      return enemy.id;
    }
    roll -= enemy.spawn.weight;
  }

  return spawnableEnemies[0].id;
}
