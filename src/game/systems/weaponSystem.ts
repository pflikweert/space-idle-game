import { BULLET_SPEED, PLAYER_FIRE_INTERVAL } from '../core/constants';
import { distanceSquared, normalize } from '../core/math';
import type { Enemy, WorldState } from '../core/types';

function findNearestEnemy(world: WorldState): Enemy | null {
  if (world.enemies.length === 0) {
    return null;
  }

  let nearest = world.enemies[0];
  let nearestDistance = distanceSquared(world.player, nearest);
  for (const enemy of world.enemies.slice(1)) {
    const enemyDistance = distanceSquared(world.player, enemy);
    if (enemyDistance < nearestDistance) {
      nearest = enemy;
      nearestDistance = enemyDistance;
    }
  }

  return nearest;
}

function fireAtNearestEnemy(world: WorldState) {
  const nearest = findNearestEnemy(world);
  if (nearest === null) {
    return;
  }

  const direction = normalize(nearest.x - world.player.x, nearest.y - world.player.y);
  world.bullets.push({
    id: world.nextId++,
    x: world.player.x,
    y: world.player.y - world.player.radius,
    radius: 4,
    vx: direction.x * BULLET_SPEED,
    vy: direction.y * BULLET_SPEED,
    life: 1.65,
  });
}

export function updateWeapons(world: WorldState, deltaMs: number) {
  world.fireTimer -= deltaMs;

  if (world.fireTimer <= 0) {
    fireAtNearestEnemy(world);
    world.fireTimer = PLAYER_FIRE_INTERVAL;
  }
}
