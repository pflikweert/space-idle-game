import {
  DIFFICULTY_SCALING,
  ENEMY_SPAWN_INTERVAL,
  ENEMY_SPEED,
  ENEMY_VARIANTS,
  MIN_ENEMY_SPAWN_INTERVAL,
} from '../core/constants';
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
  const variant = ENEMY_VARIANTS[world.nextId % ENEMY_VARIANTS.length];
  const edge = world.nextId % 4;
  const inset = variant.radius + 8;
  const drift = ((world.nextId * 71) % 100) / 100;
  let x = world.playfieldSize.width * drift;
  let y = world.playfieldSize.height * drift;

  if (edge === 0) y = -inset;
  if (edge === 1) x = world.playfieldSize.width + inset;
  if (edge === 2) y = world.playfieldSize.height + inset;
  if (edge === 3) x = -inset;

  world.enemies.push({
    id: world.nextId++,
    x,
    y,
    radius: variant.radius,
    hp: variant.hp,
    speed: ENEMY_SPEED * variant.speedMultiplier * getEnemySpeedMultiplier(world.elapsed),
    color: variant.color,
  });
}

export function updateEnemySpawning(world: WorldState, deltaMs: number) {
  world.spawnTimer -= deltaMs;

  if (world.spawnTimer <= 0 && world.enemies.length < getMaxEnemies(world.elapsed)) {
    spawnEnemy(world);
    world.spawnTimer = getSpawnInterval(world.elapsed);
  }
}
