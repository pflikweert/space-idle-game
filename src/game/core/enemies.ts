export const GROWTH_START_WAVE = 10;
export const FAST_HP_GROWTH_WAVES = 25;
export const LATE_HP_MULTIPLIER = 1.025;

export type EnemyTypeId =
  | 'void_boss'
  | 'void_drone'
  | 'red_scout'
  | 'void_tank'
  | 'ranged_shooter'
  | 'void_swarm'
  | 'kamikaze'
  | 'splitter'
  | 'elite_hunter';

export type EnemyAssetKey =
  | 'void_drone_v3'
  | 'red_scout_v3'
  | 'red_scout_drone'
  | 'red_fighter'
  | 'red_cruiser'
  | 'void_dreadnought'
  | 'void_tank_v3'
  | 'rift_shooter_v3'
  | 'ranged_shooter'
  | 'void_swarm'
  | 'kamikaze'
  | 'splitter'
  | 'elite_hunter';

export type EnemyAbility =
  | 'chase_player'
  | 'spiral_approach'
  | 'contact_damage'
  | 'ranged_burst'
  | 'guided_rockets'
  | 'orbit_approach'
  | 'railgun_salvo'
  | 'range_control'
  | 'charged_projectile'
  | 'cluster_spawn'
  | 'charge_player'
  | 'explosive_contact'
  | 'split_on_death'
  | 'elite_pressure';

export type EnemyStatus = 'active' | 'locked';

export type EnemyDefinition = {
  id: EnemyTypeId;
  assetKey: EnemyAssetKey;
  name: string;
  role: string;
  description: string;
  status: EnemyStatus;
  unlockWave: number;
  archetype: string;
  recommendedDisplaySize: number;
  navigationRadius?: number;
  flight?: { orbitStrength: number; approachSeconds: number; approachDelaySeconds: number; startRange: [number, number] };
  weapon?: { magazine: number; reloadSeconds: number; warningSeconds: number; projectileDamage: number };
  baseStats: {
    hp: number;
    speed: number;
    contactDamage: number;
    contactInterval?: number;
    cashReward: number;
    coinReward: number;
    scoreReward: number;
    radius: number;
  };
  scaling: {
    hpMultiplier: number;
    speedMultiplier: number;
    damageMultiplier: number;
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

export type WaveIntelEntry = {
  definition: EnemyDefinition;
  stats: EnemyRuntimeStats;
  spawnChance: number | null;
  guaranteedBoss: boolean;
};

export const ENEMY_DEFINITIONS = [
  {
    id: 'void_drone',
    navigationRadius: 9.35,
    flight: { orbitStrength: 0.76, approachSeconds: 25, approachDelaySeconds: 0.75, startRange: [0.38, 0.48] },
    weapon: { magazine: 1, reloadSeconds: 16, warningSeconds: 0.45, projectileDamage: 0.1 },
    assetKey: 'void_drone_v3',
    name: 'Void Drone',
    role: 'Basic chase enemy',
    description: 'The smallest, quickest inward spiral: it crosses traffic layers and rapidly pressures the hull.',
    status: 'active',
    unlockWave: 1,
    archetype: 'chaser',
    recommendedDisplaySize: 29,
    baseStats: {
      hp: 16,
      speed: 70,
      contactDamage: 1,
      contactInterval: 0.3,
      cashReward: 2,
      coinReward: 1,
      scoreReward: 10,
      radius: 10.8,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 60,
      minRunLevel: 1,
    },
    abilities: ['spiral_approach', 'contact_damage'],
  },
  {
    id: 'red_scout',
    navigationRadius: 16.36,
    flight: { orbitStrength: 0.46, approachSeconds: 115, approachDelaySeconds: 3, startRange: [0.84, 0.92] },
    weapon: { magazine: 1, reloadSeconds: 20, warningSeconds: 0.35, projectileDamage: 0.1 },
    assetKey: 'red_scout_v3',
    name: 'Red Scout',
    role: 'Fast low-HP enemy',
    description: 'A very fast scout that curves inward and strikes in quick repeated passes.',
    status: 'active',
    unlockWave: 3,
    archetype: 'fast_scout',
    recommendedDisplaySize: 41,
    baseStats: {
      hp: 12,
      speed: 59.5,
      contactDamage: 1,
      contactInterval: 0.45,
      cashReward: 4,
      coinReward: 2,
      scoreReward: 24,
      radius: 13.2,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 20,
      minRunLevel: 3,
    },
    abilities: ['spiral_approach', 'contact_damage'],
  },
  {
    id: 'void_tank',
    navigationRadius: 19.68,
    flight: { orbitStrength: 0.56, approachSeconds: 230, approachDelaySeconds: 8, startRange: [0.7, 0.8] },
    weapon: { magazine: 2, reloadSeconds: 14, warningSeconds: 0.5, projectileDamage: 0.25 },
    assetKey: 'void_tank_v3',
    name: 'Void Tank',
    role: 'Slow high-HP enemy',
    description: 'Slow armored gunship that circles inward while firing two-round railgun salvos.',
    status: 'active',
    unlockWave: 7,
    archetype: 'tank',
    recommendedDisplaySize: 58,
    baseStats: {
      hp: 80,
      speed: 17.5,
      contactDamage: 1,
      contactInterval: 0.75,
      cashReward: 8,
      coinReward: 4,
      scoreReward: 60,
      radius: 22.8,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 10,
      minRunLevel: 7,
    },
    abilities: ['spiral_approach', 'contact_damage'],
  },
  {
    id: 'void_boss',
    navigationRadius: 35.63,
    flight: { orbitStrength: 1, approachSeconds: 290, approachDelaySeconds: 12, startRange: [0.9, 0.96] },
    weapon: { magazine: 1, reloadSeconds: 4, warningSeconds: 0.6, projectileDamage: 6 },
    assetKey: 'void_dreadnought',
    name: 'Void Dreadnought',
    role: 'Boss every tenth wave',
    description: 'Slower armored rocket carrier that circles inward before making contact.',
    status: 'active',
    unlockWave: 10,
    archetype: 'boss',
    recommendedDisplaySize: 120,
    baseStats: {
      hp: 400,
      speed: 10,
      contactDamage: 3,
      contactInterval: 1,
      cashReward: 100,
      coinReward: 25,
      scoreReward: 60,
      radius: 47.5,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 0,
      minRunLevel: 10,
    },
    abilities: ['spiral_approach', 'contact_damage', 'guided_rockets'],
  },
  {
    id: 'ranged_shooter',
    navigationRadius: 12.91,
    flight: { orbitStrength: 0.9, approachSeconds: 180, approachDelaySeconds: 5, startRange: [0.86, 0.92] },
    weapon: { magazine: 3, reloadSeconds: 6, warningSeconds: 0.3, projectileDamage: 0.25 },
    assetKey: 'rift_shooter_v3',
    name: 'Rift Shooter',
    role: 'Ranged shooter',
    description: 'Starts in an outer firing orbit, then gradually spirals toward contact.',
    status: 'active',
    unlockWave: 5,
    archetype: 'ranged_shooter',
    recommendedDisplaySize: 40,
    baseStats: {
      hp: 24,
      speed: 28,
      contactDamage: 1,
      contactInterval: 0.55,
      cashReward: 6,
      coinReward: 3,
      scoreReward: 32,
      radius: 14.4,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 10,
      minRunLevel: 5,
    },
    abilities: ['spiral_approach', 'range_control', 'railgun_salvo'],
  },
  {
    id: 'void_swarm',
    assetKey: 'void_swarm',
    name: 'Void Swarm',
    role: 'Swarm',
    description: 'Small low-health contacts that arrive in clusters.',
    status: 'locked',
    unlockWave: 3,
    archetype: 'swarm',
    recommendedDisplaySize: 42,
    baseStats: {
      hp: 8,
      speed: 82,
      contactDamage: 6,
      cashReward: 0,
      coinReward: 1,
      scoreReward: 8,
      radius: 13,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 38,
      minRunLevel: 3,
    },
    abilities: ['cluster_spawn', 'contact_damage'],
  },
  {
    id: 'kamikaze',
    assetKey: 'kamikaze',
    name: 'Nova Dart',
    role: 'Kamikaze',
    description: 'A bright unstable hull that accelerates into the player and bursts on contact.',
    status: 'locked',
    unlockWave: 5,
    archetype: 'kamikaze',
    recommendedDisplaySize: 52,
    baseStats: {
      hp: 20,
      speed: 92,
      contactDamage: 20,
      cashReward: 0,
      coinReward: 4,
      scoreReward: 36,
      radius: 18,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 16,
      minRunLevel: 5,
    },
    abilities: ['charge_player', 'explosive_contact'],
  },
  {
    id: 'splitter',
    assetKey: 'splitter',
    name: 'Split Core',
    role: 'Splitter',
    description: 'A brittle core that divides into smaller swarm fragments when destroyed.',
    status: 'locked',
    unlockWave: 6,
    archetype: 'splitter',
    recommendedDisplaySize: 62,
    baseStats: {
      hp: 44,
      speed: 36,
      contactDamage: 14,
      cashReward: 0,
      coinReward: 6,
      scoreReward: 48,
      radius: 27,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 12,
      minRunLevel: 6,
    },
    abilities: ['split_on_death', 'contact_damage'],
  },
  {
    id: 'elite_hunter',
    assetKey: 'elite_hunter',
    name: 'Elite Hunter',
    role: 'Elite hunter',
    description: 'A dangerous hunter tuned for elite encounters and late-wave pressure.',
    status: 'locked',
    unlockWave: 8,
    archetype: 'elite_hunter',
    recommendedDisplaySize: 78,
    baseStats: {
      hp: 130,
      speed: 54,
      contactDamage: 28,
      cashReward: 0,
      coinReward: 16,
      scoreReward: 140,
      radius: 34,
    },
    scaling: {
      hpMultiplier: 1.115,
      speedMultiplier: 1,
      damageMultiplier: 1.14,
    },
    spawn: {
      weight: 4,
      minRunLevel: 8,
    },
    abilities: ['elite_pressure', 'charged_projectile'],
  },
] as const satisfies EnemyDefinition[];

export const ACTIVE_ENEMY_TYPE_ID: EnemyTypeId = 'void_drone';

export function getRunLevel(elapsedSeconds: number) {
  return 1 + Math.floor(elapsedSeconds / 35);
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
  const levelOffset = Math.max(0, level - GROWTH_START_WAVE);

  return {
    ...definition.baseStats,
    level,
    hp:
      definition.baseStats.hp *
      definition.scaling.hpMultiplier ** Math.min(levelOffset, FAST_HP_GROWTH_WAVES) *
      LATE_HP_MULTIPLIER ** Math.min(Math.max(0, levelOffset - FAST_HP_GROWTH_WAVES), 10000),
    speed: definition.baseStats.speed,
    contactDamage:
      definition.baseStats.contactDamage * definition.scaling.damageMultiplier ** Math.min(levelOffset, FAST_HP_GROWTH_WAVES) *
      1.01 ** Math.min(Math.max(0, levelOffset - FAST_HP_GROWTH_WAVES), 10000),
    coinReward: definition.baseStats.coinReward,
  };
}

export function getSpawnableEnemyDefinitions(runLevel: number) {
  return ENEMY_DEFINITIONS.filter(
    (enemy) =>
      enemy.status === 'active' && enemy.spawn.minRunLevel <= runLevel && enemy.spawn.weight > 0
  );
}

export function getWaveIntelRoster(wave: number): WaveIntelEntry[] {
  const resolvedWave = Math.max(1, wave);
  const regularEnemies = getSpawnableEnemyDefinitions(resolvedWave).sort(
    (a, b) => a.unlockWave - b.unlockWave
  );
  const totalWeight = regularEnemies.reduce((total, enemy) => total + enemy.spawn.weight, 0);
  const roster: WaveIntelEntry[] = regularEnemies.map((definition) => ({
    definition,
    stats: getEnemyStats(definition.id, resolvedWave),
    spawnChance: definition.spawn.weight / totalWeight,
    guaranteedBoss: false,
  }));

  if (resolvedWave % 10 === 0) {
    const definition = getEnemyDefinition('void_boss');
    roster.push({
      definition,
      stats: getEnemyStats(definition.id, resolvedWave),
      spawnChance: null,
      guaranteedBoss: true,
    });
  }

  return roster;
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
