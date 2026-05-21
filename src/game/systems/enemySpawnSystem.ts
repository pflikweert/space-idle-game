import {
  DIFFICULTY_SCALING,
  ENEMY_SPAWN_INTERVAL,
  MIN_ENEMY_SPAWN_INTERVAL,
} from '../core/constants';
import { chooseEnemyTypeIdForSpawn, getEnemyStats, getRunLevel } from '../core/enemies';
import type { EnemyDirection } from '../core/enemyDirection';
import type { WorldState } from '../core/types';

function getSpawnInterval(elapsed: number) {
  return Math.max(
    MIN_ENEMY_SPAWN_INTERVAL,
    ENEMY_SPAWN_INTERVAL - elapsed * DIFFICULTY_SCALING.spawnRampMsPerSecond
  );
}

function getEnemySpeedMultiplier(elapsed: number) {
  return Math.min(
    DIFFICULTY_SCALING.enemySpeedCapMultiplier,
    1 + elapsed * DIFFICULTY_SCALING.enemySpeedRampPerSecond
  );
}

function getMaxEnemies(elapsed: number) {
  return Math.min(
    DIFFICULTY_SCALING.maxEnemiesCap,
    DIFFICULTY_SCALING.maxEnemiesStart +
      Math.floor(elapsed / DIFFICULTY_SCALING.maxEnemiesRampSeconds)
  );
}

function spawnEnemy(world: WorldState) {
  const runLevel = getRunLevel(world.elapsed);
  const typeId = chooseEnemyTypeIdForSpawn(runLevel, world.nextId * 97);
  const stats = getEnemyStats(typeId, runLevel);
  const edgeIndex = world.nextId % 4;
  const spawnEdge = (['top', 'right', 'bottom', 'left'] as const)[edgeIndex];
  const inset = stats.radius + 8;
  const drift = ((world.nextId * 71) % 100) / 100;
  let x = world.playfieldSize.width * drift;
  let y = world.playfieldSize.height * drift;
  let direction: EnemyDirection = 'down';

  if (spawnEdge === 'top') {
    y = -inset;
    direction = 'down';
  }
  if (spawnEdge === 'right') {
    x = world.playfieldSize.width + inset;
    direction = 'left';
  }
  if (spawnEdge === 'bottom') {
    y = world.playfieldSize.height + inset;
    direction = 'up';
  }
  if (spawnEdge === 'left') {
    x = -inset;
    direction = 'right';
  }

  world.enemies.push({
    id: world.nextId++,
    typeId,
    spawnEdge,
    x,
    y,
    radius: stats.radius,
    hp: stats.hp,
    maxHp: stats.hp,
    speed: stats.speed * getEnemySpeedMultiplier(world.elapsed),
    contactDamage: stats.contactDamage,
    xpReward: stats.xpReward,
    scoreReward: stats.scoreReward,
    vx: 0,
    vy: 0,
    direction,
    visualState: 'idle',
    hitTimer: 0,
  });
}

export function updateEnemySpawning(world: WorldState, deltaMs: number) {
  world.spawnTimer -= deltaMs;

  if (world.spawnTimer <= 0 && world.enemies.length < getMaxEnemies(world.elapsed)) {
    spawnEnemy(world);
    world.spawnTimer = getSpawnInterval(world.elapsed);
  }
}
