export type EnemyTypeId = 'red_scout_drone' | 'red_fighter' | 'red_cruiser';

export type EnemyAbility =
  | 'chase_player'
  | 'contact_damage'
  | 'red_projectile_later'
  | 'flank_player_later'
  | 'spread_fire_later';

export type EnemyStatus = 'active' | 'locked';

export type EnemyDefinition = {
  id: EnemyTypeId;
  name: string;
  role: string;
  description: string;
  status: EnemyStatus;
  recommendedDisplaySize: number;
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
    role: 'Fast fodder / swarm scout',
    description:
      'Fast red hostile scout drone that enters from screen edges and chases the player.',
    status: 'active',
    recommendedDisplaySize: 48,
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
  {
    id: 'red_fighter',
    name: 'Red Fighter',
    role: 'Medium aggressive flanker',
    description: 'Sharper red attack craft that joins after the first scout pressure spike.',
    status: 'active',
    recommendedDisplaySize: 68,
    baseStats: {
      hp: 34,
      speed: 42,
      contactDamage: 14,
      xpReward: 8,
      scoreReward: 22,
      radius: 25,
    },
    scaling: {
      hpPerLevel: 5,
      speedPerLevel: 1,
      damagePerLevel: 1.4,
    },
    spawn: {
      weight: 35,
      minRunLevel: 2,
    },
    abilities: ['chase_player', 'contact_damage', 'flank_player_later'],
  },
  {
    id: 'red_cruiser',
    name: 'Red Cruiser',
    role: 'Heavy tank / slow pressure ship',
    description: 'Broad armored pressure ship that adds slower, heavier pressure later in a run.',
    status: 'active',
    recommendedDisplaySize: 96,
    baseStats: {
      hp: 90,
      speed: 25,
      contactDamage: 24,
      xpReward: 18,
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

export const ACTIVE_ENEMY_TYPE_ID: EnemyTypeId = 'red_scout_drone';

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

export function getSpawnableEnemyDefinitions(runLevel: number) {
  return ENEMY_DEFINITIONS.filter(
    (enemy) => enemy.status === 'active' && enemy.spawn.minRunLevel <= runLevel && enemy.spawn.weight > 0
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
